//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import RxBlocking

@testable import miniGnomon

class CertificateSpec: XCTestCase {
    
    func testInvalidCertificate() {
        do {
            let request = try Request<String>(URLString: "https://self-signed.badssl.com/")
            request.shouldRunTask = true
            request.authenticationChallenge = { challenge, completionHandler -> Void in
                completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            }
            
            guard let response = try HTTPClient.models(for: request).toBlocking().first() else {
                return fail("can't extract response")
            }
            
            expect(response.result.count).to(beGreaterThan(0))
        } catch {
            fail("\(error)")
            return
        }
    }
    
    func testInvalidCertificateWithoutHandler() {
        do {
            let request = try Request<String>(URLString: "https://self-signed.badssl.com/")
            request.shouldRunTask = true
            
            let result = HTTPClient.models(for: request).toBlocking().materialize()
            
            switch result {
            case .completed: fail("request should fail")
            case let .failed(_, error):
                let error = error as NSError
                expect(error.domain) == NSURLErrorDomain
                expect(error.code) == NSURLErrorServerCertificateUntrusted
            }
        } catch {
            fail("\(error)")
        }
    }
    
}
