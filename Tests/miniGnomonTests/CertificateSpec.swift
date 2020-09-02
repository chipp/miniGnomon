//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble
import RxBlocking

@testable import miniGnomon

class CertificateSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testInvalidCertificate() throws {
        let client = HTTPClient()

        let request = try Request<String>(URLString: "https://self-signed.badssl.com/")
        request.authenticationChallenge = { challenge, completionHandler -> Void in
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }

        guard let response = try client.models(for: request).toBlocking().first() else {
            return fail("can't extract response")
        }

        expect(response.result.count).to(beGreaterThan(0))
    }

    func testInvalidCertificateWithoutHandler() throws {
        let client = HTTPClient()

        let request = try Request<String>(URLString: "https://self-signed.badssl.com/")
        let result = client.models(for: request).toBlocking().materialize()

        switch result {
        case .completed: fail("request should fail")
        case let .failed(_, error):
            let error = error as NSError
            expect(error.domain) == NSURLErrorDomain
            expect(error.code) == NSURLErrorServerCertificateUntrusted
        }
    }

}
