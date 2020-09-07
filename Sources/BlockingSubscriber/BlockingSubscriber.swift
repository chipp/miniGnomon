//
//  Created by Vladimir Burdukov on 8/30/20.
//

import Foundation
import Combine

public extension Publisher {
    func toBlocking(timeout: TimeInterval? = nil) -> BlockingSubscriber<Self.Output, Self.Failure> {
        let subscriber = BlockingSubscriber<Self.Output, Self.Failure>(timeout: timeout)
        receive(subscriber: subscriber)
        return subscriber
    }
}

public final class BlockingSubscriber<Input, Failure: Error> {
    public let combineIdentifier = CombineIdentifier()
    let timeout: TimeInterval?
    let runLoop: CFRunLoop

    init(timeout: TimeInterval?) {
        self.timeout = timeout
        self.runLoop = CFRunLoopGetCurrent()
    }

    private var subscription: Subscription?
    private var inputs: [Input] = []
    private var completion: Subscribers.Completion<Failure>?

    private func run() throws {
        if let timeout = timeout {
            switch CFRunLoopRunInMode(CFRunLoopMode.defaultMode, timeout, false) {
            case .finished:
                return
            case .handledSource:
                return
            case .stopped:
                return
            case .timedOut:
                subscription?.cancel()
                throw BlockingSubscriberError.timeout
            default:
                fatalError()
            }
        } else {
            CFRunLoopRun()
        }
    }

    private func stop() {
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) {
            CFRunLoopStop(self.runLoop)
        }
        CFRunLoopWakeUp(runLoop)
    }

    private var demand: Subscribers.Demand = .none
    private var predicate: (Input) -> Bool = { _ in true }

    private func materializeResult(
        _ demand: Subscribers.Demand = .unlimited,
        predicate: @escaping (Input) -> Bool = { _ in true }
    ) throws -> MaterializedSequenceResult<Input, Failure> {
        self.demand = demand
        self.predicate = predicate

        subscription?.request(demand)

        try run()

        if let completion = completion {
            switch completion {
            case .finished:
                return .completed(elements: inputs)
            case let .failure(error):
                return .failed(elements: inputs, error: error)
            }
        } else {
            return .completed(elements: inputs)
        }
    }
}

extension BlockingSubscriber: Subscriber {
    public func receive(subscription: Subscription) {
        self.subscription = subscription
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        guard predicate(input) else {
            return demand
        }

        inputs.append(input)
        demand -= 1

        if demand == .none {
            subscription?.cancel()
            stop()
        }

        return demand
    }

    public func receive(completion: Subscribers.Completion<Failure>) {
        self.completion = completion
        stop()
    }
}

// MARK: - Operators
extension BlockingSubscriber {
    public func toArray() throws -> [Input] {
        try materializeResult().elements()
    }

    public func first() throws -> Input? {
        try materializeResult(.max(1)).elements().first
    }

    public func last() throws -> Input? {
        try materializeResult().elements().last
    }

    public func materialize() throws -> MaterializedSequenceResult<Input, Failure> {
        try materializeResult()
    }

    public func single() throws -> Input {
        return try self.single { _ in true }
    }

    public func single(_ predicate: @escaping (Input) -> Bool) throws -> Input {
        let results = try materializeResult(.max(2), predicate: predicate)
        let elements = try results.elements()

        if elements.count > 1 {
            throw BlockingSubscriberError.moreThanOneElement
        }

        guard let first = elements.first else {
            throw BlockingSubscriberError.noElements
        }

        return first
    }
}
