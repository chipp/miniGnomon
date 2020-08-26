//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class URLRequestGenerationSpec: XCTestCase {
    
    func testValidURL() throws {
        let request = try Request<String>(URLString: "https://example.com")
        let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)

        expect(urlRequest.url) == URL(string: "https://example.com")!
    }
    
    func testInvalidURL() throws {
        do {
            _ = try Request<String>(URLString: "ß")
            fail("should fail")
        } catch let error as InvalidURLStringError {
            expect(error.URLString) == "ß"
        }
    }
    
    func testMethods() throws {
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.GET)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)

            expect(urlRequest.httpMethod) == "GET"
        }

        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.HEAD)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)

            expect(urlRequest.httpMethod) == "HEAD"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.POST)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)

            expect(urlRequest.httpMethod) == "POST"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.PUT)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "PUT"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.PATCH)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "PATCH"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.DELETE)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "DELETE"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: true))
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "KEK"
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: false))
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "KEK"
        }
    }
    
    func testHeaders() throws {
        let request = try Request<String>(URLString: "https://example.com").setHeaders(["MySuperTestHeader": "kek"])
        let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)

        expect(urlRequest.allHTTPHeaderFields) == ["MySuperTestHeader": "kek"]
    }
    
    func testDisableLocalCache() throws {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let policy = cachePolicy(for: request, localCache: true)
            expect(policy) == .returnCacheDataDontLoad
        }

        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
            let policy = cachePolicy(for: request, localCache: true)
            expect(policy) == .returnCacheDataDontLoad
        }
    }
    
    func testDisableHttpCache() throws {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .useProtocolCachePolicy
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableLocalCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .useProtocolCachePolicy
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .reloadIgnoringLocalCacheData
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .reloadIgnoringLocalCacheData
        }
    }
    
    func testShouldHandleCookies() throws {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(false)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(true)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beTruthy())
        }
    }
    
    func testTimeout() throws {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.timeoutInterval) == 60
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setTimeout(5)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.timeoutInterval) == 5
        }
    }
    
}
