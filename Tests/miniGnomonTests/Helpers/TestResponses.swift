//
// Created by Vladimir Burdukov on 06/07/2018.
//

import Foundation
import Combine
@testable import miniGnomon

enum TestResponses {
    private static let url = URL(string: "https://example.com/")!

    private static func response(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    static func jsonResponse(
        result: Any, statusCode: Int = 200, cached: Bool, delay: RunLoop.SchedulerTimeType.Stride? = nil
    ) throws -> AnyPublisher<DataAndResponse, Error> {
        let data = try JSONSerialization.data(withJSONObject: result)
        var response = self.response(statusCode: statusCode)

        if cached {
            response = response.httpCachedResponse!
        }

        if let delay = delay {
            return Just((data, response))
                .setFailureType(to: Error.self)
                .delay(for: delay, scheduler: RunLoop.current)
                .eraseToAnyPublisher()
        } else {
            return Just((data, response))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    static func stringResponse(
        result: String, statusCode: Int = 200, cached: Bool
    ) throws -> AnyPublisher<DataAndResponse, Error> {
        guard let data = result.data(using: .utf8) else {
            fatalError("can't create utf8 data from string \"\(result)\"")
        }

        var response = self.response(statusCode: statusCode)

        if cached {
            response = response.httpCachedResponse!
        }

        return Just((data, response))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    static func noCacheResponse() -> AnyPublisher<DataAndResponse, Error> {
        Fail(
            outputType: DataAndResponse.self,
            failure: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorResourceUnavailable
            )
        ).eraseToAnyPublisher()
    }
}
