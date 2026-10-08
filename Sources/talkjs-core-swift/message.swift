internal import TalkJSCore

/// References the message with a given message ID.
///
/// Used in all Data API operations affecting that message, such as fetching or editing the message attributes, or deleting the message.
/// Created via ``ConversationRef/message(id:)`` and ``ConversationRef/send(text:referencedMessage:custom:)``.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct MessageRef: @unchecked Sendable {
  /// The ID of the referenced message.
  ///
  /// Immutable: if you want to reference a different message, get a new MessageRef instead.
  public let id: String
  /// The ID of the conversation that the referenced message belongs to.
  ///
  /// Immutable: if you want to reference a message from a different conversation, get a new MessageRef from that conversation.
  public let conversationId: String

  private let _messageRef: TalkJSCore::MessageRef

  init(from messageRef: TalkJSCore::MessageRef) {
    _messageRef = messageRef
    id = messageRef.id
    conversationId = messageRef.conversationId
  }

  /// Fetches a snapshot of the message.
  ///
  /// - Returns: A snapshot of the message's attributes, or nil if the message doesn't exist, the conversation doesn't exist, or you're not a participant in the conversation.
  public func get() async -> MessageSnapshot? {
    let snapshot = try! await _messageRef.get()
    return MessageSnapshot(from: snapshot)
  }

  /// Get a reference to a specific emoji reaction on this message
  ///
  /// If you call `.reaction` with an invalid emoji, it will still succeed and you will still get a ``ReactionRef``.
  /// However, the TalkJS server will reject any calls that use an invalid emoji.
  ///
  /// In the future, this will also be used to fetch a full list of people who used that specific reaction on the message.
  ///
  /// Reacting to the message with a Unicode emoji
  /// ```swift
  /// await MessageRef.reaction(emoji: "🚀").add()
  /// ```
  ///
  /// Removing your custom emoji reaction from the message
  /// ```swift
  /// await MessageRef.reaction(emoji: ":cat-roomba:").remove()
  /// ```
  ///
  /// - Parameter emoji: The emoji for the reaction you want to reference. a single Unicode emoji like "🚀" or a custom emoji like ":cat_roomba:". Custom emoji can be up to 50 characters long.
  /// - Returns: A ``ReactionRef`` for the reaction with that emoji on this message.
  ///   Throws If the emoji is not a string or is an empty string
  public func reaction(emoji: String) -> ReactionRef {
    ReactionRef(_messageRef.reaction(emoji: emoji))
  }

  /// Deletes this message, or does nothing if the message does not exist.
  ///
  /// Deleting a nonexistent message is treated as success.
  ///
  /// This function will throw if you are not a participant in the conversation or if your role does not give you permission to delete this message.
  public func delete() async {
    try! await _messageRef.delete()
  }

  /// Deletes properties of this message.
  ///
  /// Pass the name of each property to delete as a separate parameter to this function.
  /// To delete a field in the `custom` property, pass it as `custom.FIELD_TO_DELETE`.
  public func deleteFields(_ fields: String...) async {
    try! await _messageRef.deleteFields(fields: fields.toKotlinArray())
  }

  /// Edits this message.
  ///
  /// The function will throw if the request is invalid, the message doesn't exist, or you do not have permission to edit that message.
  ///
  /// - Parameter text: The new text to set as the message body.
  /// - Parameter custom: Custom metadata you have set on the message.
  ///   This value acts as a patch. Remove specific properties by calling ``deleteFields(_:)``
  ///   Default = no custom metadata
  public func edit(text: String? = nil, custom: [String: String?]? = nil) async {
    try! await _messageRef.edit(text: text, custom: custom)
  }

  /// Edits this message.
  ///
  /// This is the more advanced method for editing a message. It gives you full control over the message content.
  /// You can decide exactly how a text message should be formatted, edit an attachment, or even turn a text message into a location.
  ///
  /// The function will throw if the request is invalid, the message doesn't exist, or you do not have permission to edit that message.
  ///
  /// - Parameter content: The new content for the message.
  ///   Any value provided here will overwrite the existing message content.
  ///   By default users do not have permission to send ``Link``, ``ActionLink``, or ``ActionButton``, as they can be used to trick the recipient.
  /// - Parameter custom: Custom metadata you have set on the message.
  ///   This value acts as a patch. Remove specific properties by calling ``deleteFields(_:)``
  ///   Default = no custom metadata
  public func edit(
    content: [any SendContentBlock],
    custom: [String: String?]? = nil,
  ) async {
    try! await _messageRef.edit(
      content: content.toKotlinSendContentBlock(),
      custom: custom
    )
  }
}

