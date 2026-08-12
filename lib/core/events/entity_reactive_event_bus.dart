import 'dart:async';

/// Types of entity mutations handled by the reactive event bus.
enum EntityMutationType { created, updated, deleted }

/// Event payload emitted whenever a domain entity undergoes a mutation.
class EntityMutationEvent<T> {
  const EntityMutationEvent({
    required this.entity,
    required this.type,
  });

  final T entity;
  final EntityMutationType type;
}

/// Centralized Reactive Event Bus for cross-module state synchronization and cache invalidation.
///
/// Ensures newly created or modified entities (Customers, Job Works, Loads, Sales, Orders)
/// automatically notify subscribed Blocs and UI components across the app.
class EntityReactiveEventBus {
  EntityReactiveEventBus._();

  static final EntityReactiveEventBus instance = EntityReactiveEventBus._();

  final StreamController<EntityMutationEvent<dynamic>> _controller =
      StreamController<EntityMutationEvent<dynamic>>.broadcast();

  /// Returns a stream of mutation events filtered by entity type [T].
  Stream<EntityMutationEvent<T>> on<T>() {
    return _controller.stream
        .where((event) => event.entity is T)
        .map((event) => EntityMutationEvent<T>(
              entity: event.entity as T,
              type: event.type,
            ));
  }

  /// Broadcasts an entity creation event.
  void notifyCreated<T>(T entity) {
    _controller.add(
      EntityMutationEvent<T>(
        entity: entity,
        type: EntityMutationType.created,
      ),
    );
  }

  /// Broadcasts an entity update event.
  void notifyUpdated<T>(T entity) {
    _controller.add(
      EntityMutationEvent<T>(
        entity: entity,
        type: EntityMutationType.updated,
      ),
    );
  }

  /// Broadcasts an entity deletion event.
  void notifyDeleted<T>(T entity) {
    _controller.add(
      EntityMutationEvent<T>(
        entity: entity,
        type: EntityMutationType.deleted,
      ),
    );
  }
}
