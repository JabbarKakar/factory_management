import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/employee.dart';
import '../models/employee_model.dart';

class EmployeeRepository {
  EmployeeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection('employees');

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

  Future<String> _generateEmployeeNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'EMP-$year-${count.toString().padLeft(4, '0')}';
  }
}
