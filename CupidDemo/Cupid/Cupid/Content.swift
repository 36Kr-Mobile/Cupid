//
//  Content.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

/// Content to for Cupid to share, you must check the documentation of the service provider to learn how to configure the content payload
public struct Content {
    /// The media payload of the content
    public enum Media {
        /// URL media payload, it contains a rawvalue of the URL
        case URL(NSURL)
        /// Image media payload, it contains a rawvalue of UIImage object
        case Image(UIImage)
        /// Audio media payload, it contains a the audio URL and optionally the link URL
        case Audio(audioURL:NSURL, linkURL:NSURL?)
        /// Video media payload, it contains a rawvalue of the URL of the video
        case Video(NSURL)
    }

    /// Te title of the content
    public var title: String? {
        set {
            internalTitle = title
        }
        get {
            return internalTitle ?? ""
        }
    }
    var internalTitle: String?
    
    /// The description of the content
    public var description: String? {
        set {
            internalDescription = description
        }
        get {
            return internalDescription ?? ""
        }
    }
    var internalDescription: String?

    
    /// The thumbnail of the content
    public var thumbnail: UIImage? {
        set {
            internalThumbnail = thumbnail
        }
        get {
            return internalThumbnail?.imageForShare
        }
    }
    var internalThumbnail: UIImage?

    /// The media payload of the content
    public var media: Media?

    ///  Init a new content instance, with designated title, description, thumbnail, media
    public init(title: String?, description: String?, thumbnail: UIImage?, media: Media?) {
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.media = media
    }

    /// Init a new content instance with all values set to nil.
    public init() {}
}