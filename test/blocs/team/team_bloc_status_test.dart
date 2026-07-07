import 'package:factory_management/blocs/team/team_bloc.dart';
import 'package:factory_management/data/repositories/employee_repository.dart';
import 'package:factory_management/data/repositories/invite_repository.dart';
import 'package:factory_management/data/repositories/user_repository.dart';
import 'package:factory_management/domain/entities/app_user.dart';
import 'package:factory_management/domain/entities/employee.dart';
import 'package:factory_management/domain/entities/team_invite.dart';
import 'package:factory_management/domain/enums/user_enums.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserRepository implements UserRepository {
  final List<String> disabled = <String>[];
  final List<String> enabled = <String>[];
  Object? throwOnStatusChange;

  @override
  Stream<List<AppUser>> watchFactoryUsers(String factoryId) =>
      Stream<List<AppUser>>.value(const []);

  @override
  Future<void> disableUser(String userId) async {
    if (throwOnStatusChange != null) throw throwOnStatusChange!;
    disabled.add(userId);
  }

  @override
  Future<void> enableUser(String userId) async {
    if (throwOnStatusChange != null) throw throwOnStatusChange!;
    enabled.add(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmployeeRepository implements EmployeeRepository {
  @override
  Stream<List<Employee>> watchEmployees(String factoryId) =>
      Stream<List<Employee>>.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInviteRepository implements InviteRepository {
  @override
  Stream<List<TeamInvite>> watchPendingFactoryInvites(String factoryId) =>
      Stream<List<TeamInvite>>.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeUserRepository users;
  late TeamBloc bloc;

  setUp(() {
    users = _FakeUserRepository();
    bloc = TeamBloc(
      repository: users,
      employeeRepository: _FakeEmployeeRepository(),
      inviteRepository: _FakeInviteRepository(),
    );
    bloc.add(
      const TeamWatchStarted(factoryId: 'factory-1', currentUserId: 'owner-1'),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('disables another member and reports success', () async {
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      const TeamStatusChangeRequested(userId: 'member-1', disable: true),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<TeamState>(
          (s) => !s.isSaving && s.successMessage != null,
        ),
      ),
    );
    expect(users.disabled, contains('member-1'));
  });

  test('enables a disabled member', () async {
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      const TeamStatusChangeRequested(userId: 'member-1', disable: false),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<TeamState>(
          (s) => !s.isSaving && s.successMessage != null,
        ),
      ),
    );
    expect(users.enabled, contains('member-1'));
  });

  test('ignores an attempt to disable self (no repository call)', () async {
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      const TeamStatusChangeRequested(userId: 'owner-1', disable: true),
    );
    await Future<void>.delayed(Duration.zero);

    expect(users.disabled, isEmpty);
    expect(bloc.state.isSaving, isFalse);
  });

  test('surfaces an error message when the repository fails', () async {
    users.throwOnStatusChange = Exception('boom');
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      const TeamStatusChangeRequested(userId: 'member-1', disable: true),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<TeamState>(
          (s) => !s.isSaving && s.errorMessage != null,
        ),
      ),
    );
  });

  test('member entity defaults to active status', () async {
    await Future<void>.delayed(Duration.zero);
    const member = AppUser(
      id: 'm',
      email: 'm@test.com',
      name: 'M',
      role: 'accountant',
      factoryId: 'factory-1',
    );
    expect(member.status, UserAccountStatus.active);
  });
}
