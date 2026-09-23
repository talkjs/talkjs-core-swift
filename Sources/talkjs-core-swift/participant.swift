internal import TalkJSCore

public struct ParticipantRef {
  public let userId: String
  public let conversationId: String

  private let _participantRef: TalkJSCore::ParticipantRef

  init(_ participantRef: TalkJSCore::ParticipantRef) {
    _participantRef = participantRef
    userId = participantRef.userId
    conversationId = participantRef.conversationId
  }

  public func createIfNotExists(
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _participantRef.createIfNotExists(
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  public func delete() async {
    try! await _participantRef.delete()
  }

  public func deleteFields(_ fields: String...) async {
    try! await _participantRef.deleteFields(fields: fields.toKotlinArray())
  }

  public func edit(
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _participantRef.edit(
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  public func get() async -> ParticipantSnapshot? {
    let snapshot = try! await _participantRef.get()
    return ParticipantSnapshot(from: snapshot)
  }

  public func set(
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _participantRef.set(
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }
}

public struct ParticipantSnapshot: Equatable {
  public let access: ConversationAccess
  public let joinedAt: Int64
  public let notify: NotificationSettings
  public let user: UserSnapshot

  init?(from snapshot: TalkJSCore::ParticipantSnapshot?) {
    guard let snapshot else {
      return nil
    }

    access = ConversationAccess(from: snapshot.access)
    joinedAt = snapshot.joinedAt
    notify = NotificationSettings(from: snapshot.notify)
    user = UserSnapshot(from: snapshot.user)!
  }
}

extension Array where Element == TalkJSCore::ParticipantSnapshot {
  func fromKotlin() -> [ParticipantSnapshot] {
    self.map { ParticipantSnapshot(from: $0)! }
  }
}

public struct ParticipantSubscription: RealtimeSubscription {
  public let connected: Deferred<ParticipantSubscriptionState>
  public let terminated: Deferred<ParticipantSubscriptionState>
  public var state: ParticipantSubscriptionState {
    ParticipantSubscriptionState(from: _subscription.state)
  }

  private let _subscription: TalkJSCore::ParticipantSubscription

  init(from subscription: TalkJSCore::ParticipantSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      ParticipantSubscriptionState(
        from: $0 as! TalkJSCore::ParticipantSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      ParticipantSubscriptionState(
        from: $0 as! TalkJSCore::ParticipantSubscriptionState
      )
    }
  }

  // TODO: Test this!!!
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ParticipantSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: [ParticipantSnapshot]?, loadedAll: Bool)
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .pending: "pending"
    case .active: "active"
    case .unsubscribed: "unsubscribed"
    case .error: "error"
    }
  }

  init!(from state: any TalkJSCore::ParticipantSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::ParticipantSubscriptionStatePending:
        .pending
      case let activeState as TalkJSCore::ParticipantSubscriptionStateActive:
        .active(
          latestSnapshot: activeState.latestSnapshot?.fromKotlin(),
          loadedAll: activeState.loadedAll
        )
      case is TalkJSCore::ParticipantSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::ParticipantSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}
