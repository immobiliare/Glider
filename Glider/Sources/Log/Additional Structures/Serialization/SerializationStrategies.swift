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

// MARK: - SerializationStrategies

/// Defines the strategies used to serialize data based upon their type.
public struct SerializationStrategies: Codable {
    
    /// Serialization strategy for images.
    public var images: Image = Image()
    
}

// MARK: - SerializationStrategies.Image

extension SerializationStrategies {
    
    /// The encoding strategy for images.
    public struct Image: Codable {
        
        /// Format of the image.
        /// - `png`: png format.
        /// - `jpg`: jpg format.
        public enum Format: Codable {
            case png
            case jpg(quality: Float)
        }
        
        /// Format of the image.
        public let format: Format
        
        /// Maximum size of the image sent, length or width.
        /// When no set data is sent in the original format
        /// (keep in mind: heavy data can lead problems)
        public let maxDimension: Float?
        
        // MARK: - Initialization
        
        /// Initialize the encoding strategy used to serialize images.
        ///
        /// - Parameters:
        ///   - format: encoding format for image. By default is JPG with 85% of the quality.
        ///   - maxDimension: maximum dimension of the images; by default is set to 600.
        public init(_ format: Format = .jpg(quality: 0.85), maxDimension: Float? = 600) {
            self.format = format
            self.maxDimension = maxDimension
        }
        
    }
    
}
