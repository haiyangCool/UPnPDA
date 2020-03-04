//
//  DemoService.swift
//  NetManagerDemo
//
//  Created by 王海洋 on 2020/2/18.
//  Copyright © 2020 王海洋. All rights reserved.
//

import UIKit
import HiNetWork
class DemoService: NSObject, HiAPIManagerService {

    override init() {
    }
    
    func environment() -> HiAPIServiceEnvironment {
        return .develop
    }
    
    func serviceAddress() -> String {
        if environment() == .develop {
            return "http://expand.video.iqiyi.com/"
        }
        return "http://expand.video.iqiyi.com/"
    }
    
    func isHandleApiManagerError(_ manager: HiBaseAPIManager, errorType type: HiAPIManagerError, errorContent content: Dictionary<String, Any>?) -> Bool {
        return false
    }
    
}
