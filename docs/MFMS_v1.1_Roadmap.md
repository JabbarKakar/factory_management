# MFMS v1.1 — Pending Tasks & Roadmap

**Marble Factory Management System (MFMS)**  
**Document version:** 1.0  
**Date:** June 2026  
**Status:** Planning document (post–v1.0 release)

---

## 1. Purpose

This document lists **all remaining work** planned after **v1.0** (Sprints 1–24). It complements the main specification:

- **Reference:** [`Marble_Factory_Management_System_Documentation.md`](./Marble_Factory_Management_System_Documentation.md) — full product vision (v1.1+)
- **This file:** actionable backlog for **v1.1** only

### v1.0 status (complete)

Sprints **S1–S24** delivered a production-usable factory app:

| Phase | Sprints | Delivered |
|-------|---------|-----------|
| Phase 1 — Job Work MVP | S1–S7 | Customers, job work, invoices, payments, basic alerts, dashboard |
| Phase 2 — Operations & money | S8–S15 | Sales, expenses, P&L, suppliers, raw material, production, inventory |
| Phase 3 — Advanced operations | S16–S20 | Labour, delivery, equipment, QC, notification engine (in-app) |
| Phase 4 — Polish & release | S21–S24 | Charts, roles, exports, WhatsApp reminders, performance, release APK |

**v1.0 exit criteria met:** A factory can run job work + sales + own production with money visibility, operational modules, exports, and manual WhatsApp payment reminders.

---

## 2. v1.1 goals

v1.1 closes the largest gaps between **what the full spec describes** and **what v1.0 ships**, without entering long-term “future enhancement” territory (multi-factory, FBR, IoT, customer portal, etc.).

### v1.1 exit criteria

When v1.1 is done, the factory should have:

1. **Push notifications** (FCM) + configurable alert settings  
2. **Waste & scrap** module (Module 13) — basic tracking and scrap sales  
3. **Expanded reports** — overdue/aging, production, job work, inventory summaries  
4. **Offline resilience** — local queue + sync indicator for critical flows  
5. **In-app user invites** — owner can add staff without Firebase Console  
6. **Production release** — Play Store–ready signing, AAB, smaller APK  
7. **Test & audit hardening** — BLoC tests for critical paths, basic audit log  

---

## 3. Priority overview

| Priority | Theme | Suggested sprint | Business value |
|----------|--------|------------------|----------------|
| **P0** | Production release hardening | S25 | Safe public / sideload deployment |
| **P1** | Push notifications & settings | S26 | Alerts reach users when app is closed |
| **P2** | Waste & scrap module | S27 | Track scrap income and job work waste |
| **P3** | Advanced reports hub | S28 | Management reporting beyond P&L + statements |
| **P4** | Offline-first (critical data) | S29 | Factory floor with poor connectivity |
| **P5** | User admin + QC polish + audit | S30 | Team onboarding, QC photos, accountability |

Items marked **v1.2+** in Section 8 are intentionally **out of v1.1 scope**.

---

## 4. Detailed backlog by area

### 4.1 P0 — Production release hardening (S25)

**Current v1.0 state:** Release APK builds with debug signing; `applicationId` is `com.example.factory_management`; universal APK ~70 MB.

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 25.1 | Production signing | Release keystore, `signingConfig` in `build.gradle.kts` | Signed APK/AAB installs without debug key warning |
| 25.2 | Application ID | Rename to production package (e.g. `com.yaqoobmarble.mfms`) | Firebase project updated; `google-services.json` replaced |
| 25.3 | App Bundle (AAB) | `flutter build appbundle --release` + script | Play Store upload ready |
| 25.4 | APK size reduction | R8 minify/shrink, review assets/fonts | Meaningful size drop vs v1.0 universal APK |
| 25.5 | Versioning & changelog | `version` in `pubspec.yaml`, `CHANGELOG.md` | Traceable releases |
| 25.6 | Firestore deploy checklist | Document + verify rules + indexes deployed | `paymentReminders`, `notifications`, `qualityChecks` indexes live |
| 25.7 | Onboarding doc for factory | Install APK, login, first customer, first job work | Owner can self-deploy without developer |

**Doc reference:** §29 Release, §28 Security

---

### 4.2 P1 — Push notifications & settings (S26)

**Current v1.0 state:** In-app notification center, daily scan on login, operational + payment alerts. **No FCM**, **no local notifications**, **no owner-configurable settings**.

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 26.1 | FCM integration | `firebase_messaging`, token per user/device | Device receives push when app backgrounded |
| 26.2 | Local notifications | `flutter_local_notifications` for due today / overdue | Alert shown on lock screen when configured |
| 26.3 | Notification settings screen | Owner toggles per alert type, quiet hours, min amount | Settings stored in `factories/{id}.notificationSettings` |
| 26.4 | Channel mapping | Map doc rules (due 7/3/1, overdue repeat) to engine | Behaviour matches Module 17 table where feasible |
| 26.5 | Supplier payable alerts | Due/overdue for supplier balances | Alerts in notification center + optional push |
| 26.6 | Credit limit exceeded alert | Trigger when new order exceeds limit | In-app + push |
| 26.7 | Dashboard widget polish | Top overdue customers (doc §21.4) | Widget shows count + top 5 list |

