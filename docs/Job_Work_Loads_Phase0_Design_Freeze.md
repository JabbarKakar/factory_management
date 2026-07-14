# Job Work + Loads — Phase 0 Design Freeze

**Status:** Frozen for Sprint 1+  
**Date:** 11 July 2026  
**Scope:** Design & inventory only — **no feature UI, no schema writes in this phase**  
**Parent plan:** Persistent Job Work + Loads refactor (C + C decisions)

---

## 1. Locked product decisions

| Decision | Choice | Implication |
|----------|--------|-------------|
| JW per customer | **C** — prefer one open JW; operator may create another | Primary CTA = Add Load when open JW exists; New Job Work is secondary |
| Payments | **C** — invoice/pay **per Load** now | Every invoice/payment path carries `jobWorkId` + `loadId`; JW-level unallocated pay is **schema-ready only**, not built |
| Term | **Load** | Do not use Batch (collides with Production Batches) |
| Firestore | Top-level `jobWorkLoads` | Queryable by factory, customer, jobWork, status without deep subcollection scans |
| Migration | Existing JW → one **default Load** | Compatibility layer first; hard cutover in Sprint 7 |
| Dispatch | Collect Material per Load | Not Sales Delivery |

---

## 2. Target hierarchy

```
Customer
  └── Job Work (persistent container)          collection: jobWorkOrders
        └── Load 1..N (independent lifecycle)  collection: jobWorkLoads
              ├── nested: input, cuttingSpec, pricing, output, execution, outputShifts
              ├── jobWorkInvoices   (1 active invoice typical per Load)
              ├── jobWorkCollections (many)
              └── qualityChecks     (reference → Load)
```

**Mental model**

| Layer | Owns | Does not own |
|-------|------|--------------|
| **Job Work** | Customer link, `JW-` number, derived summary, aggregate counters (optional denorm) | Cutting FSM, output, invoice, collect qty |
| **Load** | Full cutting/finance/pickup lifecycle (today’s order semantics) | Customer identity (denormalized only) |

---

## 3. Status design (frozen)

### 3.1 Load status = today’s order FSM

**Do not invent a parallel status vocabulary in Sprint 1.**  
Reuse the existing values as **`LoadStatus`**, 1:1 with current `JobWorkStatus` firestore strings, so migration is a field move, not a remapping.

| LoadStatus (Firestore) | Label | Role |
|------------------------|-------|------|
| `received` | Received | Intake recorded |
| `agreed` | Agreed | Commercial agreement |
| `inCutting` | In Cutting | Production |
| `qc` | QC | Quality |
| `ready` | Ready | Ready for pickup |
| `invoiced` | Invoiced | Invoice generated |
| `paid` | Paid | Invoice fully paid |
| `partiallyCollected` | Partially Collected | Some material collected |
| `collected` | Collected | All produced stock collected |
| `closed` | Closed | Load archived |
| `cancelled` | Cancelled | Voided |

**Getter semantics** (same as today on `JobWorkStatus`) move to `LoadStatus`:

- `isActive`, `isInProduction`, `isCompleted`, `isPendingPickup`
- `canRecordOutput`, `canCollectMaterial`, `isCollectionStatus`
- `canAdvanceOperationally`, `nextOperationalStatus`, `nextCompletionStatus`

**User-facing synonyms** (docs/UI copy only — not separate enum values):

| Informal phrase | Maps to LoadStatus |
|-----------------|-------------------|
| Pending | `received` |
| In production | `inCutting` / `qc` |
| Ready for dispatch/pickup | `ready` |
| Partially dispatched | `partiallyCollected` |
| Fully delivered | `collected` |

### 3.2 Job Work container summary (derived)

Job Work **does not** run the cutting FSM after migration.

Introduce **`JobWorkSummaryStatus`** (derived or lightly denormalized):

| Summary | Rule |
|---------|------|
| `active` | ≥1 load with non-terminal status (not `collected`/`closed`/`cancelled`) |
| `pendingPickup` | ≥1 load `isPendingPickup` with remaining qty |
| `idle` | ≥1 load exists and all loads are `collected`/`closed` (JW still open for Add Load) |
| `cancelled` | JW explicitly cancelled (rare; all loads cancelled or JW-level cancel) |

**Rules**

