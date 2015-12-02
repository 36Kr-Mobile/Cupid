//
//  NotificationManager.swift
//  Cupid Demo
//
//  Created by Shannon Wu on 12/1/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit
import StatusBarNotificationCenter

struct NotificationManager {
    static func showSuccessMessage(message: String, duration: NSTimeInterval = 1.0) {
        var labelConfiguration = NotificationLabelConfiguration()
        labelConfiguration.backgroundColor = UIColor.blueColor()
        labelConfiguration.scrollSpeed = 160.0
        
        var notificationCenterConfiguration = NotificationCenterConfiguration(baseWindow: UIApplication.sharedApplication().keyWindow!)
        notificationCenterConfiguration.level = UIWindowLevelStatusBar
        
        StatusBarNotificationCenter.showStatusBarNotificationWithMessage(message, forDuration: duration, withNotificationCenterConfiguration: notificationCenterConfiguration, andNotificationLabelConfiguration: labelConfiguration)
    }
    
    static func showErrorMessage(message: String, duration: NSTimeInterval = 1.0) {
        var labelConfiguration = NotificationLabelConfiguration()
        labelConfiguration.backgroundColor = UIColor.redColor()
        labelConfiguration.scrollSpeed = 160.0

        var notificationCenterConfiguration = NotificationCenterConfiguration(baseWindow: UIApplication.sharedApplication().keyWindow!)
        notificationCenterConfiguration.level = UIWindowLevelStatusBar
        
        StatusBarNotificationCenter.showStatusBarNotificationWithMessage(message, forDuration: duration, withNotificationCenterConfiguration: notificationCenterConfiguration, andNotificationLabelConfiguration: labelConfiguration)
    }
}