internal import TalkJSCore

public struct MessageRef {
  public let id: String
  public let conversationId: String

  private let _messageRef: TalkJSCore::MessageRef

  init(from messageRef: TalkJSCore::MessageRef) {
    _messageRef = messageRef
    id = messageRef.id
    conversationId = messageRef.conversationId
  }

  func get() async -> MessageSnapshot? {
    let snapshot = try! await _messageRef.get()
    return MessageSnapshot(from: snapshot)
  }

  func reaction(emoji: String) -> ReactionRef {
    ReactionRef(_messageRef.reaction(emoji: emoji))
  }

  func delete() async {
    try! await _messageRef.delete()
  }

  func deleteFields(_ fields: String...) async {
    try! await _messageRef.deleteFields(fields: fields.toKotlinArray())
  }

  func edit(text: String? = nil, custom: [String: String?]? = nil) async {
    try! await _messageRef.edit(text: text, custom: custom)
  }

  func edit(content: [any SendContentBlock], custom: [String: String?]? = nil)
    async
  {
    try! await _messageRef.edit(
      content: content.toKotlinSendContentBlock(),
      custom: custom
    )
  }
}

public struct MessageSnapshot: Equatable {
  public let content: [any ContentBlock]
  public let createdAt: Int64
  public let custom: [String: String]
  public let editedAt: Int64?
  public let id: String
  public let origin: MessageOrigin
  public let plaintext: String
  public let reactions: [ReactionSnapshot]
  public let referencedMessage: ReferencedMessageSnapshot?
  public let sender: UserSnapshot?
  public let type: MessageType

  init?(from snapshot: TalkJSCore::MessageSnapshot?) {
    guard let snapshot else {
      return nil
    }

    content = try! snapshot.content.fromKotlin()
    createdAt = snapshot.createdAt
    custom = snapshot.custom
    editedAt = snapshot.editedAt?.int64Value
    id = snapshot.id
    origin = MessageOrigin(from: snapshot.origin)
    plaintext = snapshot.plaintext
    reactions = snapshot.reactions.fromKotlin()
    referencedMessage = ReferencedMessageSnapshot(
      from: snapshot.referencedMessage
    )
    sender = UserSnapshot(from: snapshot.sender)
    type = MessageType(from: snapshot.type)
  }

  public static func == (lhs: MessageSnapshot, rhs: MessageSnapshot) -> Bool {
    lhs.createdAt == rhs.createdAt && lhs.custom == rhs.custom
      && lhs.editedAt == rhs.editedAt && lhs.id == rhs.id
      && lhs.origin == rhs.origin && lhs.plaintext == rhs.plaintext
      && lhs.reactions == rhs.reactions
      && lhs.referencedMessage == rhs.referencedMessage
      && lhs.sender == rhs.sender && lhs.type == rhs.type
      && lhs.content.isEqual(rhs.content)
  }
}

extension Array where Element == TalkJSCore::MessageSnapshot {
  func fromKotlin() -> [MessageSnapshot] {
    self.map { MessageSnapshot(from: $0)! }
  }
}

public enum MessageOrigin: Equatable {
  case web, rest, `import`, email

  init(from messageOrigin: TalkJSCore::MessageOrigin) {
    switch messageOrigin.name {
    case "web":
      self = .web
    case "rest":
      self = .rest
    case "import":
      self = .`import`
    case "email":
      self = .email
    default:
      preconditionFailure("Unreachable")
    }
  }
}

public struct ReferencedMessageSnapshot: Equatable {
  public let content: [any ContentBlock]
  public let createdAt: Int64
  public let custom: [String: String]
  public let editedAt: Int64?
  public let id: String
  public let origin: MessageOrigin
  public let plaintext: String
  public let reactions: [ReactionSnapshot]
  public let referencedMessageId: String?
  public let sender: UserSnapshot?
  public let type: MessageType

  init?(from snapshot: TalkJSCore::ReferencedMessageSnapshot?) {
    guard let snapshot else {
      return nil
    }

    content = try! snapshot.content.fromKotlin()
    createdAt = snapshot.createdAt
    custom = snapshot.custom
    editedAt = snapshot.editedAt?.int64Value
    id = snapshot.id
    origin = MessageOrigin(from: snapshot.origin)
    plaintext = snapshot.plaintext
    reactions = snapshot.reactions.fromKotlin()
    referencedMessageId = snapshot.referencedMessageId
    sender = UserSnapshot(from: snapshot.sender)
    type = MessageType(from: snapshot.type)
  }

  public static func == (
    lhs: ReferencedMessageSnapshot,
    rhs: ReferencedMessageSnapshot
  ) -> Bool {
    lhs.createdAt == rhs.createdAt && lhs.custom == rhs.custom
      && lhs.editedAt == rhs.editedAt && lhs.id == rhs.id
      && lhs.origin == rhs.origin && lhs.plaintext == rhs.plaintext
      && lhs.reactions == rhs.reactions
      && lhs.referencedMessageId == rhs.referencedMessageId
      && lhs.sender == rhs.sender && lhs.type == rhs.type
      && lhs.content.isEqual(rhs.content)
  }
}

public enum MessageType: Equatable {
  case UserMessage, SystemMessage

  init(from messageType: TalkJSCore::MessageType) {
    switch messageType.name {
    case "UserMessage":
      self = .UserMessage
    case "SystemMessage":
      self = .SystemMessage
    default:
      preconditionFailure("Unreachable")
    }
  }
}

public struct MessageSubscription: RealtimeSubscription {
  public let connected: Deferred<MessageSubscriptionState>
  public let terminated: Deferred<MessageSubscriptionState>
  public var state: MessageSubscriptionState {
    MessageSubscriptionState(from: _subscription.state)
  }

  private let _subscription: TalkJSCore::MessageSubscription

  init(from subscription: TalkJSCore::MessageSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      MessageSubscriptionState(
        from: $0 as! TalkJSCore::MessageSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      MessageSubscriptionState(
        from: $0 as! TalkJSCore::MessageSubscriptionState
      )
    }
  }

  // TODO: Test this!!!
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum MessageSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: [MessageSnapshot]?, loadedAll: Bool)
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .pending: "pending"
    case .active: "active"
    case .unsubscribed: "unsubscribed"
    case .error: "error"
    }
  }

  init!(from state: any TalkJSCore::MessageSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::MessageSubscriptionStatePending:
        .pending
      case let activeState as TalkJSCore::MessageSubscriptionStateActive:
        .active(
          latestSnapshot: activeState.latestSnapshot?.fromKotlin(),
          loadedAll: activeState.loadedAll
        )
      case is TalkJSCore::MessageSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::MessageSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}
