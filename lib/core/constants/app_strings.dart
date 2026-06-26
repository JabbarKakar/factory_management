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
}
