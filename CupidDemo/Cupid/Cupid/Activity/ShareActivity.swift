//
//  AnyActivity.swift
//  Cupid
//
//  Created by Shannon Wu on 15/9/11.
//  Copyright © 2015年 36Kr. All rights reserved.
//

import UIKit

/// A template for UIActivity, check UIActivity documentation for more information.
public class ShareActivity: UIActivity {

    /// The type of the activity
    public var type: String
    /// The title of the activity
    public var title: String
    /// The image of the activity
    public var image: UIImage

    /// The content payload of the activity, check the documentation of the service provider for more information
    public var content: Content
    /// The service provider of the activity
    public var serviceProvider: ShareServiceProvider
    /// Actions after completion
    public var completionHandler: ShareCompletionHandler?

    ///  Init a new share activity
    ///
    ///  - parameter type:              type
    ///  - parameter title:             title
    ///  - parameter image:             image
    ///  - parameter content:           content
    ///  - parameter serviceProvider:   service provider
    ///  - parameter completionHandler: completion handler
    public init(type: String, title: String, image: UIImage, content: Content, serviceProvider: ShareServiceProvider, completionHandler: ShareCompletionHandler? = nil) {

        self.type = type
        self.title = title
        self.image = image

        self.content = content
        self.serviceProvider = serviceProvider
        self.completionHandler = completionHandler

        super.init()
    }

    override public class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override public func activityType() -> String? {
        return type
    }

    override public func activityTitle() -> String? {
        return title
    }

    override public func activityImage() -> UIImage? {
        return image
    }

    override public func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return serviceProvider.canShareContent(content)
    }

    override public func performActivity() {
        do {
            try Cupid.shareContent(content, serviceProvider: serviceProvider, completionHandler: completionHandler)
        }
        catch _ {
            activityDidFinish(false)
        }
        activityDidFinish(true)
    }
}
