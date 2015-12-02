//
//  QQServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

///This service provider is used to oauth and share content to QQ, check [this website](http://open.qq.com) to learn more
public class QQServiceProvider: ShareServiceProvider {
    /// Share destination
    public enum Destination: Int {
        // Share to QQ chat session
        case Friends = 0
        // Share to QZone
        case QZone = 1
    }

    static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "mqqapi://"))
    }
    
    /// Always true
    public static var canOAuth: Bool {
        return true
    }
    
    /// True if the app is installed
    public static func canShareContent(content: Content) -> Bool {
        if !QQServiceProvider.appInstalled {
            return false
        }
        
        return true
    }
    
    /// True if the app is installed
    public func canShareContent(content: Content) -> Bool {
        return QQServiceProvider.canShareContent(content)
    }

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    /// App id
    public private(set) var appID: String
    /// Destination to share
    public private(set) var destination: Destination?
    /// Completion handler after share
    public private(set) var shareCompletionHandler: ShareCompletionHandler?
    /// Completion handler after OAuth
    public private(set) var oauthCompletionHandler: NetworkResponseHandler?

    /// Init a new service provider with the given information, if you want to share content, you must provide the share destination.
    public init(appID: String, destination: Destination? = nil) {
        self.appID = appID
        self.destination = destination
    }

    var callBackName: String {
        var hexString = String(format: "%02llx", (appID as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }

        return "QQ" + hexString
    }

    /// Share content to QQ, with a optional completion block
    /// The title of the content is used for the title of the shared message
    /// The description of the content is used for the brief intro of the shared message
    /// The thumbnail of the content is used for the thumbnail of the shared message
    /// The media is the payload of the shared message
    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        self.shareCompletionHandler = completionHandler

        guard QQServiceProvider.canShareContent(content) else {
            throw ShareError.ContentCannotShare
        }

        var qqSchemeURLString = "mqqapi://share/to_fri?"
        if let encodedAppDisplayName = NSBundle.mainBundle().displayName?.base64EncodedString {
            qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
        }
        else {
            throw ShareError.FormattingError
        }

        if let destination = destination {
            qqSchemeURLString += "&version=1&cflag=\(destination.rawValue)"
        }
        else {
            throw ShareError.DestinationNotPointed
        }
        qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
        qqSchemeURLString += "&callback_name=\(callBackName)"
        qqSchemeURLString += "&src_type=app&shareType=0&file_type="

        if let media = content.media {

            func handleNewsWithURL(URL: NSURL, mediaType: String?) throws {
                if let thumbnail = content.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                    let dic = ["previewimagedata": thumbnailData]
                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                }

                qqSchemeURLString += mediaType ?? "news"
                guard let encodedURLString = URL.absoluteString.base64AndURLEncodedString else {
                    throw ShareError.FormattingError
                }

                qqSchemeURLString += "&url=\(encodedURLString)"
            }

            switch media {
                case .URL(let URL):
                    do {
                        try handleNewsWithURL(URL, mediaType: "news")
                    }
                    catch let error {
                        throw error
                    }

                case .Image(let image):
                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        throw ShareError.FormattingError
                    }
                    var dic = ["file_data": imageData, ]
                    if let thumbnail = content.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        dic["previewimagedata"] = thumbnailData
                    }
                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "img"

                case .Audio(let audioURL, _ ):
                    do {
                        try handleNewsWithURL(audioURL, mediaType: "audio")
                    }
                    catch let error {
                        throw error
                    }
                
                case .Video(let URL):
                    do {
                        try handleNewsWithURL(URL, mediaType: nil)
                    }
                    catch let error {
                        throw error
                    }
            }

            if let encodedTitle = content.title?.base64AndURLEncodedString {
                qqSchemeURLString += "&title=\(encodedTitle)"
            }

            if let encodedDescription = content.description?.base64AndURLEncodedString {
                qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
            }

        }
        else {
            qqSchemeURLString += "text&file_data="

            if let encodedDescription = content.description?.base64AndURLEncodedString {
                qqSchemeURLString += "\(encodedDescription)"
            }
        }

        if !URLHandler.openURL(URLString: qqSchemeURLString) {
            throw ShareError.FormattingError
        }
    }

    /// OAuth to QQ, the completion handler cantains the information from Pocket
    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        let scope = "get_user_info"
        if QQServiceProvider.appInstalled {
            guard let appName = NSBundle.mainBundle().displayName else {
                throw ShareError.FormattingError
            }
            let dic = ["app_id": appID, "app_name": appName, "client_id": appID, "response_type": "token", "scope": scope, "sdkp": "i", "sdkv": "2.9", "status_machine": UIDevice.currentDevice().model, "status_os": UIDevice.currentDevice().systemVersion, "status_version": UIDevice.currentDevice().systemVersion]

            let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
            UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

            URLHandler.openURL(URLString: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1")

            return
        } else {
            let accessTokenAPI = "http://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=716027609&pt_3rd_aid=209656&style=35&s_url=http%3A%2F%2Fconnect.qq.com&refer_cgi=m_authorize&client_id=\(appID)&redirect_uri=auth%3A%2F%2Fwww.qq.com&response_type=token&scope=\(scope)"
            
            webviewProvider.addWebViewByURLString(accessTokenAPI)
        }
    }

    /// Handle URL callback for QQ
    public func handleOpenURL(URL: NSURL) -> Bool? {
        // QQ Share
        if URL.scheme.hasPrefix("QQ") {
            guard let error = URL.queryInfo["error"] else {
                return false
            }
            let succeed = (error == "0")

            shareCompletionHandler?(succeed: succeed)
            return succeed
        }

        if URL.scheme.hasPrefix("tencent") {

            var userInfoDictionary: NSDictionary?
            var error: NSError?

            defer {
                oauthCompletionHandler?(userInfoDictionary, nil, error)
            }

            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("com.tencent.tencent\(appID)"), let dic = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary else {
                error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                return false
            }

            guard let result = dic["ret"]?.integerValue where result == 0 else {
                if let errorDomatin = dic["user_cancelled"] as? String where errorDomatin == "YES" {
                    error = NSError(domain: "User Cancelled", code: -2, userInfo: nil)
                }
                else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                }
                return false
            }

            userInfoDictionary = dic

            return true
        }

        // Other
        return nil
    }
}
