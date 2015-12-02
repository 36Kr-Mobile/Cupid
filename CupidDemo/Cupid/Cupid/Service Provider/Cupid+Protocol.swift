//
//  ShareServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation

/// Callback after share, true if content is shared, false if content is not shared successfully
public typealias ShareCompletionHandler = (succeed:Bool) -> Void
/// Callback after network request finshed
public typealias NetworkResponseHandler = (NSDictionary?, NSURLResponse?, NSError?) -> Void

public protocol ShareServiceProvider: class {
    /// check if can OAuth right now
    static var canOAuth: Bool { get }
    /// Used to check if the content is sharable
    static func canShareContent(content: Content) -> Bool
    func canShareContent(content: Content) -> Bool

    /// Used for OAuth callback
    var oauthCompletionHandler: NetworkResponseHandler? { get }
    /// Share content to service provider
    func shareContent(content: Content, completionHandler: ShareCompletionHandler?) throws
    /// OAuth
    func OAuth(completionHandler: NetworkResponseHandler) throws
    /// Callback after share or OAuth
    func handleOpenURL(URL: NSURL) -> Bool?
}

/// Errors thrown in OAuth or share process
public enum ShareError: ErrorType {
    /// Cannot share content
    case ContentCannotShare
    /// Cannot format the data successfully
    case FormattingError
    /// Service provider is not configured correctly.
    case InternalError
    /// Service destination is not configured.
    case DestinationNotPointed
    /// Host app is not installed, and cannot OAuth through web view
    case AppNotInstalled
    /// Service provider does not support this function
    case NotSupported
}

/// The netowrking methods needed for Cupid
public enum CupidNetworkingMethod: String {
    case GET = "GET"
    case POST = "POST"
}

/// The networking provider
public protocol CupidNetworkingProvider {
    /// Send network request with URL string
    func request(URLString: String, method: CupidNetworkingMethod, parameters: [String:AnyObject]?, completionHandler: NetworkResponseHandler)
    /// Send network request with URL
    func request(URL: NSURL, method: CupidNetworkingMethod, parameters: [String:AnyObject]?, completionHandler: NetworkResponseHandler)
    /// Used for uploading
    func upload(URL: NSURL, parameters: [String:AnyObject], completionHandler: NetworkResponseHandler)
}