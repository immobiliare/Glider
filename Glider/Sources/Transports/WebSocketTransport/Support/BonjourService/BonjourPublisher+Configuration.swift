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

extension BonjourPublisher {
    
    public struct Configuration {
        
        /// Type of service.
        var type: ServiceType
        
        /// Domain name.
        var domain: String
        
        /// Name.
        var name: String
        
        /// Port.
        var port: Int32
        
        /// Service identifier.
        var identifier: String
        
        /// Additional service info.
        var txtRecords: [String: String]
    }
    
}

// MARK: - ServiceType

extension BonjourPublisher.Configuration {
    
    /// Type of exposed service.
    /// - `tcp`: TCP based service.
    /// - `udp`: UDP based service.
    public enum ServiceType {
        case tcp(String)
        case udp(String)
        
        public var description: String {
            switch self {
            case .tcp(let name):
                return "_\(name)._tcp"
            case .udp(let name):
                return "_\(name)._udp"
            }
        }
    }
    
}