/// A snapshot of a message's attributes at a given moment in time.
///
/// Automatically expanded to include a snapshot of the user that sent the message, and a snapshot of the referenced message, if this message is a reply.
public struct MessageSnapshot: Equatable, Sendable, Codable {
  /// The main body of the message, as a list of blocks that are rendered top-to-bottom.
  @ContentBlockCoding public private(set) var content: [any ContentBlock]
  /// Time at which the message was sent, as a unix timestamp in milliseconds.
  public let createdAt: Int64
  /// Custom metadata you have set on the message
  public let custom: [String: String]
  /// Time at which the message was last edited, as a unix timestamp in milliseconds.
  /// `nil` if the message has never been edited.
  public let editedAt: Int64?
  /// The unique ID that is used to identify the message in TalkJS
  public let id: String
  /// Where this message origiranted from:
  ///
  /// - `.web` = Message sent via the UI or via `ConversationBuilder.sendMessage`
  /// - `.rest` = Message sent via the REST API's "send message" endpoint
  /// - `.import` = Message sent via the REST API's "import messages" endpoint
  /// - `.email` = Message sent by replying to an email notification
  public let origin: MessageOrigin
  /// The contents of the message, as a plain text string without any formatting or attachments.
  /// Useful for showing in a conversation list or in notifications.
  public let plaintext: String
  /// All the emoji reactions that have been added to this message.
  ///
  /// There can be up to 50 different reactions on each message.
  public let reactions: [ReactionSnapshot]
  /// A snapshot of the message that this message is aa reply to, or `nil` if this message is not a reply.
  ///
  /// Only UserMessages can reference other messages.
  /// The referenced message snapshot does not have a `referencedMessage` field.
  /// Instead, it has `referencedMessageId`.
  /// This prevents TalkJS fetching an unlimited number of messages in a long chain of replies.
  public let referencedMessage: ReferencedMessageSnapshot?
  /// A snapshot of the user who sent the message, or nil if it is a system message.
  /// The user's attributes may have been updated since they sent the message, in which case this snapshot contains the updated data.
  /// It is not a historical snapshot.
  public let sender: UserSnapshot?
  /// Whether this message was "from a user" or a general system message without a specific sender.
  ///
  /// The `sender` property is always present for `.UserMessage` messages and never present for `.SystemMessage` messages.
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

public enum MessageOrigin: String, Equatable, Sendable, Codable {
  case web, rest, `import`, email

