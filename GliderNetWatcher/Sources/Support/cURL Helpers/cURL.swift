//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

public struct CURL {
    
    // MARK: - Public Functions
    
    /// Generate a complete cURL report for a request and response.
    ///
    /// - Parameters:
    ///   - task: request task.
    ///   - data: data received.
    ///   - error: error received.
    /// - Returns: `String?`
    static public func cURL(forTask task: URLSessionTask, data: Data?, error: Error? = nil) throws -> String? {
        guard let request = task.originalRequest, let response = task.response else {
            return nil
        }
        
        let statusCode = response.curlStatusCode() ?? 0
        return cURL(forRequest: request, response: response, data: data, statusCode: statusCode)
    }
    
    // MARK: - Private Functions
    
    private static func cURL(forRequest request: URLRequest, response: URLResponse,
                             data: Data?, statusCode: Int, verbose: Bool = false) -> String {
        let titleString: String = {
            if isError(status: statusCode) {
                return "\n**************** HTTP ERROR \(statusCode) **********************"
            } else {
                return "\n**************** HTTP SUCCESS \(statusCode) **********************"
            }
        }()
        
        let requestString: String = {
            return """
                **** REQUEST ****
                \(request.cURLCommand())
                """
        }()
        
        let payloadString: String = {
            return """
                **** PAYLOAD ****
                \(data?.curlRepresentation(response: response) ?? "")
                """
        }()
        
        let suffixString: String = "****************************************************"
        
        let output = """
            \(titleString)
            \(requestString)
            \(payloadString)
            \(suffixString)
            """
        return output
    }
    
    private static func isError(status: Int) -> Bool {
        return status < 200 || status >= 300
    }
    
}
