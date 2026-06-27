abstract final class AppStrings {
  static const String appName = 'MFMS';
  static const String appFullName = 'Marble Factory Management';

  // Auth
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String sendResetLink = 'Send Reset Link';
  static const String backToLogin = 'Back to Login';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String jobWork = 'Job Work';
  static const String customers = 'Customers';
  static const String sales = 'Sales';
  static const String more = 'More';

  // Placeholders
  static const String comingSoon = 'Coming in a future sprint';
  static const String phase2 = 'Phase 2';

  // Theme
  static const String appearance = 'Appearance';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'System';

  // More / Account
  static const String general = 'General';
  static const String account = 'Account';
  static const String settings = 'Settings';
  static const String help = 'Help';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String logoutTitle = 'Log out?';
  static const String logoutMessage =
      'You will need to sign in again to access the factory dashboard.';
  static const String logoutSubtitle = 'Sign out of your account';

  // Customers
  static const String addCustomer = 'Add Customer';
  static const String editCustomer = 'Edit Customer';
  static const String saveCustomer = 'Save Customer';
  static const String saveChanges = 'Save Changes';
  static const String delete = 'Delete';
  static const String customerDetails = 'Customer Details';
  static const String customerNotFound = 'Customer not found';
  static const String customerCreated = 'Customer created successfully';
  static const String customerUpdated = 'Customer updated successfully';
  static const String customerDeleted = 'Customer deleted';
  static const String deleteCustomerTitle = 'Delete customer?';
  static const String deleteCustomerMessage =
      'This will permanently remove the customer and all linked job work and sales orders.';
  static const String searchCustomers = 'Search name, phone, city...';
  static const String all = 'All';
  static const String noCustomersYet = 'No customers yet';
  static const String noCustomersFound = 'No customers found';
  static const String addFirstCustomer = 'Add your first customer to get started';
  static const String tryDifferentSearch = 'Try a different search or filter';
  static const String customersLoadError = 'Could not load customers';
  static const String retry = 'Retry';
  static const String serviceTypeRequired = 'Service Type *';
  static const String basicInformation = 'Basic Information';
  static const String businessDetails = 'Business Details';
  static const String address = 'Address';
  static const String contactInformation = 'Contact Information';
  static const String accountSummary = 'Account Summary';
  static const String customerType = 'Customer Type';
  static const String companyName = 'Company Name';
  static const String fullName = 'Full Name';
  static const String name = 'Name';
  static const String contactPerson = 'Contact Person';
  static const String phone = 'Phone';
  static const String secondaryPhone = 'Secondary Phone';
  static const String whatsApp = 'WhatsApp';
  static const String street = 'Street';
  static const String city = 'City';
  static const String province = 'Province';
  static const String sameShippingAddress = 'Shipping address same as billing';
  static const String shippingStreet = 'Shipping Street';
  static const String shippingCity = 'Shipping City';
  static const String shippingProvince = 'Shipping Province';
  static const String billingAddress = 'Billing Address';
  static const String shippingAddress = 'Shipping Address';
  static const String cnicNtn = 'CNIC / NTN';
  static const String customerCategory = 'Category';
  static const String paymentTerms = 'Payment Terms';
  static const String creditLimit = 'Credit Limit (PKR)';
  static const String openingBalance = 'Opening Balance (PKR)';
  static const String referredBy = 'Referred By';
  static const String notes = 'Notes';
  static const String otherServiceDescription = 'Describe other services';
  static const String balance = 'Balance';
  static const String paymentStatus = 'Payment Status';
  static const String nextDueDate = 'Next Due Date';

  // Job Work
  static const String newJobWorkOrder = 'New Job Work';
  static const String saveJobWorkOrder = 'Save Job Work Order';
  static const String editJobWorkOrder = 'Edit Job Work';
  static const String jobWorkDetails = 'Job Work Details';
  static const String jobWorkCreated = 'Job work order created';
  static const String jobWorkUpdated = 'Job work order updated';
  static const String jobWorkCancelled = 'Job work order cancelled';
  static const String cancelJobWorkTitle = 'Cancel job work order?';
  static const String cancelJobWorkMessage =
      'This order will be marked as cancelled.';
  static const String cancelOrder = 'Cancel Order';
  static const String searchJobWork = 'Search order #, customer, variety...';
  static const String noJobWorkYet = 'No job work orders yet';
  static const String noJobWorkFound = 'No job work orders found';
  static const String addFirstJobWork =
      'Create a job work order when a customer brings blocks for cutting';
  static const String jobWorkLoadError = 'Could not load job work orders';
  static const String selectCustomer = 'Select Customer';
  static const String noJobWorkCustomers =
      'No customers found. Add a customer before creating a job work order.';
  static const String customerAndDates = 'Customer & Dates';
  static const String inputMaterial = 'Customer\'s Material (Input)';
  static const String cuttingSpecification = 'Cutting Specification';
  static const String pricingAgreement = 'Pricing Agreement';
  static const String receivedDate = 'Date Received';
  static const String expectedCompletion = 'Expected Completion';
  static const String marbleVariety = 'Marble Variety';
  static const String blockCount = 'Number of Blocks';
  static const String totalTons = 'Total Weight (Tons)';
  static const String totalVolume = 'Total Volume (m³)';
  static const String blockDimensions = 'Block Dimensions (L×W×H)';
  static const String conditionNotes = 'Condition Notes';
  static const String vehicleNumber = 'Vehicle / Challan #';
  static const String cuttingStrategy = 'Cutting Strategy';
  static const String targetProduct = 'Target Product';
  static const String tileSlabSizes = 'Tile / Slab Sizes';
  static const String thickness = 'Thickness';
  static const String finishRequired = 'Finish Required';
  static const String expectedOutput = 'Expected Output (sq. ft)';
  static const String specialInstructions = 'Special Instructions';
  static const String pricingModel = 'Pricing Model';
  static const String agreedRate = 'Agreed Rate (PKR)';
  static const String estimatedTotal = 'Estimated Total';
  static const String negotiatedAmount = 'Negotiated Final Amount (PKR)';
  static const String advanceReceived = 'Advance Received (PKR)';
  static const String balanceDue = 'Balance Due';
  static const String paymentDueDate = 'Payment Due Date';
  static const String collectedDate = 'Collected Date';
  static const String closedDate = 'Closed Date';
  static const String markMaterialCollected = 'Mark Material Collected';
  static const String closeJobWorkOrder = 'Close Order';
  static const String markCollectedTitle = 'Mark material collected?';
  static const String markCollectedMessage =
      'Confirm the customer has picked up their finished material.';
  static const String closeJobWorkTitle = 'Close job work order?';
  static const String closeJobWorkMessage =
      'This order will be marked as closed and archived.';
  static const String jobWorkCollected = 'Material marked as collected';
  static const String jobWorkClosed = 'Job work order closed';
  static const String pendingPickups = 'Pending Pickups';
  static const String pendingPickupsSubtitle =
      'Finished material still at the factory awaiting customer pickup';
  static const String awaitingCustomerPickup = 'Awaiting customer pickup';
  static const String viewAll = 'View all';

  // Job Work — Output (Sprint 4)
  static const String recordOutput = 'Record Output';
  static const String editOutput = 'Edit Output';
  static const String outputRecording = 'Output Recording';
  static const String outputByGrade = 'Output by Quality Grade';
  static const String gradeA = 'Grade A (sq. ft)';
  static const String gradeB = 'Grade B (sq. ft)';
  static const String gradeC = 'Grade C (sq. ft)';
  static const String reject = 'Reject (sq. ft)';
  static const String totalUsableOutput = 'Total Usable Output';
  static const String wasteAndYield = 'Waste & Yield';
  static const String wasteGenerated = 'Waste Generated';
  static const String wasteUnit = 'Waste Unit';
  static const String wastePercent = 'Waste %';
  static const String yieldPercent = 'Yield %';
  static const String slurryDust = 'Slurry / Dust (optional)';
  static const String wasteDisposition = 'Waste Disposition';
  static const String cuttingExecution = 'Cutting Execution';
  static const String cuttingStartDate = 'Cutting Start Date';
  static const String cuttingCompletionDate = 'Cutting Completion Date';
  static const String supervisorName = 'Supervisor Name';
  static const String progressNotes = 'Progress Notes';
  static const String saveOutput = 'Save Output';
  static const String outputSaved = 'Output recorded successfully';
  static const String outputSaveError = 'Could not save output recording';
  static const String outputGradeRequired =
      'Enter at least one output or waste value';
  static const String statusUpdated = 'Order status updated';
  static const String statusAutoAdvanced =
      'Order status updated automatically based on output';
  static const String outputNotRecordedYet =
      'No output recorded yet. Record grades and waste when cutting is complete.';
  static const String shiftLogs = 'Shift Logs';
  static const String addShiftLog = 'Add Shift';
  static const String shiftDate = 'Shift Date';
  static const String shiftName = 'Shift Name';
  static const String shiftNotes = 'Shift Notes';
  static const String shiftLogsHint =
      'Add one entry per shift for multi-day jobs. Totals are calculated automatically.';
  static const String manualTotals = 'Manual Totals';
  static const String manualTotalsLocked =
      'Totals are calculated from shift logs below.';
  static const String noShiftLogsYet = 'No shift logs yet';
  static const String deleteShiftLog = 'Remove shift?';
  static const String deleteShiftLogMessage =
      'This shift entry will be removed from the order.';

  // Job Work Invoice & Payments (Sprint 5)
  static const String jobWorkInvoice = 'Job Work Invoice';
  static const String generateInvoice = 'Generate Invoice';
  static const String viewInvoice = 'View Invoice';
  static const String recordPayment = 'Record Payment';
  static const String invoiceGenerated = 'Invoice generated successfully';
  static const String paymentRecorded = 'Payment recorded successfully';
  static const String invoiceNotReady =
      'Generate an invoice when the job work order is ready for pickup.';
  static const String invoiceNumber = 'Invoice Number';
  static const String invoiceTotal = 'Invoice Total';
  static const String amountPaid = 'Amount Paid';
  static const String amountDue = 'Amount Due';
  static const String lineItems = 'Line Items';
  static const String paymentHistory = 'Payment History';
  static const String paymentAmount = 'Payment Amount (PKR)';
  static const String paymentMethod = 'Payment Method';
  static const String paymentDate = 'Payment Date';
  static const String paymentReference = 'Reference / Cheque #';
  static const String paymentNotes = 'Payment Notes';
  static const String savePayment = 'Save Payment';
  static const String noPaymentsYet = 'No payments recorded yet';
  static const String accountLedger = 'Account Ledger';
  static const String ledgerOpeningBalanceNote =
      'Balance includes opening balance plus unpaid invoices.';
  static const String noLedgerActivity = 'No invoices or payments yet';
  static const String invoiceTypeJobWork = 'Job Work Invoice';
  static const String invoiceTypeSales = 'Sales Invoice';
  static const String paymentReceived = 'Payment Received';
  static const String ledgerAmountDue = 'due';

  // Notifications (Sprint 6)
  static const String notifications = 'Notifications';
  static const String markAllRead = 'Mark all read';
  static const String noNotifications = 'No notifications yet';
  static const String paymentReminders = 'Payment Reminders';
  static const String dueThisWeek = 'Due This Week';
  static const String overduePayments = 'Overdue';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String earlier = 'Earlier';
  static const String viewAllNotifications = 'View all notifications';
  static const String refreshNotifications = 'Refresh alerts';

  // Dashboard (Sprint 7)
  static const String revenueToday = 'Revenue Today';
  static const String activeJobWork = 'Active Job Work';
  static const String activeSales = 'Active Sales';
  static const String activeSalesOrders = 'Received or ready orders';
  static const String overdueTotal = 'Overdue';
  static const String customerCount = 'Customers';
  static const String quickActions = 'Quick Actions';
  static const String dashboardMvpReady =
      'Track job work and sales orders, invoices, and payments from here.';
  static const String paymentsReceivedToday = 'Payments received today';
  static const String dashboardLoadError =
      'Could not load dashboard data. Pull down to retry.';

  // Sales (Sprint 8)
  static const String newSalesOrder = 'New Sales Order';
  static const String saveSalesOrder = 'Save Sales Order';
  static const String editSalesOrder = 'Edit Sales Order';
  static const String salesOrderDetails = 'Sales Order Details';
  static const String salesOrderCreated = 'Sales order created';
  static const String salesOrderUpdated = 'Sales order updated';
  static const String salesOrderCancelled = 'Sales order cancelled';
  static const String salesOrderClosed = 'Sales order closed';
  static const String closeSalesOrderTitle = 'Close sales order?';
  static const String closeSalesOrderMessage =
      'This order will be marked as closed and archived.';
  static const String cancelSalesOrderTitle = 'Cancel sales order?';
  static const String cancelSalesOrderMessage =
      'This order will be marked as cancelled.';
  static const String searchSalesOrders = 'Search order #, customer, variety...';
  static const String noSalesOrdersYet = 'No sales orders yet';
  static const String noSalesOrdersFound = 'No sales orders found';
  static const String addFirstSalesOrder =
      'Create a sales order when a buyer purchases finished marble';
  static const String salesLoadError = 'Could not load sales orders';
  static const String noSalesCustomers =
      'No buyer customers found. Add a buyer customer before creating a sales order.';
  static const String salesLineItemRequired = 'Add at least one line item with quantity and rate';
  static const String orderDate = 'Order Date';
  static const String orderSource = 'Order Source';
  static const String orderDetails = 'Order Details';
  static const String expectedDelivery = 'Expected Delivery';
  static const String deliveryDetails = 'Delivery Details';
  static const String deliveryAddress = 'Delivery Address';
  static const String addLineItem = 'Add Line Item';
  static const String lineItem = 'Line Item';
  static const String productType = 'Product Type';
  static const String sizeThickness = 'Size / Thickness';
  static const String quantity = 'Quantity';
  static const String unit = 'Unit';
  static const String unitRate = 'Unit Rate (PKR)';
  static const String discountPercent = 'Discount %';
  static const String lineTotal = 'Line Total';
  static const String subtotal = 'Subtotal';
  static const String orderDiscount = 'Order Discount (PKR)';
  static const String taxAmount = 'Tax (PKR)';
  static const String grandTotal = 'Grand Total';
  static const String salesInvoice = 'Sales Invoice';
  static const String salesInvoiceNotReady =
      'Generate an invoice when the sales order is ready for pickup.';

  // Expenses (Sprint 10)
  static const String expenses = 'Expenses';
  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String saveExpense = 'Save Expense';
  static const String expenseCreated = 'Expense recorded';
  static const String expenseUpdated = 'Expense updated';
  static const String expenseDeleted = 'Expense deleted';
  static const String deleteExpenseTitle = 'Delete expense?';
  static const String deleteExpenseMessage =
      'This expense entry will be permanently removed.';
  static const String searchExpenses = 'Search description, payee, bill #...';
  static const String noExpensesYet = 'No expenses recorded yet';
  static const String noExpensesFound = 'No expenses found';
  static const String addFirstExpense =
      'Record factory costs like electricity, fuel, wages, and maintenance';
  static const String expensesLoadError = 'Could not load expenses';
  static const String expensesThisMonth = 'This Month';
  static const String filteredTotal = 'Filtered Total';
  static const String monthToDate = 'Month to Date';
  static const String allCategories = 'All';
  static const String expenseDetails = 'Expense Details';
  static const String optionalDetails = 'Optional Details';
  static const String expenseDate = 'Expense Date';
  static const String expenseCategory = 'Category';
  static const String description = 'Description';
  static const String amountPkr = 'Amount (PKR)';
  static const String payeeName = 'Payee / Vendor';
  static const String billNumber = 'Bill / Invoice #';
  static const String factoryExpenses = 'Factory Expenses';
  static const String viewExpenses = 'View Expenses';
  static const String expenseEntriesThisMonth = 'entries this month';
  static const String factoryExpensesSubtitle =
      'Track electricity, fuel, wages, and other costs';

  // P&L Report (Sprint 11)
  static const String monthlyPlReport = 'Monthly P&L';
  static const String plReportSubtitle =
      'Income from payments vs factory expenses';
  static const String plReportLoadError = 'Could not load P&L report';
  static const String plReportEmpty =
      'No payments or expenses recorded for this month yet.';
  static const String plReportFootnote =
      'Revenue is based on payments received. Expenses use recorded expense dates.';
  static const String revenue = 'Revenue';
  static const String salesRevenue = 'Sales Revenue';
  static const String jobWorkRevenue = 'Job Work Revenue';
  static const String totalRevenue = 'Total Revenue';
  static const String totalExpenses = 'Total Expenses';
  static const String netProfit = 'Net Profit';
  static const String netLoss = 'Net Loss';
  static const String netProfitMargin = 'Net Profit Margin';
  static const String paymentsRecorded = 'payments recorded';
  static const String noExpensesThisMonth = 'No expenses recorded this month';
  static const String previousMonth = 'Previous month';
  static const String nextMonth = 'Next month';
  static const String reports = 'Reports';

  // Suppliers (Sprint 12)
  static const String suppliers = 'Suppliers';
  static const String addSupplier = 'Add Supplier';
  static const String editSupplier = 'Edit Supplier';
  static const String saveSupplier = 'Save Supplier';
  static const String supplierDetails = 'Supplier Details';
  static const String supplierCreated = 'Supplier added';
  static const String supplierUpdated = 'Supplier updated';
  static const String supplierDeleted = 'Supplier deleted';
  static const String suppliersLoadError = 'Could not load suppliers';
  static const String supplierNotFound = 'Supplier not found';
  static const String noSuppliersYet = 'No suppliers yet';
  static const String noSuppliersFound = 'No suppliers found';
  static const String addFirstSupplier =
      'Add quarries, vendors, and service providers you buy from';
  static const String searchSuppliers = 'Search name, phone, city...';
  static const String factorySuppliers = 'Factory Suppliers';
  static const String factorySuppliersSubtitle =
      'Manage vendors and track linked purchases';
  static const String supplierType = 'Supplier Type';
  static const String materialsSupplied = 'Materials Supplied';
  static const String purchaseHistory = 'Purchase History';
  static const String totalPurchases = 'Total Purchases';
  static const String noPurchasesYet = 'No purchases linked to this supplier yet';
  static const String noPurchasesHint =
      'Link expenses to this supplier when recording a purchase';
  static const String purchasesCount = 'purchase(s)';
  static const String deleteSupplierTitle = 'Delete Supplier?';
  static const String deleteSupplierMessage =
      'This supplier will be removed from your directory. Linked expense records will remain unchanged.';
  static const String linkSupplier = 'Link Supplier';
  static const String noSupplierLinked = 'None';
  static const String supplierInformation = 'Supplier Information';
  static const String recordPurchase = 'Record Purchase';
  static const String viewAllPurchases = 'View all purchases';
  static const String showLessPurchases = 'Show less';

  // Raw materials (Sprint 13)
  static const String rawMaterials = 'Raw Materials';
  static const String rawMaterialStock = 'Raw Material Stock';
  static const String rawMaterialStockSubtitle =
      'Track blocks, slabs, and consumables in/out';
  static const String searchRawMaterials = 'Search material type...';
  static const String rawMaterialsLoadError = 'Could not load raw material stock';
  static const String stockIn = 'Stock In';
  static const String stockOut = 'Stock Out';
  static const String recordStockIn = 'Record Stock In';
  static const String recordStockOut = 'Record Stock Out';
  static const String stockInRecorded = 'Stock received';
  static const String stockOutRecorded = 'Stock consumed';
  static const String currentStock = 'Current Stock';
  static const String reorderLevel = 'Reorder Level';
  static const String averageCost = 'Average Cost';
  static const String stockValue = 'Stock Value';
  static const String lastReceipt = 'Last Receipt';
  static const String stockHistory = 'Stock History';
  static const String noStockHistory = 'No stock movements recorded yet';
  static const String lowStock = 'Low Stock';
  static const String lowStockMaterials = 'Low Stock Items';
  static const String inStock = 'In Stock';
  static const String unitCostPkr = 'Unit Cost (PKR)';
  static const String totalCost = 'Total Cost';
  static const String receiptDate = 'Receipt Date';
  static const String movementDate = 'Movement Date';
  static const String referenceNumber = 'Reference / Challan #';
  static const String consumptionReason = 'Reason / Notes';
  static const String setReorderLevel = 'Set Reorder Level';
  static const String reorderLevelUpdated = 'Reorder level updated';
  static const String reorderLevelHint =
      'Alert when stock falls to or below this level';
  static const String recordStockInFirst =
      'Record stock in first before setting a reorder level';
  static const String materialDetails = 'Material Details';
  static const String noStockMovementsFound = 'No movements match your filters';
  static const String selectMaterialForStockIn = 'Select material to receive';

  // Production (Sprint 14)
  static const String production = 'Production';
  static const String productionBatches = 'Production Batches';
  static const String productionBatchesSubtitle =
      'Record own-stock cutting runs and output';
  static const String recordProduction = 'Record Production';
  static const String productionBatchDetails = 'Batch Details';
  static const String productionBatchSaved = 'Production batch saved';
  static const String productionBatchNotFound = 'Production batch not found';
  static const String productionLoadError = 'Could not load production batches';
  static const String searchProductionBatches = 'Search batch, product, variety...';
  static const String noProductionBatchesYet = 'No production batches yet';
  static const String noProductionBatchesFound = 'No batches match your filters';
  static const String noProductionBatchesHint =
      'Record a batch when you cut factory-owned stone into finished goods';
  static const String productionThisMonth = 'Usable output this month';
  static const String batchInformation = 'Batch Information';
  static const String productionDate = 'Production Date';
  static const String shift = 'Shift';
  static const String rawMaterialConsumed = 'Raw Material Consumed';
  static const String selectRawMaterial = 'Raw Material';
  static const String selectMaterial = 'Select material';
  static const String selectRawMaterialRequired = 'Select raw material consumed';
  static const String noRawMaterialInStock =
      'No materials in stock. Record stock in first.';
  static const String quantityConsumed = 'Quantity Consumed';
  static const String productionOutput = 'Production Output';
  static const String size = 'Size';
  static const String notSpecified = 'Not specified';
  static const String wasteGeneratedTons = 'Waste Generated (tons, optional)';
  static const String saveProductionBatch = 'Save Production Batch';
  static const String materialType = 'Material Type';
  static const String materialCost = 'Material Cost';
  static const String productionStockLinked =
      'Raw material stock was deducted when this batch was saved.';
  static const String factoryNotLoaded = 'Factory not loaded';
  static const String productionGradeA = 'Grade A';
  static const String productionGradeB = 'Grade B';
  static const String productionGradeC = 'Grade C';
  static const String productionReject = 'Reject';
  static const String availableInStock = 'Available in stock';
  static const String customMarbleVarietyName = 'Custom variety name';
  static const String customVarietyRequired = 'Enter the custom variety name';
  static const String productionOutputRequired =
      'Enter output in at least one grade or reject';
  static const String quantityExceedsStock = 'Cannot exceed available stock';

  // Finished goods inventory (Sprint 15)
  static const String finishedGoodsInventory = 'Finished Goods';
  static const String finishedGoodsSubtitle =
      'Slabs and tiles ready to sell';
  static const String searchFinishedGoods = 'Search product, variety, grade...';
  static const String finishedGoodsLoadError =
      'Could not load finished goods inventory';
  static const String noFinishedGoodsYet = 'No finished goods in stock yet';
  static const String noFinishedGoodsFound =
      'No items match your filters';
  static const String noFinishedGoodsHint =
      'Stock is added automatically when you record production batches';
  static const String totalInventoryValue = 'Total Inventory Value';
  static const String lowStockFinishedGoods = 'Low Stock SKUs';
  static const String stockItemDetails = 'Stock Details';
  static const String stockItemNotFound = 'Stock item not found';
  static const String currentQuantity = 'Current Quantity';
  static const String storageLocation = 'Storage Location';
  static const String setStorageLocation = 'Set Storage Location';
  static const String locationUpdated = 'Location updated';
  static const String inventoryHistory = 'Inventory History';
  static const String noInventoryHistory = 'No inventory movements yet';
  static const String adjustStockIn = 'Add Stock';
  static const String adjustStockOut = 'Remove Stock';
  static const String recordStockAdjustment = 'Record Adjustment';
  static const String adjustmentReason = 'Reason';
  static const String adjustmentReasonRequired = 'Reason is required';
  static const String stockAdjustmentRecorded = 'Stock adjustment saved';
  static const String viewProductionBatch = 'View production batch';
  static const String fromProductionBatch = 'From production batch';
  static const String unitCostPerSqFt = 'Unit Cost (PKR / sq. ft)';
  static const String adjustmentUnitCostHint =
      'Required for empty stock; optional when adding to existing stock';
  static const String adjustmentUnitCostRequired =
      'Unit cost is required when stock is empty';

  // Labour & attendance (Sprint 16)
  static const String factoryWorkers = 'Factory Workers';
  static const String factoryWorkersSubtitle =
      'Employee profiles and wage rates';
  static const String dailyAttendance = 'Daily Attendance';
  static const String dailyAttendanceSubtitle =
      'Mark present, absent, leave, and holidays';
  static const String addEmployee = 'Add Worker';
  static const String editEmployee = 'Edit Worker';
  static const String employeeDetails = 'Worker Details';
  static const String searchEmployees = 'Search name, ID, phone, role...';
  static const String employeesLoadError = 'Could not load workers';
  static const String noEmployeesYet = 'No workers added yet';
  static const String noEmployeesFound = 'No workers match your filters';
  static const String noEmployeesHint =
      'Add factory workers to track attendance and wages';
  static const String employeeNotFound = 'Worker not found';
  static const String deleteEmployeeTitle = 'Delete worker?';
  static const String deleteEmployeeMessage =
      'This will permanently remove the worker profile. Attendance history will remain.';
  static const String cnicNumber = 'CNIC (optional)';
  static const String workerCategory = 'Job Category';
  static const String employmentType = 'Employment Type';
  static const String salaryType = 'Salary Type';
  static const String rateAmount = 'Rate Amount (PKR)';
  static const String employeeJoinDate = 'Date of Joining';
  static const String employeeStatus = 'Status';
  static const String saveEmployee = 'Save Worker';
  static const String employeeSaved = 'Worker saved';
  static const String employeeDeleted = 'Worker deleted';
  static const String attendanceHistory = 'Attendance History';
  static const String noAttendanceHistory = 'No attendance recorded yet';
  static const String markAttendance = 'Mark Attendance';
  static const String markAllPresent = 'Mark All Present';
  static const String attendanceSummary = 'Today\'s Summary';
  static const String attendancePresent = 'Present';
  static const String attendanceAbsent = 'Absent';
  static const String attendanceUnmarked = 'Not Marked';
  static const String attendanceDate = 'Attendance Date';
  static const String defaultShift = 'Default Shift';
  static const String selectAttendanceStatus = 'Status';
  static const String noActiveWorkersForAttendance =
      'Add active workers before marking attendance';
  static const String attendanceSaved = 'Attendance saved';
  static const String allMarkedPresent = 'All active workers marked present';
  static const String inactiveWorker = 'Inactive';
  static const String presentLabourToday = 'Present Today';
  static const String labourAttendanceToday = 'Today\'s attendance';
  static const String searchAttendance = 'Search worker name, ID, role...';
  static const String markAllPresentConfirmTitle = 'Overwrite attendance?';
  static const String markAllPresentConfirmMessage =
      'Some workers already have a different status. Marking all present will overwrite those entries.';
  static const String noAttendanceMatches = 'No workers match your search';
}
