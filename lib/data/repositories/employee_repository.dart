import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/document_sequence.dart';
import '../models/employee_model.dart';
import '../services/sequence_number_service.dart';

class EmployeeRepository {
  EmployeeRepository({
    FirebaseFirestore? firestore,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      trackedCollection(_firestore, 'employees');

  Stream<List<Employee>> watchEmployees(String factoryId) {
    return collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final employees = snapshot.docs
            .map((doc) => EmployeeModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        employees.sort((a, b) => a.fullName.compareTo(b.fullName));
        return employees;
      },
    );
  }

  Stream<Employee?> watchEmployee(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return EmployeeModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<Employee?> getEmployee(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return EmployeeModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<Employee> createEmployee(Employee employee) async {
    final id = employee.id.isEmpty ? _uuid.v4() : employee.id;
    final employeeNumber = employee.employeeNumber.isEmpty
        ? await _generateEmployeeNumber(employee.factoryId)
        : employee.employeeNumber;

    final model = EmployeeModel.fromEntity(
      employee.copyWith(id: id, employeeNumber: employeeNumber),
    );

    await collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getEmployee(id);
    return created ?? model.toEntity();
  }

  Future<void> updateEmployee(Employee employee) async {
    final model = EmployeeModel.fromEntity(employee);
    await collection.doc(employee.id).update(model.toFirestore());
  }

  Future<void> deleteEmployee(String id) async {
    await collection.doc(id).delete();
  }

  Future<String> _generateEmployeeNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.employee,
    );
  }
}
