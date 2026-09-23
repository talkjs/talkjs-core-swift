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

public protocol Subscription {
  func unsubscribe()
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
