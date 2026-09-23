internal import TalkJSCore

public struct ReactionRef {
  public let emoji: String
  public let messageId: String
  public let conversationId: String

  private let _reactionRef: TalkJSCore::ReactionRef

  init(_ reactionRef: TalkJSCore::ReactionRef) {
    _reactionRef = reactionRef
    emoji = reactionRef.emoji
    messageId = reactionRef.messageId
    conversationId = reactionRef.conversationId
  }

  public func add() async {
    try! await _reactionRef.add()
  }

  public func remove() async {
    try! await _reactionRef.remove()
  }
}

public struct ReactionSnapshot: Equatable {
  public let emoji: String
  public let count: Int
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
