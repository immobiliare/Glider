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

public final class AsyncURLRequestOperation: AsyncOperation {
    public typealias Response = Result<Data, Error>
    typealias Callback = ((Response) -> Void)

    // MARK: - Internal Properties
    
    /// Callback to call when operastion did finish.
    internal var onComplete: Callback?
    
    // MARK: - Private Properties
    
    /// Request to execute.
    private var request: HTTPTransportRequest
    
    /// Transport associated.
    private weak var transport: HTTPTransport?
    
    // MARK: - Initialization
    
    /// Initialize a new operation with a request.
    ///
    /// - Parameters:
    ///   - request: URLRequest to execute.
    ///   - transport: parent transport layer.
    internal init(request: HTTPTransportRequest, transport: HTTPTransport) {
        self.request = request
        self.transport = transport
    }
    
    // MARK: - Overrides
    
    public override func asyncStart() {
        request.onComplete = { [weak self] result in
            self?.onComplete?(result)
            self?.asyncFinish()
        }
        transport?.configuration.session.execute(request)
    }
    
}
