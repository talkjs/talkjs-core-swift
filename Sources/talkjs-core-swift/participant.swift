internal import TalkJSCore

/// References a given user's participation in a conversation.
///
/// Used in all Data API operations affecting that participant, such as joining/leaving a conversation, or setting their access.
/// Created via ``ConversationRef/participant(user:)``.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ParticipantRef: @unchecked Sendable {
  /// The ID of the user who is participating.
  ///
  /// Immutable: if you want to reference a different participant, get a new ParticipantRef instead.
  public let userId: String
  /// The ID of the conversation the user is participating in.
  ///
  /// Immutable: if you want to reference the user in a different conversation, get a new ParticipantRef instead.
  public let conversationId: String

  private let _participantRef: TalkJSCore::ParticipantRef

  init(_ participantRef: TalkJSCore::ParticipantRef) {
    _participantRef = participantRef
    userId = participantRef.userId
    conversationId = participantRef.conversationId
  }

  /// Adds the user as a participant, or does nothing if they are already a participant.
  ///
  /// If the participant already exists, this operation is still considered successful.
  ///
  /// The function will throw if client-side conversation syncing is disabled and the user is not already a participant.
  ///
  /// - Parameter access: The level of access the participant should have in the conversation.
  ///   Default = `.ReadWrite` access.
  /// - Parameter notify: When the participant should be notified about new messages in this conversation.
  ///   Default = `.True`.
  ///
  ///     `.False` means no notifications, `.True` means notifications for all messages, and `.MentionsOnly` means that the user will only be notified when they are mentioned with an `@`.
  public func createIfNotExists(
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _participantRef.createIfNotExists(
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  /// Removes the user as a participant, or does nothing if they are already not a participant.
  ///
  /// Deleting a nonexistent participant is treated as success.
  ///
  /// This function will throw if client-side conversation syncing is disabled.
  public func delete() async {
    try! await _participantRef.delete()
  }

  /// Deletes properties of this participant.
  ///
  /// Pass the name of each property to delete as a separate parameter to this function.
  public func deleteFields(_ fields: String...) async {
    try! await _participantRef.deleteFields(fields: fields.toKotlinArray())
  }

  /// Edits properties of a pre-existing participant. If the user is not already a participant in the conversation, the function will throw.
  ///
  /// When client-side conversation syncing is disabled, you must already be a participant and you cannot set anything except the `notify` property.
  /// Everything else requires client-side conversation syncing to be enabled, and will cause the function to throw.
  ///
  /// Properties that are `nil` will not be changed.
  /// To clear / reset a property to the default, call ``deleteFields(_:)`` instead.
  ///
  /// - Parameter access: The level of access the participant should have in the conversation.
  ///   Default = `.ReadWrite` access.
  /// - Parameter notify: When the participant should be notified about new messages in this conversation.
  ///   Default = `.True`.
  ///
  ///     `.False` means no notifications, `.True` means notifications for all messages, and `.MentionsOnly` means that the user will only be notified when they are mentioned with an `@`.
  public func edit(
    access: ConversationAccess? = nil,
    notify: NotificationSettings? = nil
  ) async {
    try! await _participantRef.edit(
      access: access?.toKotlin(),
      notify: notify?.toKotlin()
    )
  }

  /// Fetches a snapshot of the participant.
  ///
  /// This contains all of the participant's public information.
  ///
  /// - Returns: A snapshot of the participant's attributes, or nil if the user is not a participant. The function will throw if you are not a participant and try to read information about someone else.
  public func get() async -> ParticipantSnapshot? {
    let snapshot = try! await _participantRef.get()
    return ParticipantSnapshot(from: snapshot)
  }

  /// Sets properties of this participant. If the user is not already a participant in the conversation, they will be added.
  ///
  /// When client-side conversation syncing is disabled, you must already be a participant and you cannot set anything except the `notify` property.
  /// Everything else requires client-side conversation syncing to be enabled, and will cause the function to throw.
  ///
  /// Properties that are `nil` will not be changed.
  /// To clear / reset a property to the default, call ``deleteFields(_:)`` instead.
  ///
  /// - Parameter access: The level of access the participant should have in the conversation.
  ///   Default = `.ReadWrite` access.
  /// - Parameter notify: When the participant should be notified about new messages in this conversation.
  ///   Default = `.True`.
  ///
  ///     `.False` means no notifications, `.True` means notifications for all messages, and `.MentionsOnly` means that the user will only be notified when they are mentioned with an `@`.
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

/// A snapshot of a participant's attributes at a given moment in time.
public struct ParticipantSnapshot: Equatable, Sendable, Codable {
  /// The level of access this participant has in the conversation.
  public let access: ConversationAccess
  /// The date that this user joined the conversation, as a unix timestamp in milliseconds.
  public let joinedAt: Int64
  /// When the participant will be notified about new messages in this conversation.
  ///
  /// `.False` means no notifications, `.True` means notifications for all messages, and `.MentionsOnly` means that the user will only be notified when they are mentioned with an `@`.
  public let notify: NotificationSettings
  /// The user who this Participant Snapshot is referring to
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

/// A subscription to the participants in a specific conversation.
///
/// Get a ParticipantSubscription by calling ``ConversationRef/subscribeParticipants(onSnapshot:)``
///
/// The subscription is 'windowed'. It includes everyone who joined since a certain point in time.
/// By default, you subscribe to the 10 most recent participants, and any participants who joined after you subscribe.
///
/// You can expand this window by calling ``ParticipantSubscription/loadMore(count:)``, which extends the window further into the past.
/// Do not call `.loadMore` in a loop until you have loaded all participants, unless you know that the maximum number of participants is small (under 100).
///
/// Remember to `.unsubscribe` the subscription once you are done with it.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ParticipantSubscription: RealtimeSubscription, @unchecked Sendable {
  /// Resolves when the subscription starts receiving updates from the server.
  ///
  /// Wait for this promise if you want to perform some action as soon as the subscription is active.
  ///
  /// The promise rejects if the subscription is terminated before it connects.
  public let connected: Deferred<ParticipantSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<ParticipantSubscriptionState>
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``ParticipantSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``ParticipantSubscriptionState/active(latestSnapshot:loadedAll:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``ParticipantSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``ParticipantSubscriptionState/error(_:)``.
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
  /// Expand the window to include older participants
  ///
  /// Calling `loadMore` multiple times in parallel will still only load one page of participants.
  ///
  /// Avoid calling `.loadMore` in a loop until you have loaded all participants.
  /// If you do need to call loadMore in a loop, make sure you set a small upper bound (e.g. 100) on the number of participants, where the loop will exit.
  ///
  /// - Parameter count: The number of additional participants to load. Must be between 1 and 50. Default 10.
  public func loadMore(count: Int?) async {
    try! await _subscription.loadMore.invoke(p1: count?.toKotlinInt())
  }

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``ParticipantSubscriptionState/unsubscribed`` or ``ParticipantSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum ParticipantSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// `latestSnapshot`: The most recently received snapshot for the participants, or `nil` if you are not a participant in that conversation.
  ///
  /// `loadedAll`: True if `latestSnapshot` contains all participants in the conversation.
  /// Use ``ParticipantSubscription/loadMore(count:)`` to load more.
  case active(latestSnapshot: [ParticipantSnapshot]?, loadedAll: Bool)
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
