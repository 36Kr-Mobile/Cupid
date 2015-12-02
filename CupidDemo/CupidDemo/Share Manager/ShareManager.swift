//
//  ShareManager.swift
//  China
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation
import Cupid

/// For reference outside this file
typealias ShareContent = Content

struct ShareManager {
    /// Check if possible to share content to the desired destination
    static func canShareContent(content: ShareContent, to destination: Destination) -> Bool {

        return destination.serviceProviderType.canShareContent(content)
    }
    
    static func canOAuthTo(type type: OAuthType) -> Bool {
        return type.serviceProviderType.canOAuth
    }
    
    static func shareContent(content: ShareContent,
                             to destination: Destination,
                             succeed successBlock: (Void -> Void),
                             failed failBlock: (Void -> Void)) {
        do {
            try Cupid.shareContent(content, serviceProvider: destination.serviceProvider) {
                succeed in
                if succeed {
                    successBlock()
                } else {
                    failBlock()
                }
            }
        }
        catch _ {
            // maybe log error in formal environment
            failBlock()
        }
    }
    
    static func OAuth(type: OAuthType,
                succeeded successBlock: ((response:OAuthResponse) -> Void),
                failed failBlock: ((errorMessage:String?) -> Void)) {
                
        let serviceProvider = type.serviceProvider
        do {
            try Cupid.OAuth(serviceProvider) {
                (OAuthInfo, URLResonse, error) -> Void in
                switch type {
                case .QQ,
                .Wechat:
                    if let accessToken = OAuthInfo?["access_token"] as? String,
                        openID = OAuthInfo?["openid"] as? String {
                            successBlock(response: .Tencent(accessToken: accessToken, openID: openID))
                    } else {
                        failBlock(errorMessage: NSLocalizedString("第三方认证登陆失败,请重试或登陆36氪账号", comment: ""))
                    }
                case .Weibo:
                    if let accessToken = OAuthInfo?["accessToken"] as? String {
                        successBlock(response: .Weibo(accessToken: accessToken))
                    } else {
                        failBlock(errorMessage: NSLocalizedString("微博认证登陆失败,请重试或登陆36氪账号", comment: ""))
                    }
                }
            }
        }
        catch _ {
            // maybe log error in formal environment
            failBlock(errorMessage: NSLocalizedString("第三方认证登陆失败,请重试或登陆36氪账号", comment: ""))
        }
    }
    
    static func handleOpenURL(url: NSURL) -> Bool? {
        return Cupid.handleOpenURL(url)
    }
}
