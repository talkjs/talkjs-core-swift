import Foundation
internal import TalkJSCore

internal protocol KotlinConvertibleEntity {
  associatedtype KotlinType: TalkJSCore::Entity
  func toKotlin() throws -> KotlinType
}

// Since we also want the String type to conform to this protocol
// having a public property `type` would be risky as some other protocol
// the user is using could also need the property `type`.
//
// The JSON representation has to match the JS/Kotlin one, which uses the
// `type` field to distinguish the various objects. So each struct stores
// it as a `private` property: it is encoded, but it never shows up in the
// public API.
public protocol Entity: Equatable, Sendable, Codable {}

extension Entity {
  func isEqual<U: Entity>(_ rhs: U) -> Bool {
    guard let lhs = self as? U else { return false }

    return lhs == rhs
  }
}

// The String
extension String: Entity {}

public typealias EntityTreeNode = any Entity
/// A multi-root tree, which describes a bunch of formatting and logical entities within a message.
public typealias EntityTree = [EntityTreeNode]

extension Array where Element == EntityTreeNode {
  internal func toKotlinEntityTree() throws -> [TalkJSCore::Entity] {
    try self.map {
      if let entity = $0 as? (any KotlinConvertibleEntity) {
        try entity.toKotlin()
      } else {
        throw TalkJSError("Unknown Entity: \(type(of: $0))")
      }
    }
  }

