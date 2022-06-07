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

/// This class allows subclasses in order to make an async Operation.
public class AsyncOperation: Operation {
    
    /// Identifier of the operation.
    var identifier: String {
        return self.name ?? String(describing: self)
    }
    
    public override func start() {
        // Apple's docs say not to call super here.
        guard !isCancelled else {
            asyncFinish()
            return
        }
        
        setIsExecutingWithKVO(value: true)
        asyncStart()
    }
    
    /// Override this (no need to call super) to start your code.
    func asyncStart() {}
    
    /// Call this when you're done.
    func asyncFinish() {
        setIsExecutingWithKVO(value: false)
        setIsFinishedWithKVO(value: true)
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: KVO helpers.
    
    // Cannot simply override the existing named fields because
    // they are get-only and we need KVO.
    private var myFinished = false
    private var myExecuting = false
    
    public override var isFinished: Bool {
        return myFinished
    }
    
    public override var isExecuting: Bool {
        return myExecuting
    }
    
    func setIsFinishedWithKVO(value: Bool) {
        willChangeValue(forKey: "isFinished")
        myFinished = value
        didChangeValue(forKey: "isFinished")
    }

    func setIsExecutingWithKVO(value: Bool) {
        willChangeValue(forKey: "isExecuting")
        myExecuting = value
        didChangeValue(forKey: "isExecuting")
    }
    
}