- Closing **one Load** never closes the Job Work or other Loads.
- Job Work stays **Add-Load-eligible** while `idle` or `active` (unless cancelled).
- List filters that today mean “In Cutting / Ready / …” become **Load-scoped** filters (or “JW has any load in …”).

### 3.3 Enum migration strategy

| Sprint | Approach |
|--------|----------|
| 1 | Add `LoadStatus` as typedef/mirror of current values; keep `JobWorkStatus` for legacy dual-read |
| 3+ | All production/collect/invoice gates use `LoadStatus` |
| 7 | Deprecate order-level FSM writes; `JobWorkStatus` on legacy docs becomes read-only archive or removed from writes |

---

## 4. Firestore schema (frozen)

### 4.1 `jobWorkOrders` — container (post-migration shape)

```
jobWorkOrders/{jobWorkId}
  jobWorkNumber          string   // JW-{year}-{####}  (unchanged generator)
  factoryId              string
  customerId             string
  customerName           string   // denormalized
  summaryStatus          string   // JobWorkSummaryStatus firestore value
  schemaVersion          int      // 1 = legacy nested work; 2 = loads authoritative
  defaultLoadId          string?  // set after ensureDefaultLoad
  loadCount              int?     // optional denorm
  activeLoadCount        int?     // optional denorm
  // Aggregate counters (optional; may be computed in app until Sprint 6)
  totalBlocksReceived    int?
  totalBlocksCut         int?
  outstandingBalance     number?
  createdAt, updatedAt
  closedAt?              // only if JW-level close is added later
```

**After Sprint 7:** nested `input` / `cuttingSpec` / `pricing` / `output` / `execution` / `outputShifts` / order-level `status` / `invoiceId` / `collectedAt` are **not written**. They may remain on legacy docs as read-only archive until purged.

**During Sprint 1–6:** dual-read allowed (see §5).

### 4.2 `jobWorkLoads` — work unit (new)

```
jobWorkLoads/{loadId}
  loadNumber             string   // JWL-{year}-{####} factory-wide unique
  loadSequence           int      // 1-based within Job Work (display “Load 1”)
  jobWorkId              string
  jobWorkNumber          string   // denormalized
  factoryId              string
  customerId             string
  customerName           string
  status                 string   // LoadStatus
  receivedDate           timestamp
  expectedCompletionDate?
  mineLocation?, mineOwner?
  input: { variety, blockCount, totalTons, volumeM3?, dimensions?, notes?, vehicleNumber? }
  cuttingSpec: { strategy, targetProduct, smallSizes, largeSizes, legacySizes?, thickness, finish, specialInstructions? }
  pricing: { model, agreedRate, smallStockPrice, largeStockPrice, finalCuttingCharges?, advanceReceived, balanceDue, paymentTerms, paymentDueDate? }
  output?: { ... same as today ... }
  execution?: { startDate?, endDate?, supervisor?, progressNotes? }
  outputShifts?: [ ... same as today ... ]
  invoiceId?             string   // active invoice for this load (Option A)
  collectedAt?, closedAt?
  createdAt, updatedAt
  migratedFromJobWork    bool?    // true for default Load created from legacy JW
```

**Numbering**

| Entity | Pattern | Notes |
|--------|---------|--------|
| Job Work | `JW-{year}-{####}` | Unchanged; container identity |
| Load | `JWL-{year}-{####}` | Factory-wide count (same style as JW/JWI/JC) |
| Display | Load sequence `1..N` per JW | UI “Load 3”; search by `JWL-…` or sequence |

### 4.3 Child collections (add `loadId`)

| Collection | Keep | Add | Notes |
|------------|------|-----|--------|
| `jobWorkInvoices` | `jobWorkId`, `jobWorkNumber` | **`loadId`**, **`loadNumber`** | Required for new invoices; backfill on migration |
| `jobWorkCollections` | `jobWorkOrderId`, `jobWorkNumber` | **`loadId`**, **`loadNumber`** | Keep `jobWorkOrderId` name for compat (see §4.5) |
| `payments` | `invoiceId`, `invoiceType` | Optional denorm `jobWorkId`/`loadId` later | Still reach Load via invoice; Option B later may use null `loadId` |
| `qualityChecks` | `referenceType`, `referenceId`, `referenceNumber` | New reference type **`jobWorkLoad`** (or keep `jobWork` pointing at load id after cutover) | Freeze: Sprint 3 uses `jobWorkLoad` + `referenceId = loadId` |
| `notifications` | `jobWorkId` | **`loadId`** | Navigation to load-scoped screens |

