//
//  PocketServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/30/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation

///This service provider is used to oauth and share content to Pocket, check [this website](https://getpocket.com/developer/docs/authentication) to learn more
public class PocketServiceProvider: ShareServiceProvider {

    /// App id of the account
    public private(set) var appID: String
    /// Access token of the account
    public private(set) var accessToken: String?
    var requestToken: String?

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    var shareCompletionHandler: ShareCompletionHandler?
    /// Hanldler after oauth
    public var oauthCompletionHandler: NetworkResponseHandler?

    /// Init a new service provider with the given information, if you want to share content, you must provide the access token.
    public init(appID: String, accessToken: String?) {
        self.appID = appID
        self.accessToken = accessToken
    }
    
    /// Always true
    public static var canOAuth: Bool {
        return true
    }

    /// The content's media type must be URL, or return false
    public static func canShareContent(content: Content) -> Bool {
        guard content.media != nil else {
            return false
        }
        
        switch content.media! {
            case .URL:
                return true
            
            default:
                return false
        }
    }
    
    /// The content's media type must be URL, or return false
    public func canShareContent(content: Content) -> Bool {
        return PocketServiceProvider.canShareContent(content)
    }

    static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "pocket-oauth-v1://"))
    }
    
    /// The content's title is used for the title of the article, and the content media's URL is set to the url of the article
    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        shareCompletionHandler = completionHandler
        
        guard PocketServiceProvider.canShareContent(content) else {
            throw ShareError.ContentCannotShare
        }
        
        guard let accessToken = accessToken else {
            throw ShareError.InternalError
        }
        
        guard let addAPI = NSURL(string: "https://getpocket.com/v3/add") else {
            throw ShareError.FormattingError
        }
        
        
        var parameters = ["consumer_key": appID, "access_token": accessToken]
        let URLString: String
        guard let media = content.media else {
            throw ShareError.ContentCannotShare
        }
        switch media {
        case .URL(let url):
            URLString = url.absoluteString
        default:
            throw ShareError.ContentCannotShare
        }
        
        parameters["url"] = URLString
        if let title = content.title {
            parameters["title"] = title
        }
        Cupid.networkingProvier.request(addAPI, method: .POST, parameters: parameters) {
            (dict, response, error) -> Void in
            if error != nil {
                self.shareCompletionHandler?(succeed: false)
            }
            else {
                self.shareCompletionHandler?(succeed: true)
            }
        }
    }

    /// OAuth to Pocket, the completion handler cantains the information from Pocket
    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        guard let startIndex = appID.rangeOfString("-")?.startIndex else {
            throw ShareError.InternalError
        }

        let prefix = appID.substringToIndex(startIndex)
        guard let requestAPI = NSURL(string: "https://getpocket.com/v3/oauth/request") else {
            throw ShareError.FormattingError
        }
        let redirectURLString = "pocketapp\(prefix):authorizationFinished"

        let parameters = ["consumer_key": appID, "redirect_uri": redirectURLString]
        Cupid.networkingProvier.request(requestAPI, method: .POST, parameters: parameters) {
            (dictionary, response, error) -> Void in

            guard let requestToken = dictionary?["code"] as? String else {
                return
            }
            self.requestToken = requestToken

            if PocketServiceProvider.appInstalled {
                let requestTokenAPI = "pocket-oauth-v1:///authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
                URLHandler.openURL(URLString: requestTokenAPI)
                return
            } else {
                let requestTokenAPI = "https://getpocket.com/auth/authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
                dispatch_async(dispatch_get_main_queue()) {
                    self.webviewProvider.addWebViewByURLString(requestTokenAPI, flagCode: requestToken)
                }
            }
        }

    }
    
    /// Handle URL callback for Pocket
    public func handleOpenURL(URL: NSURL) -> Bool? {
        if URL.scheme.hasPrefix("pocketapp") {
            guard let accessTokenAPI = NSURL(string: "https://getpocket.com/v3/oauth/authorize") else {
                return true
            }
            
            guard let requestToken = requestToken else {
                return true
            }
            
            let parameters = ["consumer_key": self.appID, "code": requestToken]
            Cupid.networkingProvier.request(accessTokenAPI, method: .POST, parameters: parameters) {
                (dictionary, response, error) -> Void in
                self.oauthCompletionHandler?(dictionary, response, error)
            }
            return true
        }
        
        return nil
    }
}