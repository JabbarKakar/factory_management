# Sales Agreement — Sprint 6 QA Checklist

Use this after deploying PDF + dual-path cleanup.

## PDF — Single Order Invoice

- [ ] From Order → View Invoice → Export PDF / Print
- [ ] Header shows factory branding, **SALES INVOICE**, order #, optional agreement #
- [ ] Line items, totals, paid, due match on-screen invoice
- [ ] Bank & remittance block uses Factory Settings accounts (or empty hint)
- [ ] Terms & conditions always present (configured or Sales defaults)
- [ ] Signature / stamp block renders when uploaded on factory profile
- [ ] Payment history section appears when payments exist

## PDF — Grand Sales Invoice

- [ ] From Agreement → View Invoice → Export PDF / Print
- [ ] Title is **GRAND SALES INVOICE** with agreement #
- [ ] One section per billable order (order #, date, stock lines, charges/paid/remaining)
- [ ] Agreement totals match grand invoice (total / paid / outstanding)
- [ ] Bank + terms + authorization blocks match single-order chrome
- [ ] Excel export uses Grand title + Agreement # reference

## Dual-path / Agreement link cleanup

- [ ] Deep link `/sales/order/{id}` for a linked order opens Agreement → Order detail
- [ ] Deep link for a legacy unlinked order **auto-repairs** via `ensureAgreementForOrder` then opens detail
- [ ] Creating a new Sales Order always stamps `agreementId`
- [ ] Generating a single invoice fails clearly if order still has no agreement
- [ ] App start backfill leaves no leftover unlinked orders (`remainingLegacyOrders == 0`)
- [ ] Deliveries can only be scheduled from a Sales Order (no flat Deliveries FAB)

## Regression smoke

- [ ] Job Work grand invoice PDF still opens
- [ ] Sales Agreement list finance bar still works
- [ ] Record payment on order + grand still syncs paid/due
