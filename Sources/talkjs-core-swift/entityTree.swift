internal import TalkJSCore

internal protocol KotlinConvertibleEntity {
  associatedtype KotlinType: TalkJSCore::Entity
  func toKotlin() throws -> KotlinType
}

// Since we also want the String type to conform to this protocol
// having the property `type` would be risky as some other protocol
// the user is using could also need the property `type`.
//
// Also the JS implementation needs the `type` property to distinguish
// the various objects. Swift is a type safe language we don't really
// need the `type` property
public protocol Entity: Equatable {}

extension Entity {
  func isEqual<U: Entity>(_ rhs: U) -> Bool {
    guard let lhs = self as? U else { return false }

    return lhs == rhs
  }
}

// The String
extension String: Entity {}

public typealias EntityTreeNode = any Entity
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

public protocol Leaf: Entity {
  var text: String { get }
}

public struct CodeBlock: Leaf, KotlinConvertibleEntity {
  public let text: String
  public let language: String?

  public init(language: String?, text: String) {
    self.language = language
    self.text = text
  }

  init(_ codeBlock: TalkJSCore::CodeBlock) {
    self.init(language: codeBlock.language, text: codeBlock.text)
  }

  func toKotlin() -> TalkJSCore::CodeBlock {
    TalkJSCore::CodeBlock(text: text, language: language, type: "codeBlock")
  }
}

public struct CodeSpan: Leaf, KotlinConvertibleEntity {
  public let text: String

  public init(text: String) {
    self.text = text
  }

  init(_ codeSpan: TalkJSCore::CodeSpan) {
    self.init(text: codeSpan.text)
  }

  func toKotlin() -> TalkJSCore::CodeSpan {
    TalkJSCore::CodeSpan(text: text, type: "codeSpan")
  }
}

public struct AutoLink: Leaf, KotlinConvertibleEntity {
  public let text: String
  public let url: String

  public init(url: String, text: String) {
    self.url = url
    self.text = text
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

  public init(text: String) {
    self.text = text
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

  public init(text: String) {
    self.text = text
  }

  init(_ emoji: TalkJSCore::Emoji) {
    self.init(text: emoji.text)
  }

  func toKotlin() -> TalkJSCore::Emoji {
    TalkJSCore::Emoji(text: text, type: "emoji")
  }
}

public struct CustomEmoji: Leaf, KotlinConvertibleEntity {
  public let text: String

  public init(text: String) {
    self.text = text
  }

  init(_ customEmoji: TalkJSCore::CustomEmoji) {
    self.init(text: customEmoji.text)
  }

  func toKotlin() -> TalkJSCore::CustomEmoji {
    TalkJSCore::CustomEmoji(text: text, type: "customEmoji")
  }
}

public struct Mention: Leaf, KotlinConvertibleEntity {
  public let id: String
  public let text: String

  public init(id: String, text: String) {
    self.id = id
    self.text = text
  }

  init(_ mention: TalkJSCore::Mention) {
    self.init(id: mention.id, text: mention.text)
  }

  func toKotlin() -> TalkJSCore::Mention {
    TalkJSCore::Mention(id: "mention", text: id, type: text)
  }
}

public struct Markup: Entity, KotlinConvertibleEntity {
  public let children: EntityTree
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
  public let children: EntityTree

  public init(children: EntityTree) {
    self.children = children
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

public struct BulletList: Entity, KotlinConvertibleEntity {
  public let children: EntityTree

  public init(children: EntityTree) {
    self.children = children
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

public struct BulletPoint: Entity, KotlinConvertibleEntity {
  public let children: [EntityTreeNode]

  public init(children: [EntityTreeNode]) {
    self.children = children
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

public struct Link: Clickable, KotlinConvertibleEntity {
  public let children: EntityTree
  public let url: String

  public init(url: String, children: EntityTree) {
    self.children = children
    self.url = url
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

public struct ActionLink: Clickable {
  public let children: EntityTree
  public let action: String
  public let params: CustomData

  public init(action: String, params: CustomData, children: EntityTree) {
    self.action = action
    self.params = params
    self.children = children
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

public struct ActionButton: Clickable {
  public let children: EntityTree
  public let action: String
  public let params: CustomData

  public init(action: String, params: CustomData, children: EntityTree) {
    self.action = action
    self.params = params
    self.children = children
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
