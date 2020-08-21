//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class ParamsSpec: XCTestCase {
    
    let methods = [Method.GET, .HEAD, .POST, .PUT, .PATCH, .DELETE, .custom("KEK", hasBody: true),
                   .custom("KEK", hasBody: false)]
    
    let nonBodyMethods = [Method.GET, .HEAD, .custom("KEK", hasBody: false)]
    let bodyMethods = [Method.POST, .PUT, .PATCH, .DELETE, .custom("KEK", hasBody: true)]
    
    func testQueryParams() {
        for method in methods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.query(["key1": "value1", "key2": ["1", "2"]]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.url) == URL(string: "https://example.com?key1=value1&key2%5B%5D=1&key2%5B%5D=2")!
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testURLEncodedParams() {
        for method in bodyMethods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.urlEncoded(["key1": "value1", "key2": ["1", "2"]]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody) == "key1=value1&key2%5B%5D=1&key2%5B%5D=2".data(using: .utf8)!
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "application/x-www-form-urlencoded"
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testJSONParams() {
        for method in bodyMethods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.json(["key1": "value1", "key2": ["1", "2"]]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody).notTo(beNil())
                let json = urlRequest.httpBody.map({ try! JSONSerialization.jsonObject(with: $0) }) as! [String: Any]
                
                expect(json).to(haveCount(2))
                expect(json["key1"] as? String) == "value1"
                expect(json["key2"] as? [String]) == ["1", "2"]
                
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "application/json"
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testMultipartFormParams() throws {
        let form = ["question": "The Ultimate Question of Life, the Universe, and Everything", "answer": "42"]
        let expected = String(data: try Data(
            contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures")
                .appendingPathComponent("multipart-simple").appendingPathExtension("txt")
            ), encoding: .utf8)!
        
        for method in bodyMethods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.multipart(form, [:]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody).notTo(beNil())
                
                let sent = String(data: urlRequest.httpBody!, encoding: .utf8)!
                expect(sent) == expected
                
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "multipart/form-data; boundary=__X_GNOMON_BOUNDARY__"
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testMultipartFilesParams() throws {
        let data = try Data(
            contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures")
                .appendingPathComponent("lorem-ipsum").appendingPathExtension("txt")
        )
        let file = MultipartFile(data: data, contentType: "text/plain", filename: "lorem-ipsum.txt")

        let expected = String(data: try Data(
            contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures")
                .appendingPathComponent("multipart-file").appendingPathExtension("txt")
            ), encoding: .utf8)!
        
        for method in bodyMethods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.multipart([:], ["upload": file]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody).notTo(beNil())
                
                let sent = String(data: urlRequest.httpBody!, encoding: .utf8)!

                
                expect(sent) == expected
                
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "multipart/form-data; boundary=__X_GNOMON_BOUNDARY__"
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testMultipartMixedParams() throws {
        let form = ["question": "The Ultimate Question of Life, the Universe, and Everything"]
        let data = try Data(
            contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures")
                .appendingPathComponent("lorem-ipsum").appendingPathExtension("txt")
        )
        let file = MultipartFile(data: data, contentType: "text/plain", filename: "lorem-ipsum.txt")

        let expected = String(data: try Data(
            contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures")
                .appendingPathComponent("multipart-mixed").appendingPathExtension("txt")
            ), encoding: .utf8)!
        
        for method in bodyMethods {
            do {
                
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.multipart(form, ["upload": file]))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody).notTo(beNil())
                
                let sent = String(data: urlRequest.httpBody!, encoding: .utf8)!

                expect(sent) == expected
                
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "multipart/form-data; boundary=__X_GNOMON_BOUNDARY__"
            } catch {
                fail("\(error)")
            }
        }
    }
    
    func testCustomDataParams() {
        let data = "custom data".data(using: .utf8)!
        
        for method in bodyMethods {
            do {
                let request = try Request<String>(URLString: "https://example.com").setMethod(method)
                    .setParams(.data(data, contentType: "application/octet-stream"))
                let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy)
                
                expect(urlRequest.httpBody).notTo(beNil())
                
                let sent = String(data: urlRequest.httpBody!, encoding: .utf8)!
                expect(sent) == "custom data"
                
                expect(urlRequest.allHTTPHeaderFields!["Content-Type"]) == "application/octet-stream"
            } catch {
                fail("\(error)")
            }
        }
    }
    
}
