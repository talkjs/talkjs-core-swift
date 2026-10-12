internal import TalkJSCore

/// References the user with a given user ID.
///
/// Used in all Data API operations affecting that user, such as creating the user, fetching or updating user data, or adding a user to a conversation.
/// Created via ``Session/user(id:)``.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct UserRef: @unchecked Sendable {
  /// The ID of the referenced user.
  ///
  /// Immutable: if you want to reference a different user, get a new UserRef instead.
  public let id: String

  private let _userRef: TalkJSCore::UserRef

  init(from userRef: TalkJSCore::UserRef) {
    _userRef = userRef
    id = userRef.id
  }

  /// Creates a user with this ID, or does nothing if a user with this ID already exists.
  ///
  /// If the user already exists, this operation is still considered successful.
  ///
  /// - Parameter name: The user's name which is displayed on the TalkJS UI
  /// - Parameter custom: Custom metadata you have set on the user.
  ///   Default = no custom metadata
  /// - Parameter locale: An [IETF language tag](https://www.w3.org/International/articles/language-tags/)
  ///   See the [localization documentation](https://talkjs.com/docs/Features/Language_Support/Localization.html)
  ///   Default = the locale selected on the dashboard
  /// - Parameter photoUrl: An optional URL to a photo that is displayed as the user's avatar.
  ///   Default = no photo
  /// - Parameter role: TalkJS supports multiple sets of settings, called "roles". These allow you to change the behavior of TalkJS for different users.
  ///   You have full control over which user gets which configuration.
  ///   Default = the `default` role
  /// - Parameter welcomeMessage: The default message a person sees when starting a chat with this user.
  ///   Default = no welcome message
  ///
  ///     This field is only used by the Classic SDK (including the
  ///     Flutter and React Native SDKs), and not by the modern UI Components SDK.
  ///     If you use the UI Components, see
  ///     [the Welcome Messages guide](https://talkjs.com/docs/Guides/Web_Components/Welcome_Messages/).
  /// - Parameter email: An array of email addresses associated with the user.
  ///   Default = no email addresses
  /// - Parameter phone: An array of phone numbers associated with the user.
  ///   Default = no phone numbers
  /// - Parameter pushTokens: A Dictionary of push registration tokens to use when notifying this user.
  ///
  ///     Keys in the Dictionary have the format `'provider:token_id'`, where `provider` is either
  ///     `"fcm"` for Firebase Cloud Messaging or `"apns"` for Apple Push Notification Service
  ///
  ///     Default = no push registration tokens
  ///
  ///     (Value of the Dictionary is always true)
  public func createIfNotExists(
    name: String,
    role: String? = nil,
    photoUrl: String? = nil,
    email: [String]? = nil,
    custom: [String: String]? = nil,
    locale: String? = nil,
    phone: [String]? = nil,
    pushTokens: [String: Bool]? = nil,
    welcomeMessage: String? = nil,
  ) async {
    try! await _userRef.createIfNotExists(
      name: name,
      custom: custom,
      locale: locale,
      photoUrl: photoUrl,
      role: role,
      welcomeMessage: welcomeMessage,
      email: email,
      phone: phone,
      pushTokens: pushTokens?.toKotlin()
    )
  }

  /// Deletes properties of this user.
  ///
  /// Pass the name of each property to delete as a separate parameter to this function.
  /// To delete a field in the `custom` property, pass it as `custom.FIELD_TO_DELETE`.
  /// To delete a field in the `pushTokens` property, pass it as `pushTokens.FIELD_TO_DELETE`.
  public func deleteFields(_ fields: String...) async {
    await deleteFields(fields)
  }

  /// Deletes properties of this user.
  ///
  /// Pass the name of each property to delete in the `fields` array.
  /// To delete a field in the `custom` property, pass it as `custom.FIELD_TO_DELETE`.
  /// To delete a field in the `pushTokens` property, pass it as `pushTokens.FIELD_TO_DELETE`.
  public func deleteFields(_ fields: [String]) async {
    try! await _userRef.deleteFields(fields: fields.toKotlinArray())
  }

  /// Fetches a snapshot of the user.
  ///
  /// This contains all of a user's public information.
  /// Fetching a user snapshot doesn't require any permissions. You can read the public information of any user.
  /// Private information, such as email addresses and phone numbers, aren't included in the response.
  ///
  /// - Returns: A snapshot of the user's public attributes, or nil if the user doesn't exist.
  public func get() async -> UserSnapshot? {
    let snapshot = try! await _userRef.get()
    return UserSnapshot(from: snapshot)
  }

  /// Sets properties of this user. The user is created if a user with this ID doesn't already exist.
  ///
  /// `name` is required when creating a user. The function will throw if you don't provide a `name` and the user does not exist yet.
  ///
  /// Properties that are `nil` will not be changed.
  /// To clear / reset a property to the default, call ``deleteFields(_:)`` instead.
  ///
  /// - Parameter name: The user's name which will be displayed on the TalkJS UI
  /// - Parameter custom: Custom metadata you have set on the user.
  ///   This value acts as a patch. Remove specific properties by calling ``deleteFields(_:)``
  ///   Default = no custom metadata
  /// - Parameter locale: An [IETF language tag](https://www.w3.org/International/articles/language-tags/)
  ///   See the [localization documentation](https://talkjs.com/docs/Features/Language_Support/Localization.html)
  ///   Default = the locale selected on the dashboard
  /// - Parameter photoUrl: An optional URL to a photo which will be displayed as the user's avatar.
  ///   Default = no photo
  /// - Parameter role: TalkJS supports multiple sets of settings, called "roles". These allow you to change the behaviour of TalkJS for
  ///   different users.
  ///   You have full control over which user gets which configuration.
  ///   Default = the `default` role
  /// - Parameter welcomeMessage: The default message a person sees when starting a chat with this user.
  ///   Default = no welcome message
  ///
  ///     Note: User welcome messages are only supported by the Classic SDKs, and in
  ///     the Components-based SDKs, this field is ignored. To show welcome messages
  ///     in the Components-based SDK, see
  ///     [Welcome Messages](https://talkjs.com/docs/Guides/React/Welcome_Messages/).
  /// - Parameter email: An array of email addresses associated with the user.
  ///   Default = no email addresses
  /// - Parameter phone: An array of phone numbers associated with the user.
  ///   Default = no phone numbers
  /// - Parameter pushTokens: A Dictionary of push registration tokens to use when notifying this user.
  ///
  ///     Keys in the Dictionary have the format `'provider:token_id'`, where `provider` is either
  ///     `"fcm"` for Firebase Cloud Messaging or `"apns"` for Apple Push Notification Service
  ///
  ///     The value for each key must be `true` to register the device for push notifications.
  ///     To unregister that device call ``deleteFields(_:)``
  ///
  ///     Calling ``deleteFields(_:)`` with the string `pushTokens` unregisters all the previously registered devices.
  ///
  ///     Default = no push tokens
  public func set(
    name: String? = nil,
    role: String? = nil,
    photoUrl: String? = nil,
    email: [String]? = nil,
    custom: [String: String?]? = nil,  //investigate
    locale: String? = nil,
    phone: [String]? = nil,
    pushTokens: [String: Bool?]? = nil,
    welcomeMessage: String? = nil
  ) async {
    try! await _userRef.set(
      name: name,
      custom: custom,
      locale: locale,
      photoUrl: photoUrl,
      role: role,
      welcomeMessage: welcomeMessage,
      email: email,
      phone: phone,
      pushTokens: pushTokens?.toKotlin()
    )
  }

  /// Subscribe to this user's state.
  ///
  /// While the subscription is active, `onSnapshot` will be called when the user is created or the snapshot changes.
  ///
  /// Remember to call `.unsubscribe` on the subscription once you are done with it.
  ///
  /// - Returns: A subscription to the user
  public func subscribe(
    onSnapshot: (@Sendable (_ snapshot: UserSnapshot?) -> Void)? = nil
  ) -> UserSubscription {
    let handler: ((TalkJSCore::UserSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(UserSnapshot(from: $0)) }
      } else {
        nil
      }

    let subscription = _userRef.subscribe(onSnapshot: handler)
    return UserSubscription(from: subscription)
  }

  /// Subscribe to this user and their online status.
  ///
  /// While the subscription is active, `onSnapshot` will be called when the user is created or the snapshot changes (including changes to the nested UserSnapshot).
  ///
  /// Remember to call `.unsubscribe` on the subscription once you are done with it.
  ///
  /// - Returns: A subscription to the user's online status
  public func subscribeOnline(
    onSnapshot: (@Sendable (_ snapshot: UserOnlineSnapshot?) -> Void)? = nil
  )
    -> UserOnlineSubscription
  {
    let handler: ((TalkJSCore::UserOnlineSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(UserOnlineSnapshot(from: $0)) }
      } else {
        nil
      }

    let subscription = _userRef.subscribeOnline(onSnapshot: handler)
    return UserOnlineSubscription(from: subscription)
  }
}

