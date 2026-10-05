internal import TalkJSCore

/// References a specific emoji reaction on a message.
///
/// Used in all Data API operations affecting that emoji reaction, such as adding or removing the reaction.
/// Created via ``MessageRef/reaction(emoji:)``.
// @unchecked: the compiler can't look inside Kotlin.
// Sharing the value is only dangerous if someone mutates it, and this struct
// only has immutable data.
public struct ReactionRef: @unchecked Sendable {
  /// Which emoji the reaction is using.
  ///
  /// Either a single Unicode emoji, or the name of a custom emoji with a colon at the start and end.
  /// This is not validated until you send a request to the server.
  /// Since custom emoji are configured in the frontend, there are no checks to make sure a custom emoji actually exists.
  ///
  /// Immutable: if you want to use a different emoji, get a new ReactionRef instead.
  ///
  /// Unicode emoji
  /// "👍"
  ///
  /// Custom emoji
  /// ":cat-roomba:"
  public let emoji: String
  /// The ID of the message that this is a reaction to.
  ///
  /// Immutable: if you want to react to a different message, get a new ReactionRef instead.
  public let messageId: String
  /// The ID of the conversation the message belongs to.
  ///
  /// Immutable: if you want to reference a message from a different conversation, get a new MessageRef from that conversation and call `.reaction` on that MessageRef.
  public let conversationId: String

  private let _reactionRef: TalkJSCore::ReactionRef

  init(_ reactionRef: TalkJSCore::ReactionRef) {
    _reactionRef = reactionRef
    emoji = reactionRef.emoji
    messageId = reactionRef.messageId
    conversationId = reactionRef.conversationId
  }

  /// Adds this emoji reaction onto the message, from the current user.
  ///
  /// The function will throw if the request is invalid, the message doesn't exist, there are already 50 different reactions on this message, or if you do not have permission to use emoji reactions on that message.
  public func add() async {
    try! await _reactionRef.add()
  }

  /// Removes this emoji reaction from the message, from the current user.
  ///
  /// The function will throw if the request is invalid, the message doesn't exist, or you do not have permission to use emoji reactions on that message.
  public func remove() async {
    try! await _reactionRef.remove()
  }
}

/// A summary of a single emoji reaction on a message.
public struct ReactionSnapshot: Equatable, Sendable {
  /// Which emoji the users reacted with.
  ///
  /// Either a single Unicode emoji, or the name of a custom emoji with a colon at the start and end.
  /// Since custom emoji are defined in the frontend, they are not validated by the TalkJS server.
  /// The UI should ignore reactions that use unrecognised custom emoji.
  ///
  /// NOTE: In unicode, it is possible to have multiple emoji that look identical but are represented differently.
  /// For example, `"👍" != "👍️"` because the second emoji includes a [variation selector 16 codepoint](https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)).
  /// This codepoint forces the character to appear as an emoji.
  ///
  /// TalkJS normalises all emoji reactions to be "fully qualified" [according to this list](https://unicode.org/Public/emoji/16.0/emoji-test.txt).
  /// This prevents a message having multiple separate 👍 reactions.
  ///
  /// Be careful when processing the `emoji` property, as this normalisation might break equality checks:
  ///
  /// ```swift
  /// // Emoji has unnecessary variation selector 16
  /// let sent = "👍"
  ///
  /// // React with thumbs up,
  /// await message.reaction(emoji: emoji).add()
  ///
  /// // Fetch the reaction
  /// let snapshot = await message.get()
  /// let received = snapshot!.reactions[0].emoji
  ///
  /// // Fails because TalkJS removed the variation selector
  /// assert(sent == received)
  /// ```
  ///
  /// Unicode emoji
  /// "👍"
  ///
  /// Custom emoji
  /// ":cat-roomba:"
  public let emoji: String
  /// The number of times this emoji has been added to the message.
  public let count: Int
  /// Whether the current user has reacted to the message with this emoji.
  public let currentUserReacted: Bool
}

extension Array where Element == TalkJSCore::ReactionSnapshot {
  func fromKotlin() -> [ReactionSnapshot] {
    self.map {
      ReactionSnapshot(
        emoji: $0.emoji,
        count: Int($0.count),
        currentUserReacted: $0.currentUserReacted
      )
    }
  }
}
