internal import TalkJSCore

public struct ConversationListSubscription: RealtimeSubscription {
  public let connected: Deferred<ConversationListSubscriptionState>
  public let terminated: Deferred<ConversationListSubscriptionState>
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
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ConversationListSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: [ConversationSnapshot], loadedAll: Bool)
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
