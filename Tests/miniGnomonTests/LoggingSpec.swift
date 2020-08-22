//
//  Created by Vladimir Burdukov on 8/21/20.
//

//import XCTest
//import Nimble
//import RxSwift
//import RxBlocking
//
//@testable import miniGnomon
//
//class LoggingSpec: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//
//        Gnomon.logging = false
//        Gnomon.log = { string in
//            print(string)
//        }
//    }
//
//    func request(global: Bool? = nil, request loggingPolicy: LoggingPolicy? = nil) {
//        if let global = global {
//            Gnomon.logging = global
//        }
//
//        do {
//            let request = try Request<TestModel1>(URLString: "https://example.com/")
//            request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)
//
//            if let loggingPolicy = loggingPolicy {
//                request.loggingPolicy = loggingPolicy
//            }
//
//            let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()
//
//            switch result {
//            case let .completed(responses):
//                expect(responses).to(haveCount(1))
//
//                let response = responses[0]
//                expect(response.result.key) == 123
//            case let .failed(_, error):
//                fail("\(error)")
//            }
//        } catch {
//            fail("\(error)")
//        }
//    }
//
//    func testDefaultState() {
//        var log: String? = nil
//
//        Gnomon.log = { string in
//            log = log ?? "" + string + "\n"
//        }
//
//        request()
//        expect(log).to(beNil())
//    }
//
//    func testDisabledState() {
//        Gnomon.logging = false
//        testDefaultState()
//    }
//
//    func testEnabledLogging() {
//        var log: String? = nil
//
//        Gnomon.log = { string in
//            log = log ?? "" + string + "\n"
//        }
//
//        request(global: true)
//        expect(log) == "curl -X GET \"https://example.com/\"\n"
//    }
//
//    func testEnabledLoggingAndDisabledRequestLogging() {
//        var log: String? = nil
//
//        Gnomon.log = { string in
//            log = log ?? "" + string + "\n"
//        }
//
//        request(global: true, request: .never)
//        expect(log) == "curl -X GET \"https://example.com/\"\n"
//    }
//
//    func testDisabledLoggingAndEnabledRequestLogging() {
//        var log: String? = nil
//
//        Gnomon.log = { string in
//            log = log ?? "" + string + "\n"
//        }
//
//        request(global: false, request: .always)
//        expect(log).to(beNil())
//    }
//
//    func testDisabledLoggingAndDisabledRequestLogging() {
//        var log: String? = nil
//
//        Gnomon.log = { string in
//            log = log ?? "" + string + "\n"
//        }
//
//        request(global: false, request: .never)
//        expect(log).to(beNil())
//    }
//
//}
