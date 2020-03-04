//
//  HiDiskCacheMemory.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/6.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation

private let DiskCachePreFix = "HiDiskCachePreFix"
private let DiskCacheData = "HiDiskCacheData"
private let DiskCacheTime = "HiDiskCacheTime"
private let DiskCacheUpDateTime = "HiDiskCacheUpDateTime"

struct HiDiskCacheManager: HiCacheProtocol{
  
    init() {}
    
    func save(_ response: HiURLResponse, cacheTime time: TimeInterval, cacheKey key: String) {
        
        let cacheKey = DiskCachePreFix + key
        /// if code run there , response can not be nil
        let data = try? JSONSerialization.data(withJSONObject:
            [
            DiskCacheData:response.content!,
            DiskCacheTime:NSNumber.init(value: time),
            DiskCacheUpDateTime:Date.init().timeIntervalSince1970
            ],
                                               options: .prettyPrinted)
        
        let userDefault = UserDefaults.standard
        userDefault.setValue(data, forKey: cacheKey)
        userDefault.synchronize()
    }
    
    func fetchData(_ key: String) -> HiURLResponse? {
        var response: HiURLResponse? = nil
        let cacheKey = DiskCachePreFix + key
        let userDefault = UserDefaults.standard
        if let cacheData:Data = userDefault.value(forKey: cacheKey) as? Data, let dataInfo:[String : Any] = try? JSONSerialization.jsonObject(with: cacheData, options: .mutableContainers) as? [String : Any] {
            
            let data = try? JSONSerialization.data(withJSONObject: dataInfo[DiskCacheData]!, options: .prettyPrinted)
            
            
            if let updateTimeinterval:TimeInterval = dataInfo[DiskCacheUpDateTime] as? TimeInterval,let cacheTime:TimeInterval = dataInfo[DiskCacheTime] as? TimeInterval {
                let upDate = Date.init(timeIntervalSince1970: updateTimeinterval)
                let outTime = Date().timeIntervalSince(upDate)
                if outTime < cacheTime {
                    response = HiURLResponse.init(data: data)
                }else {
                    cleanData(key)
                }
            }
        }
        return response
    }
    
    func cleanAllData() {
        let userDefault = UserDefaults.standard
        let allCacheKeyList = userDefault.dictionaryRepresentation()
        
        let keys = allCacheKeyList.keys.filter { $0.contains(DiskCachePreFix)
        }
        for key in keys {
            userDefault.removeObject(forKey: key)
        }
        userDefault.synchronize()
    }
    
    func cleanData(_ key: String) {
        let cacheKey = DiskCachePreFix + key
        let userDefault = UserDefaults.standard
        userDefault.removeObject(forKey: cacheKey)
        userDefault.synchronize()
    }

}
