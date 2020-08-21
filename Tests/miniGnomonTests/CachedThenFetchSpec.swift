//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import miniGnomon

class CacheAndFetchSpec: XCTestCase {
    
    func testNoCachedValue() {
        do {
            let request = try Request<TestModel1>(URLString: "https://example.com/")
            request.cacheSessionDelegate = TestSessionDelegate.noCacheResponse()
            request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)
            
            let result = HTTPClient.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(responses):
                expect(responses).to(haveCount(1))
                
                expect(responses[0].result.key) == 123
                expect(responses[0].type) == .regular
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testCachedValueStored() {
        do {
            let request = try Request<TestModel1>(URLString: "https://example.com/")
            request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)
            request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)
            
            let result = HTTPClient.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(responses):
                expect(responses).to(haveCount(2))
                
                expect(responses[0].result.key) == 123
                expect(responses[0].type) == .localCache
                
                expect(responses[1].result.key) == 123
                expect(responses[1].type) == .httpCache
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testOutdatedCachedValueStored() {
        do {
            let request = try Request<TestModel1>(URLString: "https://example.com/")
            request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)
            request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)
            
            let result = HTTPClient.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(responses):
                expect(responses).to(haveCount(2))
                
                expect(responses[0].result.key) == 123
                expect(responses[0].type) == .localCache
                
                expect(responses[1].result.key) == 123
                expect(responses[1].type) == .regular
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
}
