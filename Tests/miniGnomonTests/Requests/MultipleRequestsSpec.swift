//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import Combine
import BlockingSubscriber

@testable import miniGnomon

// swiftlint:disable type_body_length

class MultipleRequestsSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testMultiple() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            return try! TestResponses.jsonResponse(result: ["key": value], cached: false)
        }

        let requests = try [0, 1].map { value -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com/\(123 + 111 * value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(2))

        expect(try results[0].get().result.key) == 123
        expect(try results[1].get().result.key) == 234
    }

    func testMultipleOneFail() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            if value == 234 {
                return try! TestResponses.jsonResponse(result: ["key": value], cached: false)
            } else {
                return try! TestResponses.jsonResponse(result: ["_key": value], cached: false)
            }
        }

        let requests = try [0, 1].map { value -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com/\(123 + 111 * value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case .success: fail("request should fail")
        case let .failure(DecodingError.keyNotFound(key, _)):
            expect(key.stringValue) == "key"
        case let .failure(error): fail("\(error)")
        }

        expect(try results[1].get().result.key) == 234
    }

    func testMultipleOptional() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            return try! TestResponses.jsonResponse(result: ["key": value], cached: false)
        }

        let requests = try [0, 1].map { value -> Request<TestModel?> in
            try Request<TestModel?>(URLString: "https://example.com/\(123 + 111 * value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(2))

        expect(try results[0].get().result?.key) == 123
        expect(try results[1].get().result?.key) == 234
    }

    func testMultipleOptionalOneFail() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            if value == 234 {
                return try! TestResponses.jsonResponse(result: ["key": value], cached: false)
            } else {
                return try! TestResponses.jsonResponse(result: ["_key": value], cached: false)
            }
        }

        let requests = try [0, 1].map { value -> Request<TestModel?> in
            try Request<TestModel?>(URLString: "https://example.com/\(123 + 111 * value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case let .success(response):
            expect(response.result).to(beNil())
        case let .failure(error): fail("\(error)")
        }

        expect(try results[1].get().result?.key) == 234
    }

    func testMultipleOrder() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            return try! TestResponses.jsonResponse(
                result: ["key": 123 + 111 * value], cached: false,
                delay: .milliseconds(40 + value * 10)
            )
        }

        let requests = try [0, 1, 2].map { value -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com/\(value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: 1).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(3))

        expect(try results[0].get().result.key) == 123
        expect(try results[1].get().result.key) == 234
        expect(try results[2].get().result.key) == 345
    }

    func testMultipleOrderOneFail() throws {
        let client = HTTPClient { request, _, _ in
            let value = Int(request.url!.path.dropFirst())!
            if value == 1 {
                return try! TestResponses.jsonResponse(
                    result: ["invalid": "key"],
                    statusCode: 404, cached: false,
                    delay: .milliseconds(40 + value * 10)
                )
            } else {
                return try! TestResponses.jsonResponse(
                    result: ["key": 123 + 111 * value], cached: false,
                    delay: .milliseconds(40 + value * 10)
                )
            }
        }

        let requests = try [0, 1, 2].map { value -> Request<TestModel> in
            try Request<TestModel>(URLString: "https://example.com/\(value)")
        }

        let result = try client.models(for: requests).toBlocking(timeout: 1).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let results = responses[0]
        expect(results).to(haveCount(3))

        expect(try results[0].get().result.key) == 123

        switch results[1] {
        case .success: fail("request should fail")
        case let .failure(HTTPClientError.errorStatusCode(code, _)): expect(code) == 404
        case let .failure(error): throw error
        }

        expect(try results[2].get().result.key) == 345
    }

    func testMultipleEmptyArray() throws {
        let client = HTTPClient { _, _, _ in
            Empty().eraseToAnyPublisher()
        }

        let requests = [Request<TestModel>]()
        let optionalRequests = [Request<TestModel?>]()

        expect(try client.cachedModels(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))
        expect(try client.models(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))
        expect(try client.models(for: requests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))

        let cachedThenFetch = try client.cachedThenFetch(optionalRequests).toBlocking(timeout: BlockingTimeout).toArray()
        expect(cachedThenFetch).to(haveCount(1))
        expect(cachedThenFetch[0]).to(haveCount(0))
    }

}
