//
//  HiNetReachability.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/11.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation
import Reachability

public class HiNetReachability: NSObject {
    
    static let shared = HiNetReachability()
    public override init() {}
    
    /// 网络是否可用
    func isReachable() -> Bool {
        
        let reachability = try? Reachability()

        if let connection = reachability?.connection {
            switch connection {
            case .unavailable:
                return false
            default:
                return true
            }
        }
        
        return true
    }
}
