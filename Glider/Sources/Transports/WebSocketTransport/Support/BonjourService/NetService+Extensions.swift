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

internal extension NetService {
    
    class func dictionary(fromTXTRecord data: Data) -> [String: String] {
        return NetService.dictionary(fromTXTRecord: data).mapValues { data in
            String(data: data, encoding: .utf8) ?? ""
        }
    }

    class func data(fromTXTRecord data: [String: String]) -> Data {
        return NetService.data(fromTXTRecord: data.mapValues { $0.data(using: .utf8) ?? Data() })
    }

    func setTXTRecord(dictionary: [String: String]?) {
        guard let dictionary = dictionary else {
            self.setTXTRecord(nil)
            return
        }
        self.setTXTRecord(NetService.data(fromTXTRecord: dictionary))
    }

    var txtRecordDictionary: [String: String]? {
        guard let data = self.txtRecordData() else { return nil }
        return NetService.dictionary(fromTXTRecord: data)
    }
    
}