  func isEqual(_ other: EntityTree) -> Bool {
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

extension Array {
  func fromKotlinEntityTree() throws -> EntityTree {
    try self.map {
      switch $0 {
      case let entity as String: entity
      case let entity as TalkJSCore::AutoLink: AutoLink(entity)
      case let entity as TalkJSCore::CodeBlock: CodeBlock(entity)
      case let entity as TalkJSCore::CodeSpan: CodeSpan(entity)
      case let entity as TalkJSCore::CustomEmoji: CustomEmoji(entity)
      case let entity as TalkJSCore::Emoji: Emoji(entity)
      case let entity as TalkJSCore::Mention: Mention(entity)
      case let entity as TalkJSCore::Suppressed: Suppressed(entity)
      case let entity as TalkJSCore::Blockquote: try Blockquote(entity)
      case let entity as TalkJSCore::BulletList: try BulletList(entity)
      case let entity as TalkJSCore::BulletPoint: try BulletPoint(entity)
      case let entity as TalkJSCore::Markup: try Markup(entity)
      case let entity as TalkJSCore::ActionButton: try ActionButton(entity)
      case let entity as TalkJSCore::ActionLink: try ActionLink(entity)
      case let entity as TalkJSCore::Link: try Link(entity)
      default:
        throw TalkJSError("Unknown Entity: \(type(of: $0))")
      }
    }
  }
}

private enum EntityTypeKey: String, CodingKey {
  case type
}

private func decodeEntityNode(from decoder: Decoder) throws -> any Entity {
  if let text = try? decoder.singleValueContainer().decode(String.self) {
    return text
  }

  let typeContainer = try decoder.container(keyedBy: EntityTypeKey.self)
  let type = try typeContainer.decode(String.self, forKey: .type)

  switch type {
  case "bold", "italic", "strikethrough": return try Markup(from: decoder)
  case "blockquote": return try Blockquote(from: decoder)
  case "bulletlist", "bulletList": return try BulletList(from: decoder)
  case "bulletpoint", "bulletPoint": return try BulletPoint(from: decoder)
  case "link": return try Link(from: decoder)
  case "actionlink", "actionLink": return try ActionLink(from: decoder)
  case "actionbutton", "actionButton": return try ActionButton(from: decoder)
  case "mention": return try Mention(from: decoder)
  case "autolink", "autoLink": return try AutoLink(from: decoder)
  case "codeblock", "codeBlock": return try CodeBlock(from: decoder)
  case "codespan", "codeSpan": return try CodeSpan(from: decoder)
  case "suppressed": return try Suppressed(from: decoder)
  case "emoji": return try Emoji(from: decoder)
  case "customemoji", "customEmoji": return try CustomEmoji(from: decoder)
  default: throw TalkJSError("Failed to decode Entity")
  }
}

@propertyWrapper
public struct EntityTreeCoding: Equatable, Sendable, Codable {
  public var wrappedValue: EntityTree

  public init(wrappedValue: EntityTree) {
    self.wrappedValue = wrappedValue
  }

  public static func == (lhs: EntityTreeCoding, rhs: EntityTreeCoding) -> Bool {
    lhs.wrappedValue.isEqual(rhs.wrappedValue)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for node in wrappedValue {
      try node.encode(to: container.superEncoder())
    }
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var result: EntityTree = []
    while !container.isAtEnd {
      result.append(try decodeEntityNode(from: try container.superDecoder()))
    }
    wrappedValue = result
  }
}

public func encodeEntityTree(_ tree: EntityTree) throws -> Data {
  try JSONEncoder().encode(EntityTreeCoding(wrappedValue: tree))
}

public func decodeEntityTree(_ data: Data) throws -> EntityTree {
  try JSONDecoder().decode(EntityTreeCoding.self, from: data).wrappedValue
}

public protocol Leaf: Entity {
  var text: String { get }
}

public struct CodeBlock: Leaf, KotlinConvertibleEntity {
  public let text: String
  public let language: String?
  private let type: String

  public init(language: String?, text: String) {
    self.language = language
    self.text = text
    self.type = "codeBlock"
  }

  init(_ codeBlock: TalkJSCore::CodeBlock) {
    self.init(language: codeBlock.language, text: codeBlock.text)
  }

  func toKotlin() -> TalkJSCore::CodeBlock {
    TalkJSCore::CodeBlock(text: text, language: language, type: "codeBlock")
  }
}

/// A node in a ``TextBlock`` that renders `text` in an inline code span (HTML `<code>`).
///
/// Used when a user types ` ```text``` `.
public struct CodeSpan: Leaf, KotlinConvertibleEntity {
  public let text: String
  private let type: String

  public init(text: String) {
    self.text = text
    self.type = "codeSpan"
  }

  init(_ codeSpan: TalkJSCore::CodeSpan) {
    self.init(text: codeSpan.text)
  }

  func toKotlin() -> TalkJSCore::CodeSpan {
    TalkJSCore::CodeSpan(text: text, type: "codeSpan")
  }
}

/// A node in a ``TextBlock`` that renders `text` as a link (HTML `<a>`).
///
/// Used when user-typed text is turned into a link automatically.
///
/// Unlike ``Link``, users do have permission to send ``AutoLink`` by default, because the `text` and `url` properties must match.
/// Specifically:
///
/// - If `text` is an email, `url` must contain a `mailto:` link to the same email address
///
/// - If `text` is a phone number, `url` must contain a `tel:` link to the same phone number
///
/// - If `text` is a website, the domain name including subdomains must be the same in both `text` and `url`.
///   If `text` includes a protocol (such as `https`), path (/page), query string (?page=true), or url fragment (#title), they must be the same in `url`.
///   If `text` does not specify a protocol, `url` must use either `https` or `http`.
///
/// This means that the following AutoLink is valid:
///
/// ```swift
/// AutoLink(
///     url: "https://talkjs.com/docs/JavaScript_Data_API/Message_Content/#AutoLinkNode",
///     text: "talkjs.com",
/// )
/// ```
///
/// That link will appear as `talkjs.com` and link you to the specific section of the documentation that explains how ``AutoLink`` works.
///
/// These rules ensure that the user knows what link they are clicking, and prevents ``AutoLink`` being used for phishing.
/// If you try to send a message containing an ``AutoLink`` that breaks these rules, the request will be rejected.
public struct AutoLink: Leaf, KotlinConvertibleEntity {
  /// The text to display in the link.
  public let text: String
  /// The URL to open when a user clicks this node.
  public let url: String
  private let type: String

  public init(url: String, text: String) {
    self.url = url
    self.text = text
    self.type = "autoLink"
  }

  init(_ autoLink: TalkJSCore::AutoLink) {
    self.init(url: autoLink.url, text: autoLink.text)
  }

  func toKotlin() -> TalkJSCore::AutoLink {
    TalkJSCore::AutoLink(url: url, text: text, type: "autoLink")
  }
}

public struct Suppressed: Leaf, KotlinConvertibleEntity {
  public let text: String
  private let type: String

  public init(text: String) {
    self.text = text
    self.type = "suppressed"
  }

  init(_ suppressed: TalkJSCore::Suppressed) {
    self.init(text: suppressed.text)
  }

  func toKotlin() -> TalkJSCore::Suppressed {
    TalkJSCore::Suppressed(text: text, type: "suppressed")
  }
}

public struct Emoji: Leaf, KotlinConvertibleEntity {
  public let text: String
  private let type: String

  public init(text: String) {
    self.text = text
    self.type = "emoji"
  }

  init(_ emoji: TalkJSCore::Emoji) {
    self.init(text: emoji.text)
  }

  func toKotlin() -> TalkJSCore::Emoji {
    TalkJSCore::Emoji(text: text, type: "emoji")
  }
}

/// A node in a ``TextBlock`` that is used for [custom emoji](https://talkjs.com/docs/Features/Messages/Emojis/#custom-emojis).
public struct CustomEmoji: Leaf, KotlinConvertibleEntity {
  /// The name (including colons at the start and end) of the custom emoji to show.
  public let text: String
  private let type: String

  public init(text: String) {
    self.text = text
    self.type = "customEmoji"
  }

  init(_ customEmoji: TalkJSCore::CustomEmoji) {
    self.init(text: customEmoji.text)
  }

  func toKotlin() -> TalkJSCore::CustomEmoji {
    TalkJSCore::CustomEmoji(text: text, type: "customEmoji")
  }
}

/// A node in a ``TextBlock`` that is used when a user is [mentioned](https://talkjs.com/docs/Features/Messages/Mentions/).
///
/// Used when a user types `@name` and selects the user they want to mention.
public struct Mention: Leaf, KotlinConvertibleEntity {
  /// The ID of the user who is mentioned.
  public let id: String
  /// The name of the user who is mentioned.
  public let text: String
  private let type: String

  public init(id: String, text: String) {
    self.id = id
    self.text = text
    self.type = "mention"
  }

  init(_ mention: TalkJSCore::Mention) {
    self.init(id: mention.id, text: mention.text)
  }

  func toKotlin() -> TalkJSCore::Mention {
    TalkJSCore::Mention(id: id, text: text, type: "mention")
  }
}

/// A node in a ``TextBlock`` that renders its children with a specific style.
public struct Markup: Entity, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  /// The kind of formatting to apply when rendering the children
  ///
  /// - `type: "bold"` is used when users type `*text*` and is rendered with HTML `<strong>`
  ///
  /// - `type: "italic"` is used when users type `_text_` and is rendered with HTML `<em>`
  ///
  /// - `type: "strikethrough"` is used when users type `~text~` and is rendered with HTML `<s>`
  public let type: String

  public init(type: String, children: EntityTree) throws {
    self.children = children

    switch type {
    case "bold", "italic", "strikethrough":
      self.type = type
    default:
      throw TalkJSError(
        "Invalid Markup type given. Only values allowed are: \"bold\", \"italic\" and \"strikethrough\"."
      )
    }
  }

  init(_ markup: TalkJSCore::Markup) throws {
    try self.init(
      type: markup.type,
      children: try markup.children.fromKotlinEntityTree()
    )
  }

  func toKotlin() throws -> TalkJSCore::Markup {
    try TalkJSCore::Markup(type: type, children: children.toKotlinEntityTree())
  }

  public static func == (lhs: Markup, rhs: Markup) -> Bool {
    lhs.type == rhs.type && lhs.children.isEqual(rhs.children)
  }
}

public struct Blockquote: Entity, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  private let type: String

