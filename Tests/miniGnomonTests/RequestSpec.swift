//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class RequestSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testSingleRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: ["key": 123], cached: false)
        }

        let request = try Request<TestModel>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result.key) == 123
    }

    func testSingleOptionalSuccessfulRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: ["key": 123], cached: false)
        }

        let request = try Request<TestModel?>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result?.key) == 123
    }

    func testSingleOptionalFailedRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: ["invalid": 123], cached: false)
        }

        let request = try Request<TestModel?>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result).to(beNil())
    }

    func testArrayRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                ["key": 123],
                ["key": 234],
                ["key": 345]
            ], cached: false)
        }

        let request = try Request<[TestModel]>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0].key).to(equal(123))
        expect(response.result[1].key).to(equal(234))
        expect(response.result[2].key).to(equal(345))
    }

    func testOptionalArraySuccessfulRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                ["key": 123],
                ["key": 234],
                ["key": 345]
            ], cached: false)
        }

        let request = try Request<[TestModel]?>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result?[0].key).to(equal(123))
        expect(response.result?[1].key).to(equal(234))
        expect(response.result?[2].key).to(equal(345))
    }

    func testOptionalArrayFailedRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: ["invalid": "type"], cached: false)
        }

        let request = try Request<[TestModel]?>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.result).to(beNil())
    }

    func testArrayOfOptionalsSuccessfulRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                ["key": 123],
                ["key": 234],
                ["key": 345]
            ], cached: false)
        }

        let request = try Request<[TestModel?]>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0]?.key).to(equal(123))
        expect(response.result[1]?.key).to(equal(234))
        expect(response.result[2]?.key).to(equal(345))
    }

    func testArrayOfOptionalsFailedRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                ["key": 123],
                ["_key": 234],
                ["key": 345]
            ], cached: false)
        }

        let request = try Request<[TestModel?]>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0]?.key).to(equal(123))
        expect(response.result[1]).to(beNil())
        expect(response.result[2]?.key).to(equal(345))
    }

    func testStringRequest() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.stringResponse(result: "test string", cached: false)
        }

        let request = try Request<String>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.result) == "test string"
    }

    func testErrorStatusCode() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.stringResponse(result: "error string", statusCode: 401, cached: false)
        }

        let request = try Request<String>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        switch result {
        case .completed:
            fail("request should fail")
        case let .failed(_, HTTPClientError.errorStatusCode(401, data)):
            expect(String(data: data, encoding: .utf8)) == "error string"
        case let .failed(_, error):
            throw error
        }
    }

}
