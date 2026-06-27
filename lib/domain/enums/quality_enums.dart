enum QcReferenceType {
  production,
  jobWork;

  String get firestoreValue => name;

  String get label => switch (this) {
        QcReferenceType.production => 'Production Batch',
        QcReferenceType.jobWork => 'Job Work Order',
      };

  static QcReferenceType fromString(String? value) {
    return QcReferenceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => QcReferenceType.production,
    );
  }
}

enum QcDefectType {
  cracks,
  colorVariation,
  sizeDeviation,
  surfaceDefect,
  edgeDefect;

  String get firestoreValue => name;

  String get label => switch (this) {
        QcDefectType.cracks => 'Cracks',
        QcDefectType.colorVariation => 'Color Variation',
        QcDefectType.sizeDeviation => 'Size Deviation',
        QcDefectType.surfaceDefect => 'Surface Defect',
        QcDefectType.edgeDefect => 'Edge Defect',
      };

  static QcDefectType fromString(String? value) {
    return QcDefectType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => QcDefectType.cracks,
    );
  }
}

enum QcDisposition {
  pass,
  rework,
  reject;

  String get firestoreValue => name;

  String get label => switch (this) {
        QcDisposition.pass => 'Pass',
        QcDisposition.rework => 'Rework',
        QcDisposition.reject => 'Reject',
      };

  static QcDisposition fromString(String? value) {
    return QcDisposition.values.firstWhere(
      (disposition) => disposition.name == value,
      orElse: () => QcDisposition.pass,
    );
  }
}

enum QcListFilter {
  all,
  production,
  jobWork,
  pass,
  rework,
  reject;

  String get label => switch (this) {
        QcListFilter.all => 'All',
        QcListFilter.production => 'Production',
        QcListFilter.jobWork => 'Job Work',
        QcListFilter.pass => 'Pass',
        QcListFilter.rework => 'Rework',
        QcListFilter.reject => 'Reject',
      };

  static QcListFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return QcListFilter.all;
    return QcListFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => QcListFilter.all,
    );
  }

  bool matches({
    required QcReferenceType referenceType,
    required QcDisposition disposition,
  }) {
    return switch (this) {
      QcListFilter.all => true,
      QcListFilter.production => referenceType == QcReferenceType.production,
      QcListFilter.jobWork => referenceType == QcReferenceType.jobWork,
      QcListFilter.pass => disposition == QcDisposition.pass,
      QcListFilter.rework => disposition == QcDisposition.rework,
      QcListFilter.reject => disposition == QcDisposition.reject,
    };
  }
}
