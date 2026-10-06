internal import TalkJSCore

// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ConversationRef: @unchecked Sendable {
  /// The ID of the referenced conversation.
  ///
  /// Immutable: if you want to reference a different conversation, get a new `ConversationRef` instead.
  public let id: String

  private let _conversationRef: TalkJSCore::ConversationRef

  init(from conversationRef: TalkJSCore::ConversationRef) {
    _conversationRef = conversationRef
    id = conversationRef.id
  }

  /// Creates this conversation if it does not already exist.
  ///
  /// Adds you as a participant in this conversation, if you are not already a participant.
  ///
  /// If the conversation already exists or you are already a participant, this operation is still considered successful.
  /// The function throws if you are not already a participant and client-side conversation syncing is disabled.
  ///
  /// - Parameter subject: The conversation subject to display in the chat header.
  ///   Default = no subject, list participant names instead
  /// - Parameter photoUrl: The URL for the conversation photo to display in the chat header.
  ///   Default = no photo, show a placeholder image.
  /// - Parameter welcomeMessages: System messages which are sent at the beginning of a conversation.
  ///   Default = no messages.
  /// - Parameter custom: Custom metadata you have set on the conversation.
  ///   Default = no custom metadata
  /// - Parameter access: Your access to the conversation.
  ///   Default = `.ReadWrite` access.
  /// - Parameter notify: Your notification settings.
  ///   Default = `.True`
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

  /// Fetches a snapshot of the conversation.
  ///
  /// This contains all of the information related to the conversation and the current user's participation in the conversation.
  ///
  /// - Returns: A snapshot of the current user's view of the conversation, or `nil` if the current user is not a participant (including if the conversation doesn't exist)
  public func get() async -> ConversationSnapshot? {
    let snapshot = try! await _conversationRef.get()
    return ConversationSnapshot(from: snapshot)
  }

  /// Deletes properties of this conversation.
  ///
  /// Pass the name of each property to delete as a separate parameter to this function.
  /// To delete a field in the `custom` property, pass it as `custom.FIELD_TO_DELETE`.
  public func deleteFields(_ fields: String...) async {
    try! await _conversationRef.deleteFields(fields: fields.toKotlinArray())
  }

  /// Get a reference to a message in this conversation
  ///
  /// - Parameter id: the message ID
  /// - Returns: A reference to the message with the given ID
  public func message(id: String) -> MessageRef {
    let messageRef = _conversationRef.message(id: id)
    return MessageRef(from: messageRef)
  }

  /// Get a reference to a participant in this conversation
  ///
  /// - Parameter user: the user's ID
  /// - Returns: A reference to the given participant
  public func participant(user: String) -> ParticipantRef {
    ParticipantRef(_conversationRef.participant(user: user))
  }

  /// Marks the conversation as read.
  ///
  /// The function throws if you are not a participant in the conversation.
  public func markAsRead() async {
    try! await _conversationRef.markAsRead()
  }

  /// Marks the current user as typing in this conversation for 10 seconds.
  ///
  /// This means that other users will see a typing indicator in the UI, from the current user.
  ///
  /// The user will automatically stop typing after 10 seconds. You cannot manually mark a user as "not typing".
  /// Users are also considered "not typing" when they send a message, even if that message was sent from a different tab or using the REST API.
  ///
  /// To keep the typing indicator visible for longer, call this function again to reset the 10s timer.
  public func markAsTyping() async {
    try! await _conversationRef.markAsTyping()
  }

  /// Marks the conversation as unread.
  ///
  /// The function throws if you are not a participant in the conversation.
  public func markAsUnread() async {
    try! await _conversationRef.markAsUnread()
  }

  /// Sends a text message in the conversation.
  ///
  /// - Parameter text: The text to send in the message.
  /// - Parameter custom: Custom metadata you have set on the message.
  ///   Default = no custom metadata
  /// - Parameter referencedMessage: The message that you are replying to.
  ///   Default = not a reply
  /// - Returns: A reference to the newly created message. The function throws if you are not a participant with write access in this conversation.
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

  /// Sends a message in the conversation.
  ///
  /// This is the more advanced method for sending a message, giving full control over the message content.
  /// You can decide exactly how a text message should be formatted, send an attachment, or even send a location.
  ///
  /// - Parameter content: The most important part of the message, either some text, a file attachment, or a location.
  ///   By default users do not have permission to send ``Link``, ``ActionLink``, or ``ActionButton``, as they can be used to trick the recipient.
  /// - Parameter custom: Custom metadata you have set on the message.
  ///   Default = no custom metadata
  /// - Parameter referencedMessage: The message that you are replying to.
  ///   Default = not a reply
  /// - Returns: A reference to the newly created message. The function throws if you are not a participant with write access in this conversation.
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

  /// Sets properties of this conversation and your participation in it.
  ///
  /// The conversation is created if a conversation with this ID doesn't already exist.
  /// You are added as a participant if you are not already a participant in the conversation.
  /// When client-side conversation syncing is disabled, you may only set your `notify` property, when you are already a participant.
  /// Everything else requires client-side conversation syncing to be enabled, and will cause the function to throw.
  ///
  /// Properties that are `nil` will not be changed.
  /// To clear / reset a property to the default, call ``deleteFields(_:)`` instead.
  ///
  /// - Parameter subject: The conversation subject to display in the chat header.
  ///   Default = no subject, list participant names instead.
  /// - Parameter photoUrl: The URL for the conversation photo to display in the chat header.
  ///   Default = no photo, show a placeholder image.
  /// - Parameter welcomeMessages: System messages which are sent at the beginning of a conversation.
  ///   Default = no messages.
  /// - Parameter custom: Custom metadata you have set on the conversation.
  ///   This value acts as a patch. Remove specific properties by calling ``deleteFields(_:)``
  ///   Default = no custom metadata
  /// - Parameter access: Your access to the conversation.
  ///   Default = `.ReadWrite` access.
  /// - Parameter notify: Your notification settings.
  ///   Default = `.True`
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

  /// Subscribes to the conversation.
  ///
  /// Whenever `Subscription.state.type` is "active" and something about the conversation changes, `onSnapshot` will fire and `Subscription.state.latestSnapshot` will be updated.
  /// This includes changes to nested data. As an extreme example, `onSnapshot` would be called if `snapshot.lastMessage.referencedMessage.sender.name` changes.
  ///
  /// The snapshot is nil if you are not a participant in the conversation (including when the conversation doesn't exist)
  public func subscribe(
    onSnapshot: (@Sendable (_ snapshot: ConversationSnapshot?) -> Void)? = nil
  ) -> ConversationSubscription {
    let handler: ((TalkJSCore::ConversationSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(ConversationSnapshot(from: $0)) }
      } else {
        nil
      }

    let subscription = _conversationRef.subscribe(onSnapshot: handler)
    return ConversationSubscription(from: subscription)
  }

  /// Subscribes to the messages in the conversation.
  ///
  /// Initially, you will be subscribed to the 10 most recent messages and any new messages.
  /// Call `loadMore` to load additional older messages.
  ///
  /// Whenever a message is edited, a new message is received, or you load more messages, `onSnapshot` will fire and `Subscription.latestSnapshot` will be updated.
  /// `loadedAll` is true when the snapshot contains all the messages in the conversation.
  ///
  /// The snapshot is `nil` if you are not a participant in the conversation (including when the conversation doesn't exist)
  ///
  /// - Parameter onSnapshot: function called when the list of messages is updated
  /// - Returns: A subscription to messages.
  public func subscribeMessages(
    onSnapshot: (@Sendable (_ snapshot: [MessageSnapshot]?, _ loadedAll: Bool) -> Void)? = nil
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

  /// Subscribes to the participants in the conversation.
  ///
  /// While the subscription is active, `onSnapshot` will be called whenever the participant snapshots change.
  /// This includes when someone joins or leaves, when their participant attributes are edited, and when you load more participants.
  /// It also includes when nested data changes, such as when `snapshot[0].user.name` changes.
  /// `loadedAll` is true when `snapshot` contains all the participants in the conversation, and false if you could load more.
  ///
  /// The `snapshot` list is ordered chronologically with the participants who joined most recently at the start.
  /// When someone joins the conversation, they will be added to the start of the list.
  ///
  /// The snapshot is nil if you are not a participant in the conversation (including when the conversation doesn't exist)
  ///
  /// Initially, you will be subscribed to the 10 participants who joined most recently, and any new participants.
  /// Call `loadMore` to load additional older participants. This will trigger `onSnapshot`.
  ///
  /// Remember to call `.unsubscribe` on the subscription once you are done with it.
  public func subscribeParticipants(
    onSnapshot: (@Sendable (_ snapshot: [ParticipantSnapshot]?, _ loadedAll: Bool) -> Void)? = nil
  ) -> ParticipantSubscription {
    let handler: (([TalkJSCore::ParticipantSnapshot]?, KotlinBoolean) -> Void)? =
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

  /// Subscribes to the typing status of the conversation.
  ///
  /// Whenever `Subscription.state.type` is "active" and the typing status changes, `onSnapshot` will fire and `Subscription.state.latestSnapshot` will be updated.
  /// This includes changes to nested data, such as when a user who is typing changes their name.
  ///
  /// The snapshot is nil if you are not a participant in the conversation (including when the conversation doesn't exist)
  ///
  /// Note that if there are "many" people typing and another person starts to type, `onSnapshot` will not be called.
  /// This is because your existing ``TypingSnapshot`` (with `many` set to `true`) is still valid and did not change when the new person started to type.
  public func subscribeTyping(
    onSnapshot: (@Sendable (_ snapshot: TypingSnapshot?) -> Void)? = nil
  ) -> TypingSubscription {
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

/// A snapshot of a conversation's attributes at a given moment in time.
///
/// Also includes information about the current user's view of that conversation, such as whether or not notifications are enabled.
public struct ConversationSnapshot: Equatable, Sendable {
  /// The ID of the conversation
  public let id: String
  /// Contains the conversation subject, or `nil` if the conversation does not have a subject specified.
  public let subject: String?
  /// Contains the URL of a photo to represent the topic of the conversation or `nil` if the conversation does not have a photo specified.
  public let photoUrl: String?
  /// One or more welcome messages that will be rendered at the start of this conversation as system messages.
  ///
  /// Welcome messages are rendered in the UI as messages, but they are not real messages.
  /// This means they do not appear when you list messages using the REST API or JS/Kotlin/Swift Data API, and you cannot reply or react to them.
  public let welcomeMessages: [String]
  /// Custom metadata you have set on the conversation
  public let custom: [String: String]
  /// The date that the conversation was created, as a unix timestamp in milliseconds.
  public let createdAt: Int64
  /// The date that the current user joined the conversation, as a unix timestamp in milliseconds.
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

/// A snapshot of the typing indicators in a conversation at a given moment in time.
///
/// Currently when there are 5 or less people typing in the conversation,
/// `many` will be `false` and `users` will contain the users who are currently typing in this conversation.
/// When more than 5 people are typing, `many` will be `true` and `users` will be `nil`.
/// This limit may change in the future, which will not be considered a breaking change.
///
/// Converting a TypingSnapshot to text
/// ```swift
/// func formatTyping(snapshot: TypingSnapshot) -> String {
///   if snapshot.many {
///     return "Several people are typing"
///   }
///
///   var names = (snapshot.users ?? []).map { user in user.name }
///
///   if names.isEmpty {
///     return ""
///   }
///
///   if names.count == 1 {
///     return names[0] + " is typing"
///   }
///
///   if names.count == 2 {
///     return names.joined(separator: " and ") + " are typing"
///   }
///
///   // Prefix last name with "and "
///   names.append("and " + names.removeLast())
///   return names.joined(separator: ", ") + " are typing"
/// }
/// ```
public struct TypingSnapshot: Equatable, Sendable {
  /// Check this to differentiate between few people are typing (`false`) and many people are typing (`true`).
  ///
  /// When `false`, you can see the list of users who are typing in the `users` property.
  public let many: Bool
  /// The users who are currently typing in this conversation.
  ///
  /// The list is in chronological order, starting with the users who have been typing the longest.
  /// The current user is never contained in the list, only other users.
  /// When the `many` property is `true`, this property is `nil`.
  public let users: [UserSnapshot]?

  init?(from snapshot: TalkJSCore::TypingSnapshot?) {
    guard let snapshot else {
      return nil
    }

    many = snapshot.many
    users = snapshot.users?.fromKotlin()
  }
}

public enum ConversationAccess: Equatable, Sendable {
  case Read, ReadWrite

  init(from conversationAccess: TalkJSCore::ConversationAccess) {
    if conversationAccess == .read {
      self = .Read
    } else if conversationAccess == .readWrite {
      self = .ReadWrite
    } else {
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

public enum NotificationSettings: Equatable, Sendable {
  case True, False, MentionsOnly

  init(from notificationSettings: TalkJSCore::NotificationSettings) {
    if notificationSettings == .`true` {
      self = .True
    } else if notificationSettings == .`false` {
      self = .False
    } else if notificationSettings == .mentionsOnly {
      self = .MentionsOnly
    } else {
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

/// A subscription to a specific conversation.
///
/// Get a ConversationSubscription by calling ``ConversationRef/subscribe(onSnapshot:)``
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ConversationSubscription: RealtimeSubscription, @unchecked Sendable {
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``ConversationSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``ConversationSubscriptionState/active(latestSnapshot:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``ConversationSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``ConversationSubscriptionState/error(_:)``.
  public var state: ConversationSubscriptionState {
    ConversationSubscriptionState(from: _subscription.state)
  }
  /// Resolves when the subscription starts receiving updates from the server.
  public let connected: Deferred<ConversationSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
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

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``ConversationSubscriptionState/unsubscribed`` or ``ConversationSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

/// A subscription to the typing status in a specific conversation
///
/// Get a TypingSubscription by calling ``ConversationRef/subscribeTyping(onSnapshot:)``.
///
/// When there are "many" people typing, the next update you receive will be once enough people stop typing.
/// Until then, your ``TypingSnapshot`` is still valid and does not need to changed, so `onSnapshot` will not be called.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct TypingSubscription: RealtimeSubscription, @unchecked Sendable {
  /// Resolves when the subscription starts receiving updates from the server.
  ///
  /// Wait for this promise if you want to perform some action as soon as the subscription is active.
  ///
  /// The promise rejects if the subscription is terminated before it connects.
  public let connected: Deferred<TypingSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<TypingSubscriptionState>
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``TypingSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``TypingSubscriptionState/active(latestSnapshot:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``TypingSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``TypingSubscriptionState/error(_:)``.
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

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``TypingSubscriptionState/unsubscribed`` or ``TypingSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ConversationSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// The most recently received snapshot for the conversation, or `nil` if you are not a participant in the conversation (including when the conversation does not exist).
  case active(latestSnapshot: ConversationSnapshot?)
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

public enum TypingSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// The most recently received typing indicator snapshot, or `nil` if you are not a participant in the conversation (including when the conversation does not exist).
  case active(latestSnapshot: TypingSnapshot?)
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
