internal import TalkJSCore

// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct Session: @unchecked Sendable {
  /// A reference to the user this session is connected as
  ///
  /// This is immutable. If you want to connect as a different user,
  /// call ``getTalkSession(appId:userId:token:tokenFetcher:)`` again to get a new session.
  ///
  /// Equivalent to calling ``user(id:)`` with the current user's ID.
  ///
  /// - SeeAlso: ``user(id:)`` which lets you get a reference to any user.
  public let currentUser: UserRef

  private let _session: TalkSession

  init(from session: TalkSession) {
    self._session = session
    self.currentUser = UserRef(from: session.currentUser)
  }

  /// Get a reference to a user
  ///
  /// - Parameter id: The ID of the user that you want to reference
  /// - Returns: A ``UserRef`` for the user with that ID
  public func user(id: String) -> UserRef {
    UserRef(from: _session.user(id: id))
  }

  /// Get a reference to a conversation
  ///
  /// - Parameter id: The ID of the conversation that you want to reference
  /// - Returns: A ``ConversationRef`` for the conversation with that ID
  public func conversation(id: String) -> ConversationRef {
    ConversationRef(from: _session.conversation(id: id))
  }

  /// Attaches a handler that will be called when the session encounters an error
  ///
  /// Returns a callback which detaches your handler
  public func onError(handler: @escaping @Sendable (TalkJSError) -> Void)
    -> any Subscription
  {
    KotlinSubscription(
      _session.onError { handler(TalkJSError(from: $0)) }
    )
  }

  /// Subscribes to the most recently active conversations for the current user
  public func subscribeConversations(
    onSnapshot: (@Sendable ([ConversationSnapshot], Bool) -> Void)?
  ) -> ConversationListSubscription {
    let handler:
      (([TalkJSCore::ConversationSnapshot], KotlinBoolean) -> Void)? =
        if onSnapshot != nil {
          { (snapshot, loadedAll) in
            onSnapshot!(snapshot.fromKotlin(), loadedAll.boolValue)
          }
        } else {
          nil
        }

    let subscription = _session.subscribeConversations(
      onSnapshot: handler
    )
    return ConversationListSubscription(from: subscription)
  }

  /// Upload an audio file with audio-specific metadata.
  ///
  /// This is a variant of ``uploadFile(data:metadata:)`` used for audio files.
  ///
  /// - Parameter data: The binary audio data. Usually a [File](https://developer.mozilla.org/en-US/docs/Web/API/File).
  /// - Parameter metadata: Information about the audio file.
  /// - Returns: A file token that can be used to send the audio file in a message.
  public func uploadAudio(data: [Int8], metadata: AudioFileMetadata) async
    -> String
  {
    return try! await _session.uploadAudio(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  /// Upload a generic file without any additional metadata.
  ///
  /// This function does not send any message, it only uploads the file and returns a file token.
  /// To send the file in a message, pass the file token in a ``SendFileBlock`` when calling ``ConversationRef/send(content:referencedMessage:custom:)``.
  ///
  /// [See the documentation](https://talkjs.com/docs/Reference/Concepts/Message_Content/#sending-message-content) for more information about sending files in messages.
  ///
  /// If the file is a video, image, audio file, or voice recording, use one of the other functions like ``uploadImage(data:metadata:)`` instead.
  ///
  /// - Parameter data: The binary file data. Usually a [File](https://developer.mozilla.org/en-US/docs/Web/API/File).
  /// - Parameter metadata: Information about the file
  /// - Returns: A file token that can be used to send the file in a message.
  public func uploadFile(data: [Int8], metadata: GenericFileMetadata) async
    -> String
  {
    return try! await _session.uploadFile(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  /// Upload a video with video-specific metadata.
  ///
  /// This is a variant of ``uploadFile(data:metadata:)`` used for videos.
  ///
  /// - Parameter data: The binary video data. Usually a [File](https://developer.mozilla.org/en-US/docs/Web/API/File).
  /// - Parameter metadata: Information about the video.
  /// - Returns: A file token that can be used to send the video in a message.
  public func uploadVideo(data: [Int8], metadata: VideoFileMetadata) async
    -> String
  {
    return try! await _session.uploadVideo(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  /// Upload an image with image-specific metadata.
  ///
  /// This is a variant of ``uploadFile(data:metadata:)`` used for images.
  ///
  /// - Parameter data: The binary image data. Usually a [File](https://developer.mozilla.org/en-US/docs/Web/API/File).
  /// - Parameter metadata: Information about the image.
  /// - Returns: A file token that can be used to send the image in a message.
  public func uploadImage(data: [Int8], metadata: ImageFileMetadata) async
    -> String
  {
    return try! await _session.uploadImage(
      data: data.toKotlinByteArray(),
      metadata: metadata.toKotlin()
    )
  }

  /// Upload a voice recording with voice-specific metadata.
  ///
  /// This is a variant of ``uploadFile(data:metadata:)`` used for voice recordings.
  ///
  /// - Parameter data: The binary audio data. Usually a [File](https://developer.mozilla.org/en-US/docs/Web/API/File).
  /// - Parameter metadata: Information about the voice recording.
  /// - Returns: A file token that can be used to send the audio file in a message.
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

  /// - Parameter filename: The name of the file including extension.
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

  /// - Parameter filename: The name of the file including extension.
  /// - Parameter duration: The duration of the audio file in seconds, if known.
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

  /// - Parameter filename: The name of the file including extension.
  /// - Parameter width: The width of the video in pixels, if known.
  /// - Parameter height: The height of the video in pixels, if known.
  /// - Parameter duration: The duration of the video in seconds, if known.
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

  /// - Parameter filename: The name of the file including extension.
  /// - Parameter width: The width of the image in pixels, if known.
  /// - Parameter height: The height of the image in pixels, if known.
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

  /// - Parameter filename: The name of the file including extension.
  /// - Parameter duration: The duration of the recording in seconds, if known.
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
