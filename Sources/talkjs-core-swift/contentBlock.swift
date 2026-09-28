internal import TalkJSCore

internal protocol KotlinConvertibleSendBlock {
  associatedtype KotlinType: TalkJSCore::SendContentBlock
  func toKotlin() throws -> KotlinType
}

internal protocol KotlinConvertibleContentBlock {
  associatedtype KotlinType: TalkJSCore::ContentBlock
  func toKotlin() throws -> KotlinType
}

extension Array where Element == any SendContentBlock {
  func toKotlinSendContentBlock() throws -> [TalkJSCore::SendContentBlock] {
    try self.map {
      if let entity = $0 as? (any KotlinConvertibleSendBlock) {
        try entity.toKotlin()
      } else {
        throw TalkJSError("Unknown SendContentBlock: \(type(of: $0))")
      }
    }
  }
}

/// The content of a message is structured as a list of content blocks.
///
/// Currently, each message can only have one content block, but this will change in the future.
/// This will not be considered a breaking change, so your code should assume there can be multiple content blocks.
///
/// These blocks are rendered in order, top-to-bottom.
///
/// Currently the available Content Block types are:
///
/// - ``TextBlock``
///
/// - ``FileBlock``
///
/// - ``LocationBlock``
public protocol ContentBlock: Equatable, Sendable {}

extension ContentBlock {
  func isEqual<U: ContentBlock>(_ rhs: U) -> Bool {
    guard let lhs = self as? U else { return false }

    return lhs == rhs
  }
}

extension Array where Element == any ContentBlock {
  func isEqual(_ other: [any ContentBlock]) -> Bool {
    guard self.count == other.count else { return false }

    for index in 0..<self.count {
      let lhs = self[index]
      let rhs = other[index]

      if !lhs.isEqual(rhs) {
        return false
      }
    }

    return true
  }
}

extension Array where Element == TalkJSCore::ContentBlock {
  func fromKotlin() throws -> [any ContentBlock] {
    try self.map {
      switch $0 {
      case let block as TalkJSCore::TextBlock: try TextBlock(block)
      case let block as TalkJSCore::LocationBlock: LocationBlock(block)
      case let block as TalkJSCore::GenericFileBlock: GenericFileBlock(block)
      case let block as TalkJSCore::ImageBlock: ImageBlock(block)
      case let block as TalkJSCore::VideoBlock: VideoBlock(block)
      case let block as TalkJSCore::AudioBlock: AudioBlock(block)
      case let block as TalkJSCore::VoiceBlock: VoiceBlock(block)
      default:
        throw TalkJSError("Unknown ContentBlock: \(type(of: $0))")
      }
    }
  }
}

/// The version of ``ContentBlock`` that is used when sending or editing messages.
///
/// This is the same as ``ContentBlock`` except it uses ``SendFileBlock`` instead of ``FileBlock``
///
/// `SendContentBlock` is a subset of `ContentBlock`.
/// This means that you can re-send the `content` from an existing message without any issues:
///
/// ```swift
/// let existingMessage: MessageSnapshot = ...
///
/// let convRef = session.conversation(id: "example_conversation_id")
/// await convRef.send(content: existingMessage.content)
/// ```
public protocol SendContentBlock: Equatable {}

/// A block of formatted text in a message's content.
///
/// Each TextBlock is a tree of children describing the structure of some formatted text.
/// Each child is either a plain text string, or a `node` representing some text with additional formatting.
///
/// For example, if the user typed:
///
/// > *This first bit* is bold, and *_the second bit_* is bold and italics
///
/// Then this would become a Text Block with the structure:
///
/// ```swift
/// TextBlock(
///   children: [
///     try Markup(type: "bold", children: ["This first bit"]),
///     " is bold, and ",
///     try Markup(
///       type: "bold",
///       children: [
///         try Markup(type: "italic", children: ["the second bit"]),
///       ],
///     ),
///     " is bold and italics",
///   ],
/// )
/// ```
///
/// Rather than relying the automatic message parsing, you can also specify the `TextBlock` directly using ``ConversationRef/send(content:referencedMessage:custom:)``.
public struct TextBlock:
  ContentBlock, SendContentBlock, KotlinConvertibleSendBlock
{
  public let children: EntityTree

  public init(children: EntityTree) {
    self.children = children
  }

  init(_ textBlock: TalkJSCore::TextBlock) throws {
    self.init(children: try textBlock.children.fromKotlinEntityTree())
  }

  func toKotlin() throws -> TalkJSCore::TextBlock {
    TalkJSCore::TextBlock(
      children: try children.toKotlinEntityTree(),
      type: "textBlock"
    )
  }

  public static func == (lhs: TextBlock, rhs: TextBlock) -> Bool {
    lhs.children.isEqual(rhs.children)
  }
}

