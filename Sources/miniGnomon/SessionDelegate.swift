//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import RxSwift

func configuration(with policy: URLRequest.CachePolicy) -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = policy
    return configuration
}

final class SessionDelegate: NSObject, URLSessionDataDelegate {
    fileprivate let subject = PublishSubject<DataAndResponse>()
    var result: Observable<DataAndResponse> { return subject }

    var authenticationChallenge: AuthenticationChallenge?

    private var response: URLResponse?
    private var data = Data()

    func urlSession(
        _ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let authenticationChallenge = authenticationChallenge {
            authenticationChallenge(challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        self.response = response
        if response.expectedContentLength > 0 {
            data.reserveCapacity(Int(response.expectedContentLength))
        }

        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse cached: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void
    ) {
        if let response = cached.response as? HTTPURLResponse, let updated = response.httpCachedResponse {
            let newCached = CachedURLResponse(response: updated, data: cached.data, userInfo: cached.userInfo,
                                              storagePolicy: cached.storagePolicy)
            completionHandler(newCached)
        } else {
            completionHandler(cached)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        data.regions.forEach {
            self.data.append($0)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            subject.onError(error)
        } else {
            guard let response = response else {
                subject.onError(HTTPClientError.undefined(message: nil))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                subject.onError(HTTPClientError.nonHTTPResponse(response: response))
                return
            }

            subject.onNext((data, httpResponse))
            subject.onCompleted()
        }
    }
}
