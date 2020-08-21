//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class URLRequestGenerationSpec: XCTestCase {
    
    func testValidURL() {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.url) == URL(string: "https://example.com")!
        } catch {
            fail("\(error)")
        }
    }
    
    func testInvalidURL() {
        do {
            _ = try Request<String>(URLString: "ß")
            fail("should fail")
        } catch let error as InvalidURLStringError {
            expect(error.URLString) == "ß"
        } catch {
            fail("\(error)")
        }
    }
    
    func testMethods() {
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.GET)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "GET"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.HEAD)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "HEAD"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.POST)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "POST"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.PUT)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "PUT"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.PATCH)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "PATCH"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.DELETE)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "DELETE"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: true))
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "KEK"
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: false))
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpMethod) == "KEK"
        } catch {
            fail("\(error)")
        }
    }
    
    func testHeaders() {
        do {
            let request = try Request<String>(URLString: "https://example.com").setHeaders(["MySuperTestHeader": "kek"])
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.allHTTPHeaderFields) == ["MySuperTestHeader": "kek"]
        } catch {
            fail("\(error)")
        }
    }
    
    func testDisableLocalCache() {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let policy = cachePolicy(for: request, localCache: true)
            expect(policy) == .returnCacheDataDontLoad
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
            let policy = cachePolicy(for: request, localCache: true)
            expect(policy) == .returnCacheDataDontLoad
        } catch {
            fail("\(error)")
        }
    }
    
    func testDisableHttpCache() {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .useProtocolCachePolicy
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableLocalCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .useProtocolCachePolicy
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .reloadIgnoringLocalCacheData
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setDisableCache(true)
            let policy = cachePolicy(for: request, localCache: false)
            expect(policy) == .reloadIgnoringLocalCacheData
        } catch {
            fail("\(error)")
        }
    }
    
    func testShouldHandleCookies() {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(false)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(true)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.httpShouldHandleCookies).to(beTruthy())
        } catch {
            fail("\(error)")
        }
    }
    
    func testTimeout() {
        do {
            let request = try Request<String>(URLString: "https://example.com")
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.timeoutInterval) == 60
        } catch {
            fail("\(error)")
        }
        
        do {
            let request = try Request<String>(URLString: "https://example.com").setTimeout(5)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
            
            expect(urlRequest.timeoutInterval) == 5
        } catch {
            fail("\(error)")
        }
    }
    
}
