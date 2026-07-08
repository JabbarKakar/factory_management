part of 'production_form_bloc.dart';

abstract class ProductionFormEvent extends Equatable {
  const ProductionFormEvent();

  @override
  List<Object?> get props => [];
}

class ProductionFormInitialized extends ProductionFormEvent {
  const ProductionFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

class ProductionFormLoadRequested extends ProductionFormEvent {
  const ProductionFormLoadRequested(this.batchId);

  final String batchId;

  @override
  List<Object?> get props => [batchId];
}

class ProductionFormSubmitted extends ProductionFormEvent {
  const ProductionFormSubmitted({
    required this.productionDate,
    required this.shift,
    required this.rawMaterialType,
    required this.materialConsumed,
    required this.productType,
    required this.marbleVariety,
    required this.gradeASqFt,
    required this.gradeBSqFt,
    required this.gradeCSqFt,
    required this.rejectSqFt,
    this.thickness,
    this.size,
    this.wasteTons,
    this.supervisorName,
    this.notes,
  });

  final DateTime productionDate;
  final ProductionShift shift;
  final RawMaterialType rawMaterialType;
  final double materialConsumed;
  final ProductionProductType productType;
  final String marbleVariety;
  final String? thickness;
  final String? size;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double? wasteTons;
  final String? supervisorName;
  final String? notes;

  @override
  List<Object?> get props => [
        productionDate,
        shift,
        rawMaterialType,
        materialConsumed,
        productType,
        marbleVariety,
        thickness,
        size,
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
        wasteTons,
        supervisorName,
        notes,
      ];
}
