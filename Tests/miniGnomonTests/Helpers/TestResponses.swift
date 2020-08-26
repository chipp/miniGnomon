//
// Created by Vladimir Burdukov on 06/07/2018.
//

import Foundation
import RxSwift
@testable import miniGnomon

enum TestResponses {
    private static let url = URL(string: "https://example.com/")!
    
    private static func response(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
    
    static func jsonResponse(
        result: Any, statusCode: Int = 200, cached: Bool, delay: DispatchTimeInterval = .seconds(0)
    ) throws -> Observable<(Data, HTTPURLResponse)> {
        let data = try JSONSerialization.data(withJSONObject: result)
        var response = self.response(statusCode: statusCode)
        
        if cached {
            response = response.httpCachedResponse!
        }
        
        return Observable.just((data, response))
            .delay(delay, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
    }
    
    static func stringResponse(
        result: String, statusCode: Int = 200, cached: Bool
    ) throws -> Observable<(Data, HTTPURLResponse)> {
        guard let data = result.data(using: .utf8) else {
            fatalError("can't create utf8 data from string \"\(result)\"")
        }

        var response = self.response(statusCode: statusCode)
        
        if cached {
            response = response.httpCachedResponse!
        }
        
        return Observable.just((data, response))
    }
    
    static func noCacheResponse() -> Observable<(Data, HTTPURLResponse)> {
        return Observable.error(NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable))
    }
}
