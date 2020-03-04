//
//  DemoAPIManager.swift
//  NetManagerDemo
//
//  Created by 王海洋 on 2020/2/18.
//  Copyright © 2020 王海洋. All rights reserved.
//

import UIKit
import HiNetWork

class DemoAPIManager: HiBaseAPIManager {

    override init() {
        super.init()
        delegate = self
        validator = self
        service = DemoService()
    }
}

extension DemoAPIManager: HiAPIManagerChildProtocol, HiAPIManagerValidator {

    func apiAddress() -> String {
        return "c/top/list.json"
    }
    
    func requestType() -> HiAPIManagerRequestType {
        return .GET
    }
    
    func cachePolicy() -> HiAPIManagerCachePolicy {
        return .none
    }
    
    func paramsIsCorrect(_ manager: HiBaseAPIManager, params: [String : String]?) -> HiAPIManagerError {
        return .default
    }
    
    func responseIsCorrect(_ manager: HiBaseAPIManager, response: Dictionary<String, Any>?) -> HiAPIManagerError {
        return .default
    }
    
}
