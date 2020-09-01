//
//  Created by Vladimir Burdukov on 8/30/20.
//

import XCTest
import Combine
import Nimble

@testable import miniGnomon

class PublisherAsResultTests: XCTestCase {
    struct TestError: Error, Equatable {}

    func testAsResultSuccess() throws {
        let result = try Just("test").setFailureType(to: TestError.self).asResult().toBlocking(timeout: 1).materialize()
        expect(try result.elements()) == [.success("test")]
    }

    func testAsResultFailure() throws {
        let result = try Fail(outputType: String.self, failure: TestError()).asResult().toBlocking(timeout: 1).materialize()
        expect(try result.elements()) == [.failure(TestError())]
    }

    func testAsResultSuccessAndFailure() throws {
        let result = try Just("test").setFailureType(to: TestError.self)
            .append(Fail(outputType: String.self, failure: TestError()))
            .asResult().toBlocking(timeout: 1).materialize()
        expect(try result.elements()) == [.success("test"), .failure(TestError())]
    }
}