/// A snapshot of a user's attributes at a given moment in time.
///
/// Users also have private information, such as email addresses and phone numbers, but these are only exposed on the [REST API](https://talkjs.com/docs/Reference/REST_API/Getting_Started/Introduction/)
public struct UserSnapshot: Equatable, Sendable, Codable {
  /// The unique ID that is used to identify the user in TalkJS
  public let id: String
  /// The user's name, which is displayed on the TalkJS UI
  public let name: String
  /// TalkJS supports multiple sets of settings for users, called "roles". Roles allow you to change the behavior of TalkJS for different users.
  /// You have full control over which user gets which configuration.
  public let role: String
  /// Custom metadata you have set on the user
  public let custom: [String: String]
  /// An optional URL to a photo that is displayed as the user's avatar
  public let photoUrl: String?
  /// An [IETF language tag](https://www.w3.org/International/articles/language-tags/)
  /// For more information, see: [localization](https://talkjs.com/docs/Features/Language_Support/Localization.html)
  ///
  /// When `locale` is nil, the app's default locale will be used
  public let locale: String?

  init?(from snapshot: TalkJSCore::UserSnapshot?) {
    guard let snapshot else {
      return nil
    }

    id = snapshot.id
    name = snapshot.name
    role = snapshot.role
    custom = snapshot.custom
    photoUrl = snapshot.photoUrl
    locale = snapshot.locale
  }
}

