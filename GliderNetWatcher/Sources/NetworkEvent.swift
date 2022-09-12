//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation
import Glider

/// Identify a single intercepted request+response from network; this
/// object is generated automatically from the `NetworkLogger` class
/// when activated.
public struct NetworkEvent: Equatable, Codable, SerializableObject {
    
    // MARK: - Public Properties (Request)
    
    /// Unique identifier of the call.
    public let id = UUID()
    
    /// Full URL of the request.
    public let url: URL
    
    /// Host of the request.
    public let host: String?
    
    /// Port of the request.
    public let port: Int?
    
    /// Scheme used for request.
    public let scheme: String?
    
    /// HTTP Method
    public let method: String
    
    /// Headers of the request.
    public private(set) var headers = [String: String]()
    
    /// Secure credentials.
    public var credentials = [String: String]()
    
    /// Cookies.
    public var cookies: String?

    /// Status code received.
    public var statusCode: Int = 0
    
    /// Request start date.
    public private(set) var startDate: Date
    
    // MARK: - Public Properties (Response)
    
    /// Duration of the request+reponse.
    public private(set) var duration: TimeInterval?
    
    /// Received data.
    public private(set) var responseData: Data?
    
    /// Headers received inside the response.
    public private(set) var responseHeaders: [String: String]?
    
    /// Error description, if any.
    public private(set) var responseErrorDescription: String?

    // MARK: - Helper Properties
    // NOTE:
    // The following properties are never encoded, still present only at runtime.
    
    /// Error occurred, if any.
    public private(set) var responseError: Error? {
        didSet {
            responseErrorDescription = responseError?.localizedDescription
        }
    }
    
    /// Request origin.
    public private(set) var urlRequest: URLRequest?
    
    /// Parent `URLSession` instance.
    public private(set) var urlSession: URLSession?
    
    /// Response received.
    public private(set) var urlResponse: URLResponse?
    
    /// HTTP Response received.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    // MARK: - Initialization
    
    /// Initialize a new log event with a request coming from a session.
    ///
    /// - Parameters:
    ///   - request: request to save.
    ///   - session: origin url session instance.
    internal init?(request: NSMutableURLRequest, inSession session: URLSession?) {
        guard let fullURL = request.url else {
            return nil
        }
        
        self.url = fullURL
        self.host = fullURL.host
        self.port = fullURL.port
        self.scheme = fullURL.scheme
        self.method = request.httpMethod
        self.headers = request.allHTTPHeaderFields ?? [:]

        self.startDate = Date()
        self.urlRequest = request as URLRequest
        self.urlSession = session
        
        extractCookiesAndCredentials()
    }
    
    // MARK: - Protocol Conformance
    
    public static func == (lhs: NetworkEvent, rhs: NetworkEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Internal Function

    internal mutating func didReceive(data: Data) {
        if self.responseData == nil {
            self.responseData = data
        } else {
            self.responseData?.append(data)
        }
    }
    
    internal mutating func didReceive(response: URLResponse) {
        self.urlResponse = response
        self.statusCode = httpResponse?.statusCode ?? 0
        self.responseHeaders = httpResponse?.allHeaderFields as? [String: String]
        self.responseData = Data()
    }
    
    internal mutating func didCompleteWithError(_ error: Error?) {
        self.responseError = error
        duration = fabs(startDate.timeIntervalSinceNow)
    }
    
    // MARK: - Private Functions
    
    /// The following method extract credentials and cookies.
    ///
    /// NOTE:
    /// I've taken inspiration from the Wormholy project by Paolo Musolino
    /// you can found here: <https://github.com/pmusolino/Wormholy>.
    private mutating func extractCookiesAndCredentials() {
        // collect all HTTP Request headers except the "Cookie" header.
        // Many request representations treat cookies with special parameters or structures.
        // For cookie collection, refer to the bottom part of this method
        self.urlSession?.configuration.httpAdditionalHeaders?
            .filter {  $0.0 != AnyHashable("Cookie") }
            .forEach { element in
                guard let key = element.0 as? String, let value = element.1 as? String else {
                    return
                }
                
                headers[key] = value
            }
        
        // if the target server uses HTTP Basic Authentication, collect username and password
        if let credentialStorage = urlSession?.configuration.urlCredentialStorage,
            let host = self.host,
            let port = self.port {
            let protectionSpace = URLProtectionSpace(
                host: host,
                port: port,
                protocol: scheme,
                realm: host,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    self.credentials[user] = password
                }
            }
        }
        
        // Collect cookies associated with the target host
        // TODO: Add the else branch.
        // With the condition below, it is handled only the case where `session.configuration.httpShouldSetCookies == true`.
        // Some developers could opt to handle cookie manually using the "Cookie" header stored in httpAdditionalHeaders
        // and disabling the handling provided by URLSessionConfiguration (`httpShouldSetCookies == false`).
        // See <https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411589-httpshouldsetcookies?language=objc>
        if let session = urlSession, let url = urlRequest?.url, session.configuration.httpShouldSetCookies {
            if let cookieStorage = session.configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
                self.cookies = cookies.reduce("") {
                    $0 + "\($1.name)=\($1.value);"
                }
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, host, port, scheme, method, headers,
             credentials, cookies,
             statusCode, startDate,
             duration, responseData, responseHeaders, responseErrorDescription
    }
    
}

// MARK: - Glider.Event Extensions

extension Glider.Event {
    
    /// Return the network event if the event itself encapsulate a sniffed call.
    public func networkEvent() -> NetworkEvent? {
        object as? NetworkEvent
    }
    
}
