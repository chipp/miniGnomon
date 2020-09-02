//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class URLParamsEncodingSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }
    
    func testEmptyParams() throws {
        let request = try Request<String>(URLString: "https://example.com/post")
        expect(try prepareURL(with: request.url, params: nil).absoluteString) == "https://example.com/post"
    }
    
    func testSimpleDictionary() throws {
        let request = try Request<String>(URLString: "https://example.com/get")

        let params = ["key1": "value1", "key2": "value2"]
        let expected = "https://example.com/get?key1=value1&key2=value2"
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
    func testArray() throws {
        let request = try Request<String>(URLString: "https://example.com/get")

        let expected = "https://example.com/get?key1=value1&key2=value2&key3%5B%5D=1&key3%5B%5D=2&key3%5B%5D=3"
        let params: [String: Any] = ["key1": "value1", "key2": "value2", "key3": ["1", "2", "3"]]
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
    func testInnerDictionary() throws {
        let request = try Request<String>(URLString: "https://example.com/get")

        let params: [String: Any] = ["key1": "value1", "key2": "value2",
                                     "key3": ["inKey1": "inValue1", "inKey2": "inValue2"]]
        let expected = "https://example.com/get?key1=value1&key2=value2&key3%5BinKey1%5D=inValue1&" +
        "key3%5BinKey2%5D=inValue2"
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
    func testInnerDictionaryInArray() throws {
        let request = try Request<String>(URLString: "https://example.com/get")

        let params: [String: Any] = [
            "key1": "value1", "key2": "value2",
            "key3": [["inKey1": "inValue1", "inKey2": "inValue2"]]
        ]

        let expected = "https://example.com/get?key1=value1&key2=value2&key3%5B%5D%5BinKey1%5D=inValue1&key3%5B%5D%5BinKey2%5D=inValue2"
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
    func testNumbers() throws {
        let request = try Request<String>(URLString: "https://example.com/get")

        let params: [String: Any] = ["key1": 1, "key2": 2.30]
        let expected = "https://example.com/get?key1=1&key2=2.3"
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
    func testRequestWithParamsInURL() throws {
        let request = try Request<String>(URLString: "https://example.com/get?key3=value3").setMethod(.GET)

        let params = ["key1": "value1", "key2": "value2"]
        let expected = "https://example.com/get?key1=value1&key2=value2&key3=value3"
        expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    }
    
}