extension Array where Element == TalkJSCore::UserSnapshot {
  func fromKotlin() -> [UserSnapshot] {
    self.map { UserSnapshot(from: $0)! }
  }
}

/// A snapshot of a user's online status at a given moment in time.
///
/// Snapshots are immutable and we try to reuse them when possible. You should only re-render your UI when `oldSnapshot != newSnapshot`.
public struct UserOnlineSnapshot: Equatable, Sendable, Codable {
  /// Whether the user is connected right now
  ///
  /// Users are considered connected whenever they have an active websocket connection to the TalkJS servers.
  /// In practice, this means:
  ///
  /// People using the [JS Data API](https://talkjs.com/docs/Reference/JavaScript_Data_API/) are considered connected if they are subscribed to something, or if they sent a request in the last few seconds.
  /// Creating a `TalkSession` is not enough to appear connected.
  ///
  /// People using [Components](https://talkjs.com/docs/Reference/Components/), are considered connected if they have a UI open.
  ///
  /// People using the [JavaScript SDK](https://talkjs.com/docs/Reference/JavaScript_Chat_SDK/), [React SDK](https://talkjs.com/docs/Reference/React_SDK/Installation/), [React Native SDK](https://talkjs.com/docs/Reference/React_Native_SDK/Installation/), or [Flutter SDK](https://talkjs.com/docs/Reference/Flutter_SDK/Installation/) are considered connected whenever they have an active `Session` object.
  public let isConnected: Bool
  /// The user this snapshot relates to
  public let user: UserSnapshot

  init?(from snapshot: TalkJSCore::UserOnlineSnapshot?) {
    guard let snapshot else {
      return nil
    }

    user = UserSnapshot(from: snapshot.user)!
    isConnected = snapshot.isConnected
  }
}

// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct UserSubscription: RealtimeSubscription, @unchecked Sendable {
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``UserSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``UserSubscriptionState/active(latestSnapshot:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``UserSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``UserSubscriptionState/error(_:)``.
  public var state: UserSubscriptionState {
    UserSubscriptionState(from: _subscription.state)
  }
  /// Resolves when the subscription starts receiving updates from the server.
  public let connected: Deferred<UserSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<UserSubscriptionState>

  private let _subscription: TalkJSCore::UserSubscription

  init(from _subscription: TalkJSCore::UserSubscription) {
    self._subscription = _subscription
    self.connected = Deferred(_subscription.connected) {
      UserSubscriptionState(
        from: $0 as! TalkJSCore::UserSubscriptionStateActive
      )
    }
    self.terminated = Deferred(_subscription.terminated) {
      UserSubscriptionState(
        from: $0 as! TalkJSCore::UserSubscriptionState
      )
    }
  }

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``UserSubscriptionState/unsubscribed`` or ``UserSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

/// A subscription to the online status of a user
///
/// Get a UserOnlineSubscription by calling ``UserRef/subscribeOnline(onSnapshot:)``.
///
/// Remember to `.unsubscribe` the subscription once you are done with it.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct UserOnlineSubscription: RealtimeSubscription, @unchecked Sendable {
  /// The current state of the subscription
  ///
  /// An enum with the following fields:
  ///
  /// `type` is one of "pending", "active", "unsubscribed", or "error".
  ///
  /// When `type` is "pending", this property is ``UserOnlineSubscriptionState/pending``.
  ///
  /// When `type` is "active", this property is ``UserOnlineSubscriptionState/active(latestSnapshot:)``.
  ///
  /// When `type` is "unsubscribed", this property is ``UserOnlineSubscriptionState/unsubscribed``.
  ///
  /// When `type` is "error", this property is ``UserOnlineSubscriptionState/error(_:)``.
  public var state: UserOnlineSubscriptionState {
    UserOnlineSubscriptionState(fromKotlin: _subscription.state)
  }
  /// Resolves when the subscription starts receiving updates from the server.
  ///
  /// Wait for this promise if you want to perform some action as soon as the subscription is active.
  ///
  /// The promise rejects if the subscription is terminated before it connects.
  public let connected: Deferred<UserOnlineSubscriptionState>
  /// Resolves when the subscription permanently stops receiving updates from the server.
  ///
  /// This is either because you unsubscribed or because the subscription encountered an unrecoverable error.
  public let terminated: Deferred<UserOnlineSubscriptionState>

  private let _subscription: TalkJSCore::UserOnlineSubscription

  init(from subscription: TalkJSCore::UserOnlineSubscription) {
    self._subscription = subscription
    self.connected = Deferred(subscription.connected) {
      UserOnlineSubscriptionState(
        fromKotlin: $0 as! TalkJSCore::UserOnlineSubscriptionStateActive
      )
    }
    self.terminated = Deferred(subscription.terminated) {
      UserOnlineSubscriptionState(
        fromKotlin: $0 as! TalkJSCore::UserOnlineSubscriptionState
      )
    }
  }

  /// Unsubscribe from this resource and stop receiving updates.
  ///
  /// If the subscription is already in the ``UserOnlineSubscriptionState/unsubscribed`` or ``UserOnlineSubscriptionState/error(_:)`` state, this is a no-op.
  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum UserSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// The most recently received snapshot for the user, or `nil` if the user does not exist yet.
  case active(latestSnapshot: UserSnapshot?)
  /// The error that caused the subscription to be terminated
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .error: "error"
    case .active: "active"
    case .pending: "pending"
    case .unsubscribed: "unsubscribed"
    }
  }

  init!(from state: any TalkJSCore::UserSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::UserSubscriptionStatePending:
        .pending
      case let activeState as TalkJSCore::UserSubscriptionStateActive:
        .active(latestSnapshot: UserSnapshot(from: activeState.latestSnapshot))
      case is TalkJSCore::UserSubscriptionStateUnsubscribed:
        .unsubscribed
      case let errorState as TalkJSCore::UserSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))
      default:
        preconditionFailure("Unreachable")
      }
  }
}

public enum UserOnlineSubscriptionState: SubscriptionState, Equatable, Sendable {
  case pending
  case unsubscribed
  /// The most recently received snapshot
  case active(latestSnapshot: UserOnlineSnapshot?)
  /// The error that caused the subscription to be terminated
  case error(TalkJSError)

  public var type: String {
    switch self {
    case .error: "error"
    case .active: "active"
    case .pending: "pending"
    case .unsubscribed: "unsubscribed"
    }
  }

  init!(fromKotlin state: any TalkJSCore::UserOnlineSubscriptionState) {
    self =
      switch state {
      case is TalkJSCore::UserOnlineSubscriptionStatePending:
        .pending
      case is TalkJSCore::UserOnlineSubscriptionStateUnsubscribed:
        .unsubscribed
      case let activeState as TalkJSCore::UserOnlineSubscriptionStateActive:
        .active(
          latestSnapshot: UserOnlineSnapshot(from: activeState.latestSnapshot)
        )
      case let errorState as TalkJSCore::UserOnlineSubscriptionStateError:
        .error(TalkJSError(from: errorState.error))

      default:
        preconditionFailure("Unreachable")
      }
  }
}