### 4.4 Indexes (planned)

```
jobWorkLoads: factoryId + jobWorkId
jobWorkLoads: factoryId + status
jobWorkLoads: factoryId + customerId
jobWorkLoads: factoryId + loadNumber  (if equality search needed)

jobWorkInvoices: factoryId + loadId
jobWorkCollections: factoryId + loadId
qualityChecks: factoryId + referenceId + referenceType  (already exists; new type value)
```

### 4.5 FK naming freeze

| Field | Meaning |
|-------|---------|
| `jobWorkId` | Container id (preferred on new fields) |
| `jobWorkOrderId` | **Legacy alias** on `jobWorkCollections` only — same as `jobWorkId`; do not rename until Sprint 7 |
| `loadId` | Load document id — required on new collect/invoice/QC/alert writes |

Sprint 7 may unify collections to `jobWorkId`; until then dual presence is OK (`jobWorkOrderId` required, `jobWorkId` optional mirror).

---

## 5. Compatibility & migration contract

### 5.1 Definitions

| Term | Meaning |
|------|---------|
| **Legacy JW** | `jobWorkOrders` doc with nested work fields and no (or incomplete) load children; `schemaVersion` missing or `1` |
| **Migrated JW** | `schemaVersion == 2`, `defaultLoadId` set, ≥1 `jobWorkLoads` doc |
| **Virtual Load** | In-memory Load synthesized from nested JW fields when no load doc exists yet |

### 5.2 Resolver contract (`JobWorkLoadResolver`) — Sprint 1

```
resolveLoads(jobWork) → List<Load>
  if any jobWorkLoads for jobWorkId → return those (authoritative)
  else → return [synthesizeDefaultLoad(jobWork)]  // virtual, not written yet
```

```
ensureDefaultLoad(jobWorkId) → Load  // idempotent write
  if load exists for jobWork → return it
  else create Load from nested JW fields:
    loadSequence = 1
    migratedFromJobWork = true
    copy status, input, cuttingSpec, pricing, output, execution, outputShifts,
         invoiceId, collectedAt, closedAt, mine*, receivedDate, …
    set jobWork.defaultLoadId, schemaVersion = 2
    backfill loadId onto existing invoices/collections for this JW (best-effort)
```

**When to call `ensureDefaultLoad`**

- Before any **write** that today mutates nested output/status/invoice/collect on the JW
- Optionally on JW detail open (lazy migration)
- Batch backfill job in Sprint 7 for remaining legacy docs

**Idempotency:** second call must not create Load 2.

### 5.3 Dual-read / dual-write window (Sprints 1–6) — closed in Sprint 7

| Operation | Behavior (Sprint 7+) |
|-----------|----------------------|
| Read list/detail | Persisted Loads only when `schemaVersion >= 2`; virtual Load only for pre-migration legacy |
| Record output / advance status / collect / invoice | Write **Load** only |
| Legacy nested fields | **Not written** on authoritative JW (`toFirestore(containerOnly: true)`); archive remains on disk |
| Batch backfill | `JobWorkLoadsBackfillService` on auth; stamps single-Load orphans; reports multi-Load orphans |
| Rules | `jobWorkInvoices` / `jobWorkCollections` **create** requires non-empty `loadId` |

Operator note: [`Job_Work_Add_Load_vs_New_Job_Work.md`](Job_Work_Add_Load_vs_New_Job_Work.md).

### 5.4 Data safety

- Nested legacy fields are **not deleted** automatically after Sprint 7 (archive until a purge sprint).
- Customer delete / JW delete must cascade **loads** + existing children.
- Multi-Load invoices/collections with null `loadId` are **not** auto-stamped — manual attribution required.

---

## 6. Payments (Option A now, B-ready)

| Rule | Detail |
|------|--------|
| Invoice | One logical invoice stream **per Load** (`loadId` required) |
| Many invoices per JW | Allowed (one per Load); remove `limit(1)` by `jobWorkId` as sole assumption |
| Payment | Still via `invoiceId` + `invoiceType: jobWork`; invoice carries `loadId` |
| JW outstanding | Sum of Load balances |
| Future Option B | Allow payment with `jobWorkId` set and `loadId` null (unallocated) — **not implemented** until a later epic |

---

## 7. UX rules (for later sprints — not built in Phase 0)

