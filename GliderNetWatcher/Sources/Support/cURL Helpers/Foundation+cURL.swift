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

//  Origin:
//  <https://github.com/zakkhoyt/SwiftyCurl>

import Foundation

/// Used to format cURL data.
private struct CurlParameters {
    static let request = " -X %@ \"%@\""
    static let command = "curl"
    static let verbosity = " --verbose"
    static let header = " -H \"%@:%@\""
    static let data = " -d '%@'"
}

// MARK: - URLRequest Extension

public extension URLRequest {
    
    // MARK: - Public Functions
    
    /// Generate the cURL representation of a equest.
    ///
    /// - Parameter verbose: `true` to get verbse output.
    /// - Returns: `String`
    func cURLCommand(verbose: Bool = false) -> String {
        let verboseString = verbose ? CurlParameters.verbosity : ""
        
        let command = CurlParameters.command + verboseString
        
        var headerString = ""
        if let headers = self.allHTTPHeaderFields {
            for (key, value) in headers {
                if key != "Accept-Language" {
                    headerString += String(format: CurlParameters.header, key, value)
                }
            }
        }
        
        let commandWithHeaders = command + headerString
        var dataString = ""
        if let httpBody = self.httpBody {
            if let d = String(data: httpBody, encoding: String.Encoding.utf8) {
                dataString = String(format: CurlParameters.data, d)
            }
        }
        var request = ""
        if let httpMethod = self.httpMethod,
            let urlString = self.url?.absoluteString {
            request = String(format: CurlParameters.request, httpMethod, urlString)
        }
        return commandWithHeaders + dataString + request
    }
    
}

// MARK: - Data Extension

extension Data {
    
    /// Representation of the response as cURL format.
    ///
    /// - Parameter response: response.
    /// - Returns: `String`
    internal func curlRepresentation(response: URLResponse?) -> String {
        do {
            if let json = try JSONSerialization.jsonObject(with: self, options: []) as? NSDictionary {
                return json.description
            }
        } catch let error {
            return "Error printing payload: " + error.localizedDescription
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: self, options: []) as? NSArray {
                return json.description
            }
        } catch let error {
            return "Error printing payload: " + error.localizedDescription
        }

        if let str = String(data: self, encoding: .utf8) {
            return str
        }

//        // TODO: What happens when we get here?
//        // Payload is neither dictionary nor array
//        // User could expect Int, UInt, Double, Bool, etc..
//        // Casting from data doesn't have a way to measure success
//        let value = self.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
//            return ptr.pointee
//        }
//        return "\(value)"
        
        var output = """
        Unable to represent payload with text.
        Recieved payload of \(self.count) bytes.
        """
        if let response = response {
            output += "\nExpected payload of \(response.expectedContentLength) bytes."
            if let mimeType = response.mimeType {
                output += "\nMIME Type: \(mimeType)."
            }
            if let textEncodingName = response.textEncodingName {
                output += "\nText Encoding: \(textEncodingName)."
            }
            if let suggestedFilename = response.suggestedFilename {
                output += "\nSuggested File Name: \(suggestedFilename)."
            }
        }
        return output;
    }
    
}

// MARK: - URLResponse Extension

extension URLResponse {
 
    internal func curlStatusCode() -> Int? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return nil
        }
        return httpResponse.statusCode
    }
    
}
