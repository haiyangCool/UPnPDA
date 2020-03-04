//
//  HiMemoryCacheManager.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/6.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation

/// 内存缓存管理
public struct HiMemoryCacheManager: HiCacheProtocol {
   
    lazy var cache = NSCache<NSString, AnyObject>()
    init() {}
    
    public mutating func fetchData(_ key: String) -> HiURLResponse? {
        
        var response: HiURLResponse? = nil
        if let cacheData: HiMemoryCacheObject = cache.object(forKey: key as NSString) as? HiMemoryCacheObject {
            if !cacheData.isEmpty() || !cacheData.isOutOfTime() {
                response = HiURLResponse.init(data: cacheData.content)
            }else {
                cleanData(key)
            }
        }
        return response
    }
    
    mutating func save(_ response: HiURLResponse,
                       cacheTime time: TimeInterval,
                       cacheKey key: String) {
        var cacheObj = HiMemoryCacheObject.init()
        if let data:Data = response.data {
            cacheObj.updateContent(data)
        }
        cache.setObject(cacheObj as AnyObject, forKey: key as NSString)
    }
    
    func cleanAllData() {
        let cache = NSCache<NSString, AnyObject>()
        cache.removeAllObjects()
    }
    
    func cleanData(_ key: String) {
        let cache = NSCache<NSString, AnyObject>()
        cache.removeObject(forKey: key as NSString)
    }
}

/// 内存缓存对象
struct HiMemoryCacheObject {
    
    /// data content
    var content:Data?
    
    /// 缓存时间
    var cacheTimeInterval:TimeInterval?
    
    /// 更新时间
    private var upDateTime:Date?
    
    init() {}
    
    public mutating func updateContent(_ content:Data) {
        self.content = content
        self.upDateTime = Date()
    }
    
    public func isOutOfTime() -> Bool {
        let time = Date().timeIntervalSince(self.upDateTime!)
        return cacheTimeInterval! > time
    }
    
    public func isEmpty() -> Bool {
        return self.content == nil
    }
}
