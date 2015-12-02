//
//  Cupid.swift
//  Cupid
//
//  Created by Shannon Wu on 15/9/11.
//  Copyright © 2015年 36Kr. All rights reserved.
//

import UIKit

/// A central hub for share and OAuth
public struct Cupid {
    static var serviceProvider: ShareServiceProvider?
    static var intenalNetworkingProvider: CupidNetworkingProvider?
    /// Networking provider for request, if you don't specify your own, default will be used.
    public static var networkingProvier: CupidNetworkingProvider {
        set {
            intenalNetworkingProvider = networkingProvier
        }
        
        get {
            if let networkingProvider = intenalNetworkingProvider {
                return networkingProvider
            } else {
                return SimpleNetworking.sharedInstance
            }
        }
    }

    ///  Share content to service provider
    ///
    ///  - parameter content:           the content to share
    ///  - parameter serviceProvider:   the service provider
    ///  - parameter completionHandler: actions after completion, default to nil
    ///
    ///  - throws: errors may occur in share process
    public static func shareContent(content: Content, serviceProvider: ShareServiceProvider, completionHandler: ShareCompletionHandler? = nil) throws {
        self.serviceProvider = serviceProvider

        func completionHandlerCleaner(succeed: Bool) {
            completionHandler?(succeed: succeed)
            Cupid.serviceProvider = nil
        }

        do {
            try serviceProvider.shareContent(content, completionHandler: completionHandlerCleaner)
        }
        catch let error {
            Cupid.serviceProvider = nil
            throw error
        }
    }

    ///  OAuth to service provider
    ///
    ///  - parameter serviceProvider:   the service provider used for OAuth
    ///  - parameter completionHandler: actions after OAuth completion
    ///
    ///  - throws: errors may occur in OAuth process
    public static func OAuth(serviceProvider: ShareServiceProvider, completionHandler: NetworkResponseHandler) throws {
        self.serviceProvider = serviceProvider

        func completionHandlerCleaner(dictionary: NSDictionary?, response: NSURLResponse?, error: NSError?) {
            completionHandler(dictionary, response, error)
            Cupid.serviceProvider = nil
        }

        do {
            try serviceProvider.OAuth(completionHandler)
        }
        catch let error {
            Cupid.serviceProvider = nil
            throw error
        }
    }

    ///  Handle URL realted to Cupid, you must call this method to check the callbacks.
    ///
    ///  - parameter URL: the URL of the callback
    ///
    ///  - returns: nil if the URL is not for Cupid, true for success, false for fail
    public static func handleOpenURL(URL: NSURL) -> Bool? {
        if let serviceProvider = serviceProvider {
            return serviceProvider.handleOpenURL(URL)
        }
        else {
            return false
        }
    }

}
