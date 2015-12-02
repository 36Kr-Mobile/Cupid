//
//  AlipayServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation
import Cupid

class AlipayServiceProvider: ShareServiceProvider {
    var appKey: String
    private var shareCompletionHandler: ShareCompletionHandler?
    var oauthCompletionHandler: NetworkResponseHandler?
    
    lazy var alipayDelegate: APOpenAPIDelegate = {
        let delegate = AlipayDelegate()
        delegate.alipayServiceProvider = self
        return delegate
    }()

    init(appKey: String) {
        self.appKey = appKey
        APOpenAPI.registerApp(ShareManager.Alipay.appKey)
    }
    
    private static var appInstalled: Bool {
        return APOpenAPI.isAPAppInstalled() && APOpenAPI.isAPAppSupportOpenApi()
    }
    
    static var canOAuth: Bool {
        return false
    }

    static func canShareContent(content: Content) -> Bool {
        return appInstalled
    }
    
    func canShareContent(content: Content) -> Bool {
        return AlipayServiceProvider.canShareContent(content)
    }

    func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        guard canShareContent(content) else {
            throw ShareError.ContentCannotShare
        }

        self.shareCompletionHandler = completionHandler

        let message = APMediaMessage()
        message.title = content.title ?? ""
        message.desc = content.description ?? ""
        if let thumbnail = content.thumbnail {
            message.thumbData = UIImagePNGRepresentation(thumbnail)
        }
        
        func share(message : APMediaMessage) {
            let req = APSendMessageToAPReq()
            req.message = message
            if !APOpenAPI.sendReq(req) {
                completionHandler?(succeed: false)
            }
        }
        
        guard let media = content.media else {
            return share(message)
        }
        switch media {
        case .URL(let url):
            let obj = APShareWebObject()
            obj.wepageUrl = url.absoluteString
            message.mediaObject = obj
        case .Image(let image):
            let obj = APShareImageObject()
            obj.imageData = UIImagePNGRepresentation(image)
            message.mediaObject = obj
        case .Audio(audioURL: let audioURL, linkURL: let linkURL):
            let obj = APShareTextObject()
            obj.text = "\(audioURL) \(linkURL ?? "")"
            message.mediaObject = obj
        case .Video(let URL):
            let obj = APShareTextObject()
            obj.text = "\(URL)"
            message.mediaObject = obj
        }
        share(message)
    }
    
    
    func OAuth(completionHandler: NetworkResponseHandler) throws {
        throw ShareError.NotSupported
    }
    
    func handleOpenURL(URL: NSURL) -> Bool? {
        if URL.scheme.hasPrefix("ap") {
            return APOpenAPI.handleOpenURL(URL, delegate: alipayDelegate)
        } else {
            return nil
        }
    }
    
}

class AlipayDelegate: NSObject, APOpenAPIDelegate {
    var alipayServiceProvider: AlipayServiceProvider?
    
    func onReq(req: APBaseReq!) {}
    
    func onResp(resp: APBaseResp!) {
        alipayServiceProvider?.shareCompletionHandler?(succeed: (resp.errCode == APSuccess.rawValue))
    }
}