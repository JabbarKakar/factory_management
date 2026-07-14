# Add Load vs New Job Work

Operator guidance for the Job Work + Loads model (Sprint 7 cutover).

## When to **Add Load**

Use **Add Load** on an existing open Job Work when:

- More blocks / material arrive for the **same customer engagement** (same mine/job relationship).
- You need another cutting run, collection, invoice, or payment cycle under the same Job Work number.
- The Job Work is still open (`active` / `idle` / in progress) — Add Load is the primary action on the customer summary when an open JW exists.

Each Load has its own input, cutting, output, QC, collect, invoice, and payments. Closing one Load does **not** close the Job Work or other Loads.

## When to create a **New Job Work**

Use **New Job Work** when:

- This is a **new commercial engagement** with the customer (different job, contract, or accounting container).
- The previous Job Work is cancelled or you intentionally want a separate JW number for reporting.
- There is **no** open Job Work for that customer yet.

New Job Work is the secondary CTA when an open Job Work already exists.

## What operators should not do on the Job Work itself

After migration (Loads authoritative):

| Action | Do it on… |
|--------|-----------|
| Record output / shifts | **Load** |
| QC | **Load** |
| Collect material | **Load** |
| Invoice / record payment | **Load** |
| Edit cutting sizes, rates, blocks | **Load** (Edit Load) |
| Add another batch of material | **Add Load** |
| Change customer label / mine notes on the container | Job Work (container edit only) |

Nested fields left on old Job Work documents are a **read-only archive**. Do not expect edits on the Job Work form to change cutting/output/pricing once Loads exist.

## Multi-Load orphans (manual review)

If an invoice or collection has no `loadId` and the Job Work already has **more than one** Load, the app will **not** auto-assign it (unsafe). Stamp the correct Load in Firestore or via support before treating migration as complete.