  init(from messageOrigin: TalkJSCore::MessageOrigin) {
    if messageOrigin == .web {
      self = .web
    } else if messageOrigin == .rest {
      self = .rest
    } else if messageOrigin == .`import` {
      self = .`import`
    } else if messageOrigin == .email {
      self = .email
    } else {
      preconditionFailure("Unreachable")
    }
  }
}

/// A snapshot of a message's attributes at a given moment in time, used in ``MessageSnapshot/referencedMessage``.
///
/// Automatically expanded to include a snapshot of the user that sent the message.
/// Since this is a snapshot of a referenced message, its referenced message is not automatically expanded, to prevent fetching an unlimited number of messages in a long chain of replies.
/// Instead, contains the `referencedMessageId` field.
///
/// Snapshots are immutable and we try to reuse them when possible. You should only re-render your UI when `oldSnapshot != newSnapshot`.
public struct ReferencedMessageSnapshot: Equatable, Sendable, Codable {
  /// The main body of the message, as a list of blocks that are rendered top-to-bottom.
  @ContentBlockCoding public private(set) var content: [any ContentBlock]
  /// Time at which the message was sent, as a unix timestamp in milliseconds
  public let createdAt: Int64
  /// Custom metadata you have set on the message
  public let custom: [String: String]
  /// Time at which the message was last edited, as a unix timestamp in milliseconds.
  /// `nil` if the message has never been edited.
  public let editedAt: Int64?
  /// The unique ID that is used to identify the message in TalkJS
  public let id: String
  /// Where this message originated from:
  ///
  /// - `.web` = Message sent via the UI or via `ConversationBuilder.sendMessage`
  ///
  /// - `.rest` = Message sent via the REST API's "send message" endpoint
  ///
  /// - `.import` = Message sent via the REST API's "import messages" endpoint
  ///
  /// - `.email` = Message sent by replying to an email notification
  public let origin: MessageOrigin
  /// The contents of the message, as a plain text string without any formatting or attachments.
  /// Useful for showing in a conversation list or in notifications.
  public let plaintext: String
  /// All the emoji reactions that have been added to this message.
  public let reactions: [ReactionSnapshot]
  /// The ID of the message that this message is a reply to, or nil if this message is not a reply.
  ///
  /// Since this is a snapshot of a referenced message, we do not automatically expand its referenced message.
  /// The ID of its referenced message is provided here instead.
  public let referencedMessageId: String?
  /// A snapshot of the user who sent the message.
  /// The user's attributes may have been updated since they sent the message, in which case this snapshot contains the updated data.
  /// It is not a historical snapshot.
  ///
  /// Guaranteed to be set, unlike in MessageSnapshot, because you cannot reference a SystemMessage
  public let sender: UserSnapshot?
  /// Referenced messages are always `.UserMessage` because you cannot reply to a system message.
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

public enum MessageType: String, Equatable, Sendable, Codable {
  case UserMessage, SystemMessage

  init(from messageType: TalkJSCore::MessageType) {
    if messageType == .userMessage {
      self = .UserMessage
    } else if messageType == .systemMessage {
      self = .SystemMessage
    } else {
      preconditionFailure("Unreachable")
    }
  }
}

/// A subscription to the messages in a specific conversation.
///
/// Get a MessageSubscription by calling ``ConversationRef/subscribeMessages(onSnapshot:)``
///
/// The subscription is 'windowed'. It includes all messages since a certain point in time.
/// By default, you subscribe to the 30 most recent messages, and any new messages that are sent after you subscribe.
///
/// You can expand this window by calling ``MessageSubscription/loadMore(count:)``, which extends the window further into the past.
///
/// Remember to `.unsubscribe` the subscription once you are done with it.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct MessageSubscription: RealtimeSubscription, @unchecked Sendable {
  /// Resolves when the subscription starts receiving updates from the server.
  ///
  /// Wait for this promise if you want to perform some action as soon as the subscription is active.
  ///
  /// The promise rejects if the subscription is terminated before it connects.
  public let connected: Deferred<MessageSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<MessageSubscriptionState>
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``MessageSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``MessageSubscriptionState/active(latestSnapshot:loadedAll:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``MessageSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``MessageSubscriptionState/error(_:)``.
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
  /// Expand the window to include older messages
  ///
  /// Calling `loadMore` multiple times in parallel will still only load one page of messages.
  ///
  /// - Parameter count: The number of additional messages to load. Must be between 1 and 100
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``MessageSubscriptionState/unsubscribed`` or ``MessageSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum MessageSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// `latestSnapshot`: The most recently received snapshot for the messages, or `nil` if you're not a participant in the conversation.
  ///
  /// `loadedAll`: True if `latestSnapshot` contains all messages in the conversation.
  /// Use ``MessageSubscription/loadMore(count:)`` to load more.
  case active(latestSnapshot: [MessageSnapshot]?, loadedAll: Bool)
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
