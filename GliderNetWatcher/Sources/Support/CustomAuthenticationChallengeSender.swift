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

internal class CustomAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    typealias CustomAuthenticationChallengeHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
 
    // MARK: - Private Properties
    
    private let handler: CustomAuthenticationChallengeHandler
    
    // MARK: - Initialixation
    
    init(handler: @escaping CustomAuthenticationChallengeHandler) {
        self.handler = handler
    }
    
    // MARK:- - Implementation

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, credential)
    }
    
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, nil)
    }
    
    func cancel(_ challenge: URLAuthenticationChallenge) {
        handler(.cancelAuthenticationChallenge, nil)
    }
    
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        handler(.performDefaultHandling, nil)
    }
    
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        handler(.rejectProtectionSpace, nil)
    }
    
}
