//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import BlockingSubscriber

@testable import miniGnomon

class CacheAndFetchSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testNoCachedValue() throws {
        let client = HTTPClient { _, policy, _ in
            if case .returnCacheDataDontLoad = policy {
                return TestResponses.noCacheResponse()
            } else {
                return try! TestResponses.jsonResponse(result: ["key": 123], cached: false)
            }
        }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = try client.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .regular
    }

    func testCachedValueStored() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: ["key": 123], cached: true)
        }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = try client.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(2))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache

        expect(responses[1].result.key) == 123
        expect(responses[1].type) == .httpCache
    }

    func testOutdatedCachedValueStored() throws {
        let client = HTTPClient { _, policy, _ in
            if case .returnCacheDataDontLoad = policy {
                return try! TestResponses.jsonResponse(result: ["key": 123], cached: true)
            } else {
                return try! TestResponses.jsonResponse(result: ["key": 123], cached: false)
            }
        }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = try client.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(2))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache

        expect(responses[1].result.key) == 123
        expect(responses[1].type) == .regular
    }

}
