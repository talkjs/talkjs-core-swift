internal import TalkJSCore

/// A subscription to your most recently active conversations.
///
/// Get a ConversationListSubscription by calling ``Session/subscribeConversations(onSnapshot:)``.
///
/// The subscription is 'windowed'. Initially, this window contains the 20 most recent conversations.
/// Conversations are ordered by last activity. The last activity of a conversation is either `joinedAt` or `lastMessage.createdAt`, whichever is higher.
///
/// The window will automatically expand to include any conversations you join, and any old conversations that receive new messages after subscribing.
///
/// You can expand this window by calling ``ConversationListSubscription/loadMore(count:)``, which extends the window further into the past.
///
/// Remember to `.unsubscribe` the subscription once you are done with it.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ConversationListSubscription: RealtimeSubscription, @unchecked Sendable {
  /// Resolves when the subscription starts receiving updates from the server.
  ///
  /// Wait for this promise if you want to perform some action as soon as the subscription is active.
  ///
  /// The promise rejects if the subscription is terminated before it connects.
  public let connected: Deferred<ConversationListSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<ConversationListSubscriptionState>
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``ConversationListSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``ConversationListSubscriptionState/active(latestSnapshot:loadedAll:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``ConversationListSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``ConversationListSubscriptionState/error(_:)``.
  public var state: ConversationListSubscriptionState {
    ConversationListSubscriptionState(from: _subscription.state)
  }

  private let _subscription: TalkJSCore::ConversationListSubscription

  init(from subscription: TalkJSCore::ConversationListSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      ConversationListSubscriptionState(
        from: $0 as! TalkJSCore::ConversationListSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      ConversationListSubscriptionState(
        from: $0 as! TalkJSCore::ConversationListSubscriptionState
      )
    }
  }

  // TODO: Test this!!!
  /// Expand the window to include older conversations
  ///
  /// Calling `loadMore` multiple times in parallel will still only load one page of conversations.
  ///
  /// Avoid calling `.loadMore` in a loop until you have loaded all conversations.
  /// This is usually unnecessary: any time a conversation receives a message, it appears at the start of the list of conversations.
  /// If you do need to call loadMore in a loop, make sure you set a small upper bound (e.g. 100) on the number of conversations, where the loop will exit.
  ///
  /// - Parameter count: The number of additional conversations to load. Must be between 1 and 30. Default 20.
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``ConversationListSubscriptionState/unsubscribed`` or ``ConversationListSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ConversationListSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// `latestSnapshot`: The most recently received snapshot for the conversations
  ///
  /// `loadedAll`: True if `latestSnapshot` contains all conversations you are in.
  /// Use ``ConversationListSubscription/loadMore(count:)`` to load more.
  case active(latestSnapshot: [ConversationSnapshot], loadedAll: Bool)
  /// The error that caused the subscription to be terminated
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .pending: "pending"
    case .active: "active"
    case .unsubscribed: "unsubscribed"
    case .error: "error"
    }
  }

  init!(from state: any TalkJSCore::ConversationListSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::ConversationListSubscriptionStatePending:
        .pending
      case let activeState
        as TalkJSCore::ConversationListSubscriptionStateActive:
        .active(
          latestSnapshot: activeState.latestSnapshot.fromKotlin(),
          loadedAll: activeState.loadedAll
        )
      case is TalkJSCore::ConversationListSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::ConversationListSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}
