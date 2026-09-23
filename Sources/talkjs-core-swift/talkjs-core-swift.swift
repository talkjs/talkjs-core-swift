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

public typealias TokenFetcher = () async -> String

public func getTalkSession(
  appId: String,
  userId: String,
  token: String? = nil,
  tokenFetcher: TokenFetcher? = nil,
  signature: String? = nil,
  host: String? = nil,
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
      tokenFetcher: nil,
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
    token: token,
    tokenFetcher: tokenFetcher,
    host: ""  // prod
  )
}
