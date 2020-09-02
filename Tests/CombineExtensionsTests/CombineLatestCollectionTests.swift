//
//  Created by Vladimir Burdukov on 8/30/20.
//

import XCTest
import Combine
import Nimble
import CombineExtensions
@testable import miniGnomon

class CombineLatestCollectionTests: XCTestCase {
    struct TestError: Error, Equatable {
        let index: Int
    }

    var publishers: [PassthroughSubject<Int, TestError>] = []

    override func setUp() {
        publishers = Array(repeating: (), count: 5).map(PassthroughSubject.init)
    }

    func testValues() throws {
        var completion: Subscribers.Completion<TestError>!
        var values: [[Int]] = []

        let disposable = CombineLatestCollection(publishers).sink(receiveCompletion: { receivedCompletion in
            completion = receivedCompletion
        }, receiveValue: { receivedValues in
            values.append(receivedValues)
        })

        expect(completion).to(beNil())
        expect(values).to(beEmpty())

        publishers[0].send(1)
        publishers[1].send(2)
        publishers[2].send(3)
        publishers[3].send(4)

        expect(completion).to(beNil())
        expect(values).to(beEmpty())

        publishers[4].send(5)

        expect(completion).to(beNil())
        expect(values) == [[1, 2, 3, 4, 5]]

        for (index, publisher) in publishers.enumerated() {
            publisher.send(index + 2)
        }

        expect(completion).to(beNil())
        expect(values) == [
            [1, 2, 3, 4, 5],

            [2, 2, 3, 4, 5],
            [2, 3, 3, 4, 5],
            [2, 3, 4, 4, 5],
            [2, 3, 4, 5, 5],
            [2, 3, 4, 5, 6]
        ]

        doNothing(disposable)
    }

    // TODO:
//    func testValuesAsync() throws {
//        var values: [[Int]] = []
//        let cancellable = CombineLatestCollection(publishers.enumerated().map { idx, pub in
//            pub.subscribe(on: DispatchQueue.global(qos: .background))
//        }).receive(on: RunLoop.main).sink(receiveCompletion: { _ in }, receiveValue: { rcvd in
//            values.append(rcvd)
//        })
//
////        let values = try CombineLatestCollection(publishers).toBlocking().toArray()
//
//        for (index, publisher) in publishers.enumerated() {
//            publisher.send(index + 1)
//        }
//
//        expect(values).toEventually(equal([[1, 2, 3, 4, 5]]))
//
//        for (index, publisher) in publishers.enumerated() {
//            publisher.send(index + 2)
//        }
//
//        expect(values).toEventually(equal([
//            [1, 2, 3, 4, 5],
//            [2, 2, 3, 4, 5],
//            [2, 3, 3, 4, 5],
//            [2, 3, 4, 4, 5],
//            [2, 3, 4, 5, 5],
//            [2, 3, 4, 5, 6]
//        ]))
//
//        doNothing(cancellable)
//    }

    func testCompletion() {
        var completion: Subscribers.Completion<TestError>!

        let disposable = CombineLatestCollection(publishers).sink(receiveCompletion: { receivedCompletion in
            completion = receivedCompletion
        }, receiveValue: { _ in })

        expect(completion).to(beNil())

        publishers[0].send(completion: .finished)
        publishers[1].send(completion: .finished)
        publishers[2].send(completion: .finished)
        publishers[3].send(completion: .finished)

        expect(completion).to(beNil())

        publishers[4].send(completion: .finished)

        expect(completion) == .finished

        doNothing(disposable)
    }

    func testFailed() {
        var completion: Subscribers.Completion<TestError>!

        let disposable = CombineLatestCollection(publishers).sink(receiveCompletion: { receivedCompletion in
            completion = receivedCompletion
        }, receiveValue: { _ in })

        expect(completion).to(beNil())

        publishers[2].send(completion: .failure(.init(index: 2)))
        expect(completion) == .failure(.init(index: 2))

        publishers[4].send(completion: .finished)
        expect(completion) == .failure(.init(index: 2))

        publishers[1].send(completion: .failure(.init(index: 1)))
        expect(completion) == .failure(.init(index: 2))

        doNothing(disposable)
    }

    func testValuesAfterFailed() {
        var completion: Subscribers.Completion<TestError>!
        var values: [[Int]] = []

        let disposable = CombineLatestCollection(publishers).sink(receiveCompletion: { receivedCompletion in
            completion = receivedCompletion
        }, receiveValue: { receivedValues in
            values.append(receivedValues)
        })

        for (index, publisher) in publishers.enumerated() {
            publisher.send(index + 1)
        }

        expect(completion).to(beNil())
        expect(values) == [[1, 2, 3, 4, 5]]

        publishers[2].send(completion: .failure(.init(index: 2)))
        expect(completion) == .failure(.init(index: 2))

        publishers[1].send(10)
        expect(completion) == .failure(.init(index: 2))
        expect(values) == [[1, 2, 3, 4, 5]]

        doNothing(disposable)
    }
}

func doNothing<T>(_ t: T) {}
