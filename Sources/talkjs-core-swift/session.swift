internal import TalkJSCore

// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct Session: @unchecked Sendable {
  public let currentUser: UserRef

  private let _session: TalkSession

  init(from session: TalkSession) {
    self._session = session
    self.currentUser = UserRef(from: session.currentUser)
  }

  public func user(id: String) -> UserRef {
    UserRef(from: _session.user(id: id))
  }

  public func conversation(id: String) -> ConversationRef {
    ConversationRef(from: _session.conversation(id: id))
  }

  public func onError(handler: @escaping @MainActor (TalkJSError) -> Void)
    -> any Subscription
  {
    KotlinSubscription(
      _session.onError {
        // Called by Kotlin on a background thread; deliver on the main actor.
        let error = TalkJSError(from: $0)
        Task { @MainActor in
          handler(error)
        }
      }
    )
  }

  public func subscribeConversations(
    onSnapshot: (@MainActor ([ConversationSnapshot], Bool) -> Void)?
  ) -> ConversationListSubscription {
    let handler:
      (([TalkJSCore::ConversationSnapshot], KotlinBoolean) -> Void)? =
        if onSnapshot != nil {
          { (snapshot, loadedAll) in
            // Called by Kotlin on a background thread; deliver on the main actor.
            let snapshot = snapshot.fromKotlin()
            let loadedAll = loadedAll.boolValue
            Task { @MainActor in
              onSnapshot!(snapshot, loadedAll)
            }
          }
        } else {
          nil
        }

    let subscription = _session.subscribeConversations(
      onSnapshot: handler
    )
    return ConversationListSubscription(from: subscription)
  }

  public func uploadAudio(data: [Int8], metadata: AudioFileMetadata) async
    -> String
  {
    return try! await _session.uploadAudio(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  public func uploadFile(data: [Int8], metadata: GenericFileMetadata) async
    -> String
  {
    return try! await _session.uploadFile(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  public func uploadVideo(data: [Int8], metadata: VideoFileMetadata) async
    -> String
  {
    return try! await _session.uploadVideo(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  public func uploadImage(data: [Int8], metadata: ImageFileMetadata) async
    -> String
  {
    return try! await _session.uploadImage(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  public func uploadVoice(data: [Int8], metadata: VoiceRecordingFileMetadata)
    async
    -> String
  {
    return try! await _session.uploadVoice(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }
}

public struct GenericFileMetadata {
  let filename: String

  public init(filename: String) {
    self.filename = filename
  }

  func toKotlin() -> TalkJSCore::GenericFileMetadata {
    TalkJSCore::GenericFileMetadata(filename: filename)
  }
}

public struct AudioFileMetadata {
  let filename: String
  let duration: Double?

  public init(filename: String, duration: Double? = nil) {
    self.filename = filename
    self.duration = duration
  }

  func toKotlin() -> TalkJSCore::AudioFileMetadata {
    TalkJSCore::AudioFileMetadata(
      filename: filename,
      duration: duration?.toKotlinDouble()
    )
  }
}

public struct VideoFileMetadata {
  let filename: String
  let duration: Double?
  let width: Int?
  let height: Int?

  public init(
    filename: String,
    duration: Double? = nil,
    width: Int? = nil,
    height: Int? = nil
  ) {
    self.filename = filename
    self.duration = duration
    self.width = width
    self.height = height
  }

  func toKotlin() -> TalkJSCore::VideoFileMetadata {
    TalkJSCore::VideoFileMetadata(
      filename: filename,
      width: width?.toKotlinInt(),
      height: height?.toKotlinInt(),
      duration: duration?.toKotlinDouble()
    )
  }
}

public struct ImageFileMetadata {
  let filename: String
  let width: Int?
  let height: Int?

  public init(filename: String, width: Int? = nil, height: Int? = nil) {
    self.filename = filename
    self.width = width
    self.height = height
  }

  func toKotlin() -> TalkJSCore::ImageFileMetadata {
    TalkJSCore::ImageFileMetadata(
      filename: filename,
      width: width?.toKotlinInt(),
      height: height?.toKotlinInt()
    )
  }
}

public struct VoiceRecordingFileMetadata {
  let filename: String
  let duration: Double?

  public init(filename: String, duration: Double? = nil) {
    self.filename = filename
    self.duration = duration
  }

  func toKotlin() -> TalkJSCore::VoiceRecordingFileMetadata {
    TalkJSCore::VoiceRecordingFileMetadata(
      filename: filename,
      duration: duration?.toKotlinDouble()
    )
  }
}
