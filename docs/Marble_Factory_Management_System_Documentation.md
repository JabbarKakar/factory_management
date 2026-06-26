# Marble Factory Management System (MFMS)
## Full Technical & Functional Documentation
### Flutter Application — Version 1.1

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Firebase vs Supabase — Recommendation](#3-firebase-vs-supabase--recommendation)
4. [App Architecture](#4-app-architecture)
5. [Module 1 — Dashboard & Analytics](#5-module-1--dashboard--analytics)
6. [Module 2 — Raw Material Management](#6-module-2--raw-material-management)
7. [Module 3 — Production Management](#7-module-3--production-management)
8. [Module 4 — Inventory Management](#8-module-4--inventory-management)
9. [Module 5 — Equipment & Machinery Management](#9-module-5--equipment--machinery-management)
10. [Module 6 — Labour & HR Management](#10-module-6--labour--hr-management)
11. [Module 7 — Customer Management (CRM)](#11-module-7--customer-management-crm)
12. [Module 8 — Job Work & Contract Cutting Service](#12-module-8--job-work--contract-cutting-service) *(NEW)*
13. [Module 9 — Sales & Order Management](#13-module-9--sales--order-management)
14. [Module 10 — Supplier Management](#14-module-10--supplier-management)
15. [Module 11 — Expense & Cost Management](#15-module-11--expense--cost-management)
16. [Module 12 — Financial Reporting (P&L)](#16-module-12--financial-reporting-pl)
17. [Module 13 — Waste & Scrap Management](#17-module-13--waste--scrap-management)
18. [Module 14 — Quality Control](#18-module-14--quality-control)
19. [Module 15 — Delivery & Logistics](#19-module-15--delivery--logistics)
20. [Module 16 — User Roles & Permissions](#20-module-16--user-roles--permissions)
21. [Module 17 — Notifications & Alerts](#21-module-17--notifications--alerts) *(ENHANCED)*
22. [Module 18 — Reports & Exports](#22-module-18--reports--exports)
23. [Database Schema (Overview)](#23-database-schema-overview)
24. [Flutter Project Structure](#24-flutter-project-structure)
25. [Key Flutter Packages](#25-key-flutter-packages)
26. [UI/UX Guidelines](#26-uiux-guidelines)
27. [Offline-First Strategy](#27-offline-first-strategy)
28. [Security Considerations](#28-security-considerations)
29. [Deployment & Release Plan](#29-deployment--release-plan)
30. [Future Enhancements](#30-future-enhancements)

---

## 1. Project Overview

**App Name:** Marble Factory Management System (MFMS)
**Platform:** Flutter (Android + iOS + Web optional)
**Target User:** Marble cutting/processing factory owner, managers, supervisors, and workers
**Purpose:** A comprehensive, end-to-end factory management solution specifically designed for marble processing businesses. It covers every operational aspect — from raw stone procurement to finished product delivery — along with full financial visibility through monthly and yearly Profit & Loss statements.

### Core Business Context

A marble factory typically performs the following operations:

- **Procurement** of raw marble blocks/slabs from quarries or suppliers
- **Cutting** of large marble blocks into slabs, tiles, or custom shapes using gang saws or wire saws
- **Job Work / Contract Cutting** — customers bring their own marble blocks; the factory cuts them per agreed specifications and charges a cutting fee
- **Polishing & Finishing** using polishing machines
- **Quality checking** before dispatch
- **Sale and delivery** to builders, contractors, retailers, or individuals
- **Management of workforce**, equipment, utilities, and finances

### Three Revenue Streams

| Stream | Description | Who Owns the Stone |
|---|---|---|
| **Own Production & Sales** | Factory buys marble, cuts, polishes, and sells finished goods | Factory |
| **Job Work / Contract Cutting** | Customer brings blocks; factory cuts per specs and charges service fee | Customer |
| **Hybrid** | Customer buys some stock AND brings blocks for cutting | Mixed |

The MFMS app digitalizes and centralizes all of these operations into a single mobile/tablet app.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| State Management | **BLoC** (`flutter_bloc` + `equatable`) |
| Local Database | SQLite via `drift` package |
| Online Sync | Firebase (recommended — see Section 3) |
| Authentication | Firebase Auth |
| File Storage | Firebase Storage (for photos, PDFs, invoices) |
| PDF Generation | `pdf` + `printing` Flutter packages |
| Charts & Analytics | `fl_chart` or `syncfusion_flutter_charts` |
| Notifications | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` |
| Excel Export | `excel` Flutter package |
| QR/Barcode | `mobile_scanner` package |

---

## 3. Firebase vs Supabase — Recommendation

### ✅ Recommendation: Firebase

**Why Firebase is better for this use case:**

| Criteria | Firebase | Supabase |
|---|---|---|
| **Offline Support** | ✅ Excellent — Firestore has built-in offline caching, critical for factory floor use where internet may be spotty | ⚠️ Limited offline support |
| **Real-time Sync** | ✅ Native real-time listeners — stock changes, orders update instantly across devices | ✅ Good but requires setup |
| **Flutter SDK** | ✅ FlutterFire is the most mature Flutter–Firebase integration | ✅ Supabase Flutter SDK exists but less mature |
| **Authentication** | ✅ Rich options (Email, Phone, Google) | ✅ Similar |
| **File Storage** | ✅ Firebase Storage, easy integration | ✅ Supabase Storage, also good |
| **Scalability** | ✅ Auto-scales, no server management | ✅ Also scalable |
| **Cost** | Free tier is generous for small factory | Free tier good but Firebase is more predictable |
| **Community / Docs** | ✅ Largest community, most Stack Overflow answers | Growing |
| **Complex Queries** | ⚠️ Firestore has limited query capability | ✅ PostgreSQL full SQL support |
| **Relational Data** | ⚠️ Needs structuring | ✅ Native relational tables |

**Verdict:** For a **marble factory** with mobile workers who may face connectivity issues on the factory floor, **Firebase + Firestore is the best choice** due to its superior offline-first capabilities and real-time sync.

### Firebase Architecture for MFMS:
- **Firestore** — core business data (orders, customers, stock, labour, job work)
- **Firebase Auth** — user login and roles
- **Firebase Storage** — invoice PDFs, product photos, equipment images, block photos
- **Firebase Cloud Messaging** — push notifications for dues, overdues, low stock, order updates
- **Firebase Analytics** — optional usage analytics

---

## 4. App Architecture

```
MFMS App
│
├── Presentation Layer (Flutter UI)
│   ├── Screens / Pages
│   ├── Widgets (Reusable)
│   └── Navigation (GoRouter)
│
├── State Management Layer (BLoC)
│   ├── Blocs (business logic coordinators)
│   ├── Events (user/system actions)
│   ├── States (UI states: initial, loading, loaded, error)
│   └── BlocObserver (logging, analytics)
│
├── Domain Layer (Business Logic)
│   ├── Use Cases
│   ├── Entities
│   └── Repository Interfaces
│
├── Data Layer
│   ├── Firebase Repositories (remote)
│   ├── SQLite Repositories (local/offline)
│   └── Data Models (DTOs)
│
└── Core
    ├── Constants
    ├── Themes
    ├── Utils (formatters, validators)
    └── Services (auth, notification, export)
```

**Pattern:** Clean Architecture + BLoC + Repository Pattern
**Navigation:** GoRouter (named routes, deep linking)
**Dependency Injection:** `get_it` service locator (registers repositories, use cases, blocs)

### BLoC Conventions

| Convention | Rule |
|---|---|
| **One Bloc per feature** | e.g. `CustomerBloc`, `JobWorkBloc`, `NotificationBloc` |
| **Events** | Named as verbs: `LoadCustomers`, `AddCustomer`, `RecordJobWorkPayment` |
| **States** | Use `Equatable`; include `copyWith` via sealed classes or freezed |
| **UI wiring** | `BlocProvider` at route level; `BlocBuilder` / `BlocListener` in widgets |
| **Side effects** | Navigation, snackbars, and one-time alerts via `BlocListener` only |
| **Cross-bloc** | Use repository streams or a thin `AppBloc` for global session — avoid bloc-to-bloc direct calls |
| **Testing** | `bloc_test` package for unit tests on every bloc |

### Example BLoC Flow (Job Work)

```
UI: User taps "Save Job Work Order"
  → JobWorkBloc.add(SaveJobWorkOrder(order))
  → emit JobWorkSaving()
  → JobWorkRepository.save(order)
  → emit JobWorkSaved(order) | JobWorkError(message)
  → BlocListener shows snackbar / navigates back
```

---

## 5. Module 1 — Dashboard & Analytics

### Purpose
The first screen every user sees. Gives a live bird's-eye view of the factory's current status.

### Features

#### 5.1 KPI Cards (Top Row)
- Today's Revenue (PKR) — split: Sales + Job Work
- Today's Production (sq. ft or pieces)
- Active Orders Count (Sales + Job Work)
- Pending Deliveries Count
- **Upcoming Dues (next 7 days)** — total PKR receivable
- **Overdue Payments** — count + total PKR
- Low Stock Alerts Count
- Present Labour Count

#### 5.2 Production Chart
- Daily / Weekly / Monthly bar chart of marble produced (tons, slabs, tiles)
- Separate series for **own production** vs **job work output**
- Compare current month vs previous month

#### 5.3 Sales Chart
- Line chart: Revenue trend over last 30/90/365 days
- Category breakdown: Tiles vs Slabs vs Custom vs **Job Work Fees**

#### 5.4 Quick Action Buttons
- + New Sales Order
- + **New Job Work Order**
- + Record Production
- + Add Expense
- + New Customer

#### 5.5 Alerts Panel
- Low raw material stock warnings
- **Upcoming customer payment dues (3 / 7 / 15 days)**
- **Overdue customer payments (with aging)**
- **Upcoming supplier payables**
- Equipment maintenance due dates
- Pending deliveries
- **Job work orders awaiting customer pickup**

#### 5.6 Recent Activity Feed
- Last 10 transactions (sales, job work, purchases, payments)

---

## 6. Module 2 — Raw Material Management

### Purpose
Track all incoming marble raw materials — blocks, rough slabs — from procurement to factory entry.

> **Note:** Raw materials purchased by the factory for own production. Customer-owned blocks for job work are tracked in **Module 8 — Job Work**, not here.

### 6.1 Raw Material Types (Marble-specific)

| Material | Unit | Description |
|---|---|---|
| Marble Blocks | Cubic meter (m³) / Ton | Large uncut blocks from quarry |
| Marble Rough Slabs | Slab (piece) / m² | Pre-cut rough slabs |
| Marble Chips/Aggregate | Ton / Bag | Byproduct or purchased chips |
| Silica Sand | Bag / Ton | Used in polishing |
| Diamond Segments | Piece | Cutting blade components |
| Abrasive Pads | Set | Polishing consumables |
| Water (utility) | Liters tracked | Used in cutting & cooling |
| Resin/Epoxy | Kg / Liter | Crack filling and surface treatment |
| Colorants/Dyes | Liter | For coloring marble tiles |
| Cutting Wire | Meter roll | For wire saw machines |
| Lubricating Oil | Liter | Machine maintenance |
| Grinding Wheels | Piece | Edge finishing |

### 6.2 Features

#### Stock Entry (Purchase Receipt)
- Select Supplier
- Material Type
- Quantity & Unit
- Unit Cost (PKR)
- Total Cost (auto-calculated)
- Date of receipt
- Vehicle number (transport record)
- Challan/Invoice number
- Quality grade (A/B/C)
- Add photo of delivery
- Notes/remarks
- Batch/Lot number

#### Stock Register (Real-time)
- Current stock quantity per material
- Reorder Level setting (trigger low-stock alert)
- Average cost per unit (weighted average)
- Last purchase date
- Total stock value (PKR)

#### Stock Consumption (Factory Use)
- Record daily consumption per material per production batch
- Auto-deduct from stock on production record
- Manual adjustment with reason

#### Stock History
- Full log of all receipts and consumption
- Filter by date, material, supplier
- Export to Excel/PDF

#### Low Stock Alerts
- Notification when stock falls below reorder level
- Dashboard badge count

---

## 7. Module 3 — Production Management

### Purpose
Track every **own-factory** production batch from raw block to finished marble product.

> **Distinction:** This module is for stone **owned by the factory**. Customer-owned stone processed on contract is handled in **Module 8 — Job Work**.

### 7.1 Marble Product Types

| Product | Unit | Description |
|---|---|---|
| Marble Tiles | sq. ft / piece | Standard cut square/rectangle tiles |
| Marble Slabs (Polished) | sq. ft / slab | Large polished slabs |
| Marble Slabs (Unpolished) | sq. ft / slab | Cut but not polished |
| Marble Strips/Border | Linear ft | Thin strips for borders |
| Marble Steps/Stairs | piece / linear ft | Custom stair pieces |
| Custom Cut Pieces | piece | Custom shape per order |
| Marble Columns/Pillars | piece | Decorative pillars |
| Marble Countertops | sq. ft | Kitchen/bathroom tops |
| Marble Flooring Sheets | sq. ft | Large format floor tiles |
| Marble Mosaic Tiles | sq. ft | Small decorative pieces |
| Marble Chips (finished) | Bag/Ton | Byproduct sold separately |

### 7.2 Marble Varieties/Colors (stock list)

Each product is associated with a marble variety:
- White Ziarat
- Green Onyx
- Verona Grey
- Sunny Grey
- Black Marquina (imported)
- Botticino Beige
- Crema Marfil (imported)
- Thar White
- Mughal Pink
- Badal Grey
- Custom (user-defined)

### 7.3 Features

#### Production Batch Entry
- Batch ID (auto-generated)
- Production Type: **Own Stock** (default for this module)
- Date & Shift (Morning/Evening/Night)
- Raw material consumed (linked to stock, auto-deducts)
- Machine/Equipment used
- Workers assigned (linked to Labour module)
- Production output:
  - Product type
  - Marble variety
  - Quantity produced
  - Unit (sq. ft, pieces, slabs)
  - Thickness (e.g. 18mm, 20mm, 30mm)
  - Size (e.g. 60x60cm, 30x60cm, custom)
  - Quality grade (A, B, C, Reject)
- Wastage/scrap generated (auto-added to Waste module)
- Production cost (auto-calculated from materials + labour + machine cost)
- Supervisor name
- Notes

#### Daily Production Summary
- Total produced per product type per day
- Total raw material consumed
- Total waste generated
- Shift-wise breakdown

#### Production History
- Filter by date, product, machine, worker
- Search by batch ID
- Export to PDF/Excel

#### Production vs Target
- Set monthly production targets per product
- Real-time progress bar
- Alert if production is below target

---

## 8. Module 4 — Inventory Management

### Purpose
Manage the finished goods stock — what's ready to sell (factory-owned inventory only).

### 8.1 Features

#### Finished Goods Stock
- Auto-populated from Production module (completed batches)
- Stock card per SKU (product + variety + size + thickness + grade)
- Current quantity in sq. ft / pieces / slabs
- Location in factory (e.g. Shed A, Shed B, Open Yard)
- Stock valuation (cost-based)

#### Manual Adjustment
- Add stock (for opening balance, returns from customer)
- Reduce stock (damage, correction)
- Reason required for manual adjustment
- Full audit log

#### Stock Transfer
- Move stock between storage locations within factory
- Date, quantity, from-location, to-location, authorized by

#### Low Stock Alert
- Set minimum stock level per SKU
- Auto-notification when below threshold

#### Barcode/QR Integration
- Generate QR code for each stock SKU
- Scan QR to instantly view stock details
- Scan to record consumption on sale

#### Inventory Valuation Report
- Total stock value (cost)
- Total stock value (at sale price) = potential revenue
- By product category
- Monthly snapshot for balance sheet

---

## 9. Module 5 — Equipment & Machinery Management

### Purpose
Track all factory machinery, tools, and assets — their condition, usage, and maintenance.

### 9.1 Equipment Types (Marble Factory Specific)

| Equipment | Description |
|---|---|
| Gang Saw / Multi-blade Saw | Cuts marble blocks into slabs |
| Wire Saw Machine | Cuts large blocks using diamond wire |
| Bridge Saw / Disc Cutter | Precision cuts for tiles and custom shapes |
| Edge Polishing Machine | Finishes edges of tiles/slabs |
| Surface Polishing Machine | Polishes top surface to glossy/matte finish |
| Water Jet Cutter | High-precision custom shape cutting |
| Crane / Overhead Hoist | Lifts heavy marble blocks |
| Forklift | Moves marble slabs in yard |
| Resin Line Machine | Applies resin to fill cracks |
| Calibrating Machine | Makes tiles uniform thickness |
| Chamfering Machine | Creates beveled edges |
| Compressor | Air supply for tools |
| Water Pump / Recycling System | Water supply for cutting |
| Generator | Backup electricity |
| Conveyor Belt | Moves slabs between stations |
| Hand Grinder | Manual edge work |
| Overhead Crane | Block movement |

### 9.2 Features

#### Equipment Register
- Equipment ID (auto)
- Equipment Name
- Category (Cutting / Polishing / Lifting / Utility)
- Brand / Model / Serial Number
- Purchase Date
- Purchase Cost (PKR)
- Supplier/Vendor
- Current Status: Running / Under Maintenance / Broken / Retired
- Location in factory
- Photos (Firebase Storage)
- Notes
- Depreciation rate % (for P&L)
- Current book value (auto-calculated)

#### Maintenance Log
- Schedule: Last Maintenance Date + Next Due Date
- Maintenance Type: Preventive / Corrective / Emergency
- Description of work done
- Parts replaced (linked to spare parts inventory)
- Cost of maintenance (labour + parts)
- Performed by (in-house / external vendor)
- Downtime duration (hours)
- Status after maintenance

#### Maintenance Alerts
- Notification X days before next scheduled maintenance
- Dashboard badge for overdue maintenance

#### Spare Parts Inventory
- Part name, quantity, unit cost
- Minimum stock level (reorder alert)
- Linked to specific machines

#### Equipment Cost Report
- Monthly maintenance costs per machine
- Total downtime hours per machine
- Depreciation per month (for P&L)
- Cost per production unit (PKR per sq. ft)

---

## 10. Module 6 — Labour & HR Management

### Purpose
Manage all factory workers — daily attendance, wages, advances, and payroll.

### 10.1 Worker Categories

| Category | Description |
|---|---|
| Machine Operator | Operates gang saw, bridge saw, polishing machines |
| Helper / Assistant | Assists machine operators |
| Polish Worker | Manual polishing/finishing |
| Loading/Unloading Worker | Handles blocks and slabs |
| Crane Operator | Operates overhead crane/hoist |
| Forklift Driver | Moves stock in yard |
| Supervisor | Oversees production floor |
| Quality Inspector | Checks final products |
| Security Guard | Factory security |
| Cleaner | Factory cleaning |
| Driver | Delivery truck driver |
| Electrician | Electrical maintenance |
| Mechanic | Machine repair |
| Accountant | Handles financial records (office) |
| Manager | Overall supervision |

### 10.2 Features

#### Employee Profile
- Employee ID (auto)
- Full Name, Father's Name
- CNIC Number
- Date of Birth
- Address
- Phone Number(s)
- Emergency Contact
- Job Title / Category
- Department
- Date of Joining
- Employment Type: Permanent / Daily Wage / Contract
- Salary Type: Monthly Fixed / Daily Rate / Per Piece Rate
- Salary/Rate Amount (PKR)
- Bank Account (if applicable)
- ID Card photo (Firebase Storage)
- Skills/Certificates
- Notes

#### Daily Attendance
- Mark Present / Absent / Half-Day / Leave / Holiday
- Attendance time: Check-in / Check-out
- Shift assigned (Morning / Evening / Night)
- Overtime hours recorded
- Weekly view and monthly view
- Bulk attendance entry (mark all present, then modify exceptions)

#### Leave Management
- Types: Casual Leave, Sick Leave, Earned Leave, Without Pay
- Leave application (with approval workflow)
- Leave balance per employee
- Leave history

#### Wages & Payroll
- Auto-calculate monthly salary based on attendance
- Daily wage calculation for daily-wage workers
- Overtime pay (rate × 1.5 or custom)
- Deductions: Advance deductions, fines
- Bonus (Eid bonus, performance bonus)
- Final payslip generation (PDF)
- Payroll summary per month (total wages expense for P&L)

#### Advance Salary
- Record advance taken by employee
- Amount, date, reason
- Auto-deduct from next salary
- Outstanding advance balance

#### Piece-Rate Workers
- Link production output to worker
- Pieces cut / sq. ft polished per worker per day
- Auto-calculate earnings based on piece rate

#### Labour Cost Report
- Total wages per month per department
- Per-worker annual cost
- Labour cost per unit of production (PKR per sq. ft)

---

## 11. Module 7 — Customer Management (CRM)

### Purpose
Full customer database with contact info, service preferences, order history, job work history, payment records, and marble purchase details.

### 11.1 Customer Profile

#### Basic Information
- Customer ID (auto)
- Customer Type: Individual / Business
- Full Name / Company Name
- Contact Person Name (for businesses)
- Phone Number(s) (multiple)
- WhatsApp Number
- Email Address
- Billing Address (Street, City, Province)
- Shipping Address (if different)
- CNIC / NTN number
- Customer Category: Retail / Wholesale / Contractor / Builder / Exporter
- **Primary Service Type** *(required at registration — see below)*
- Credit Limit (PKR)
- Payment Terms: Cash / 7 days / 15 days / 30 days / 60 days
- Date Added
- Referred By
- Notes / Special Instructions

#### Customer Service Type *(NEW — captured at registration)*

When adding a new customer, the app **must** ask what services they need. This drives which modules and workflows appear for that customer.

| Service Type | Code | Description | Enabled Modules |
|---|---|---|---|
| **Buyer Only** | `BUYER` | Purchases finished marble from factory stock | Sales, Delivery, Invoicing |
| **Job Work Only** | `JOB_WORK` | Brings own blocks for cutting only; does not buy stock | Job Work, Payments |
| **Buyer + Job Work** | `BOTH` | Buys finished goods AND brings blocks for cutting | All customer-facing modules |
| **Other Services** | `OTHER` | Polishing-only, edge work, resin filling, etc. | Custom service orders (future) |

- Multiple service types can be selected for `OTHER` with free-text description
- Service type can be updated later; history is preserved
- Customer list filter: by service type
- Dashboard and reports segment customers by service type

#### Customer Account Ledger
- Opening balance
- All sales invoices raised
- All job work invoices raised
- All payments received
- Debit notes / Credit notes
- Current outstanding balance (auto-calculated)
- Aging analysis (0-30 days, 31-60, 61-90, 90+ days overdue)
- **Next due date** and **amount due** prominently displayed on profile

### 11.2 Features

#### Customer List
- Search by name, phone, city, category, service type
- Filter by outstanding balance, overdue status, service type
- Sort by last order date, next due date
- Color indicator: Green (paid up), Yellow (due within 7 days), Orange (due today/tomorrow), Red (overdue)

#### Customer Statement
- Printable PDF statement for any date range
- Includes sales AND job work transactions
- Opening balance + transactions + closing balance
- Send via WhatsApp or email from app

#### Customer Purchase History
- All sales orders with: Product, Variety, Size, Quantity, Rate, Amount
- Filter by marble type they usually buy
- Lifetime purchase value
- Frequency of purchase (helps identify VIP customers)

#### Customer Job Work History *(NEW)*
- All job work orders linked to this customer
- Total tons processed, total sq. ft output, total fees earned
- Average yield % (output vs input)

#### Credit Management
- Credit limit set per customer
- Warning when new order exceeds credit limit
- Overdue payment alerts (linked to Notification module)

---

## 12. Module 8 — Job Work & Contract Cutting Service

### Purpose
Manage the complete lifecycle when a **customer brings their own marble blocks** to the factory for cutting. This is a core revenue stream separate from buying-and-selling finished marble.

### 12.1 Business Workflow

```
Customer Arrives with Blocks
    → Register / Select Customer (must have JOB_WORK or BOTH service type)
    → Inspect & Weigh Blocks (record tons, variety, condition)
    → Discuss Cutting Requirements (sizes, strategy, grade expectations)
    → Bargain & Agree Price (per ton / per sq. ft / lump sum)
    → Create Job Work Order (with cutting specifications)
    → Customer Signs Agreement (optional PDF / photo of signed chit)
    → Schedule Cutting (assign machine, shift, workers)
    → Execute Cutting (record daily progress)
    → Record Output by Grade (A / B / C / Waste)
    → QC Inspection (optional)
    → Notify Customer (ready for pickup)
    → Generate Job Work Invoice
    → Customer Pays (full or balance after advance)
    → Customer Collects Finished Material
    → Order Closed
```

### 12.2 Job Work Order Entry

#### Header
- Job Work ID (auto, e.g. `JW-2025-0001`)
- Date Received
- Customer (linked from CRM — filtered to JOB_WORK / BOTH)
- Expected Completion Date
- Status: `Received` → `Agreed` → `In Cutting` → `QC` → `Ready` → `Invoiced` → `Paid` → `Collected` → `Closed` / `Cancelled`

#### Input — Customer's Raw Material
| Field | Unit | Required | Notes |
|---|---|---|---|
| Marble Variety | — | Yes | e.g. White Ziarat, Sunny Grey |
| Number of Blocks | pieces | Yes | |
| Total Weight | **Tons** | Yes | Weighed at factory entry |
| Total Volume | m³ | Optional | |
| Block dimensions | L × W × H per block | Optional | For large blocks |
| Condition notes | text | Optional | Cracks, color variation |
| Photos | images | Recommended | Before cutting |
| Vehicle / Challan number | text | Optional | How material arrived |

#### Cutting Specification — How Customer Wants It Cut

This is the **most critical section**. Capture exactly what the customer agreed to.

| Field | Description |
|---|---|
| **Cutting Strategy** | Gang Saw (slabs) / Bridge Saw (tiles) / Wire Saw / Water Jet / Mixed |
| **Target Product** | Slabs / Tiles / Strips / Steps / Custom shapes |
| **Tile/Slab Size** | e.g. 12×12", 18×18", 24×24", 60×60cm, 30×60cm, custom |
| **Thickness** | e.g. 10mm, 18mm, 20mm, 30mm |
| **Finish Required** | Unpolished / Polished / Honed / Brushed / Edge-only |
| **Expected Output (sq. ft)** | Customer's estimate — for comparison |
| **Special Instructions** | Free text: vein direction, book-matching, min slab size, etc. |
| **Cutting Diagram** | Optional sketch/photo upload |

#### Pricing Agreement (After Bargaining)
| Field | Description |
|---|---|
| Pricing Model | Per Ton / Per Sq. Ft / Lump Sum / Per Block |
| Agreed Rate | PKR per unit |
| Estimated Total | Auto-calculated from rate × qty |
| **Negotiated Final Amount** | Actual agreed price after bargaining |
| Advance Received | PKR (if any at booking) |
| Balance Due | Auto: Final − Advance |
| Payment Due Date | Date by which customer must pay |
| Payment Terms | Cash on pickup / 7 days / etc. |

### 12.3 Cutting Execution & Output Recording

When cutting is complete (or per shift for large orders), record actual output:

#### Output by Quality Grade

| Grade | Field | Unit |
|---|---|---|
| **Grade A** | `gradeASqFt` | sq. ft |
| **Grade B** | `gradeBSqFt` | sq. ft |
| **Grade C** | `gradeCSqFt` | sq. ft |
| **Reject** | `rejectSqFt` | sq. ft |
| **Total Usable Output** | auto-sum A+B+C | sq. ft |

#### Waste & Yield Tracking

| Field | Unit | Description |
|---|---|---|
| **Waste Generated** | tons OR sq. ft | Stone lost as slurry, off-cuts, breakage |
| **Waste %** | % | Auto: waste ÷ input tons × 100 |
| **Yield %** | % | Auto: total usable sq. ft ÷ expected sq. ft × 100 |
| **Slurry / Dust** | liters or tons | Optional environmental tracking |

> Waste from job work belongs to the **customer** unless otherwise agreed. Record disposition: customer takes / factory keeps / disposed.

#### Production Link
- Machine used (from Equipment module)
- Workers assigned (from Labour module)
- Shift(s) worked
- Cutting start date / completion date
- Supervisor name
- Daily progress notes (for multi-day jobs)

### 12.4 Job Work Invoice & Payment

- Auto-generate invoice from completed job work order
- Invoice Number (e.g. `JWI-2025-0001`)
- Line items: cutting fee, polishing fee (if applicable), other charges
- Show summary: Input tons → Output A/B/C sq. ft → Waste
- Payment due date (triggers notification alerts)
- Receipt on payment
- Outstanding balance updates customer ledger

### 12.5 Job Work Reports

| Report | Description |
|---|---|
| Active Job Work Orders | In-progress jobs with expected completion |
| Completed Job Work Summary | Monthly count, revenue, tons processed |
| Yield Analysis | Average yield % by variety, machine, operator |
| Waste Analysis | Waste % trends by variety |
| Customer Job Work Statement | Per-customer history and totals |
| Revenue by Pricing Model | Per ton vs per sq. ft vs lump sum breakdown |
| Pending Pickups | Completed but not collected by customer |

### 12.6 Dashboard KPIs (Job Work)
- Active job work orders count
- Tons in processing (customer-owned stone on floor)
- Job work revenue this month
- Pending job work payments (PKR)
- Average yield % this month

---

## 13. Module 9 — Sales & Order Management

### Purpose
Manage the full **sales** cycle from order to delivery to payment (factory-owned finished goods).

> Customers with `BUYER` or `BOTH` service type only.

### 13.1 Sales Order

#### Order Entry
- Order ID (auto, e.g. ORD-2025-0001)
- Date
- Customer (linked from CRM — filtered to BUYER / BOTH)
- Delivery Address
- Expected Delivery Date
- Order Source: Walk-in / Phone / WhatsApp / Contractor
- Order Items:
  - Product Type (Tile/Slab/Custom)
  - Marble Variety
  - Size / Thickness
  - Quantity (sq. ft or pieces)
  - Unit Rate (PKR)
  - Discount %
  - Line Total (auto)
- Sub-total, Discount, Tax (if any), Grand Total
- Payment Terms
- Advance received at booking
- Special cutting/finishing instructions
- Order Status: Received / In Production / Ready / Dispatched / Delivered / Cancelled

#### Order Workflow
```
Order Received
    → Production Scheduled (linked to Production Module)
    → Stock Reserved
    → Ready for Delivery
    → Delivery Challan Generated
    → Delivered
    → Invoice Generated
    → Payment Received
    → Closed
```

### 13.2 Invoicing

#### Invoice Generation
- Auto-generate from confirmed order
- Invoice Number (e.g. INV-2025-0001)
- Full itemized list
- Subtotal, discount, taxes, grand total
- **Payment due date** (feeds notification engine)
- Terms & conditions
- Company header (factory name, address, phone)
- PDF generation
- Share via WhatsApp, Print, Email

#### Delivery Challan
- Separate from invoice
- Lists items dispatched (quantity may differ if partial delivery)
- Vehicle number, driver name
- Customer signature space (PDF)

#### Payment Recording
- Payment ID (auto)
- Date
- Customer
- Invoice linked (sales or job work)
- Payment Method: Cash / Bank Transfer / Cheque / Online
- Bank/Cheque details if applicable
- Amount received
- Outstanding balance (auto-updated)
- Receipt PDF generation

### 13.3 Sales Reports
- Daily sales summary
- Monthly sales by product type
- Monthly sales by marble variety
- Monthly sales by customer
- Top 10 customers by revenue
- Sales target vs actual
- Pending/overdue invoices list

---

## 14. Module 10 — Supplier Management

### Purpose
Manage all suppliers — marble quarries, material vendors, equipment suppliers, service providers.

### 14.1 Supplier Types
- Marble Block/Slab Supplier (quarry or wholesaler)
- Consumables Supplier (abrasives, diamond blades, wire)
- Chemical Supplier (resin, polish, epoxy)
- Machinery Supplier
- Spare Parts Supplier
- Transport/Logistics Supplier
- Utility (electricity, water)

### 14.2 Supplier Profile
- Supplier ID (auto)
- Supplier Name / Company
- Contact Person
- Phone Number(s)
- Address / City
- NTN / CNIC
- Bank Account (for payments)
- Payment Terms
- Materials they supply
- Lead time (days)
- Quality rating (1–5 stars based on experience)
- Notes

### 14.3 Features
- Supplier Ledger (purchases + payments = outstanding)
- Purchase history with each supplier
- Supplier Statement (printable PDF)
- Supplier performance (delivery time, quality issues)
- Compare quotes from multiple suppliers (manual entry)
- **Upcoming payable alerts** (linked to Notification module)

---

## 15. Module 11 — Expense & Cost Management

### Purpose
Record and categorize all factory expenses for accurate P&L calculation.

### 15.1 Expense Categories

| Category | Examples |
|---|---|
| Raw Material Purchase | Marble blocks, rough slabs |
| Labour Wages | All worker salaries |
| Electricity | Monthly electricity bills |
| Water & Sewage | Water bills, borehole expenses |
| Fuel | Diesel for generator, vehicles |
| Machine Maintenance | Repairs, servicing |
| Spare Parts | Blades, pads, segments |
| Transportation (Inward) | Freight on raw materials |
| Transportation (Outward) | Delivery charges |
| Rent | Factory premises rent |
| Office Supplies | Stationery, printing |
| Communication | Phone bills, internet |
| Bank Charges | Bank fees, interest |
| Depreciation | Equipment depreciation |
| Insurance | Factory/vehicle insurance |
| Marketing | Advertising, samples |
| Professional Fees | Accountant, lawyer |
| Miscellaneous | Petty cash, others |

### 15.2 Features

#### Expense Entry
- Expense ID (auto)
- Date
- Category
- Sub-category
- Description
- Amount (PKR)
- Payment Method: Cash / Bank / Cheque
- Payee (linked to Supplier or standalone)
- Invoice / Bill number
- Attach receipt photo (Firebase Storage)
- Approved by

#### Petty Cash Management
- Petty cash fund balance
- Petty cash expense entries (small day-to-day expenses)
- Replenishment record
- Petty cash register report

#### Monthly Expense Summary
- Total expenses by category
- Comparison with previous month
- Budget vs actual (if budget set)
- Largest expense categories (pie chart)

---

## 16. Module 12 — Financial Reporting (P&L)

### Purpose
Full Profit & Loss Statement — monthly and yearly — plus supporting financial summaries.

### 16.1 Income Statement (P&L)

#### Monthly P&L Structure

```
MARBLE FACTORY — PROFIT & LOSS STATEMENT
Period: [Month] [Year]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REVENUE
  Sales — Marble Tiles              PKR ___
  Sales — Marble Slabs              PKR ___
  Sales — Custom Cut Pieces         PKR ___
  Sales — Marble Chips / Scrap      PKR ___
  Job Work / Cutting Service Fees   PKR ___   ← NEW
  Other Income                      PKR ___
─────────────────────────────────────────────
GROSS REVENUE                       PKR ___
  Less: Sales Returns / Discounts  (PKR ___)
─────────────────────────────────────────────
NET REVENUE                         PKR ___

COST OF GOODS SOLD (COGS)
  Raw Material Consumed             PKR ___
  Direct Labour Wages               PKR ___
  Machine Running Cost (fuel/elec)  PKR ___
  Consumables (blades, pads, wire)  PKR ___
  Production Overhead               PKR ___
─────────────────────────────────────────────
TOTAL COGS                         (PKR ___)
─────────────────────────────────────────────
GROSS PROFIT                        PKR ___
GROSS PROFIT MARGIN                 ___%

OPERATING EXPENSES
  Electricity Bill                  PKR ___
  Rent                              PKR ___
  Administrative Salaries           PKR ___
  Transportation (Outward)          PKR ___
  Equipment Maintenance             PKR ___
  Depreciation                      PKR ___
  Insurance                         PKR ___
  Marketing & Advertising           PKR ___
  Bank Charges                      PKR ___
  Communication                     PKR ___
  Office & Admin Expenses           PKR ___
  Miscellaneous                     PKR ___
─────────────────────────────────────────────
TOTAL OPERATING EXPENSES           (PKR ___)
─────────────────────────────────────────────
OPERATING PROFIT (EBIT)             PKR ___
  Less: Interest Expense           (PKR ___)
─────────────────────────────────────────────
NET PROFIT / (LOSS)                 PKR ___
NET PROFIT MARGIN                   ___%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> **Note:** Job Work revenue is mostly service margin — COGS for job work is labour + machine time, not raw material (customer owns the stone).

#### Yearly P&L
- Same structure but aggregated annually
- Month-by-month comparison columns (Jan–Dec)
- Trend analysis: best month, worst month
- Year-over-year comparison (if data available)

### 16.2 Additional Financial Reports

#### Cash Flow Summary
- Cash inflows: collections from customers (sales + job work)
- Cash outflows: payments to suppliers, wages, expenses
- Net cash position

#### Accounts Receivable Aging
- Total outstanding from customers
- Broken down by aging buckets
- Separate tabs: Sales receivables vs Job Work receivables

#### Accounts Payable Aging
- Total owed to suppliers
- Broken down by aging buckets

#### Cost Per Unit Analysis
- Total cost of production ÷ total sq. ft produced
- Cost per sq. ft by product type
- Job work margin per ton / per sq. ft

#### Break-Even Analysis
- Fixed costs total
- Variable cost per unit
- Break-even quantity and revenue
- Shown as an interactive chart

### 16.3 Features
- Generate PDF of any financial report
- Export to Excel
- Share via WhatsApp
- Date range selector (any custom period)
- Comparison mode (current vs previous period)

---

## 17. Module 13 — Waste & Scrap Management

### Purpose
Track marble waste, scrap, and off-cuts — many of which have resale value.

### 17.1 Waste Types

| Waste Type | Disposition |
|---|---|
| Marble Slurry (water + dust) | Dispose / sell to cement factories |
| Off-cuts (large) | Cut and sell as smaller tiles |
| Off-cuts (small) | Sell as marble chips |
| Broken Slabs | Sell as decorative stone or chips |
| Reject Tiles (Grade C) | Sell at discounted price |
| Diamond Wire Scrap | Return to supplier / scrap dealer |
| Blade Segments (used) | Scrap dealer |
| Dust (fine powder) | Sell to chemical factories |

### 17.2 Features
- Auto-record scrap quantity from production batch entry
- Auto-record scrap from job work output (tagged to job work order)
- Scrap inventory (stock of saleable scrap)
- Scrap sales (record quantity sold, rate, customer, amount)
- Scrap revenue included in P&L under "Other Income"
- Monthly scrap analysis: generated vs sold vs disposed
- Job work waste report: waste % by customer variety

---

## 18. Module 14 — Quality Control

### Purpose
Ensure finished marble products meet quality standards before delivery or customer pickup.

### 18.1 Quality Grades
- **Grade A:** Perfect — no cracks, uniform color, smooth finish
- **Grade B:** Minor defects — slight color variation, minor edge chip
- **Grade C (Second Quality):** Noticeable defect — sold at discount
- **Reject:** Cannot be sold as marble product — goes to scrap

### 18.2 Features

#### QC Inspection Entry
- Batch ID (production) OR Job Work ID (job work)
- Inspector name + date
- Product details (type, variety, size)
- Quantity inspected
- Quantity Grade A / B / C / Reject
- Defects found: Cracks, Color variation, Size deviation, Surface defect, Edge defect
- Photos of defects (Firebase Storage)
- Disposition: Pass / Rework / Reject
- Inspector signature/name

#### QC Report
- Pass rate % per batch / per job work order
- Defect frequency analysis
- Reject rate trend (monthly)
- Inspector-wise report

#### Customer Complaint Log
- Complaint ID
- Customer name + date
- Product complained about
- Nature of complaint
- Action taken: Replacement / Credit Note / Repair
- Status: Open / Resolved
- Linked to customer account

---

## 19. Module 15 — Delivery & Logistics

### Purpose
Manage the dispatch of finished goods to customers (sales orders only; job work customers typically pick up).

### 19.1 Features

#### Delivery Order
- Delivery ID (auto)
- Sales Order linked
- Customer details
- Delivery address
- Scheduled delivery date
- Items to deliver (quantity, product)
- Vehicle assigned (truck/pickup)
- Driver assigned (linked to Labour)
- Loading supervisor
- Delivery Status: Scheduled / Loaded / In Transit / Delivered / Partially Delivered / Failed

#### Delivery Challan
- PDF generation
- Items loaded, quantity
- Vehicle details
- Driver name
- Sent to customer before arrival

#### Delivery Confirmation
- Mark as delivered
- Record actual delivery date/time
- Customer signature (image capture or digital)
- If partial delivery: remaining quantity auto-updates to pending

#### Vehicle/Fleet Management
- Vehicle list: Truck, Pickup, Rikshaw
- Vehicle registration number
- Driver assigned
- Fuel log (fill-up date, liters, cost)
- Maintenance log
- Running cost per month

#### Delivery Report
- Deliveries completed per day/month
- On-time delivery %
- Failed or returned deliveries
- Delivery cost per km (optional)

---

## 20. Module 16 — User Roles & Permissions

### Purpose
Control who can see and do what in the app.

### 20.1 Roles

| Role | Access Level |
|---|---|
| Owner / Admin | Full access to everything, all reports, settings |
| Factory Manager | Production, inventory, labour, equipment, job work — no financial P&L |
| Accountant | Financial modules, customer ledger, P&L, expenses — no production entry |
| Sales Staff | Customer management, orders, invoicing, delivery |
| **Job Work Clerk** | Job work orders, customer intake, output recording — no financial reports |
| Supervisor | Production entry, job work progress, attendance, QC — read-only elsewhere |
| Store Keeper | Raw material stock, finished goods inventory |
| Driver | View own delivery assignments only |
| Viewer | Read-only access to dashboard only |

### 20.2 Permissions Matrix
Each module has granular permissions:
- **View** — can see the data
- **Create** — can add new records
- **Edit** — can modify existing records
- **Delete** — can delete (Owner only by default)
- **Export** — can export to PDF/Excel
- **Approve** — for workflows (e.g., leave approval, credit limit override, job work pricing)

### 20.3 Multi-user Setup
- Each user has their own login (Firebase Auth)
- Role assigned by Owner in Settings
- Activity log: who did what, when (audit trail)

---

## 21. Module 17 — Notifications & Alerts

### Purpose
Proactive, reliable alerts so **nothing slips through the cracks** — especially payment dues and overdues across sales and job work.

### 21.1 Notification Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Notification Engine                     │
├─────────────────────────────────────────────────────────┤
│  Scheduled Jobs (daily 8 AM factory time)               │
│    → Scan all invoices, job work orders, payables       │
│    → Compute due dates, overdue days                    │
│    → Generate notifications per rules below             │
├─────────────────────────────────────────────────────────┤
│  Real-time Triggers (Firestore listeners / BLoC)        │
│    → Low stock, order status change, QC reject          │
├─────────────────────────────────────────────────────────┤
│  Delivery Channels                                      │
│    → In-app (notification bell + badge)                 │
│    → Push (FCM)                                         │
│    → Local notification (flutter_local_notifications)   │
│    → Optional: WhatsApp share prompt                    │
└─────────────────────────────────────────────────────────┘
```

**BLoC:** `NotificationBloc` manages in-app list, read/unread state, badge count, and settings.

### 21.2 Payment Due & Overdue Alerts *(PRIMARY FOCUS)*

#### Customer Receivables (Sales + Job Work)

| Alert | Trigger | Priority | Default Channels |
|---|---|---|---|
| **Due in 15 days** | Payment due date = today + 15 days | Low | In-app only |
| **Due in 7 days** | Payment due date = today + 7 days | Medium | In-app + Push |
| **Due in 3 days** | Payment due date = today + 3 days | Medium | In-app + Push |
| **Due tomorrow** | Payment due date = tomorrow | High | In-app + Push |
| **Due today** | Payment due date = today | High | In-app + Push + Local |
| **Overdue 1–7 days** | 1–7 days past due | High | In-app + Push + Local |
| **Overdue 8–30 days** | 8–30 days past due | Critical | In-app + Push + Local (daily reminder) |
| **Overdue 30+ days** | More than 30 days past due | Critical | In-app + Push (daily) + Dashboard red flag |
| **Partial payment received** | Payment < full amount | Info | In-app — shows remaining balance + new due date |
| **Credit limit exceeded** | New order pushes balance over limit | High | In-app + Push |

#### Notification Payload (example)
```json
{
  "type": "PAYMENT_OVERDUE",
  "priority": "CRITICAL",
  "title": "Overdue Payment — Ali Marble Works",
  "body": "INV-2025-0042: PKR 85,000 overdue by 12 days",
  "data": {
    "customerId": "cust_abc",
    "invoiceId": "inv_042",
    "invoiceType": "SALES",
    "amountDue": 85000,
    "dueDate": "2025-06-14",
    "daysOverdue": 12
  },
  "actions": ["View Invoice", "Record Payment", "Send Reminder"]
}
```

#### Supplier Payables

| Alert | Trigger | Priority |
|---|---|---|
| **Payable due in 7 days** | Supplier invoice due in 7 days | Medium |
| **Payable due tomorrow** | Due tomorrow | High |
| **Payable overdue** | Past due date | Critical |

#### Job Work Specific

| Alert | Trigger | Priority |
|---|---|---|
| **Job work ready for pickup** | Status → Ready | Medium |
| **Job work payment due** | Uses same due/overdue rules as sales | High |
| **Job work not collected (7 days)** | Ready for 7+ days, not collected | Medium |
| **Large job work order received** | Input > X tons (configurable) | Info |

### 21.3 Operational Alerts

| Alert | Trigger |
|---|---|
| Low Raw Material Stock | Stock < reorder level |
| Equipment Maintenance Due | X days before scheduled maintenance |
| Equipment Maintenance Overdue | Past scheduled date |
| Order Ready for Dispatch | Production batch completed for an order |
| Pending Delivery | Delivery not marked complete on due date |
| Labour Attendance Not Entered | If attendance not marked by X time |
| Monthly P&L Ready | Auto-generated on 1st of each month |
| Advance Salary Alert | When advance exceeds Y% of monthly salary |
| QC Rejection Alert | Reject rate exceeds threshold |
| Sync Error | Offline changes failed to sync |

### 21.4 In-App Notification Center

#### UI Features
- Bell icon in app bar with **unread badge count**
- Notification list: grouped by **Today / Yesterday / Earlier**
- Filter tabs: **All | Payments | Job Work | Stock | Operations**
- Each item shows: icon, title, body, timestamp, priority color
- Swipe to mark read / dismiss
- Tap → deep link to relevant screen (invoice, customer, job work order)
- **"Payment Reminders"** quick filter — all due + overdue in one view
- Bulk "Mark all as read"

#### Payment Reminders Dashboard Widget
- Total receivable (PKR)
- Due this week (count + amount)
- Overdue (count + amount) — tappable list
- Top 5 overdue customers

### 21.5 Notification Settings (Owner Configurable)

| Setting | Options |
|---|---|
| Enable/disable per alert type | Toggle each |
| Due reminder days | Default: 15, 7, 3, 1, 0 |
| Overdue repeat interval | Daily / Every 3 days / Weekly |
| Quiet hours | No push between e.g. 10 PM – 7 AM |
| Minimum amount for alerts | Ignore dues below PKR X |
| Channels per alert type | In-app / Push / Local |

### 21.6 Delivery & Persistence
- Push notification (Firebase Cloud Messaging)
- Local notifications when app is backgrounded (`flutter_local_notifications`)
- In-app notification bell with badge count
- Notification history (last 90 days, paginated)
- Stored in Firestore `/notifications/{notifId}` for multi-device sync
- `readBy[]` array per user for read state

### 21.7 Customer Payment Reminder Action
- One-tap **"Send Reminder"** on overdue notification
- Pre-filled WhatsApp message: customer name, invoice #, amount, due date
- Log reminder sent (date, user) on customer/invoice record

---

## 22. Module 18 — Reports & Exports

### Purpose
All reports in one place, exportable to PDF and Excel.

### 22.1 Report List

**Production Reports**
- Daily Production Report
- Monthly Production Summary
- Production by Product/Variety
- Raw Material Consumption Report
- Waste & Scrap Report

**Job Work Reports** *(NEW)*
- Active Job Work Orders
- Monthly Job Work Summary
- Yield & Waste Analysis
- Customer Job Work History
- Job Work Revenue Report

**Sales Reports**
- Daily Sales Report
- Monthly Sales Summary
- Customer-wise Sales Report
- Product-wise Sales Report
- Pending Orders Report
- Overdue Invoices Report

**Financial Reports**
- Monthly P&L Statement
- Yearly P&L Statement
- Cash Flow Statement
- Customer Aging Report
- Supplier Aging Report
- **Upcoming Dues Report** *(NEW)*
- **Overdue Payments Report** *(NEW)*
- Expense Summary by Category
- Cost of Production Analysis

**HR Reports**
- Monthly Attendance Summary
- Monthly Payroll Summary
- Employee Leave Report

**Inventory Reports**
- Stock Status Report
- Inventory Valuation Report
- Stock Movement Report (in/out)

**Equipment Reports**
- Maintenance Cost Report
- Equipment Downtime Report
- Asset Register

### 22.2 Export Options
- PDF (printable, shareable)
- Excel (.xlsx)
- Share via WhatsApp, Email, or Save to device

---

## 23. Database Schema (Overview)

### Firestore Collections

```
/users/{userId}
  - name, email, role, factoryId, createdAt

/factories/{factoryId}
  - name, address, ownerName, phone, logo
  - notificationSettings: { dueReminderDays[], overdueRepeat, quietHours, ... }

/customers/{customerId}
  - name, phone, address, category
  - serviceTypes: ['BUYER'] | ['JOB_WORK'] | ['BOTH'] | ['OTHER']
  - otherServiceDescription (optional)
  - creditLimit, balance, nextDueDate, totalOverdue

/suppliers/{supplierId}
  - name, phone, address, type, balance, nextPayableDate

/rawMaterials/{materialId}
  - name, unit, currentStock, reorderLevel, avgCost

/stockTransactions/{txnId}
  - materialId, type(IN/OUT), qty, cost, date, ref

/products/{productId}
  - name, type, variety, size, thickness, unit

/productionBatches/{batchId}
  - productionType: 'OWN'
  - date, shift, materials[], workers[], output[], wastage, cost, status

/jobWorkOrders/{jobWorkId}                    ← NEW
  - jobWorkNumber, customerId, factoryId
  - status: received|agreed|inCutting|qc|ready|invoiced|paid|collected|closed
  - receivedDate, expectedCompletionDate, completedDate
  - input: { variety, blockCount, totalTons, volumeM3, dimensions[], photos[], notes }
  - cuttingSpec: {
      strategy,           // gangSaw|bridgeSaw|wireSaw|waterJet|mixed
      targetProduct,      // slabs|tiles|strips|steps|custom
      sizes[],            // e.g. ["12x12", "24x24", "60x60cm"]
      thickness,          // e.g. "18mm"
      finish,             // unpolished|polished|honed|brushed
      expectedOutputSqFt,
      specialInstructions,
      diagramUrl
    }
  - pricing: {
      model,              // perTon|perSqFt|lumpSum|perBlock
      agreedRate,
      estimatedTotal,
      negotiatedFinalAmount,
      advanceReceived,
      balanceDue,
      paymentDueDate,
      paymentTerms
    }
  - output: {
      gradeASqFt, gradeBSqFt, gradeCSqFt, rejectSqFt,
      totalUsableSqFt,      // computed
      wasteTons, wasteSqFt, wastePercent, yieldPercent,
      wasteDisposition      // customerTakes|factoryKeeps|disposed
    }
  - execution: { machineIds[], workerIds[], shifts[], supervisor, startDate, endDate }
  - invoiceId, createdAt, updatedAt, createdBy

/jobWorkInvoices/{invoiceId}                  ← NEW
  - jobWorkId, customerId, items[], total, paid, due, dueDate, status

/finishedGoods/{skuId}
  - productId, variety, size, thickness, grade, qty, location

/equipment/{equipId}
  - name, category, status, purchaseDate, cost, nextMaintenance

/maintenanceLogs/{logId}
  - equipId, date, type, cost, downtime, performedBy

/employees/{empId}
  - name, cnic, jobTitle, salaryType, rate, joinDate, status

/attendance/{date}/{empId}
  - status, shiftIn, shiftOut, overtime

/salesOrders/{orderId}
  - customerId, date, items[], total, status, deliveryDate

/invoices/{invoiceId}
  - orderId, customerId, invoiceType: 'SALES'|'JOB_WORK'
  - items[], total, paid, due, dueDate, status, daysOverdue

/payments/{paymentId}
  - type(IN/OUT), partyId, invoiceId, invoiceType, amount, method, date

/paymentReminders/{reminderId}              ← NEW
  - invoiceId, customerId, sentAt, sentBy, channel (whatsapp|sms|inApp)

/expenses/{expenseId}
  - category, description, amount, date, payee, method

/deliveries/{deliveryId}
  - orderId, customerId, items[], vehicleId, driverId, status

/qualityChecks/{qcId}
  - refType: 'PRODUCTION'|'JOB_WORK', refId
  - gradeA, gradeB, gradeC, reject, defects[], inspector

/notifications/{notifId}
  - type, priority, title, body, data{}, readBy[], createdAt, factoryId, expiresAt
```

### Local SQLite (Drift) — Mirror Tables
All collections above have corresponding Drift tables for offline-first. Additional local-only tables:
- `sync_queue` — pending Firestore writes
- `notification_cache` — last 90 days notifications for offline viewing

---

## 24. Flutter Project Structure

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── marble_data.dart        # varieties, product types, cutting strategies
│   ├── theme/
│   │   └── app_theme.dart
│   ├── di/
│   │   └── injection.dart          # get_it registrations
│   ├── utils/
│   │   ├── formatters.dart
│   │   ├── validators.dart
│   │   └── pdf_generator.dart
│   └── services/
│       ├── auth_service.dart
│       ├── notification_service.dart   # FCM + local notifications
│       ├── due_scanner_service.dart    # daily due/overdue scan
│       └── export_service.dart
│
├── data/
│   ├── models/
│   │   ├── customer_model.dart
│   │   ├── job_work_order_model.dart   # NEW
│   │   ├── notification_model.dart
│   │   └── ...
│   ├── repositories/
│   │   ├── customer_repository.dart
│   │   ├── job_work_repository.dart    # NEW
│   │   ├── notification_repository.dart
│   │   └── ...
│   └── datasources/
│       ├── firestore_datasource.dart
│       └── local_datasource.dart       # Drift
│
├── domain/
│   ├── entities/
│   │   ├── customer.dart
│   │   ├── job_work_order.dart         # NEW
│   │   └── ...
│   └── usecases/
│       ├── get_overdue_payments.dart
│       ├── create_job_work_order.dart
│       └── ...
│
├── blocs/                              # BLoC (replaces providers/)
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   ├── customer/
│   │   ├── customer_bloc.dart
│   │   ├── customer_event.dart
│   │   └── customer_state.dart
│   ├── job_work/                       # NEW
│   │   ├── job_work_bloc.dart
│   │   ├── job_work_event.dart
│   │   └── job_work_state.dart
│   ├── notification/                   # NEW
│   │   ├── notification_bloc.dart
│   │   ├── notification_event.dart
│   │   └── notification_state.dart
│   ├── dashboard/
│   ├── sales/
│   └── ...
│
├── presentation/
│   ├── routes/
│   │   └── app_router.dart             # GoRouter
│   ├── screens/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── customers/
│   │   │   ├── customers_screen.dart
│   │   │   ├── add_customer_screen.dart   # includes service type picker
│   │   │   └── customer_detail_screen.dart
│   │   ├── job_work/                   # NEW
│   │   │   ├── job_work_list_screen.dart
│   │   │   ├── add_job_work_screen.dart
│   │   │   ├── job_work_detail_screen.dart
│   │   │   ├── cutting_spec_screen.dart
│   │   │   ├── record_output_screen.dart
│   │   │   └── job_work_invoice_screen.dart
│   │   ├── notifications/              # NEW
│   │   │   ├── notification_center_screen.dart
│   │   │   └── payment_reminders_screen.dart
│   │   ├── sales/
│   │   ├── production/
│   │   └── ...
│   └── widgets/
│       ├── kpi_card.dart
│       ├── notification_bell.dart      # NEW
│       ├── service_type_chip.dart      # NEW
│       ├── due_status_badge.dart       # NEW
│       └── ...
│
└── blocs/app_bloc_observer.dart        # global BLoC logging
```

---

## 25. Key Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.x.x
  firebase_auth: ^5.x.x
  cloud_firestore: ^5.x.x
  firebase_storage: ^12.x.x
  firebase_messaging: ^15.x.x
  firebase_analytics: ^11.x.x

  # State Management — BLoC
  flutter_bloc: ^8.x.x
  bloc: ^8.x.x
  equatable: ^2.x.x

  # Dependency Injection
  get_it: ^8.x.x

  # Local Database (Offline)
  drift: ^2.x.x
  sqlite3_flutter_libs: ^0.5.x

  # Notifications
  flutter_local_notifications: ^17.x.x

  # Navigation
  go_router: ^14.x.x

  # UI
  fl_chart: ^0.68.x
  flutter_slidable: ^3.x.x
  shimmer: ^3.x.x
  cached_network_image: ^3.x.x

  # PDF & Printing
  pdf: ^3.x.x
  printing: ^5.x.x

  # Excel Export
  excel: ^4.x.x

  # QR / Barcode
  mobile_scanner: ^5.x.x
  qr_flutter: ^4.x.x

  # Image Picker
  image_picker: ^1.x.x

  # File Utilities
  path_provider: ^2.x.x
  share_plus: ^10.x.x
  open_filex: ^4.x.x

  # Date
  intl: ^0.19.x

  # Connectivity
  connectivity_plus: ^6.x.x

  # Misc
  uuid: ^4.x.x
  freezed_annotation: ^2.x.x

dev_dependencies:
  build_runner: ^2.x.x
  bloc_test: ^9.x.x
  freezed: ^2.x.x
  json_serializable: ^6.x.x
  drift_dev: ^2.x.x
  mocktail: ^1.x.x
```

---

## 26. UI/UX Guidelines

### Design Principles for a Factory App

1. **Large touch targets** — factory workers may be wearing gloves or have dusty hands. All interactive elements minimum 48×48dp.

2. **High contrast** — factory lighting is often harsh or dim. Use high-contrast text and status colors.

3. **Minimal typing required** — use dropdowns, radio buttons, and date pickers wherever possible instead of free text.

4. **Quick entry screens** — workers shouldn't spend more than 30 seconds logging daily attendance or production output.

5. **Offline-first indicators** — clearly show when working offline vs synced.

6. **Service type clarity** — customer cards and job work screens clearly show BUYER / JOB WORK / BOTH badges.

7. **Payment urgency visibility** — due and overdue amounts always visible on customer profile and notification center.

### Color Palette (Suggested)

```
Primary:       #1A237E  (Deep Navy — authority, industry)
Accent:        #F57F17  (Amber — warmth, marble's earthy tones)
Background:    #F5F5F5  (Light Grey)
Surface:       #FFFFFF  (White cards)
Success:       #2E7D32  (Green)
Warning:       #E65100  (Orange)
Error:         #C62828  (Red)
Due Soon:      #F9A825  (Amber — payment due within 7 days)
Overdue:       #B71C1C  (Dark Red)
Text Primary:  #212121
Text Secondary:#757575
```

### Key UX Patterns
- Bottom Navigation Bar (5 main sections: Dashboard, Production, Job Work, Sales, More)
- Drawer (for all sub-modules)
- FAB (Floating Action Button) for primary action on each screen
- Pull-to-refresh on all lists
- Infinite scroll / pagination for large lists
- Filter + sort on all list screens
- Swipe-to-action (edit/delete) on list items
- Confirmation dialogs for all destructive actions
- **Notification bell** always visible in app bar
- **Stepper wizard** for new job work order (Customer → Input → Spec → Price → Confirm)

---

## 27. Offline-First Strategy

### How it works
1. User performs any action (add stock, record attendance, create job work order, etc.)
2. Data is **immediately written to local SQLite** (via Drift)
3. A sync queue captures the pending change
4. In the background, the app **syncs to Firestore** when online
5. Conflict resolution: **last-write-wins** for simple records; **server timestamp** for financial records

### Sync Status Indicator
- Green dot: Fully synced
- Orange dot: Pending sync (offline)
- Red dot: Sync error (tap to retry)

### Data that MUST sync:
- Sales invoices and payments
- Job work orders and invoices
- Production batches
- Customer accounts

### Data that can work offline-only temporarily:
- Attendance marking
- Expense entry
- Raw material stock updates
- Job work output recording (sync when online)

### Due Scanner (Background)
- On app launch (if online) and daily via `workmanager` or Firebase Cloud Function
- Recalculates `daysOverdue` on all open invoices
- Generates notifications per Module 17 rules
- Works offline with cached due dates; full scan when online

---

## 28. Security Considerations

- **Firebase Security Rules:** Enforce role-based access at the database level (not just app level)
- **HTTPS only:** All Firestore and Storage communication is encrypted
- **Authentication required:** Every screen requires valid login
- **Sensitive data:** Customer CNIC, financial data — access restricted by role
- **Audit log:** Every Create/Edit/Delete recorded with userId + timestamp
- **Data backup:** Firestore automatic backups daily
- **Factory-level data isolation:** If app used by multiple factories in future, each factory's data is isolated by `factoryId`
- **Job work agreements:** Signed agreement photos stored with restricted access

---

## 29. Deployment & Release Plan

### Phase 1 — MVP (Month 1–3)
- Customer Management (with service type)
- Sales Orders & Invoicing
- **Job Work Orders (basic: intake, spec, output, invoice)**
- Basic Expense Tracking
- Simple P&L Report
- **Basic payment due notifications**

### Phase 2 — Operations (Month 4–5)
- Production Management
- Raw Material Stock
- Labour & Attendance
- Inventory Management
- **Full job work yield/waste tracking**

### Phase 3 — Advanced (Month 6–7)
- Equipment Maintenance
- Quality Control (production + job work)
- Delivery Management
- Full Financial Reporting
- **Complete notification engine (all alert types)**

### Phase 4 — Polish (Month 8)
- Advanced Reports
- Excel/PDF exports
- User roles fine-tuning
- Payment reminder WhatsApp integration
- Performance optimization
- BLoC test coverage

### Release
- **Android:** Google Play Store (or direct APK for factory use)
- **iOS:** App Store (optional)
- **Testing devices:** Android tablets recommended for factory floor use (10-inch, rugged if possible)

---

## 30. Future Enhancements

| Feature | Description |
|---|---|
| **WhatsApp Integration** | Auto-send invoices/statements/payment reminders via WhatsApp Business API |
| **GPS Delivery Tracking** | Track delivery vehicle in real-time |
| **Customer Portal** | Web portal where customers can view their invoices and place orders |
| **Quotation Module** | Send quotes before formal order or job work agreement |
| **Machine IoT Integration** | Connect machines to log actual running hours automatically |
| **Multi-factory Support** | Manage multiple factory branches |
| **AI Price Suggestion** | Suggest job work price based on tons, variety, and historical rates |
| **Biometric Attendance** | Integrate with fingerprint device for attendance |
| **Tax / FBR Integration** | Pakistan FBR integration for VAT/Sales Tax |
| **Bank Reconciliation** | Match bank statement to recorded payments |
| **Purchase Order Module** | Formal PO to suppliers before material delivery |
| **Marble Rate API** | Pull current market rates for marble varieties |
| **Digital Agreement Signing** | In-app signature capture for job work contracts |

---

## Summary Table — All Modules

| # | Module | Key Output |
|---|---|---|
| 1 | Dashboard | Live KPIs, charts, due/overdue alerts |
| 2 | Raw Materials | Stock levels, purchase records, consumption |
| 3 | Production | Own-stock batch records, output, cost |
| 4 | Inventory | Finished goods stock, valuation |
| 5 | Equipment | Asset register, maintenance log |
| 6 | Labour & HR | Employee profiles, attendance, payroll |
| 7 | Customer CRM | Customer database, **service types**, ledger |
| 8 | **Job Work** | **Contract cutting orders, yield/waste, fees** |
| 9 | Sales & Orders | Orders, invoices, payments, receipts |
| 10 | Suppliers | Supplier database, purchase history |
| 11 | Expenses | All factory expenses, categories |
| 12 | P&L Reports | Monthly & Yearly Profit & Loss |
| 13 | Waste/Scrap | Scrap tracking, scrap sales |
| 14 | Quality Control | QC inspection, complaint log |
| 15 | Delivery | Dispatch, challan, delivery confirmation |
| 16 | User Roles | Role-based access control |
| 17 | Notifications | **Dues, overdues, operational alerts** |
| 18 | Reports & Export | PDF/Excel export for all reports |

---

## Appendix A — Job Work vs Own Production (Quick Reference)

| Aspect | Own Production (Module 3) | Job Work (Module 8) |
|---|---|---|
| Stone owner | Factory | Customer |
| Raw material source | Raw Material stock | Customer brings blocks |
| Revenue model | Sell finished goods | Cutting/service fee |
| Output goes to | Factory inventory | Customer pickup |
| Waste belongs to | Factory (usually) | Customer (usually) |
| P&L line | Sales revenue − COGS | Service revenue − direct labour/machine |
| Customer type | BUYER or BOTH | JOB_WORK or BOTH |

---

## Appendix B — BLoC List (Implementation Reference)

| Bloc | Responsibility |
|---|---|
| `AuthBloc` | Login, logout, session, role |
| `DashboardBloc` | KPIs, charts, alert counts |
| `CustomerBloc` | CRUD, ledger, service types |
| `JobWorkBloc` | Full job work lifecycle |
| `SalesBloc` | Orders, invoices |
| `PaymentBloc` | Record payments, balance updates |
| `NotificationBloc` | In-app notifications, read state, settings |
| `ProductionBloc` | Own production batches |
| `InventoryBloc` | Finished goods stock |
| `RawMaterialBloc` | Raw material stock |
| `LabourBloc` | Employees, attendance, payroll |
| `ExpenseBloc` | Expense entries |
| `FinanceBloc` | P&L, aging, reports |
| `EquipmentBloc` | Machinery, maintenance |
| `DeliveryBloc` | Dispatch management |
| `SyncBloc` | Offline sync status |

---

*Document prepared for: Marble Factory Management System (MFMS)*
*Platform: Flutter | State: BLoC | Backend: Firebase | Version: 1.1*
*Total Modules: 18 | Target Platform: Android (Tablet + Phone)*
