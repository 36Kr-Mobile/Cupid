//
//  Utils.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 36Kr. All rights reserved.
//

import Foundation

extension NSBundle {

    var displayName: String? {

        func getNameByInfo(info: [String:AnyObject]) -> String? {

            guard let displayName = info["CFBundleDisplayName"] as? String else {
                return info["CFBundleName"] as? String
            }

            return displayName
        }

        guard let info = localizedInfoDictionary ?? infoDictionary else {
            return nil
        }

        return getNameByInfo(info)
    }

    var bundleID: String? {
        return objectForInfoDictionaryKey("CFBundleIdentifier") as? String
    }
}

extension String {

    var base64EncodedString: String? {
        return dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    var base64AndURLEncodedString: String? {
        return base64EncodedString?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }

}

extension NSURL {

    var queryInfo: [String:String] {

        var info = [String: String]()

        if let querys = query?.componentsSeparatedByString("&") {
            for query in querys {
                let keyValuePair = query.componentsSeparatedByString("=")
                if keyValuePair.count == 2 {
                    let key = keyValuePair[0]
                    let value = keyValuePair[1]

                    info[key] = value
                }
            }
        }

        return info
    }
}
