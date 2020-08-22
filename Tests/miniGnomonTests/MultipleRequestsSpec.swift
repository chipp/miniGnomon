//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import miniGnomon

// swiftlint:disable type_body_length

class MultipleRequestsSpec: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Nimble.AsyncDefaults.Timeout = 7
        URLCache.shared.removeAllCachedResponses()
    }
    
    func testMultiple() {
        do {
            let requests = try [0, 1].map { value -> Request<TestModel1> in
                let request = try Request<TestModel1>(URLString: "https://example.com")
                request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                                   cached: false)
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(2))
                
                switch results[0] {
                case let .success(response):
                    expect(response.result.key) == 123
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case let .success(response):
                    expect(response.result.key) == 234
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testMultipleOneFail() {
        do {
            let requests = try [0, 1].map { value -> Request<TestModel1> in
                let request = try Request<TestModel1>(URLString: "https://example.com")
                if value == 1 {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                                       cached: false)
                } else {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["_key": 123 + 111 * value],
                                                                                       cached: false)
                }
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(2))
                
                switch results[0] {
                case .success: fail("request should fail")
                case let .failure(DecodingError.keyNotFound(key, _)):
                    expect(key.stringValue) == "key"
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case let .success(response):
                    expect(response.result.key) == 234
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testMultipleOptional() {
        do {
            let requests = try [0, 1].map { value -> Request<TestModel1?> in
                let request = try Request<TestModel1?>(URLString: "https://example.com")
                request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                                   cached: false)
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(2))
                
                switch results[0] {
                case let .success(response):
                    expect(response.result?.key) == 123
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case let .success(response):
                    expect(response.result?.key) == 234
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testMultipleOptionalOneFail() {
        do {
            let requests = try [0, 1].map { value -> Request<TestModel1?> in
                let request = try Request<TestModel1?>(URLString: "https://example.com")
                if value == 1 {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                                       cached: false)
                } else {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["_key": 123 + 111 * value],
                                                                                       cached: false)
                }
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(2))
                
                switch results[0] {
                case let .success(response):
                    expect(response.result).to(beNil())
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case let .success(response):
                    expect(response.result?.key) == 234
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testMultipleOrder() {
        do {
            let requests = try [0, 1, 2].map { value -> Request<TestModel1> in
                let request = try Request<TestModel1>(URLString: "https://example.com")
                request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(
                    result: ["key": 123 + 111 * value], cached: false,
                    delay: .milliseconds(40 + value * 10)
                )
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: 1).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(3))
                
                switch results[0] {
                case let .success(response):
                    expect(response.result.key) == 123
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case let .success(response):
                    expect(response.result.key) == 234
                case let .failure(error): fail("\(error)")
                }
                
                switch results[2] {
                case let .success(response):
                    expect(response.result.key) == 345
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testMultipleOrderOneFail() {
        do {
            let requests = try [0, 1, 2].map { value -> Request<TestModel1> in
                let request = try Request<TestModel1>(URLString: "https://example.com")
                if value == 1 {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(
                        result: ["invalid": "key"],
                        statusCode: 404, cached: false,
                        delay: .milliseconds(40 + value * 10)
                    )
                } else {
                    request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(
                        result: ["key": 123 + 111 * value], cached: false,
                        delay: .milliseconds(40 + value * 10)
                    )
                }
                return request
            }
            
            let result = HTTPClient.models(for: requests).toBlocking(timeout: 1).materialize()
            
            switch result {
            case let .completed(elements):
                expect(elements).to(haveCount(1))
                
                let results = elements[0]
                expect(results).to(haveCount(3))
                
                switch results[0] {
                case let .success(response):
                    expect(response.result.key) == 123
                case let .failure(error): fail("\(error)")
                }
                
                switch results[1] {
                case .success: fail("request should fail")
                case let .failure(HTTPClient.Error.errorStatusCode(code, _)): expect(code) == 404
                case let .failure(error): fail("\(error)")
                }
                
                switch results[2] {
                case let .success(response):
                    expect(response.result.key) == 345
                case let .failure(error): fail("\(error)")
                }
            case let .failed(_, error):
                fail("\(error)")
            }
        } catch {
            switch error {
            case HTTPClient.Error.errorStatusCode(let code, let data):
                expect(code).to(equal(404))
                expect(data).toNot(beNil())
            default: fail("should't fail with other type of error")
            }
            return
        }
    }
    
    func testMultipleEmptyArray() {
        do {
            let requests = [Request<TestModel1>]()
            let optionalRequests = [Request<TestModel1?>]()
            
            expect(try HTTPClient.cachedModels(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(
                haveCount(0))
            expect(try HTTPClient.models(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))
            expect(try HTTPClient.models(for: requests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))
            
            let cachedThenFetch = try HTTPClient.cachedThenFetch(optionalRequests).toBlocking(timeout: BlockingTimeout).toArray()
            expect(cachedThenFetch).to(haveCount(1))
            expect(cachedThenFetch[0]).to(haveCount(0))
        } catch {
            fail("\(error)")
            return
        }
    }
    
}
