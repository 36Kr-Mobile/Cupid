//
//  PasteboardServiceProvider.swift
//  Cupid Demo
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

///this service provider is used to copy content to the system paste board
public class PasteboardServiceProvider: ShareServiceProvider {
    /// Always false
    public static var canOAuth: Bool {
        return false
    }
    
    public static var appInstalled: Bool {
        return true
    }

    /// Always nil
    public let oauthCompletionHandler: NetworkResponseHandler? = nil
    
    /// Init a new paste board service provider
    public init() {}
    
    /// Always true
    public static func canShareContent(content: Content) -> Bool {
        return true
    }

    /// Always true
    public func canShareContent(content: Content) -> Bool {
        return true
    }

    /// The pasteboard's string property is set to the content's title and the content's description
    /// If the media's type is URL, the pasteboard's URL property is set to the URL of the content's media
    /// If the media's type is Image, the pasteboard's image property is set to thhe image of the content's media
    /// If the media's type is Video, the pasteboard's URL property is set to the URL of the content's media
    /// If the media's type is Audio, the pasteboard's URLs property is set to the URLs of the content's media
    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        let pasterBoard = UIPasteboard.generalPasteboard()
        
        pasterBoard.string = "\(content.title ?? "") \(content.description ?? "")"
        
        if let media = content.media {
            switch media {
            case .URL(let URL):
                pasterBoard.URL = URL
            case .Image(let image):
                pasterBoard.image = image
            case .Video(let URL):
                pasterBoard.URL = URL
            case .Audio(audioURL: let audioURL, linkURL: let linkURL):
                if let linkURL = linkURL {
                    pasterBoard.URLs = [audioURL, linkURL]
                } else {
                    pasterBoard.URL = audioURL
                }
            }
        }
        
        completionHandler?(succeed: true)
    }
    
    /// Always throw ShareError.NotSupported
    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        throw ShareError.NotSupported
    }
    
    /// Always returns nil
    public func handleOpenURL(URL: NSURL) -> Bool?  {
        return nil
    }
}
