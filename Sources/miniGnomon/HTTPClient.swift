//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import Combine

public class HTTPClient {
    // MARK: - Initialization

    typealias PerformURLRequest = (
        URLRequest, URLRequest.CachePolicy, AuthenticationChallenge?
    ) -> AnyPublisher<DataAndResponse, Error>

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
    ) -> AnyPublisher<DataAndResponse, Error> {
        let delegate = SessionDelegate()
        delegate.authenticationChallenge = authenticationChallenge

        let session = URLSession(configuration: configuration(with: policy), delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest)
        task.resume()
        session.finishTasksAndInvalidate()

        return delegate.result.handleEvents(receiveCancel: {
            if task.state == .running {
                task.cancel()
            }
        }).eraseToAnyPublisher()
    }

    // MARK: - Single request

    public func models<M>(for request: Request<M>) -> AnyPublisher<Response<M>, Error> {
        observable(for: request, localCache: false).flatMap { data, response -> AnyPublisher<Response<M>, Error> in
            let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
            return Self.parse(data: data, response: response, responseType: type, for: request)
        }.eraseToAnyPublisher()
    }

    public func cachedModels<M>(for request: Request<M>) -> AnyPublisher<Response<M>, Error> {
        cachedModels(for: request, catchErrors: true)
    }

    public func cachedThenFetch<M>(_ request: Request<M>) -> AnyPublisher<Response<M>, Error> {
        cachedModels(for: request).append(models(for: request)).eraseToAnyPublisher()
    }

    // MARK: - Multiple requests

    public func models<M>(for requests: [Request<M>]) -> AnyPublisher<[Result<Response<M>, Error>], Never> {
        guard !requests.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return requests.map { request in
            models(for: request).asResult()
        }.combineLatest().eraseToAnyPublisher()
    }

    public func cachedModels<M>(for requests: [Request<M>]) -> AnyPublisher<[Result<Response<M>, Error>], Never> {
        guard !requests.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return requests.map { request in
            cachedModels(for: request, catchErrors: false).asResult()
        }.combineLatest().eraseToAnyPublisher()
    }

    public func cachedThenFetch<M>(_ requests: [Request<M>]) -> AnyPublisher<[Result<Response<M>, Error>], Never> {
        guard !requests.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return Empty(outputType: [Result<Response<M>, Error>].self, failureType: Never.self)
            .eraseToAnyPublisher()

//        let cached = requests.map { cachedModels(for: $0, catchErrors: true).asResult() }
//        let http = requests.map { models(for: $0).asResult() }
//
//        return Observable.zip(cached).filter { results in
//            results.filter { $0.value != nil }.count == requests.count
//        }.concat(Observable.zip(http))
    }

    // MARK: - Private

    private func cachedModels<M>(for request: Request<M>, catchErrors: Bool) -> AnyPublisher<Response<M>, Error> {
        let result = observable(for: request, localCache: true).flatMap { data, response in
            Self.parse(data: data, response: response, responseType: .localCache, for: request)
        }

        if catchErrors {
            return result.catch { _ in
                Empty(outputType: Response<M>.self, failureType: Error.self)
            }.eraseToAnyPublisher()
        } else {
            return result.eraseToAnyPublisher()
        }
    }

    private func observable<M>(
        for request: Request<M>, localCache: Bool
    ) -> AnyPublisher<DataAndResponse, Error> {
        Deferred<AnyPublisher<DataAndResponse, Error>> {
            let policy = cachePolicy(for: request, localCache: localCache)
            let urlRequest: URLRequest
            do {
                urlRequest = try prepareURLRequest(from: request, cachePolicy: policy)
            } catch {
                return Fail(outputType: DataAndResponse.self, failure: error)
                    .eraseToAnyPublisher()
            }

            let result = self.performURLRequest(urlRequest, policy, request.authenticationChallenge)

            return result.tryMap { tuple -> DataAndResponse in
                let (data, response) = tuple

                    guard (200..<400) ~= response.statusCode else {
                        throw HTTPClientError.errorStatusCode(response.statusCode, data)
                    }

                return tuple
            }.eraseToAnyPublisher()
            // TODO: share and replay
//            .share(replay: 1, scope: .whileConnected)
        }.eraseToAnyPublisher()
    }

    private static func parse<M>(
        data: Data, response httpResponse: HTTPURLResponse, responseType: ResponseType, for request: Request<M>
    ) -> AnyPublisher<Response<M>, Error> {
        Future { completion in
            let result: M
            do {
                let container = try M.dataContainer(with: data, at: request.xpath)
                result = try M(container)
            }
            catch {
                completion(.failure(error))
                return
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
            completion(.success(response))
        }
        .subscribe(on: DispatchQueue.global(qos: request.dispatchQoS))
        .eraseToAnyPublisher()
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