1. Customer with open JW → primary **Add Load**; secondary **Create another Job Work**.
2. JW detail = dashboard: summary + chronological Load list (group by year when helpful).
3. Operational screens (output, QC, collect, invoice) are **Load-scoped** routes:  
   `/job-work/:jobWorkId/loads/:loadId/...`
4. Closing a Load ≠ closing the Job Work.

---

## 8. Blast-radius inventory (files)

Paths relative to repo root. **M** = must modify for Loads; **N** = new; **R** = read-only / light touch.

### 8.1 Domain

| File | Tag | Why |
|------|-----|-----|
| `lib/domain/entities/job_work_order.dart` | M | Become container |
| `lib/domain/entities/job_work_load.dart` | N | Load entity |
| `lib/domain/entities/job_work_output.dart` | M | Attach to Load |
| `lib/domain/entities/job_work_invoice.dart` | M | Add loadId/loadNumber |
| `lib/domain/entities/job_work_collection.dart` | M | Add loadId/loadNumber |
| `lib/domain/entities/stock_output.dart` | R | Nested line type |
| `lib/domain/enums/job_work_enums.dart` | M | LoadStatus + summary + filters |
| `lib/domain/enums/job_work_collection_enums.dart` | R/M | Likely stable |
| `lib/domain/enums/quality_enums.dart` | M | `jobWorkLoad` reference |
| `lib/domain/enums/notification_enums.dart` | R/M | May add load-scoped types later |
| `lib/domain/entities/dashboard_kpis.dart` | M | Load-aware KPIs |
| `lib/domain/entities/quality_check.dart` | M | Reference load |
| `lib/domain/entities/app_notification.dart` | M | loadId |
| `lib/domain/entities/payment.dart` | R | Via invoice |
| `lib/domain/enums/invoice_enums.dart` | R | `InvoiceType.jobWork` |

### 8.2 Data models / repos

| File | Tag | Why |
|------|-----|-----|
| `lib/data/models/job_work_order_model.dart` | M | Slim container + schemaVersion |
| `lib/data/models/job_work_load_model.dart` | N | |
| `lib/data/models/job_work_invoice_model.dart` | M | loadId |
| `lib/data/models/job_work_collection_model.dart` | M | loadId |
| `lib/data/models/quality_check_model.dart` | M | reference type |
| `lib/data/models/notification_model.dart` | M | loadId |
| `lib/data/repositories/job_work_repository.dart` | M | Container CRUD + ensureDefaultLoad hook |
| `lib/data/repositories/job_work_load_repository.dart` | N | |
| `lib/data/repositories/job_work_invoice_repository.dart` | M | Per-load invoice |
| `lib/data/repositories/job_work_collection_repository.dart` | M | Per-load collect |
| `lib/data/repositories/payment_repository.dart` | M | Sync Load status |
| `lib/data/repositories/quality_check_repository.dart` | M | Eligible loads |

### 8.3 Services / helpers

| File | Tag | Why |
|------|-----|-----|
| `lib/data/services/job_work_load_resolver.dart` | N | Dual-read / synthesize |
| `lib/data/services/job_work_collection_quantity_helper.dart` | M | Load-scoped stock pool |
| `lib/data/services/job_work_collection_status_helper.dart` | M | Load status sync |
| `lib/core/utils/job_work_charges_calculator.dart` | M | Load charges |
| `lib/core/utils/job_work_block_progress.dart` | M | Load shifts |
| `lib/core/utils/dashboard_job_work_metrics.dart` | M | Aggregate loads |
| `lib/data/services/operational_alert_scanner_service.dart` | M | Per-load alerts |
| `lib/data/services/payment_due_scanner_service.dart` | M | Invoice→load |
| `lib/data/services/customer_ledger_service.dart` | M | Multi-invoice per JW |
| `lib/data/services/customer_statement_service.dart` | M | |
| `lib/data/services/dashboard_analytics_service.dart` | M | |
| `lib/data/services/pl_report_service.dart` | R/M | Revenue still from payments |
| `lib/data/services/job_work_cleanup_service.dart` | M | Cascade loads |
| `lib/data/services/export/job_work_collection_slip_pdf_exporter.dart` | M | Show load # |
| `lib/data/services/export/invoice_pdf_exporter.dart` | M | Load context |
| `lib/data/services/export/proforma_invoice_pdf_template.dart` | M | |

### 8.4 BLoCs

