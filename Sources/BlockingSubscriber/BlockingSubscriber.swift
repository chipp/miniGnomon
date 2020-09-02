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

public enum BlockingMaterializedSequenceResult<Input, Failure: Error> {
    case completed(elements: [Input])
    case failed(elements: [Input], error: Failure)

    public func elements() throws -> [Input] {
        switch self {
        case let .completed(elements):
            return elements
        case let .failed(_, error):
            throw error
        }
    }
}

extension BlockingMaterializedSequenceResult: Equatable where Input: Equatable, Failure: Equatable {}

public final class BlockingSubscriber<Input, Failure: Error>: Subscriber {
    public let combineIdentifier = CombineIdentifier()
    let timeout: TimeInterval?
    let runLoop: CFRunLoop

    let lock = NSRecursiveLock()

    init(timeout: TimeInterval?) {
        self.timeout = timeout
        self.runLoop = CFRunLoopGetCurrent()
    }

    private var subscription: Subscription?
    public func receive(subscription: Subscription) {
        self.subscription = subscription
    }

    private var inputs: [Input] = []
    public func receive(_ input: Input) -> Subscribers.Demand {
        inputs.append(input)

        if
            let max = max,
            inputs.count >= max
        {
            subscription?.cancel()
            stop()
        }

        return .unlimited
    }

    private var completion: Subscribers.Completion<Failure>?
    public func receive(completion: Subscribers.Completion<Failure>) {
        self.completion = completion
        stop()
    }

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
                throw TimeoutError(inputs: inputs)
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

    struct TimeoutError<Input>: Error {
        let inputs: [Input]
    }

    public func first() throws -> Input? {
        try materializeResult(1).elements().first
    }

    public func toArray() throws -> [Input] {
        try materializeResult().elements()
    }

    public func materialize() throws -> BlockingMaterializedSequenceResult<Input, Failure> {
        try materializeResult()
    }

    private var max: Int?
    private func materializeResult(_ max: Int? = nil) throws -> BlockingMaterializedSequenceResult<Input, Failure> {
        self.max = max

        subscription?.request(.unlimited)

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