**Doc reference:** §21 Notifications & Alerts (full Module 17)

**Not in v1.1:** WhatsApp Business API auto-send (see §8).

---

### 4.3 P2 — Waste & scrap module (S27)

**Current v1.0 state:** Job work output records waste fields; production batches track grades. **No dedicated Module 13** — no scrap inventory, scrap sales, or scrap P&L line.

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 27.1 | Firestore schema | `scrapInventory`, `scrapTransactions` (or equivalent) | Rules + indexes |
| 27.2 | Scrap types catalog | Slurry, off-cuts, chips, reject tiles, etc. | Matches doc §17.1 |
| 27.3 | Auto-capture from production | Reject / waste from batch → scrap stock | Optional manual adjustment |
| 27.4 | Auto-capture from job work | Waste from job work output → tagged record | Linked to job work order |
| 27.5 | Scrap stock register | Current qty, valuation | List + detail screens |
| 27.6 | Scrap sale entry | Qty, rate, buyer, amount | Revenue recorded |
| 27.7 | P&L integration | Scrap revenue under “Other income” | Monthly P&L reflects scrap sales |
| 27.8 | Basic scrap report | Generated vs sold vs disposed (monthly) | PDF/Excel export |

**Doc reference:** §17 Module 13 — Waste & Scrap Management

---

### 4.4 P3 — Advanced reports (S28)

**Current v1.0 state:** Reports hub with monthly P&L, expense summary, customer statements, invoice PDF/Excel. Many report types in doc §22.1 are **not** built.

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 28.1 | Overdue invoices report | All open overdue sales + job work | Filter, PDF, Excel |
| 28.2 | Upcoming dues report | Due in next 7/15/30 days | Exportable |
| 28.3 | Customer aging report | Buckets: current, 30, 60, 90+ days | PDF/Excel |
| 28.4 | Job work summary report | Monthly revenue, active orders, yield | Hub entry + export |
| 28.5 | Production summary report | Monthly output sq. ft by variety | Hub entry + export |
| 28.6 | Inventory valuation report | Finished goods + raw material value | Snapshot export |
| 28.7 | Stock status / movement reports | In/out summary per material/SKU | Basic date range |
| 28.8 | Attendance / payroll summary | Monthly HR exports | PDF/Excel from labour data |
| 28.9 | Equipment maintenance cost report | Cost + downtime from logs | Monthly summary |
| 28.10 | Reports hub expansion | Group by Production / Sales / Financial / HR / Inventory | Permission-gated tiles |

**Doc reference:** §22 Module 18 — Reports & Exports

**Deferred to v1.2:** Yearly P&L, cash flow, COGS analysis, QC defect-frequency reports.

---

### 4.5 P4 — Offline-first (critical paths) (S29)

**Current v1.0 state:** Firestore offline cache only. **No Drift/SQLite**, **no sync queue**, **no sync status UI**.

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 29.1 | Drift setup | Local DB + mirror tables for critical collections | App compiles; migrations work |
| 29.2 | Sync queue | `sync_queue` table; retry on reconnect | Failed writes retry automatically |
| 29.3 | Write path | Expense, attendance, stock movement, job work output | Works offline; syncs when online |
| 29.4 | Sync indicator | Green / orange / red dot in app bar | User sees pending/error state |
| 29.5 | Conflict policy | Last-write-wins + server timestamp for financial docs | Documented behaviour |
| 29.6 | Read path | Cache-first for lists (customers, job work, stock) | Usable with airplane mode |

**Doc reference:** §27 Offline-First Strategy

**Not in v1.1:** Full mirror of all 20+ collections; background `workmanager` due scanner (optional stretch).

---

### 4.6 P5 — User admin, QC polish, audit (S30)

**Current v1.0 state:** Team screen lists users and changes roles (S22). **No in-app user creation.** QC has no photos. **No audit log.**

| # | Task | Description | Acceptance criteria |
|---|------|-------------|---------------------|
| 30.1 | Invite user flow | Owner sends invite email / temp password | New user appears in team list |
| 30.2 | Disable / deactivate user | Soft-disable without deleting Firestore history | Cannot login when disabled |
| 30.3 | Factory profile editor | Name, address, logo on `factories/{id}` | Used on PDFs and reminders |
| 30.4 | QC defect photos | `image_picker` + Firebase Storage | Photos on QC detail |
| 30.5 | QC edit / delete | Correct mistaken inspections | Owner or QC role only |
| 30.6 | Customer complaint log | Basic CRUD linked to customer | Module 14 §18.2 |
| 30.7 | Audit log | `auditLogs` collection: who/when/what on financial mutations | Owner can view log |
| 30.8 | BLoC test coverage | Dashboard, payment reminder, auth blocs | CI runs `flutter test` |
| 30.9 | WhatsApp share on exports | Share PDF statement/invoice via system share | Works on MIUI + stock Android |

**Doc reference:** §16 Module 16, §18 Module 14, §28 Security (audit)

---

