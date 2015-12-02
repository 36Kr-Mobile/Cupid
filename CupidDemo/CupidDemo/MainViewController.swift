//
//  MainViewController.swift
//  Cupid Demo
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    // Types
    struct Media {
        static let URL = ShareContent.Media.URL(NSURL(string: "http://www.36kr.com")!)
        static let image = ShareContent.Media.Image(UIImage(named: "Cupid")!)
        static let audio = ShareContent.Media.Audio(audioURL: NSURL(string: "http://y.qq.com/#type=song&mid=001iZnof2dRaPm")!, linkURL: nil)
        static let video = ShareContent.Media.Video(NSURL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
    }
    
    // Properties
    var content = ShareContent()
    let destinationMapper = [1: ShareManager.Destination.Alipay,
                             2: ShareManager.Destination.Pasteboard,
                             3: ShareManager.Destination.Weibo,
                             4: ShareManager.Destination.WechatSession,
                             5: ShareManager.Destination.WechatTimeline,
                             6: ShareManager.Destination.QQ]
    let OAuthMapper = [3: ShareManager.OAuthType.Weibo,
                       4: ShareManager.OAuthType.Wechat,
                       6:ShareManager.OAuthType.QQ]
    
    @IBOutlet weak var shareOrOAuthSegmentControl: UISegmentedControl!
    @IBOutlet weak var mediaTypeSegmentControl: UISegmentedControl!
    
    @IBAction func chooseMedia(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            content.media = Media.URL
        case 1:
            content.media = Media.image
        case 2:
            content.media = Media.audio
        case 3:
            content.media = Media.video
        default: ()
        }
        updateShareButtonState()
    }
    
    @IBAction func toggleShareOAuth(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            mediaTypeSegmentControl.hidden = true
        } else {
            mediaTypeSegmentControl.hidden = false
        }
        updateShareButtonState()
    }
    
    
        
    @IBAction func share(sender: UIButton) {
        switch shareOrOAuthSegmentControl.selectedSegmentIndex {
        case 0:
            if let destination = destinationMapper[sender.tag] {
                ShareManager.shareContent(content, to: destination,
                    succeed: {
                        NotificationManager.showSuccessMessage("Share Succeed")
                    },
                    failed: {
                        NotificationManager.showErrorMessage("Share Failed")
                    })
            }
        case 1:
            if let OAuthType = OAuthMapper[sender.tag] {
                ShareManager.OAuth(OAuthType,
                    succeeded: { (response) -> Void in
                        NotificationManager.showSuccessMessage("OAuth succeed: \(response)")
                    },
                    failed: { (errorMessage) -> Void in
                        NotificationManager.showErrorMessage("OAuth failed: \(errorMessage)")
                })
            }
        default: ()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        content.title = "36Kr"
        content.description = "The platform for entrepreneur"
        content.thumbnail = UIImage(named: "Cupid")
        content.media = Media.URL
        
        updateShareButtonState()
    }
    
    
    // Share
    private func updateShareButtonState() {
        guard view != nil else { return }
        for i in 1...6 {
            if let button = view.viewWithTag(i) as? UIButton {
                switch shareOrOAuthSegmentControl.selectedSegmentIndex {
                // Share
                case 0:
                    if let destination = destinationMapper[i] {
                        button.enabled = destination.serviceProviderType.canShareContent(content)
                    } else {
                        button.enabled = false
                    }
                    
                // OAuth
                case 1:
                    if let OAuthType = OAuthMapper[i] {
                        button.enabled = OAuthType.serviceProviderType.canOAuth
                    } else {
                        button.enabled = false
                    }

                default: ()
                }
            }
        }
    }

}
