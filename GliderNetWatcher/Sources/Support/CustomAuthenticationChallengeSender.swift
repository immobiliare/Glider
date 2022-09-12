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