## 5. v1.0 known gaps (polish, not new modules)

These are small improvements identified during v1.0 sprints. Bundle into v1.1 sprints as time allows.

| Area | Gap | Suggested sprint |
|------|-----|----------------|
| Suppliers | “Record purchase” / “Stock in” shortcut from supplier detail | S28 or S30 |
| Raw material | Dashboard KPI opens list pre-filtered to low stock | S28 |
| Stock in ↔ expense | Optional link when recording stock receipt | S29 |
| Job work | Digital agreement photo on order | S30 |
| Delivery | GPS / map link for address (not live tracking) | v1.2 |
| Dashboard | List screen performance (virtualization) | S25 |
| Login / branding | App logo on login screen (splash logo exists) | S25 |
| iOS | TestFlight build + launch assets | S25 (if iOS needed) |

---

## 6. Module completion matrix

Legend: **Done** = v1.0 MVP · **Partial** = core exists, doc gaps remain · **Pending** = not started

| Module | v1.0 | v1.1 target |
|--------|------|-------------|
| 1 Dashboard | Partial | Top overdue customers, performance |
| 2 Raw materials | Partial | Reports, offline sync |
| 3 Production | Partial | Production reports, scrap link |
| 4 Inventory | Partial | Valuation/movement reports |
| 5 Equipment | Partial | Maintenance cost report |
| 6 Labour & HR | Partial | Attendance/payroll exports |
| 7 Customer CRM | Done | Complaint log |
| 8 Job work | Done | Agreement photos, waste reports |
| 9 Sales | Done | Overdue/aging reports |
| 10 Suppliers | Partial | Payable alerts, PO deferred |
| 11 Expenses | Done | — |
| 12 P&L | Partial | Yearly/COGS → v1.2 |
| **13 Waste/scrap** | **Pending** | **Full v1.1 module** |
| 14 QC | Partial | Photos, complaints, edit |
| 15 Delivery | Done | GPS tracking → v1.2 |
| 16 User roles | Partial | Invite/disable users |
| 17 Notifications | Partial | FCM, local, settings |
| 18 Reports | Partial | Report hub expansion |

---

## 7. Suggested sprint schedule (v1.1)

| Sprint | Focus | Duration (guide) |
|--------|--------|------------------|
| **S25** | Release hardening + deploy docs | 1 week |
| **S26** | FCM + notification settings | 2 weeks |
| **S27** | Waste & scrap module | 2 weeks |
| **S28** | Advanced reports | 2 weeks |
| **S29** | Offline-first (critical paths) | 2–3 weeks |
| **S30** | User admin, QC polish, audit, tests | 2 weeks |

**Total estimate:** ~10–12 weeks for v1.1 (adjust based on factory priority).

### If the factory wants a smaller v1.1

Minimum viable **v1.1-lite** (highest ROI only):

1. S25 — Production signing + Firestore deploy  
2. S26 — Push notifications for payment due/overdue  
3. S28 — Overdue invoices + customer aging reports  

Defer waste module and offline sync to **v1.2**.

---

## 8. Explicitly out of v1.1 (v1.2+ / future)

These appear in the main documentation but are **not** scheduled for v1.1:

| Feature | Reason to defer |
|---------|----------------|
| WhatsApp Business API (auto-send) | Requires Meta Business API, templates, compliance |
| Multi-factory / branches | Architecture change |
| Customer web portal | Separate web project |
| Quotation module | New sales workflow |
| Purchase order module | Supplier workflow expansion |
| GPS live delivery tracking | Maps API, driver app complexity |
| Biometric attendance hardware | Device integration |
| FBR / tax integration | Regulatory project |
| Bank reconciliation | Accounting scope |
| Machine IoT | Hardware dependency |
| AI price suggestion | ML / data volume |
| Marble rate API | External data dependency |
| Full Drift mirror of all collections | Large engineering effort |
| Yearly P&L, cash flow, COGS deep dive | v1.2 financial phase |

**Doc reference:** §30 Future Enhancements

---

## 9. Technical prerequisites for v1.1

Before starting S25–S30:

- [ ] v1.0 APK tested on factory devices (job work → invoice → payment → reminder)  
- [ ] Firestore rules + indexes deployed to production Firebase project  
- [ ] Firebase Blaze plan if using Cloud Functions for scheduled scans (optional)  
- [ ] Play Console account (if Play Store release)  
- [ ] Decision: production `applicationId` and app name on store  
- [ ] Backup strategy confirmed (Firestore automatic backups enabled)  

---

## 10. How to use this document

1. **Prioritise with the factory owner** — e.g. push alerts vs waste module first.  
2. **Pick the next sprint** from Section 7 (or v1.1-lite from Section 7).  
3. **Track tasks** using the tables in Section 4 (copy into GitHub Issues / project board).  
4. **Update this file** when v1.1 ships — mark items done and cut v1.2 doc.  

---

## 11. Document history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jun 2026 | Initial v1.1 roadmap after Sprint 24 / v1.0 completion |

---

*For the complete functional specification, see [`Marble_Factory_Management_System_Documentation.md`](./Marble_Factory_Management_System_Documentation.md).*
