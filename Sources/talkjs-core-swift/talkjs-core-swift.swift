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
