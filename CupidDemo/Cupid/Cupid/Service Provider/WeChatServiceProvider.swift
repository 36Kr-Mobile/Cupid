//
//  WeChatServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

///This service provider is used to oauth and share content to WeChat, check [this website](https://open.weixin.qq.com) to learn more
public class WeChatServiceProvier: ShareServiceProvider {
    /// Share destination
    public enum Destination: Int {
        /// Share to chat session
        case Session = 0
        /// Share to moments
        case Timeline = 1
    }

    static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "weixin://"))
    }
    
    /// True if app is installed
    public static var canOAuth: Bool {
        return appInstalled
    }
    

    /// App id
    public private(set) var appID: String
    /// App key
    public private(set) var appKey: String?
    /// Destination to share
    public private(set) var destination: Destination?
    /// Completion handler after share
    public private(set) var shareCompletionHandler: ShareCompletionHandler?
    /// Completion handler after OAuth
    public private(set) var oauthCompletionHandler: NetworkResponseHandler?

    /// Init a new service provider with the given information, if you want to share content, you must provide the share destination.
    public init(appID: String, appKey: String?, destination: Destination? = nil) {
        self.appID = appID
        self.appKey = appKey
        self.destination = destination
    }

    /// True if app is installed
    public static func canShareContent(content: Content) -> Bool {
        return appInstalled
    }
    
    /// True if app is installed
    public func canShareContent(content: Content) -> Bool {
        return WeChatServiceProvier.canShareContent(content)
    }

    /// Share content to WeChat, with a optional completion block
    /// The title of the content is used for the title of the shared message
    /// The description of the content is used for the brief intro of the shared message
    /// The thumbnail of the content is used for the thumbnail of the shared message
    /// The media is the payload of the shared message
    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        self.shareCompletionHandler = completionHandler

        guard WeChatServiceProvier.canShareContent(content) else {
            throw ShareError.ContentCannotShare
        }

        var weChatMessageInfo: [String:AnyObject]
        if let destination = destination {
            weChatMessageInfo = ["result": "1", "returnFromApp": "0", "scene": destination.rawValue, "sdkver": "1.5", "command": "1010", ]
        }
        else {
            throw ShareError.DestinationNotPointed
        }

        if let title = content.title {
            weChatMessageInfo["title"] = title
        }

        if let description = content.description {
            weChatMessageInfo["description"] = description
        }

        if let thumbnailImage = content.thumbnail,
           let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.5) {
            weChatMessageInfo["thumbData"] = thumbnailData
        }

        if let media = content.media {
            switch media {
                case .URL(let URL):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString

                case .Image(let image):
                    weChatMessageInfo["objectType"] = "2"

                    if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                        weChatMessageInfo["fileData"] = fileImageData
                    }

                case .Audio(let audioURL, let linkURL):
                    weChatMessageInfo["objectType"] = "3"

                    if let linkURL = linkURL {
                        weChatMessageInfo["mediaUrl"] = linkURL.absoluteString
                    }

                    weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString

                case .Video(let URL):
                    weChatMessageInfo["objectType"] = "4"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString
            }

        }
        else {
            weChatMessageInfo["command"] = "1020"
        }

        let weChatMessage = [appID: weChatMessageInfo]

        guard let data = try? NSPropertyListSerialization.dataWithPropertyList(weChatMessage, format: .BinaryFormat_v1_0, options: 0) else {
            throw ShareError.FormattingError
        }

        UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "content")

        let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"

        if !URLHandler.openURL(URLString: weChatSchemeURLString) {
            throw ShareError.FormattingError
        }
    }

    /// OAuth to Wechat, the completion handler cantains the information from Wechat
    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        guard WeChatServiceProvier.appInstalled else {
            throw ShareError.AppNotInstalled
        }

        let scope = "snsapi_userinfo"
        URLHandler.openURL(URLString: "weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth")
    }

    func fetchWeChatOAuthInfoByCode(code code: String, completionHandler: NetworkResponseHandler) {
        guard let key = appKey else {
            completionHandler(["code": code], nil, nil)
            return
        }

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + key
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        Cupid.networkingProvier.request(accessTokenAPI, method: CupidNetworkingMethod.GET, parameters: nil) {
            (OAuthJSON, response, error) -> Void in
            completionHandler(OAuthJSON, response, error)
        }
    }

    /// Handle URL callback for Wechat
    public func handleOpenURL(URL: NSURL) -> Bool? {
        if URL.scheme.hasPrefix("wx") {
            // WeChat OAuth
            if URL.absoluteString.containsString("&state=Weixinauth") {
                let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)

                guard let items = components?.queryItems else {
                    return false
                }

                var infos = [String: AnyObject]()
                items.forEach {
                    infos[$0.name] = $0.value
                }

                guard let code = infos["code"] as? String else {
                    return false
                }

                // Login Succcess
                fetchWeChatOAuthInfoByCode(code: code) {
                    (info, response, error) -> Void in
                    self.oauthCompletionHandler?(info, response, error)
                }
                return true
            }

            // WeChat Share
            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") else {
                return false
            }

            if let dic = try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil) {
                if let dic = dic[appID] as? NSDictionary,
                       result = dic["result"]?.integerValue {
                        let succeed = (result == 0)
                        shareCompletionHandler?(succeed: succeed)
                        return succeed
                }
            }
        }

        // Other
        return nil
    }
}
