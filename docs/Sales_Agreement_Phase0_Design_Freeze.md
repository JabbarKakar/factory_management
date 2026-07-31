# Sales Agreement + Orders — Phase 0 Design Freeze

**Status:** Frozen for Sprint 1+  
**Date:** 31 July 2026  
**Scope:** Design & schema foundation — **no feature UI in this sprint**  
**Parent plan:** Align Sales architecture with Job Work hierarchy (Agreement → Orders → Grand/Single invoices)

---

## 1. Locked product decisions

| Decision | Choice | Implication |
|----------|--------|-------------|
| Parent entity | **Sales Agreement** | Customer-facing container; number `SA-{year}-{####}` |
| Child entity | **Sales Order** | Billable unit under an Agreement (like JW Load); keeps `ORD-` numbers |
| Payments | Invoice/pay **per Order** now | Every single invoice carries `agreementId` + `salesOrderId`; Agreement-level unallocated pay is schema-ready only |
| Grand Invoice | Agreement-scoped | `salesInvoices` with `agreementId` set and empty `salesOrderId` |
| Deliveries | Stay under Order | Fulfillment history per Order (like JW collections per Load) |
| Firestore | Top-level `salesAgreements` | Queryable by factory, customer, status |
| Migration | Legacy Order → one Agreement (1:1) | Backfill creates Agreement + stamps `agreementId`; dual-read until later sprints |
| Term | **Agreement** / **Order** | Do not call Orders “Loads” or “Dispatches” in UI |

---

## 2. Target hierarchy

```
Customer
  └── Sales Agreement (persistent container)     collection: salesAgreements
        └── Order 1..N (independent lifecycle)   collection: salesOrders
              ├── salesInvoices   (1 active single invoice typical per Order)
              ├── deliveries      (many)
              └── payments        (via invoiceId)
        └── Grand salesInvoice   (agreementId set, salesOrderId empty)
```

**Mental model**

| Layer | Owns | Does not own |
|-------|------|--------------|
| **Sales Agreement** | Customer link, `SA-` number, derived summary, aggregate finance denorm | Line-item stock, dispatch FSM, per-order invoice |
| **Sales Order** | Stock/rates, order status FSM, single invoice, deliveries, advances | Customer identity (denormalized only) |

---

## 3. Status design (frozen)

### 3.1 Order status = today’s sales order FSM

**Do not invent a parallel status vocabulary in Sprint 1.**  
Reuse existing `SalesOrderStatus` Firestore values on Orders unchanged.

### 3.2 Agreement summary (derived)

Introduce **`SalesAgreementSummaryStatus`** (derived or lightly denormalized):

| Summary | Rule |
|---------|------|
| `active` | ≥1 order with non-terminal status (not `paid`/`closed`/`cancelled`/`delivered`) |
| `pendingDelivery` | ≥1 order `ready` or `partiallyDispatched` |
| `idle` | ≥1 order exists and all non-cancelled orders are terminal (`paid`/`closed`/`delivered`) |
| `cancelled` | Agreement explicitly cancelled, or all orders cancelled |

**Rules**

- Closing **one Order** never closes the Agreement or other Orders.
- Agreement stays **Add-Order-eligible** while `idle` or `active` (unless cancelled).
- List filters that today mean “Ready / Partially Dispatched / …” become **Order-scoped** (or “Agreement has any order in …”).

### 3.3 Schema version

| Constant | Value | Meaning |
|----------|-------|---------|
| `SalesAgreementSchemaVersion.legacy` | `1` | Pre-Agreement dual-read / incomplete link |
| `SalesAgreementSchemaVersion.ordersAuthoritative` | `2` | Orders under Agreement are authoritative |

---

## 4. Firestore schema (frozen)

### 4.1 `salesAgreements` — container (new)

```
salesAgreements/{agreementId}
  agreementNumber        string   // SA-{year}-{####}
  factoryId              string
  customerId             string
  customerName           string   // denormalized
  summaryStatus          string   // SalesAgreementSummaryStatus
  schemaVersion          int      // 1 = legacy link; 2 = orders authoritative
  orderCount             int?
  activeOrderCount       int?
  // Optional denorm finance (computed in later sprints)
  totalAmount            number?
  paidAmount             number?
  balanceDue             number?
  notes?                 string
  createdAt, updatedAt
  closedAt?
```

### 4.2 `salesOrders` — order unit (extended)

```
salesOrders/{salesOrderId}
  // existing fields unchanged (orderNumber ORD-…, lineItems, status, finance, …)
  agreementId            string?  // required on new writes after Sprint 2
  agreementNumber        string?  // denormalized
  orderSequence          int?     // 1-based within Agreement (display “Order 1”)
  // existing: invoiceId, advanceReceived, balanceDue, …
```

### 4.3 `salesInvoices` — single + grand (extended)

```
salesInvoices/{invoiceId}
  // existing: invoiceNumber, factoryId, customer*, items, total/paid/due, status, …
  agreementId            string?  // required on new writes after Sprint 3/4
  agreementNumber        string?
  salesOrderId           string   // EMPTY for Grand Invoice; set for Single Order Invoice
  orderNumber            string   // empty or agreement label for Grand
```

**Discrimination**

