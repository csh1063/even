import Foundation

// 문자열 기능 확장
extension String {

    // 종성 받침 여부
    var josa: Bool? {
        guard Locale.current.language.languageCode?.identifier == "ko" else { return nil}
        guard let text = self.last else { return false }
        let val = UnicodeScalar(String(text))?.value
        guard let value = val, value > 0xac00 else { return false }
        let code = value - 0xac00
        guard code < 11172 else { return false }
        if (code) % 28 == 0 {
            return false
        }
        return true
    }

    // 한글 검색시 사용 가능
    var hangul: String {
        let hangle = [
            ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"],
            ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ",
             "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"],
            ["", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ",
             "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        ]

        return reduce("") { result, char in
            var code = 0
            for scalar in String(char).unicodeScalars {
                code += Int(scalar.value)
            }
            code -= 44032
            if code > -1 && code < 11172 {
                let cho = code / 21 / 28, jung = code % (21 * 28) / 28, jong = code % 28
                return result + hangle[0][cho] + hangle[1][jung] + hangle[2][jong]
            }
            return result + String(char)
        }
    }

    var htmlString: String {
        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\"/>"
            + "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">"
            + "<title>Page Title</title>"
            + "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, user-scalable=no\">"
            + "</head><body>"
            + "<style type=\"text/css\"> "
            + "body {margin: 0} img{width: 100%}"
            + "@font-face {"
            + "font-family: 'Noto Sans KR';"
            + "src: url('NotoSans-DemiLight.ttf');"
            + "}"
            + "@font-face {"
            + "font-family: 'Noto Sans KR';"
            + "src: url('NotoSans-Bold.ttf');"
            + "font-weight: bold;"
            + "font-style: normal;"
            + "}"
            + "</style><div class=\"fw_content\">"
            + self
            + "</div><script type=\"text/javascript\">"
            + "Array.from(document.querySelectorAll('.fw_content img:not(.disabled)'))"
            + ".forEach(function(item, count, array) {"
            + "item.addEventListener('click', function(){"
            + "if(typeof webkit === 'undefined'){"
            + "}else if(/iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream){"
            + "var selectedIndex = 0;"
            + "let urlList = array.map(function(x,i){if(x.src==item.src) {selectedIndex = i};return x.src;});"
            + "urlList.splice(0,0, selectedIndex.toString());"
            + "webkit.messageHandlers.expandImagesHandler.postMessage(urlList);}})});"
            + "Array.from(document.querySelectorAll('.fw_content a')).forEach(function(item, count, array) {"
            + "item.addEventListener('click', function(e){"
            + "if(typeof webkit === 'undefined'){"
            + "}else if(/iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream){"
            + "e.preventDefault();"
            + "webkit.messageHandlers.openBodyLink.postMessage(item.href);}})});"
            + "</script>"
            + "</body></html>"
    }

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main,
                                 value: "", comment: "")
    }

    var encodeEmoji: String {
        if let cString = self.cString(using: .nonLossyASCII) {
            if let encodeStr = NSString(cString: cString, encoding: String.Encoding.utf8.rawValue) {
                return encodeStr as String
            }
        }
        return self
    }

    var decodeEmoji: String {
        if let data = self.data(using: String.Encoding.utf8) {
            let decodedStr = NSString(data: data, encoding: String.Encoding.nonLossyASCII.rawValue)
            if let str = decodedStr {
                return str as String
            }
        }
        return self
    }

    // 문자열에서 int 번째 문자 확인
    subscript (int: Int) -> Character {
        return self[index(startIndex, offsetBy: int)]
    }

    // 문자열에서 int 번째 문자 확인
    subscript (int: Int) -> String {
        return String(self[int])
    }

    // range 만큼 substring
    subscript (range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[Range(uncheckedBounds: (start, end))])
    }

    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func wholeRange() -> Range<String.Index> {
        return Range(uncheckedBounds: (self.startIndex, self.endIndex))
    }

    func wholeNSRange() -> NSRange {
        return NSRange(location: 0, length: (self as NSString).length)
    }
}
