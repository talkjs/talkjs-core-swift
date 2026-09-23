import Foundation
internal import TalkJSCore

extension Array where Element == Int8 {
  func toKotlinByteArray() -> KotlinByteArray {
    let result = KotlinByteArray.init(size: Int32(self.count))
    for (index, value) in self.enumerated() {
      result.set(index: Int32(index), value: value)
    }

    return result
  }
}

extension Array where Element == String {
  func toKotlinArray() -> KotlinArray<NSString> {
    KotlinArray(size: Int32(self.count)) { index in
      self[index.intValue] as NSString
    }
  }
}

extension Double {
  func toKotlinDouble() -> KotlinDouble {
    KotlinDouble(value: self)
  }
}

extension Int {
  func toKotlinInt() -> KotlinInt {
    KotlinInt(value: Int32(self))
  }
}

extension Dictionary where Key == String, Value == Bool {
  func toKotlin() -> [String : KotlinBoolean] {
    self.mapValues{ KotlinBoolean(value: $0) }
  }
}

extension Dictionary where Key == String, Value == Bool? {
  func toKotlin() -> [String: KotlinBoolean?] {
    self.mapValues {
      $0 != nil ? KotlinBoolean(value: $0!) : nil
    }
  }
}
