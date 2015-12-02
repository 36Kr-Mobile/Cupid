//
//  AppDelegate.swift
//  CupidDemo
//
//  Created by Shannon Wu on 12/2/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?



    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        return true
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        // Check if it is callback for ShareManager, if it is return the flag.
        if let shareFlag = ShareManager.handleOpenURL(url) {
            return shareFlag
        }
        
        return false
    }

}