| Kind | `agreementId` | `salesOrderId` | Getter |
|------|---------------|----------------|--------|
| Single Order Invoice | set | non-empty | `!isGrandInvoice` |
| Grand Sales Invoice | set | empty / null | `isGrandInvoice` |

### 4.4 Indexes (Sprint 1)

```
salesAgreements: factoryId + customerId
salesAgreements: factoryId + summaryStatus

salesOrders: factoryId + agreementId
salesInvoices: factoryId + agreementId
salesInvoices: factoryId + salesOrderId   (already used; keep)
```

### 4.5 FK naming freeze

| Field | Meaning |
|-------|---------|
| `agreementId` | Sales Agreement container id |
| `salesOrderId` | Child Order id — empty on Grand Invoice |
| `orderSequence` | 1-based display index within Agreement |

---

## 5. Compatibility & migration contract

### 5.1 Definitions

| Term | Meaning |
|------|---------|
| **Legacy Order** | `salesOrders` doc with missing/empty `agreementId` |
| **Migrated Order** | `agreementId` set; parent Agreement `schemaVersion == 2` |
| **Backfill Agreement** | 1:1 Agreement created from a legacy Order (`orderSequence = 1`) |

### 5.2 Backfill contract (`SalesAgreementBackfillService`) — Sprint 1

```
ensureAgreementForOrder(order) → Agreement  // idempotent
  if order.agreementId set and Agreement exists → return it
  else create Agreement from order customer/factory/dates:
    agreementNumber = SA-{year}-{####}
    summaryStatus derived from order.status
    schemaVersion = 2
    orderCount = 1
  stamp order: agreementId, agreementNumber, orderSequence = 1
  stamp existing salesInvoices for salesOrderId with agreementId/agreementNumber
```

**When to call**

- `SalesOrderRepository.createSalesOrder` → `ensureAgreementForOrder` (always, after write)
- `runIfNeeded(factoryId)` on auth — re-checks for leftover legacy orders even if a prior completion flag was set
- Before Agreement-scoped writes in later sprints

**Idempotency:** second call must not create Agreement 2 for the same Order.

### 5.3 Dual-read window (Sprints 1–5)

| Operation | Behavior |
|-----------|----------|
| Read existing screens | Still Order-centric; Agreement fields optional |
| New Agreement UI | Sprint 2+ |
| Grand Invoice writes | Sprint 4+; require `agreementId`, empty `salesOrderId` |
| Legacy nested/order fields | Not deleted |

---

## 6. Payments (Order-scoped now, Agreement-ready)

| Rule | Detail |
|------|--------|
| Single invoice | One active invoice stream **per Order** (`salesOrderId` required) |
| Many invoices per Agreement | Allowed (one per Order + optional Grand) |
| Payment | Still via `invoiceId` + `invoiceType: sales` |
| Agreement outstanding | Sum of Order balances (later rollup helper) |
| Future unallocated pay | Allow payment with `agreementId` and empty `salesOrderId` — **not implemented** until a later epic |

---

## 7. UX rules

1. Sales list → **Agreements** (like Job Work list).
2. Agreement detail = dashboard: summary + Orders list + Add Order + Grand Invoice CTA.
3. Order detail = stock, Single Invoice, payments, deliveries.
4. Closing an Order ≠ closing the Agreement.

---

## 8. Sprint 1 deliverables checklist

- [x] This design freeze document
- [x] `SalesAgreement` entity + model
- [x] `SalesAgreementSummaryStatus` + schema version constants
- [x] Extend `SalesOrder` / model with Agreement link fields
- [x] Extend `SalesInvoice` / model with `agreementId` + grand discrimination
- [x] `SalesAgreementRepository` + agreement-scoped order/invoice queries
- [x] Firestore rules + indexes
- [x] `SalesAgreementBackfillService` (1:1 legacy Order → Agreement)
- [x] `createSalesOrder` always links via `ensureAgreementForOrder`
- [x] Backfill re-scans leftovers after a stale “complete” flag

---

## 8b. Sprint 2 deliverables checklist

- [x] Routes: `/sales` Agreement list, `/sales/:agreementId` detail, `/sales/:agreementId/orders/add`, `/sales/:agreementId/orders/:salesOrderId`
- [x] Agreement list + detail screens (Job Work parallel)
- [x] Add Agreement (`/sales/add`) + Add Order under Agreement (stock form)
- [x] `SalesContainerSyncHelper` + `syncAgreementContainer` on order mutations
- [x] Grand Invoice CTA placeholder (generation = Sprint 4)
- [x] Edit Agreement entry on list + detail
- [x] Secondary flat order list at `/sales/orders`
- [x] `SalesContainerSyncHelper` unit tests

---

## 8c. Sprint 3 deliverables checklist

- [x] Order detail Invoice section (Generate / View / Record Payment)
- [x] Order detail Payment History (live watch + edit/delete)
- [x] Watch single-order invoice + payments on order detail
- [x] Payment sync updates `salesInvoices` → `salesOrders` finance → Agreement rollup
- [x] One active single invoice per order (skip cancelled; Grand excluded)

---

## 9. Out of scope for Sprint 1–3

- Grand Invoice generation / PDF (Sprint 4)
- Changing Delivery schema