/// A block showing a location in the world, typically because a user shared their location in the chat.
///
/// In the TalkJS UI, location blocks are rendered as a link to Google Maps, with the map pin showing at the specified coordinate.
/// A thumbnail shows the surrounding area on the map.
public struct LocationBlock:
  ContentBlock, SendContentBlock, KotlinConvertibleSendBlock
{
  /// The north-south coordinate of the location.
  ///
  /// Usually listed first in a pair of coordinates.
  ///
  /// Must be a number between -90 and 90
  public let latitude: Double
  /// The east-west coordinate of the location.
  ///
  /// Usually listed second in a pair of coordinates.
  ///
  /// Must be a number between -180 and 180
  public let longitude: Double

  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }

  init(_ locationBlock: TalkJSCore::LocationBlock) {
    self.init(
      latitude: locationBlock.latitude,
      longitude: locationBlock.longitude
    )
  }

  func toKotlin() throws -> TalkJSCore::LocationBlock {
    TalkJSCore::LocationBlock(
      latitude: latitude,
      longitude: longitude,
      type: "location"
    )
  }
}

/// The version of ``FileBlock`` that is used when sending or editing messages.
///
/// When a user receives the message you send with `SendFileBlock`, this block will have turned into one of the ``FileBlock`` variants.
///
/// For information on how to obtain a file token, see ``FileToken``.
///
/// The `SendFileBlock` interface is a subset of the `FileBlock` interface.
/// If you have an existing `FileBlock` received in a message, you can re-use that block to re-send the same attachment:
///
/// ```swift
/// let existingFileBlock = ...
/// let imageToShare = existingFileBlock.content[0] as! ImageBlock
///
/// let convRef = session.conversation(id: "example_conversation_id")
/// await convRef.send(content: [imageToShare])
/// ```
public struct SendFileBlock: SendContentBlock, KotlinConvertibleSendBlock {
  /// The encoded identifier for the file, obtained by uploading a file with ``Session/sendFile``, or taken from another message.
  public let fileToken: String

  public init(fileToken: String) {
    self.fileToken = fileToken
  }

  func toKotlin() throws -> TalkJSCore::SendFileBlock {
    TalkJSCore::SendFileBlock(fileToken: fileToken, type: "file")
  }
}

public protocol FileBlock: ContentBlock {
  var url: String { get }
  var size: Int64 { get }
  var filename: String { get }
  var fileToken: String { get }
}

/// The most basic FileBlock variant, used whenever there is no additional metadata for a file.
///
/// Do not try to check for `block is GenericFileBlock` directly, as this will break when we add new FileBlock variants in the future.
///
/// Instead, treat GenericFileBlock as the default. For example:
///
/// ```swift
/// switch block {
///     case let block as VideoBlock: handleVideoBlock(block)
///     case let block as ImageBlock: handleImageBlock(block)
///     case let block as AudioBlock: handleAudioBlock(block)
///     case let block as VoiceBlock: handleVoiceBlock(block)
///     default: handleGenericFileBlock(block)
/// }
/// ```
public struct GenericFileBlock: FileBlock {
  /// The URL where you can fetch the file
  public let url: String
  /// The size of the file in bytes
  public let size: Int64
  /// The name of the file, including file extension
  public let filename: String
  /// An encoded identifier for this file. Use in ``SendFileBlock`` to send this file in another message.
  public let fileToken: String

  public init(url: String, size: Int64, filename: String, fileToken: String) {
    self.url = url
    self.size = size
    self.filename = filename
    self.fileToken = fileToken
  }

  init(_ genericFileBlock: TalkJSCore::GenericFileBlock) {
    self.init(
      url: genericFileBlock.url,
      size: genericFileBlock.size,
      filename: genericFileBlock.filename,
      fileToken: genericFileBlock.fileToken
    )
  }
}

/// A FileBlock variant for an image attachment, with additional image-specific metadata.
///
/// You can identify this variant by checking `block is ImageBlock`.
///
/// Includes metadata about the height and width of the image in pixels, where available.
///
/// Images that you upload with the TalkJS UI will include the image dimensions as long as the sender's browser can preview the file.
/// Images that you upload with the REST API or ``Session/uploadImage(data:metadata:)`` will include the dimensions if you specified them when uploading.
/// Image attached in a reply to an email notification will not include the dimensions.
public struct ImageBlock: FileBlock {
  /// The URL where you can fetch the file.
  public let url: String
  /// The size of the file in bytes.
  public let size: Int64
  /// The name of the image file, including file extension.
  public let filename: String
  /// An encoded identifier for this file. Use in ``SendFileBlock`` to send this image in another message.
  public let fileToken: String

  /// The width of the image in pixels, if known.
  public let width: Int?
  /// The height of the image in pixels, if known.
  public let height: Int?

  public init(
    url: String,
    size: Int64,
    filename: String,
    fileToken: String,
    width: Int? = nil,
    height: Int? = nil
  ) {
    self.url = url
    self.size = size
    self.filename = filename
    self.fileToken = fileToken

    self.width = width
    self.height = height
  }

  init(_ imageBlock: TalkJSCore::ImageBlock) {
    self.init(
      url: imageBlock.url,
      size: imageBlock.size,
      filename: imageBlock.filename,
      fileToken: imageBlock.fileToken,
      width: imageBlock.width?.intValue,
      height: imageBlock.height?.intValue
    )
  }
}

