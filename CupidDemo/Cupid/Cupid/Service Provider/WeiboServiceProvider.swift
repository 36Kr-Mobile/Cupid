//
//  WeiboServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

///This service provider is used to oauth and share content to Weibo, check [this website](http://open.weibo.com) to learn more
public class WeiboServiceProvier: ShareServiceProvider {
    public static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "weibosdk://request"))
    }
    
    /// Always true
    public static var canOAuth: Bool {
        return true
    }

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    /// App id
    public private(set) var appID: String
    /// App key
    public private(set) var appKey: String
    /// Access token
    public private(set) var accessToken: String?
    /// Redirect URL
    public private(set) var redirectURL: String
    /// Completion handler after share
    public private(set) var shareCompletionHandler: ShareCompletionHandler?
    /// Completion handler after OAuth
    public private(set) var oauthCompletionHandler: NetworkResponseHandler?

    /// Init a new service provider with the given information, if you want to share content, you must provide the access token.
    public init(appID: String, appKey: String, redirectURL: String, accessToken: String? = nil) {
        self.appID = appID
        self.appKey = appKey
        self.redirectURL = redirectURL
        self.accessToken = accessToken
    }

    /// False if both the content's description and media payload are nil, this will open Weibo but return immediately
    public static func canShareContent(content: Content) -> Bool {
        if (content.description == nil && content.media == nil) {
            return false
        }
        
        if let media = content.media {
            switch media {
            case .Audio,
                 .Video:
            return false
            default:
            return true
            }
        }
        
        return true
    }
    
    /// False if both the content's description and media payload are nil, this will open Weibo but return immediately
    public func canShareContent(content: Content) -> Bool {
        return WeiboServiceProvier.canShareContent(content)
    }

    /// Share content to WeChat, with a optional completion block
    /// The title of the content is used for the title of the shared message
    /// The description of the content is used for the placehodler text of the shared message
    /// The thumbnail of the content is used for the thumbnail of the shared message
    /// The media is the payload of the shared message, audio and video is not supported right now
    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        self.shareCompletionHandler = completionHandler

        guard WeiboServiceProvier.canShareContent(content) else {
            throw ShareError.ContentCannotShare
        }

        guard !URLHandler.canOpenURL(NSURL(string: "weibosdk://request")) else {
            var messageInfo: [String:AnyObject] = ["__class": "WBMessageObject"]

            if let title = content.title {
                messageInfo["text"] = title
            }

            if let media = content.media {
                switch media {
                    case .URL(let URL):
                        var mediaObject: [String:AnyObject] = ["__class": "WBWebpageObject", "objectID": "identifier1"]

                        if let desc = content.description {
                            mediaObject["title"] = desc
                        }

                        if let thumbnailImage = content.thumbnail, let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                            mediaObject["thumbnailData"] = thumbnailData
                        }

                        mediaObject["webpageUrl"] = URL.absoluteString

                        messageInfo["mediaObject"] = mediaObject

                    case .Image(let image):
                        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                            messageInfo["imageObject"] = ["imageData": imageData]
                        }

                    case .Audio:
                        throw ShareError.ContentCannotShare

                    case .Video:
                        throw ShareError.ContentCannotShare
                }
            }

            let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            let dict = ["__class": "WBSendMessageToWeiboRequest", "message": messageInfo, "requestID": uuIDString]

            let messageData: [AnyObject] = [["transferObject": NSKeyedArchiver.archivedDataWithRootObject(dict)], ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().bundleID ?? ""])]]

            UIPasteboard.generalPasteboard().items = messageData

            if !URLHandler.openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000") {
                throw ShareError.FormattingError
            }

            return
        }

        // Web Share

        var parameters = [String: AnyObject]()

        guard let accessToken = accessToken else {
            throw ShareError.InternalError
        }

        parameters["access_token"] = accessToken

        var statusText = ""

        if let title = content.title {
            statusText += title
        }

        if let description = content.description {
            statusText += description
        }

        var mediaType = Content.Media.URL(NSURL())

        if let media = content.media {

            switch media {

                case .URL(let URL):

                    statusText += URL.absoluteString

                    mediaType = Content.Media.URL(URL)

                case .Image(let image):

                    guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                        ShareError.FormattingError
                        return
                    }

                    parameters["pic"] = imageData
                    mediaType = Content.Media.Image(image)

                case .Audio:
                    ShareError.ContentCannotShare

                case .Video:
                    ShareError.ContentCannotShare
            }
        }

        parameters["status"] = statusText

        switch mediaType {

            case .URL(_ ):
                let URLString = "https://api.weibo.com/2/statuses/update.json"
                Cupid.networkingProvier.request(URLString, method: .POST, parameters: parameters) {
                    (responseData, HTTPResponse, error) -> Void in if let JSON = responseData, let _ = JSON["idstr"] as? String {
                        completionHandler?(succeed: true)
                    }
                    else {
                        completionHandler?(succeed: false)
                    }
                }

            case .Image(_ ):
                let URLString = "https://upload.api.weibo.com/2/statuses/upload.json"
                guard let URL = NSURL(string: URLString) else {
                    ShareError.FormattingError
                    return
                }

                Cupid.networkingProvier.upload(URL, parameters: parameters) {
                    (responseData, HTTPResponse, error) -> Void in if let JSON = responseData, let _ = JSON["idstr"] as? String {
                        completionHandler?(succeed: true)
                    }
                    else {
                        completionHandler?(succeed: false)
                    }
                }
            
            case .Audio:
                ShareError.ContentCannotShare

            case .Video:
                ShareError.ContentCannotShare
        }
    }

    /// OAuth to Wechat, the completion handler cantains the information from Weibo
    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        self.oauthCompletionHandler = completionHandler

        let scope = "all"
        
        guard !WeiboServiceProvier.appInstalled else {
            let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            let authData = [["transferObject": NSKeyedArchiver.archivedDataWithRootObject(["__class": "WBAuthorizeRequest", "redirectURI": redirectURL, "requestID": uuIDString, "scope": scope])], ["userInfo": NSKeyedArchiver.archivedDataWithRootObject(["mykey": "as you like", "SSO_From": "SendMessageToWeiboViewController"])], ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().bundleID ?? "", "name": NSBundle.mainBundle().displayName ?? ""])]]

            UIPasteboard.generalPasteboard().items = authData
            URLHandler.openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000")
            return
        }

        let accessTokenAPI = "https://open.weibo.cn/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"
        webviewProvider.addWebViewByURLString(accessTokenAPI)
    }

    /// Handle URL callback for Weibo
    public func handleOpenURL(URL: NSURL) -> Bool? {
        if URL.scheme.hasPrefix("wb") {
            guard let items = UIPasteboard.generalPasteboard().items as? [[String:AnyObject]] else {
                return false
            }

            var results = [String: AnyObject]()

            for item in items {
                for (key, value) in item {
                    if let valueData = value as? NSData where key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObjectWithData(valueData)
                    }
                }
            }

            guard let responseData = results["transferObject"] as? [String:AnyObject], let type = responseData["__class"] as? String else {
                return false
            }

            guard let statusCode = responseData["statusCode"] as? Int else {
                return false
            }

            switch type {

                case "WBAuthorizeResponse":
                    var userInfoDictionary: NSDictionary?
                    var error: NSError?

                    defer {
                        oauthCompletionHandler?(responseData, nil, error)
                    }

                    userInfoDictionary = responseData

                    if statusCode != 0 {
                        error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                        return false
                    }
                    return true

                case "WBSendMessageToWeiboResponse":
                    let succeed = (statusCode == 0)
                    shareCompletionHandler?(succeed: succeed)

                    return succeed
                default:
                    return false
            }

        }

        // Other
        return nil
    }

}