  public init(children: EntityTree) {
    self.children = children
    self.type = "blockquote"
  }

  init(_ blockquote: TalkJSCore::Blockquote) throws {
    self.init(children: try blockquote.children.fromKotlinEntityTree())
  }

  func toKotlin() throws -> TalkJSCore::Blockquote {
    TalkJSCore::Blockquote(
      children: try children.toKotlinEntityTree(),
      type: "blockquote"
    )
  }

  public static func == (lhs: Blockquote, rhs: Blockquote) -> Bool {
    lhs.children.isEqual(rhs.children)
  }
}

/// A node in a ``TextBlock`` that adds indentation for a bullet-point list around its children (HTML `<ul>`).
///
/// Used when users send a bullet-point list by starting lines of their message with `-` or `*`.
public struct BulletList: Entity, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  private let type: String

  public init(children: EntityTree) {
    self.children = children
    self.type = "bulletList"
  }

  init(_ bulletList: TalkJSCore::BulletList) throws {
    self.init(children: try bulletList.children.fromKotlinEntityTree())
  }

  func toKotlin() throws -> TalkJSCore::BulletList {
    TalkJSCore::BulletList(
      children: try children.toKotlinEntityTree(),
      type: "bulletList"
    )
  }

  public static func == (lhs: BulletList, rhs: BulletList) -> Bool {
    lhs.children.isEqual(rhs.children)
  }
}

