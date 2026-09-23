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

public protocol ContentBlock: Equatable {}

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

public protocol SendContentBlock: Equatable {}

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

public struct LocationBlock:
  ContentBlock, SendContentBlock, KotlinConvertibleSendBlock
{
  public let latitude: Double
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

public struct SendFileBlock: SendContentBlock, KotlinConvertibleSendBlock {
  public let fileToken: String

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

public struct GenericFileBlock: FileBlock {
  public let url: String
  public let size: Int64
  public let filename: String
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

public struct ImageBlock: FileBlock {
  public let url: String
  public let size: Int64
  public let filename: String
  public let fileToken: String

  public let width: Int?
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

public struct VideoBlock: FileBlock {
  public let url: String
  public let size: Int64
  public let filename: String
  public let fileToken: String

  public let width: Int?
  public let height: Int?
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

public struct AudioBlock: FileBlock {
  public let url: String
  public let size: Int64
  public let filename: String
  public let fileToken: String

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

public struct VoiceBlock: FileBlock {
  public let url: String
  public let size: Int64
  public let filename: String
  public let fileToken: String

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