/// A FileBlock variant for a video attachment, with additional video-specific metadata.
///
/// You can identify this variant by checking `block is VideoBlock`.
///
/// Includes metadata about the height and width of the video in pixels, and the duration of the video in seconds, where available.
///
/// Videos that you upload with the TalkJS UI will include the dimensions and duration as long as the sender's browser can preview the file.
/// Videos that you upload with the REST API or ``Session/uploadVideo(data:metadata:)`` will include this metadata if you specified it when uploading.
/// Videos attached in a reply to an email notification will not include any metadata.
public struct VideoBlock: FileBlock {
  /// The URL where you can fetch the file.
  public let url: String
  /// The size of the file in bytes.
  public let size: Int64
  /// The name of the video file, including file extension.
  public let filename: String
  /// An encoded identifier for this file. Use in ``SendFileBlock`` to send this video in another message.
  public let fileToken: String

  /// The width of the video in pixels, if known.
  public let width: Int?
  /// The height of the video in pixels, if known.
  public let height: Int?
  /// The duration of the video in seconds, if known.
  public let duration: Double?

  public init(
    url: String,
    size: Int64,
    filename: String,
    fileToken: String,
    width: Int? = nil,
    height: Int? = nil,
    duration: Double? = nil
  ) {
    self.url = url
    self.size = size
    self.filename = filename
    self.fileToken = fileToken

    self.width = width
    self.height = height
    self.duration = duration
  }

  init(_ videoBlock: TalkJSCore::VideoBlock) {
    self.init(
      url: videoBlock.url,
      size: videoBlock.size,
      filename: videoBlock.filename,
      fileToken: videoBlock.fileToken,
      width: videoBlock.width?.intValue,
      height: videoBlock.height?.intValue,
      duration: videoBlock.duration?.doubleValue
    )
  }
}

/// A FileBlock variant for an audio attachment, with additional audio-specific metadata.
///
/// You can identify this variant by checking `block is AudioBlock`.
///
/// The same file could be uploaded as either an audio block, or as a ``VoiceBlock``.
/// The same data will be available either way, but they will be rendered differently in the UI.
///
/// Includes metadata about the duration of the audio file in seconds, where available.
///
/// Audio files that you upload with the TalkJS UI will include the duration as long as the sender's browser can preview the file.
/// Audio files that you upload with the REST API or ``Session/uploadAudio(data:metadata:)`` will include the duration if you specified it when uploading.
/// Audio files attached in a reply to an email notification will not include the duration.
public struct AudioBlock: FileBlock {
  /// The URL where you can fetch the file
  public let url: String
  /// The size of the file in bytes
  public let size: Int64
  /// The name of the audio file, including file extension
  public let filename: String
  /// An encoded identifier for this file. Use in ``SendFileBlock`` to send this file in another message.
  public let fileToken: String

  /// The duration of the audio in seconds, if known
  public let duration: Double?

  public init(
    url: String,
    size: Int64,
    filename: String,
    fileToken: String,
    duration: Double? = nil
  ) {
    self.url = url
    self.size = size
    self.filename = filename
    self.fileToken = fileToken

    self.duration = duration
  }

  init(_ audioBlock: TalkJSCore::AudioBlock) {
    self.init(
      url: audioBlock.url,
      size: audioBlock.size,
      filename: audioBlock.filename,
      fileToken: audioBlock.fileToken,
      duration: audioBlock.duration?.doubleValue
    )
  }
}

/// A FileBlock variant for a voice recording attachment, with additional voice-recording-specific metadata.
///
/// You can identify this variant by checking `block is VoiceBlock`.
///
/// The same file could be uploaded as either a voice block, or as an ``AudioBlock``.
/// The same data will be available either way, but they will be rendered differently in the UI.
///
/// Includes metadata about the duration of the recording in seconds, where available.
///
/// Voice recordings done in the TalkJS UI will always include the duration.
/// Voice recording that you upload with the REST API or ``Session/uploadVoice(data:metadata:)`` will include this metadata if you specified it when uploading.
///
/// Voice recordings will never be taken from a reply to an email notification.
/// Any attached audio file will become an ``AudioBlock`` instead of a voice block.
public struct VoiceBlock: FileBlock {
  /// The URL where you can fetch the file
  public let url: String
  /// The size of the file in bytes
  public let size: Int64
  /// The name of the file, including file extension
  public let filename: String
  /// An encoded identifier for this file. Use in ``SendFileBlock`` to send this voice recording in another message.
  public let fileToken: String

  /// The duration of the voice recording in seconds, if known
  public let duration: Double?

  public init(
    url: String,
    size: Int64,
    filename: String,
    fileToken: String,
    duration: Double? = nil
  ) {
    self.url = url
    self.size = size
    self.filename = filename
    self.fileToken = fileToken

    self.duration = duration
  }

  init(_ videoBlock: TalkJSCore::VoiceBlock) {
    self.init(
      url: videoBlock.url,
      size: videoBlock.size,
      filename: videoBlock.filename,
      fileToken: videoBlock.fileToken,
      duration: videoBlock.duration?.doubleValue
    )
  }
}
