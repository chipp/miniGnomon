//
//  Created by Vladimir Burdukov on 8/27/20.
//

import Combine
import Foundation

extension Collection where Element: Publisher {
    func combineLatest() -> CombineLatestCollection<Self> {
        CombineLatestCollection(self)
    }
}

struct CombineLatestCollection<Upstreams>: Publisher where Upstreams: Collection, Upstreams.Element: Publisher {
    typealias Upstream = Upstreams.Element

    typealias Output = [Upstream.Output]
    typealias Failure = Upstream.Failure

    let publishers: Upstreams
    init(_ publishers: Upstreams) {
        self.publishers = publishers
    }

    func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let combiner = CombineLatestCollectionSubscription(publishers: publishers, subscriber: subscriber)

        for (index, publisher) in publishers.enumerated() {
            publisher.subscribe(CombineLatestCollectionSubscription.SubSubscriber<Upstream.Output>(combiner, index: index))
        }

        subscriber.receive(subscription: combiner)
    }
}

private final class CombineLatestCollectionSubscription<Upstreams, Downstream>: Subscription
    where Upstreams: Collection,
        Upstreams.Element: Publisher, Downstream: Subscriber,
        Downstream.Input == [Upstreams.Element.Output],
        Downstream.Failure == Upstreams.Element.Failure
{
    typealias Upstream = Upstreams.Element

    let combinerLock = NSRecursiveLock()
//    let subscriberLock = NSLock()

    deinit {
        cancel()
    }

    let publishers: Upstreams
    let subscriber: Downstream

    var subscriptions: [Subscription?]

    var numberOfElements = 0
    var elements: [Input?]

    var isFinished: [Bool]
    var numberOfFinished = 0

    var isFailed = false
    var isCancelled = false

    var canForwardEvents: Bool {
        !(isFailed || isCancelled || numberOfFinished == isFinished.count)
    }

    init(publishers: Upstreams, subscriber: Downstream) {
        self.publishers = publishers
        self.subscriber = subscriber

        elements = .init(repeating: nil, count: publishers.count)
        subscriptions = .init(repeating: nil, count: publishers.count)
        isFinished = .init(repeating: false, count: publishers.count)
    }

    private var demand: Subscribers.Demand = .none
    func request(_ demand: Subscribers.Demand) {
        debug("request demand", demand, Thread.current)

        combinerLock.lock()
        self.demand += demand

        for subscription in subscriptions {
            subscription?.request(demand)
        }
        combinerLock.unlock()
    }

    func cancel() {
        reset()

        let subscriptions = self.subscriptions
        for subscription in subscriptions {
            subscription?.cancel()
        }
    }

    private func reset() {
        combinerLock.lock()
        demand = .none

        elements = .init(repeating: nil, count: publishers.count)
        subscriptions = .init(repeating: nil, count: publishers.count)
        isFinished = .init(repeating: false, count: publishers.count)
        combinerLock.unlock()
    }

}

extension CombineLatestCollectionSubscription {
    typealias Input = Upstream.Output
    typealias Failure = Upstream.Failure

    func receive(subscription: Subscription, index: Int) {
        debug(#function, index, "waiting lock", Thread.current)
        combinerLock.lock()
        debug(#function, index, "lock", Thread.current)
        subscriptions[index] = subscription

        if demand > 0 {
            subscription.request(demand)
        }

        combinerLock.unlock()
        debug(#function, index, "unlock", Thread.current)
    }

    func receive(_ input: Input, index: Int) -> Subscribers.Demand {
        debug(#function, index, "waiting lock", Thread.current)
        combinerLock.lock()
        debug(#function, index, "lock", Thread.current)

        guard canForwardEvents else {
            combinerLock.unlock()
            debug(#function, index, "unlock", Thread.current)
            return .none
        }

        if elements[index] == nil {
            numberOfElements += 1
        }

        elements[index] = input

        if numberOfElements < elements.count {
            combinerLock.unlock()
            debug(#function, index, "unlock", Thread.current)
            return .none
        }

        demand -= 1

//        subscriberLock.lock()
        demand += subscriber.receive(elements.compactMap { $0 })
//        subscriberLock.unlock()

        combinerLock.unlock()
        debug(#function, index, "unlock", Thread.current)

        return .none
    }

    func receive(completion: Subscribers.Completion<Failure>, index: Int) {
        debug(#function, index, "waiting lock", Thread.current, completion)
        combinerLock.lock()
        debug(#function, index, "lock", Thread.current)

        guard canForwardEvents else {
            combinerLock.unlock()
            debug(#function, index, "unlock", Thread.current)
            return
        }

        switch completion {
        case .finished:
            if isFinished[index] {
                combinerLock.unlock()
                debug(#function, index, "unlock", Thread.current)
                return
            }

            isFinished[index] = true
            numberOfFinished += 1

            if numberOfFinished == isFinished.count {
//                subscriberLock.lock()
                subscriber.receive(completion: .finished)
//                subscriberLock.unlock()
            }
        case let .failure(error):
            isFailed = true

//            subscriberLock.lock()
            subscriber.receive(completion: .failure(error))
//            subscriberLock.unlock()
            cancel()
        }

        combinerLock.unlock()
        debug(#function, index, "unlock", Thread.current)
    }
}

extension CombineLatestCollectionSubscription {
    final class SubSubscriber<Input>: Subscriber {
        let combiner: CombineLatestCollectionSubscription
        let index: Int

        init(_ combiner: CombineLatestCollectionSubscription, index: Int) {
            self.combiner = combiner
            self.index = index
        }

        func receive(subscription: Subscription) {
            combiner.receive(subscription: subscription, index: index)
        }

        func receive(_ input: CombineLatestCollectionSubscription.Input) -> Subscribers.Demand {
            debug("receive(input:)", index, input)
            return combiner.receive(input, index: index)
        }

        func receive(completion: Subscribers.Completion<CombineLatestCollectionSubscription.Failure>) {
            debug("receive(completion:)", index, completion)
            combiner.receive(completion: completion, index: index)
        }
    }
}

private func debug(_ items: Any...) {
//    print(items)
}
