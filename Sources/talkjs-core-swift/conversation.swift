internal import TalkJSCore

public struct ConversationRef {
  public let id: String

  private let _conversationRef: TalkJSCore::ConversationRef

  init(from conversationRef: TalkJSCore::ConversationRef) {
    _conversationRef = conversationRef
    id = conversationRef.id
  }

  public func createIfNotExists(
    access: ConversationAccess? = nil,
    custom: [String: String]? = nil,
    notify: NotificationSettings? = nil,
    photoUrl: String? = nil,
    subject: String? = nil,
    welcomeMessages: [String]? = nil
  ) async {
    try! await _conversationRef.createIfNotExists(
      subject: subject,
      photoUrl: photoUrl,
      welcomeMessages: welcomeMessages,
      custom: custom,
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  public func get() async -> ConversationSnapshot? {
    let snapshot = try! await _conversationRef.get()
    return ConversationSnapshot(from: snapshot)
  }

  public func deleteFields(_ fields: String...) async {
    try! await _conversationRef.deleteFields(fields: fields.toKotlinArray())
  }

  public func message(id: String) -> MessageRef {
    let messageRef = _conversationRef.message(id: id)
    return MessageRef(from: messageRef)
  }

  public func participant(user: String) -> ParticipantRef {
    ParticipantRef(_conversationRef.participant(user: user))
  }

  public func markAsRead() async {
    try! await _conversationRef.markAsRead()
  }

  public func markAsTyping() async {
    try! await _conversationRef.markAsTyping()
  }

  public func markAsUnread() async {
    try! await _conversationRef.markAsUnread()
  }

  public func send(
    text: String,
    referencedMessage: String? = nil,
    custom: [String: String]? = nil
  ) async -> MessageRef {
    let messageRef = try! await _conversationRef.send(
      text: text,
      custom: custom,
      referencedMessage: referencedMessage
    )
    return MessageRef(from: messageRef)
  }

  public func send(
    content: [any SendContentBlock],
    referencedMessage: String? = nil,
    custom: [String: String]? = nil
  ) async -> MessageRef {
    let messageRef = try! await _conversationRef.send(
      content: content.toKotlinSendContentBlock(),
      custom: custom,
      referencedMessage: referencedMessage,
    )
    return MessageRef(from: messageRef)
  }

  public func set(
    subject: String? = nil,
    photoUrl: String? = nil,
    welcomeMessages: [String]? = nil,
    custom: [String: String?]? = nil,
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _conversationRef.set(
      subject: subject,
      photoUrl: photoUrl,
      welcomeMessages: welcomeMessages,
      custom: custom,
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  public func subscribe(onSnapshot: ((ConversationSnapshot?) -> Void)? = nil)
    -> ConversationSubscription
  {
    let handler: ((TalkJSCore::ConversationSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(ConversationSnapshot(from: $0)) }
      } else {
        nil
      }

    let subscription = _conversationRef.subscribe(onSnapshot: handler)
    return ConversationSubscription(from: subscription)
  }

  public func subscribeMessages(
    onSnapshot: (([MessageSnapshot]?, Bool) -> Void)? = nil
  ) -> MessageSubscription {
    let handler: (([TalkJSCore::MessageSnapshot]?, KotlinBoolean) -> Void)? =
      if onSnapshot != nil {
        { (snapshot, loadedAll) in
          onSnapshot!(snapshot?.fromKotlin(), loadedAll.boolValue)
        }
      } else {
        nil
      }

    let subscription = _conversationRef.subscribeMessages(onSnapshot: handler)
    return MessageSubscription(from: subscription)
  }

  public func subscribeParticipants(
    onSnapshot: (([ParticipantSnapshot]?, Bool) -> Void)? = nil
  ) -> ParticipantSubscription {
    let handler:
      (([TalkJSCore::ParticipantSnapshot]?, KotlinBoolean) -> Void)? =
        if onSnapshot != nil {
          { (snapshot, loadedAll) in
            onSnapshot!(snapshot?.fromKotlin(), loadedAll.boolValue)
          }
        } else {
          nil
        }

    let subscription = _conversationRef.subscribeParticipants(
      onSnapshot: handler
    )
    return ParticipantSubscription(from: subscription)
  }

  public func subscribeTyping(onSnapshot: ((TypingSnapshot?) -> Void)? = nil)
    -> TypingSubscription
  {
    let handler: ((TalkJSCore::TypingSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(TypingSnapshot(from: $0)) }
      } else {
        nil
      }

    let internalSubscription = _conversationRef.subscribeTyping(
      onSnapshot: handler
    )
    return TypingSubscription(from: internalSubscription)
  }
}

public struct ConversationSnapshot: Equatable {
  public let id: String
  public let subject: String?
  public let photoUrl: String?
  public let welcomeMessages: [String]
  public let custom: [String: String]
  public let createdAt: Int64
  public let joinedAt: Int64

  init?(from snapshot: TalkJSCore::ConversationSnapshot?) {
    guard let snapshot else {
      return nil
    }

    id = snapshot.id
    subject = snapshot.subject
    photoUrl = snapshot.photoUrl
    welcomeMessages = snapshot.welcomeMessages
    custom = snapshot.custom
    createdAt = snapshot.createdAt
    joinedAt = snapshot.joinedAt
  }
}

extension Array where Element == TalkJSCore::ConversationSnapshot {
  func fromKotlin() -> [ConversationSnapshot] {
    self.map { ConversationSnapshot(from: $0)! }
  }
}

public struct TypingSnapshot: Equatable {
  public let many: Bool
  public let users: [UserSnapshot]?

  init?(from snapshot: TalkJSCore::TypingSnapshot?) {
    guard let snapshot else {
      return nil
    }

    many = snapshot.many
    users = snapshot.users?.fromKotlin()
  }
}

public enum ConversationAccess: Equatable {
  case Read, ReadWrite

  init(from conversationAccess: TalkJSCore::ConversationAccess) {
    switch conversationAccess.name {
    case "Read":
      self = .Read
    case "ReadWrite":
      self = .ReadWrite
    default:
      preconditionFailure("Unreachable")
    }
  }

  func toKotlin() -> TalkJSCore::ConversationAccess {
    switch self {
    case .Read: .read
    case .ReadWrite: .readWrite
    }
  }
}

public enum NotificationSettings: Equatable {
  case True, False, MentionsOnly

  init(from notificationSettings: TalkJSCore::NotificationSettings) {
    switch notificationSettings.name {
    case "true":
      self = .True
    case "false":
      self = .False
    case "mentionsOnly":
      self = .MentionsOnly
    default:
      preconditionFailure("Unreachable")
    }
  }

  func toKotlin() -> TalkJSCore::NotificationSettings {
    switch self {
    case .True: .`true`
    case .False: .`false`
    case .MentionsOnly: .mentionsOnly
    }
  }
}

public struct ConversationSubscription: RealtimeSubscription {
  public var state: ConversationSubscriptionState {
    ConversationSubscriptionState(from: _subscription.state)
  }
  public let connected: Deferred<ConversationSubscriptionState>
  public let terminated: Deferred<ConversationSubscriptionState>

  private let _subscription: TalkJSCore::ConversationSubscription

  init(from subscription: TalkJSCore::ConversationSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      ConversationSubscriptionState(
        from: $0 as! TalkJSCore::ConversationSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      ConversationSubscriptionState(
        from: $0 as! TalkJSCore::ConversationSubscriptionState
      )
    }
  }

  public func unsubscribe() { _subscription.unsubscribe() }
}

public struct TypingSubscription: RealtimeSubscription {
  public let connected: Deferred<TypingSubscriptionState>
  public let terminated: Deferred<TypingSubscriptionState>
  public var state: TypingSubscriptionState {
    TypingSubscriptionState(from: _subscription.state)
  }

  private let _subscription: TalkJSCore::TypingSubscription

  init(from subscription: TalkJSCore::TypingSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      TypingSubscriptionState(
        from: $0 as! TalkJSCore::TypingSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      TypingSubscriptionState(
        from: $0 as! TalkJSCore::TypingSubscriptionState
      )
    }
  }

  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ConversationSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: ConversationSnapshot?)
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .pending: "pending"
    case .active: "active"
    case .unsubscribed: "unsubscribed"
    case .error: "error"
    }
  }

  init!(from state: any TalkJSCore::ConversationSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::ConversationSubscriptionStatePending:
        .pending
      case let activeState as TalkJSCore::ConversationSubscriptionStateActive:
        .active(
          latestSnapshot: ConversationSnapshot(from: activeState.latestSnapshot)
        )
      case is TalkJSCore::ConversationSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::ConversationSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}

public enum TypingSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: TypingSnapshot?)
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .pending: "pending"
    case .active: "active"
    case .unsubscribed: "unsubscribed"
    case .error: "error"
    }
  }

  init!(from state: any TalkJSCore::TypingSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::TypingSubscriptionStatePending:
        .pending
      case let activeState as TalkJSCore::TypingSubscriptionStateActive:
        .active(
          latestSnapshot: TypingSnapshot(from: activeState.latestSnapshot)
        )
      case is TalkJSCore::TypingSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::TypingSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}