| File | Tag | Why |
|------|-----|-----|
| `lib/blocs/job_work/job_work_list_*.dart` | M | Container list + load-aware filters |
| `lib/blocs/job_work/job_work_form_*.dart` | M | Create JW + first Load |
| `lib/blocs/job_work/job_work_output_*.dart` | M | Load-scoped |
| `lib/blocs/job_work/job_work_invoice_*.dart` | M | By loadId |
| `lib/blocs/job_work/job_work_collection_form_*.dart` | M | By loadId |
| `lib/blocs/job_work/job_work_load_*` | N | Load list/form |
| `lib/blocs/dashboard/dashboard_*.dart` | M | |
| `lib/blocs/customer/customer_*` | M | Counts / cascade / Add Load CTA |
| `lib/blocs/quality/qc_form_*.dart` | M | Reference loads |

### 8.5 UI / routes / DI

| Area | Tag | Notes |
|------|-----|-------|
| All `lib/presentation/screens/job_work/*` | M | Detail → dashboard; load routes |
| All `lib/presentation/widgets/job_work/*` except generic detail_section/row | M | |
| `job_work_detail_section.dart`, `job_work_detail_row.dart` | R | Generic layout |
| Dashboard / pending pickups / customer widgets | M | |
| QC / notifications screens | M | Navigation targets |
| `route_paths.dart`, `app_router.dart` | M | `/loads/:loadId` |
| `injection.dart`, `app_strings.dart` | M | |
| `firestore.rules`, `firestore.indexes.json` | M | |

### 8.6 Tests

| File | Tag |
|------|-----|
| `test/data/services/job_work_collection_*_test.dart` | M |
| `test/core/utils/job_work_*_test.dart` | M |
| `test/data/services/job_work_load_resolver_test.dart` | N |
| Migration / ensureDefaultLoad tests | N |

### 8.7 Docs

| File | Tag |
|------|-----|
| This file | Phase 0 freeze |
| `docs/Marble_Factory_Management_System_Documentation.md` | Update Module 8 after Sprint 2+ |
| `docs/MFMS_v1.1_Roadmap.md` | Optional backlog pointer |

---

## 9. Current-state facts (baseline)

### Collections & FKs today

| Collection | FK fields |
|------------|-----------|
| `jobWorkOrders` | — (root) |
| `jobWorkInvoices` | `jobWorkId`, `jobWorkNumber` |
| `jobWorkCollections` | `jobWorkOrderId`, `jobWorkNumber` |
| `payments` | `invoiceId`, `invoiceType: jobWork` |
| `qualityChecks` | `referenceType: jobWork`, `referenceId` = order id |
| `notifications` | `jobWorkId?` |

### Number prefixes today

| Prefix | Pattern |
|--------|---------|
| JW- | `JW-{year}-{####}` |
| JWI- | `JWI-{year}-{####}` |
| JC- | `JC-{year}-{####}` |
| JWL- | **new** for Loads |

### Nested work on JW today (moves to Load)

`input`, `cuttingSpec`, `pricing`, `output`, `execution`, `outputShifts`, plus order-level `status`, `invoiceId`, `collectedAt`, `closedAt`, mine fields, `receivedDate`.

---

## 10. Sprint gate checklist

Phase 0 is **complete** when this document is accepted. Sprint 1 may start only with:

- [x] Product decisions C + C locked  
- [x] LoadStatus = current FSM values (no parallel enum)  
- [x] Container vs Load field ownership defined  
- [x] `ensureDefaultLoad` / resolver contract defined  
- [x] Child FK plan (`loadId`) defined  
- [x] Blast-radius file list captured  
- [ ] **No feature UI in Phase 0** (confirmed — none shipped)

---

## 11. Explicit non-goals (Phase 0 / near term)

- Implementing Add Load UI  
- Writing `jobWorkLoads` in production  
- Auto-merging multiple historical JWs for one customer  
- Building JW-level unallocated payments  
- Renaming `jobWorkOrderId` on collections before Sprint 7  
- Changing Sales Delivery / Production Batch modules  

---

## 12. Approval

| Role | Sign-off |
|------|----------|
| Product (factory workflow) | C + C + Load term |
| Engineering | Schema + resolver + status freeze |

**Next:** Sprint 1 — Domain + Firestore foundation + `JobWorkLoadResolver` / `ensureDefaultLoad` (still minimal UI).
