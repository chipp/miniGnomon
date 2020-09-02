//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import RxSwift

public class HTTPClient {
    typealias PerformURLRequest = (
        URLRequest, URLRequest.CachePolicy, AuthenticationChallenge?
    ) -> Observable<(Data, HTTPURLResponse)>

    let performURLRequest: PerformURLRequest

    public init() {
        self.performURLRequest = HTTPClient.performURLRequest
    }

    init(performURLRequest: @escaping PerformURLRequest) {
        self.performURLRequest = performURLRequest
    }

    private static func performURLRequest(
        urlRequest: URLRequest, policy: URLRequest.CachePolicy,
        authenticationChallenge: AuthenticationChallenge?
    ) -> Observable<(Data, HTTPURLResponse)> {
        let delegate = SessionDelegate()
        delegate.authenticationChallenge = authenticationChallenge

        let session = URLSession(configuration: configuration(with: policy), delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest)
        task.resume()
        session.finishTasksAndInvalidate()

        return delegate.result.do(onDispose: {
            if task.state == .running {
                task.cancel()
            }
        })
    }

    public func models<M>(for request: Request<M>) -> Observable<Response<M>> {
        observable(for: request, localCache: false).flatMap { data, response -> Observable<Response<M>> in
            let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
            return self.parse(data: data, response: response, responseType: type, for: request)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: request.dispatchQoS))
        }
    }

    public func cachedModels<M>(for request: Request<M>) -> Observable<Response<M>> {
        cachedModels(for: request, catchErrors: true)
    }

    private func cachedModels<M>(for request: Request<M>, catchErrors: Bool) -> Observable<Response<M>> {
        let result = observable(for: request, localCache: true).flatMap { data, response in
            self.parse(data: data, response: response, responseType: .localCache, for: request)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: request.dispatchQoS))
        }

        if catchErrors {
            return result.catchError { _ in
                Observable<Response<M>>.empty()
            }
        } else {
            return result
        }
    }

    public func cachedThenFetch<M>(_ request: Request<M>) -> Observable<Response<M>> {
        cachedModels(for: request).concat(models(for: request))
    }

    public func cachedModels<M>(for requests: [Request<M>]) -> Observable<[Result<Response<M>, Error>]> {
        guard !requests.isEmpty else { return .just([]) }

        return Observable.combineLatest(requests.map { request in
            cachedModels(for: request, catchErrors: false).asResult()
        })
    }

    public func models<M>(for requests: [Request<M>]) -> Observable<[Result<Response<M>, Error>]> {
        guard !requests.isEmpty else { return .just([]) }

        return Observable.combineLatest(requests.map { request in
            models(for: request).asResult()
        })
    }

    public func cachedThenFetch<M>(_ requests: [Request<M>]) -> Observable<[Result<Response<M>, Error>]> {
        guard !requests.isEmpty else { return .just([]) }

        let cached = requests.map { cachedModels(for: $0, catchErrors: true).asResult() }
        let http = requests.map { models(for: $0).asResult() }

        return Observable.zip(cached).filter { results in
            results.filter { $0.value != nil }.count == requests.count
        }.concat(Observable.zip(http))
    }

    private func observable<M>(
        for request: Request<M>, localCache: Bool
    ) -> Observable<(Data, HTTPURLResponse)> {
        Observable.deferred {
            let policy = cachePolicy(for: request, localCache: localCache)
            let urlRequest = try prepareURLRequest(from: request, cachePolicy: policy)

            let result = self.performURLRequest(urlRequest, policy, request.authenticationChallenge)

            return result.map { tuple -> (Data, HTTPURLResponse) in
                let (data, response) = tuple

                guard (200..<400) ~= response.statusCode else {
                    throw HTTPClientError.errorStatusCode(response.statusCode, data)
                }

                return tuple
            }.share(replay: 1, scope: .whileConnected)
        }
    }

    private func parse<M>(
        data: Data, response httpResponse: HTTPURLResponse, responseType: ResponseType, for request: Request<M>
    ) -> Observable<Response<M>> {
        Observable.create { subscriber -> Disposable in
            let result: M
            do {
                let container = try M.dataContainer(with: data, at: request.xpath)
                result = try M(container)
            }
            catch {
                subscriber.onError(error)
                return Disposables.create()
            }

            let headers: [String: String]
            if let responseHeaders = httpResponse.allHeaderFields as? [String: String] {
                headers = responseHeaders
            }
            else {
                headers = [:]
            }

            let response = Response(
                result: result, type: responseType, headers: headers, statusCode: httpResponse.statusCode
            )
            request.response?(response)
            subscriber.onNext(response)
            subscriber.onCompleted()

            return Disposables.create()
        }
    }

    // MARK: - Logging
//    public static var logging = false
//
//    private static func curlLog<U>(_ request: Request<U>, _ dataRequest: URLRequest) {
//        guard request.loggingPolicy == .never else { return }
//        debugLog(URLRequestFormatter.cURLCommand(from: dataRequest), request.loggingPolicy)
//    }
//
//    internal static var debugLog: (String, LoggingPolicy) -> Void = { string, policy in
//        if logging || policy == .always {
//            log(string)
//        } else if policy == .onError {
//            errorLog(string)
//        }
//    }
//
//    internal static var errorLog: (String) -> Void = { string in
//        log(string)
//    }
//
//    public static var log: (String) -> Void = { string in
//        print(string)
//    }
}
