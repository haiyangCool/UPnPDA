//
//  HiCacheManager.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/1.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation
import CommonCrypto
protocol HiCacheProtocol {
    /// 存储数据
    /// - Parameter response: response
    /// - Parameter time: cache Time in memory
    /// - Parameter key: cache Key
    mutating func save(_ response: HiURLResponse,
                       cacheTime time: TimeInterval,
                       cacheKey key: String)
    
    /// 获取缓存数据
    /// - Parameter key: cache Key
    mutating func fetchData(_ key: String) -> HiURLResponse?
    
    /// 清理所有缓存
    mutating func cleanAllData()
    
    /// 清理相关Key对应缓存
    /// - Parameter key: cache Key
    mutating func cleanData(_ key:String)
}

/// 缓存控制
public struct HiCacheManager {
    
    /// 内存缓存控制
    lazy var memoryCacheManager: HiMemoryCacheManager = {
        let memoryCacheManager = HiMemoryCacheManager()
        return memoryCacheManager
    }()
    
    /// 磁盘缓存控制
    lazy var diskCacheManager: HiDiskCacheManager = {
        let diskCacheManager = HiDiskCacheManager()
        return diskCacheManager
    }()
    
    static let shared = HiCacheManager()
    private init() {}
    
    public mutating func save(_ response: HiURLResponse,
                  serviceIdentifier identifier: String,
                  apiName name: String,
                  parameter params: [String:String?]?,
                  cacheTime time: TimeInterval,
                  cacheType type: HiAPIManagerCachePolicy) {
        
        let key = self.key(identifier, apiName: name, parameter: params)
        if type == .memory {
            memoryCacheManager.save(response, cacheTime: time, cacheKey: key)
        }
        
        if type == .disk {
            diskCacheManager.save(response, cacheTime: time, cacheKey: key)
        }
    }
    
    public mutating func fetchData(serviceIdentifier identifier:String,
                   apiName name: String,
                   parameter params: [String:String?]?,
                   cacheTime time: TimeInterval,
                   cacheType type: HiAPIManagerCachePolicy) -> HiURLResponse? {
        
        var response: HiURLResponse? = nil
        
        let key = self.key(identifier, apiName: name, parameter: params)
        if type == .memory {
            response =  memoryCacheManager.fetchData(key)
        }
        if type == .disk {
            response = diskCacheManager.fetchData(key)
        }
        return response
    }
    
    public mutating func cleanAllCache(_ cacheType: HiAPIManagerCachePolicy) {
        if cacheType == .memory {
            memoryCacheManager.cleanAllData()
        }
        if cacheType == .disk {
            diskCacheManager.cleanAllData()
        }
    }
}

/// Private methods
extension HiCacheManager {
    
    private func key(_ serviceIdr:String,apiName name:String,parameter params:[String:String?]?) -> String {
        var key = ""
        key = key + serviceIdr + name
        if params == nil || params!.isEmpty {
            return key
        }
        let allKeys = params!.keys
        let sortKeys = allKeys.sorted()
        
        for k in sortKeys {
            if let v:String = params![k] ?? "" {
                key += "\(k)=\(v)"
            }
        }
        return key.md5()
    }
}

extension String {
    /// CommonCrypto add Swift is not safe
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
}
