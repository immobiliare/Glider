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
import Glider

public class GliderLogglyTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Delegate
    public weak var delegate: GliderLogglyTransportDelegate?
    
    /// Authentication token.
    /// See <https://documentation.solarwinds.com/en/success_center/loggly/content/admin/customer-token-authentication-token.htm>
    public let token: String
    
    
    
}
