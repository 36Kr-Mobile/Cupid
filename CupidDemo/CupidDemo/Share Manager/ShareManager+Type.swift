//
//  ShareManager+Type.swift
//  China
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation
import Cupid

/// Extension to manager differenct third party platforms.
extension ShareManager {
    /// Share Destination
    enum Destination {
        case Weibo
        case QQ
        case Alipay
        case WechatTimeline
        case WechatSession
        case Pasteboard
        
        var serviceProviderType: ShareServiceProvider.Type {
            let serviceProvierClass: ShareServiceProvider.Type
            switch self {
            case .QQ:
                serviceProvierClass = QQServiceProvider.self
            case .Alipay:
                serviceProvierClass = AlipayServiceProvider.self
            case .WechatSession,
            .WechatTimeline:
                serviceProvierClass = WeChatServiceProvier.self
                
            case .Weibo:
                serviceProvierClass = WeiboServiceProvier.self
                
            case .Pasteboard:
                serviceProvierClass = PasteboardServiceProvider.self
            }
            
            return serviceProvierClass
        }
        
        var serviceProvider: ShareServiceProvider {
            let serviceProvider: ShareServiceProvider
            
            switch self {
            case .QQ:
                serviceProvider = QQServiceProvider(appID: ShareManager.QQ.appID, destination: .Friends)
                
            case .Alipay:
                serviceProvider = AlipayServiceProvider(appKey: ShareManager.Alipay.appKey)
                
            case .WechatSession:
                serviceProvider = WeChatServiceProvier(appID: ShareManager.Wechat.appID, appKey: Wechat.appKey, destination: .Session)
                
            case .WechatTimeline:
                serviceProvider = WeChatServiceProvier(appID: ShareManager.Wechat.appID, appKey: Wechat.appKey, destination: .Timeline)
                
            case .Weibo:
                serviceProvider = WeiboServiceProvier(appID: ShareManager.Weibo.appID, appKey: ShareManager.Weibo.appKey, redirectURL: ShareManager.Weibo.redirectURL)
                
            case .Pasteboard:
                serviceProvider = PasteboardServiceProvider()
            }
            
            return serviceProvider
        }
    }
    
    enum OAuthType {
        case QQ
        case Wechat
        case Weibo
        
        var serviceProvider: ShareServiceProvider {
            switch self {
            case .QQ:
                return Destination.QQ.serviceProvider
            case .Wechat:
                return Destination.WechatTimeline.serviceProvider
            case .Weibo:
                return Destination.Weibo.serviceProvider
            }
        }
        
        var serviceProviderType: ShareServiceProvider.Type {
            switch self {
            case .QQ:
                return Destination.QQ.serviceProviderType
            case .Wechat:
                return Destination.WechatTimeline.serviceProviderType
            case .Weibo:
                return Destination.Weibo.serviceProviderType
            }
        }
    }
    
    enum OAuthResponse {
        case Tencent(accessToken: String, openID: String)
        case Weibo(accessToken: String)
    }
    
    /// QQ configuration information
    struct QQ {
        static let appID = "1104999026"
        static let appKey = "BLeQhlFDONwyoKs2"
    }
    
    /// Weibo Configuration information
    struct Weibo {
        static let appID = "4005151997"
        static let appKey = "11c2cb5cd5a3c347744a8eb808ede882"
        static let redirectURL = "http://weibo.com/igenuis/home?wvr=5&lf=reg"
    }
    
    /// Wechat configuration information
    struct Wechat {
        static let appID = "wx4868b35061f87885"
        static let appKey = "64020361b8ec4c99936c0e3999a9f249"
    }
    
    /// Alipay configuration information
    struct Alipay {
        static let appKey = "xxxxxxxxxxxxxxxx"
    }
}
