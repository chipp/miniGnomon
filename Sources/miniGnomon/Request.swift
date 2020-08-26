//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import RxSwift

public typealias AuthenticationChallenge = (
    URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
) -> Void

public enum Method: CustomStringConvertible {
    case GET, HEAD, POST, PUT, PATCH, DELETE
    case custom(String, hasBody: Bool)

    public var hasBody: Bool {
        switch self {
        case .GET, .HEAD: return false
        case .DELETE, .PATCH, .POST, .PUT: return true
        case let .custom(_, hasBody): return hasBody
        }
    }

    public var description: String {
        switch self {
        case .GET: return "GET"
        case .HEAD: return "HEAD"
        case .POST: return "POST"
        case .PUT: return "PUT"
        case .PATCH: return "PATCH"
        case .DELETE: return "DELETE"
        case let .custom(method, _): return method
        }
    }
}

public enum RequestParams {
    case none
    case skipURLEncoding
    case query([String: Any])
    case urlEncoded([String: Any])
    case json([String: Any])
    case multipart([String: String], [String: MultipartFile])
    case data(Data, contentType: String)
}

public enum LoggingPolicy {
    case never
    case always
    case onError
}

public struct MultipartFile {
    public let data: Data
    public let contentType: String
    public let filename: String

    public init(data: Data, contentType: String, filename: String) {
        self.data = data
        self.contentType = contentType
        self.filename = filename
    }
}

public struct InvalidURLStringError: Error {
    public let URLString: String
    // TODO: Error message
}

public class Request<M: Model> {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public convenience init(URLString: String) throws {
        guard let url = URL(string: URLString) else { throw InvalidURLStringError(URLString: URLString) }
        self.init(url: url)
    }

    public var xpath: String?
    public var method = Method.GET
    public var params = RequestParams.none
    public var headers: [String: String]?

    public var disableLocalCache: Bool = false
    public var disableHttpCache: Bool = false

    public var shouldHandleCookies: Bool = false

    public var authenticationChallenge: AuthenticationChallenge?

    public var timeout: TimeInterval = 60

//    public var loggingPolicy: LoggingPolicy = .never

    public var response: ((Response<M>) -> Void)?

    public var dispatchQoS: DispatchQoS = .userInitiated

    public typealias IntermediateRequest = Request<M>
}

public extension Request {
    @discardableResult
    func setXPath(_ value: String?) -> IntermediateRequest {
        xpath = value
        return self
    }

    @discardableResult
    func setMethod(_ value: Method) -> IntermediateRequest {
        method = value
        return self
    }

    @discardableResult
    func setParams(_ value: RequestParams) -> IntermediateRequest {
        params = value
        return self
    }

    @discardableResult
    func setHeaders(_ value: [String: String]?) -> IntermediateRequest {
        headers = value
        return self
    }

    @discardableResult
    func setDisableLocalCache(_ value: Bool) -> IntermediateRequest {
        disableLocalCache = value
        return self
    }

    @discardableResult
    func setDisableHttpCache(_ value: Bool) -> IntermediateRequest {
        disableHttpCache = value
        return self
    }

    @discardableResult
    func setDisableCache(_ value: Bool) -> IntermediateRequest {
        disableLocalCache = value
        disableHttpCache = value
        return self
    }

    @discardableResult
    func setShouldHandleCookies(_ value: Bool) -> IntermediateRequest {
        shouldHandleCookies = value
        return self
    }

    @discardableResult
    func setAuthenticationChallenge(_ value: @escaping AuthenticationChallenge) -> IntermediateRequest {
        authenticationChallenge = value
        return self
    }

    @discardableResult
    func setTimeout(_ value: TimeInterval) -> IntermediateRequest {
        timeout = value
        return self
    }

//    @discardableResult
//    func setLoggingPolicy(_ value: LoggingPolicy) -> IntermediateRequest {
//        loggingPolicy = value
//        return self
//    }

    @discardableResult
    func setDispatchQoS(_ value: DispatchQoS) -> IntermediateRequest {
        dispatchQoS = value
        return self
    }
}
