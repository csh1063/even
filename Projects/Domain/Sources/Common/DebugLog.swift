import Foundation

/// 디버그 빌드에서만 출력되는 로그. release 빌드에는 아예 포함되지 않는다.
public func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}
