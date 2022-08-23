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

// MARK: - Formats

extension String {
    
    /// Apply privacy scope.
    ///
    /// - Parameter privacy: privacy scope.
    /// - Returns: String
    internal func privacy(_ privacy: LogPrivacy?) -> String {
        guard let privacy = privacy else {
            return self
        }

        #if DEBUG
        if GliderSDK.shared.disablePrivacyRedaction {
            return String(describing: self)
        }
        #endif
        
        switch privacy {
        case .public:
            return String(describing: self)
            
        case .private(mask: .hash):
            return "\(String(describing: self).hash)"
            
        case .private(mask: .partiallyHide):
            var hiddenString = self
            let charsToHide = Int(Double(hiddenString.count) * 0.35)
            let endIndex = index(hiddenString.startIndex, offsetBy: charsToHide)
            hiddenString.replaceSubrange(...endIndex, with: String(repeating: "*", count: charsToHide))
            return hiddenString
            
        default:
            return LogPrivacy.redacted
        }
    }
    
}

extension Bool {
    
    internal func format(_ format: LogBoolFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }

        switch format {
        case .answer:
            return (self ? "yes": "no")
        case .truth:
            return (self ? "true": "false")
        case .numeric:
            return (self ? "1" : "0")
        }
    }
    
}

extension Double {
    
    internal static func format(value: NSNumber, _ format: LogDoubleFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .fixed(let precision):
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = precision
            formatter.decimalSeparator = "."
            formatter.groupingSeparator = ""
            return (formatter.string(from: value) ?? "").removeGroupingSeparatorAndUseDotDecimal()
            
        case .formatter(let formatter):
            return formatter.string(for: value) ?? ""
            
        case .measure(let unit, let options, let style):
            let formatter = MeasurementFormatter()
            formatter.unitOptions = options
            formatter.unitStyle = style
            formatter.locale = GliderSDK.shared.locale
            return formatter.string(from: .init(value: value.doubleValue, unit: unit)).removeGroupingSeparatorAndUseDotDecimal()
            
        case .bytes(let style):
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = .useAll
            formatter.includesUnit = true
            formatter.isAdaptive = true
            formatter.countStyle = style
            return formatter.string(from: .init(value: value.doubleValue, unit: .bytes)).removeGroupingSeparatorAndUseDotDecimal()
            
        case .currency(let symbol, let usesGroupingSeparator):
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.currencyDecimalSeparator = "."
            currencyFormatter.currencyGroupingSeparator = ""
            if let symbol = symbol {
                currencyFormatter.currencySymbol = symbol
            }
            currencyFormatter.usesGroupingSeparator = usesGroupingSeparator
            currencyFormatter.locale = GliderSDK.shared.locale
            return (currencyFormatter.string(from: value) ?? "").removeGroupingSeparatorAndUseDotDecimal()
            
        }
    }
    
}

extension String {
    
    fileprivate func removeGroupingSeparatorAndUseDotDecimal() -> String {
        return self.replacingOccurrences(of: ",", with: ".")
    }
    
}

extension Date {
    
    internal func format(_ format: LogDateFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: self)
            
        case let .custom(format, locale):
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = format
            return formatter.string(from: self)
            
        }
    }
    
}

extension Int {
    
    internal static func format(value: NSNumber, _ format: LogIntegerFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .decimal(let minDigits, let maxDigits):
            let formatter = NumberFormatter()
            
            if let minDigits = minDigits {
                formatter.minimumIntegerDigits = minDigits
            }
            
            if let maxDigits = maxDigits {
                formatter.maximumIntegerDigits = maxDigits
            }
            
            return formatter.string(from: value) ?? ""
            
        case .formatter(let formatter):
            return formatter.string(from: value) ?? ""

        }
    }
    
}