/// A node in a ``TextBlock`` that renders its children with a bullet-point (HTML `<li>`).
///
/// Used when users start a line of their message with `-` or `*`.
public struct BulletPoint: Entity, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: [EntityTreeNode]
  private let type: String

  public init(children: [EntityTreeNode]) {
    self.children = children
    self.type = "bulletPoint"
  }

  init(_ bulletPoint: TalkJSCore::BulletPoint) throws {
    self.init(children: try bulletPoint.children.fromKotlinEntityTree())
  }

  func toKotlin() throws -> TalkJSCore::BulletPoint {
    TalkJSCore::BulletPoint(
      children: try children.toKotlinEntityTree(),
      type: "bulletPoint"
    )
  }

  public static func == (lhs: BulletPoint, rhs: BulletPoint) -> Bool {
    lhs.children.isEqual(rhs.children)
  }
}

public protocol Clickable: Entity {
  var children: EntityTree { get }
}

/// A node in a ``TextBlock`` that renders its children as a clickable link (HTML `<a>`).
///
/// By default, users do not have permission to send messages containing ``Link`` as it can be used to maliciously hide the true destination of a link.
public struct Link: Clickable, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  /// The URL to open when the node is clicked.
  public let url: String
  private let type: String

  public init(url: String, children: EntityTree) {
    self.children = children
    self.url = url
    self.type = "link"
  }

  init(_ link: TalkJSCore::Link) throws {
    self.init(
      url: link.url,
      children: try link.children.fromKotlinEntityTree()
    )
  }

  func toKotlin() throws -> TalkJSCore::Link {
    TalkJSCore::Link(
      url: url,
      children: try children.toKotlinEntityTree(),
      type: "link",
    )
  }

  public static func == (lhs: Link, rhs: Link) -> Bool {
    lhs.url == rhs.url && lhs.children.isEqual(rhs.children)
  }
}

public typealias CustomData = [String: String]

/// A node in a ``TextBlock`` that renders its children as a clickable [action link](https://talkjs.com/docs/Guides/JavaScript/Classic/Action_Buttons_Links/) which triggers a custom action.
///
/// By default, users do not have permission to send messages containing ``ActionLink`` as it can be used maliciously to trick others into invoking custom actions.
/// For example, a user could send an "accept offer" action link, but disguise it as a link to a website.
public struct ActionLink: Clickable, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  /// The name of the custom action to invoke when the link is clicked.
  public let action: String
  /// The parameters to pass to the custom action when the link is clicked.
  public let params: CustomData
  private let type: String

  public init(action: String, params: CustomData, children: EntityTree) {
    self.action = action
    self.params = params
    self.children = children
    self.type = "actionLink"
  }

  init(_ actionLink: TalkJSCore::ActionLink) throws {
    self.init(
      action: actionLink.action,
      params: actionLink.params,
      children: try actionLink.children.fromKotlinEntityTree()
    )
  }

  func toKotlin() throws -> TalkJSCore::ActionLink {
    TalkJSCore::ActionLink(
      action: action,
      params: params,
      children: try children.toKotlinEntityTree(),
      type: "actionLink",
    )
  }

  public static func == (lhs: ActionLink, rhs: ActionLink) -> Bool {
    lhs.action == rhs.action && lhs.params == rhs.params
      && lhs.children.isEqual(rhs.children)
  }
}

/// A node in a ``TextBlock`` that renders its children as a clickable [action button](https://talkjs.com/docs/Guides/JavaScript/Classic/Action_Buttons_Links/) which triggers a custom action.
///
/// By default, users do not have permission to send messages containing action buttons as they can be used maliciously to trick others into invoking custom actions.
/// For example, a user could send an "accept offer" action button, but disguise it as "view offer".
public struct ActionButton: Clickable, KotlinConvertibleEntity {
  @EntityTreeCoding public private(set) var children: EntityTree
  /// The name of the custom action to invoke when the button is clicked.
  public let action: String
  /// The parameters to pass to the custom action when the button is clicked.
  public let params: CustomData
  private let type: String

  public init(action: String, params: CustomData, children: EntityTree) {
    self.action = action
    self.params = params
    self.children = children
    self.type = "actionButton"
  }

  init(_ actionButton: TalkJSCore::ActionButton) throws {
    self.init(
      action: actionButton.action,
      params: actionButton.params,
      children: try actionButton.children.fromKotlinEntityTree()
    )
  }

  func toKotlin() throws -> TalkJSCore::ActionButton {
    TalkJSCore::ActionButton(
      action: action,
      params: params,
      children: try children.toKotlinEntityTree(),
      type: "actionButton",
    )
  }

  public static func == (lhs: ActionButton, rhs: ActionButton) -> Bool {
    lhs.action == rhs.action && lhs.params == rhs.params
      && lhs.children.isEqual(rhs.children)
  }
}
