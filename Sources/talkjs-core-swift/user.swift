internal import TalkJSCore

public struct UserRef {
  public let id: String

  private let _userRef: TalkJSCore::UserRef

  init(from userRef: TalkJSCore::UserRef) {
    _userRef = userRef
    id = userRef.id
  }

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

  public func deleteFields(_ fields: String...) async {
    try! await _userRef.deleteFields(fields: fields.toKotlinArray())
  }

  public func get() async -> UserSnapshot? {
    let snapshot = try! await _userRef.get()
    return UserSnapshot(from: snapshot)
  }

  public func set(
    name: String,
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

  public func subscribe(onSnapshot: ((UserSnapshot?) -> Void)? = nil)
    -> UserSubscription
  {
    let handler: ((TalkJSCore::UserSnapshot?) -> Void)? =
      if onSnapshot != nil {
        { onSnapshot!(UserSnapshot(from: $0)) }
      } else {
        nil
      }

    let subscription = _userRef.subscribe(onSnapshot: handler)
    return UserSubscription(from: subscription)
  }

  public func subscribeOnline(
    onSnapshot: ((UserOnlineSnapshot?) -> Void)? = nil
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

public struct UserSnapshot: Equatable {
  public let id: String
  public let name: String
  public let role: String
  public let custom: [String: String]
  public let photoUrl: String?
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

public struct UserOnlineSnapshot: Equatable {
  public let isConnected: Bool
  public let user: UserSnapshot

  init?(from snapshot: TalkJSCore::UserOnlineSnapshot?) {
    guard let snapshot else {
      return nil
    }

    user = UserSnapshot(from: snapshot.user)!
    isConnected = snapshot.isConnected
  }
}

public struct UserSubscription: RealtimeSubscription {
  public var state: UserSubscriptionState {
    UserSubscriptionState(from: _subscription.state)
  }
  public let connected: Deferred<UserSubscriptionState>
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

  public func unsubscribe() { _subscription.unsubscribe() }
}

public struct UserOnlineSubscription: RealtimeSubscription {
  public var state: UserOnlineSubscriptionState {
    UserOnlineSubscriptionState(fromKotlin: _subscription.state)
  }
  public let connected: Deferred<UserOnlineSubscriptionState>
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

  public func unsubscribe() { _subscription.unsubscribe() }
}

public enum UserSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: UserSnapshot?)
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

public enum UserOnlineSubscriptionState: SubscriptionState, Equatable {
  case pending
  case unsubscribed
  case active(latestSnapshot: UserOnlineSnapshot?)
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
