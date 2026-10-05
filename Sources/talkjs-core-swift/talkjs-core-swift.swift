internal import TalkJSCore

public struct ApiUrlOptions: Equatable {
  let realtimeWsApiUrl: String
  let internalHttpApiUrl: String
  let restApiHttpUrl: String

  public init(
    realtimeWsApiUrl: String,
    internalHttpApiUrl: String,
    restApiHttpUrl: String
  ) {
    self.realtimeWsApiUrl = realtimeWsApiUrl
    self.internalHttpApiUrl = internalHttpApiUrl
    self.restApiHttpUrl = restApiHttpUrl
  }
}

public typealias TokenFetcher = @Sendable () async throws -> String

// The binary takes the token fetcher as a Kotlin `suspend () -> String`, which
// is exported as `KotlinSuspendFunction0`. This adapts a Swift async closure.
// If the fetcher throws, the session terminates.
//
// SKIE renames the original suspend method by adding a `__` prefix (to avoid a
// clash with the `invoke()` wrapper it generates), so `__invoke()` is the
// requirement to implement. See https://skie.touchlab.co/features/suspend
final class TokenFetcherAdapter: TalkJSCore::KotlinSuspendFunction0 {
  private let fetcher: TokenFetcher

  init(_ fetcher: @escaping TokenFetcher) {
    self.fetcher = fetcher
  }

  func __invoke() async throws -> Any? {
    try await fetcher()
  }
}

// forceCreateNew:
// If set to true, then `getTalkSession` will bypass the registry and create a new session
// This option is the only way to have two sessions for the same user with different auth tokens.
//
// IE it's an undocumented, secret escape hatch for that specific weird niche use case.
// It *is* designed to be used by customers, but it's undocumented so they'd only find out about it
// if they contacted live support and we told them about it.
//
// host:
// note: it makes little sense to have both `host` and `apiUrls`. I intend to
// remove `apiUrls` in the future in favour of just `host`.

/// Returns a TalkSession option for the specified App ID and User ID.
///
/// Backed by a registry, so calling this function twice with the same app and user returns the same session object both times.
/// A new session will be created if the old one encountered an error or got garbage collected.
///
/// The `token` and `tokenFetcher` properties are ignored if there is already a session for that user in the registry.
///
/// - Parameter appId: Your app's unique TalkJS ID. Get it from the **Settings** page of the [dashboard](https://talkjs.com/dashboard).
/// - Parameter userId: The `id` of the user you want to connect and act as. Any messages you send will be sent as this user.
/// - Parameter token: A token to authenticate the session with. Ignored if a TalkSession object already exists for this appId + userId.
/// - Parameter tokenFetcher: A callback that fetches a new token from your backend and returns it. If this callback throws an error, the session will terminate. Your callback should retry failed requests. Ignored if a TalkSession object already exists for this appId + userId.
public func getTalkSession(
  appId: String,
  userId: String,
  host: String,
  token: String? = nil,
  tokenFetcher: TokenFetcher? = nil,
  signature: String? = nil,
  apiUrls: ApiUrlOptions? = nil,
  forceCreateNew: Bool = false,
) -> Session {
  var urlOptions: TalkJSCore::ApiUrlOptions?
  if let urls = apiUrls {
    urlOptions = TalkJSCore::ApiUrlOptions(
      realtimeWsApiUrl: urls.realtimeWsApiUrl,
      internalHttpApiUrl: urls.internalHttpApiUrl,
      restApiHttpUrl: urls.restApiHttpUrl
    )
  }

  return Session(
    from: TalkJSCore::getTalkSession(
      appId: appId,
      userId: userId,
      token: token,
      tokenFetcher: tokenFetcher.map { TokenFetcherAdapter($0) },
      forceCreateNew: forceCreateNew,
      signature: signature,
      apiUrls: urlOptions,
      host: host,
      clientBuild: "swift-0.0.1"
    )
  )
}

/// Returns a TalkSession option for the specified App ID and User ID.
///
/// Backed by a registry, so calling this function twice with the same app and user returns the same session object both times.
/// A new session will be created if the old one encountered an error or got garbage collected.
///
/// The `token` and `tokenFetcher` properties are ignored if there is already a session for that user in the registry.
///
/// - Parameter appId: Your app's unique TalkJS ID. Get it from the **Settings** page of the [dashboard](https://talkjs.com/dashboard).
/// - Parameter userId: The `id` of the user you want to connect and act as. Any messages you send will be sent as this user.
/// - Parameter token: A token to authenticate the session with. Ignored if a TalkSession object already exists for this appId + userId.
/// - Parameter tokenFetcher: A callback that fetches a new token from your backend and returns it. If this callback throws an error, the session will terminate. Your callback should retry failed requests. Ignored if a TalkSession object already exists for this appId + userId.
public func getTalkSession(
  appId: String,
  userId: String,
  token: String? = nil,
  tokenFetcher: TokenFetcher? = nil
) -> Session {
  return getTalkSession(
    appId: appId,
    userId: userId,
    host: "",  // prod
    token: token,
    tokenFetcher: tokenFetcher
  )
}
