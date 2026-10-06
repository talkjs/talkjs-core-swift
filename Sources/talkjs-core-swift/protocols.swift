internal import TalkJSCore

public struct Deferred<T> {
  private let _kotlinDeferred: Kotlinx_coroutines_coreDeferred
  private let _transformer: (Any?) -> T

  public func await() async -> T {
    _transformer(try! await _kotlinDeferred.await())
  }

  init(
    _ kotlinDeferred: Kotlinx_coroutines_coreDeferred,
    transformer: @escaping (Any?) -> T
  ) {
    _kotlinDeferred = kotlinDeferred
    _transformer = transformer
  }
}

public struct TalkJSError: Error, Equatable {
  public let message: String?

  init(from exception: KotlinException) {
    message = exception.message
  }

  init(_ message: String) {
    self.message = message
  }
}

/// A subscription to an event
public protocol Subscription {
  /// Stop receiving events for this subscription
  func unsubscribe()
}

// The Kotlin `Subscription` is a different protocol than the one above, so a
// Kotlin object can never be cast to it. This forwards `unsubscribe()` instead.
struct KotlinSubscription: Subscription {
  private let _subscription: any TalkJSCore::Subscription

  init(_ subscription: any TalkJSCore::Subscription) {
    _subscription = subscription
  }

  func unsubscribe() { _subscription.unsubscribe() }
}

public protocol RealtimeSubscription {
  associatedtype SubscriptionState

  var state: SubscriptionState { get }
  var connected: Deferred<SubscriptionState> { get }
  var terminated: Deferred<SubscriptionState> { get }

  func unsubscribe()
}

// For some unknown reason the `SubscriptionState` in TalkJSCore is
// restricted to class types only. So I'm just rewriting it here
public protocol SubscriptionState {
  var type: String { get }
}
