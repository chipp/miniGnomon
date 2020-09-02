//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import miniGnomon

// swiftlint:disable:next type_body_length
class CacheSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testSingleNoCachedValue() throws {
        let client = HTTPClient { _, _, _ in TestResponses.noCacheResponse() }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = client.cachedModels(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        expect(try result.elements()).to(haveCount(0))
    }

    func testSingleCachedValueStored() throws {
        let response = try TestResponses.jsonResponse(result: ["key": 123], cached: true)
        let client = HTTPClient { _, _, _ in response }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = client.cachedModels(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache
    }

    func testMultipleNoCachedValue() throws {
        let client = HTTPClient { _, _, _ in TestResponses.noCacheResponse() }

        let requests = try (0 ... 2).map { _ -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com")
        }

        let result = client.cachedModels(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let elements = try result.elements()
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        for result in results {
            switch result {
            case .success: fail("request should fail")
            case let .failure(error):
                let error = error as NSError
                expect(error.domain) == NSURLErrorDomain
                expect(error.code) == NSURLErrorResourceUnavailable
            }
        }
    }

    func testMultipleCachedValueStored() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!

            if value != 234 {
                return try! TestResponses.jsonResponse(result: ["key": value], cached: true)
            } else {
                return TestResponses.noCacheResponse()
            }
        }

        let requests = try (0 ... 2).map { 123 + 111 * $0 }.map { value -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com/\(value)")
        }

        let result = client.cachedModels(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let elements = try result.elements()
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        do {
            let value = try results[0].get()

            expect(value.result.key) == 123
            expect(value.type) == .localCache
        }

        switch results[1] {
        case .success: fail("request should fail")
        case let .failure(error):
            let error = error as NSError
            expect(error.domain) == NSURLErrorDomain
            expect(error.code) == NSURLErrorResourceUnavailable
        }

        do {
            let value = try results[2].get()

            expect(value.result.key) == 345
            expect(value.type) == .localCache
        }
    }

}
