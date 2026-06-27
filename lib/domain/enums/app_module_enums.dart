enum AppModule {
  dashboard,
  jobWork,
  customers,
  sales,
  expenses,
  plReport,
  suppliers,
  rawMaterials,
  production,
  finishedGoods,
  labour,
  equipment,
  qualityControl,
  delivery,
  notifications,
  team;

  String get label => switch (this) {
        AppModule.dashboard => 'Dashboard',
        AppModule.jobWork => 'Job Work',
        AppModule.customers => 'Customers',
        AppModule.sales => 'Sales',
        AppModule.expenses => 'Expenses',
        AppModule.plReport => 'P&L Report',
        AppModule.suppliers => 'Suppliers',
        AppModule.rawMaterials => 'Raw Materials',
        AppModule.production => 'Production',
        AppModule.finishedGoods => 'Finished Goods',
        AppModule.labour => 'Labour',
        AppModule.equipment => 'Equipment',
        AppModule.qualityControl => 'Quality Control',
        AppModule.delivery => 'Delivery',
        AppModule.notifications => 'Notifications',
        AppModule.team => 'Team',
      };
}

enum PermissionAction {
  view,
  create,
  edit,
  delete,
  export,
}
