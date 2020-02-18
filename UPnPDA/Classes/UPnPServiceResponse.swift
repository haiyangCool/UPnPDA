//
//  UPnPServiceResponse.swift
//  NetWork
//
//  Created by 王海洋 on 2018/5/23.
//  Copyright © 2020 王海洋. All rights reserved.
//
/// SSDP 搜索服务的两种方式的数据响应
/// 搜索-响应
/// 主动通知
import Foundation

///搜索-响应
public struct UPnPServiceSearchResponse {
    
    let http = "HTTP/1.1 200 OK"
    var change_control = "max-age=66"
    /// 设备描述信息地址 (DDD)
    var location: String?
    /// 由设备上的 操作系统/版本 UPnP/1.0 服务名/服务版本 组成
    var server: String?
    /// 搜索目标与搜索信息中的字段信息相同 ST
    var searchTarget: String?
    /// 服务的唯一标识 USN
    var serviceUniqueId:String?
    
    public init() {}
    public init(_ response: String) {
        parse(response: response)
    }
    public mutating func parse(response: String) {
        let propertys = response.split(separator: "\r\n")
        for property in propertys {
        
            if property.hasPrefix("Location:") {
                location = property.replacingOccurrences(of: "Location: ", with: "")
                continue
            }
            
            if property.hasPrefix("LOCATION:") {
                location = property.replacingOccurrences(of: "LOCATION: ", with: "")
                continue
            }
            
            if property.hasPrefix("USN:") {
                serviceUniqueId = property.replacingOccurrences(of: "USN: ", with: "")
                continue
            }
            
            if property.hasPrefix("Usn:") {
                serviceUniqueId = property.replacingOccurrences(of: "Usn: ", with: "")
                continue
            }
            
            if property.hasPrefix("ST:") {
                searchTarget = property.replacingOccurrences(of: "ST: ", with: "")
                continue
            }
            if property.hasPrefix("SERVER:") {
                server = property.replacingOccurrences(of: "SERVER: ", with: "")
                continue
            }
            if property.hasPrefix("CACHE-CONTROL:") {
                change_control = property.replacingOccurrences(of: "CACHE-CONTROL: ", with: "")
                continue
            }
        }
    }
}


/// 主动通知
public struct UPnPServiceAutoNotify {
    
    private let noify = "NOTIFY * HTTP/1.1"
    private let host = "239.255.255.250:1900"
    var change_control = "max-age=66"
    /// 设备描述信息地址 (DDD)
    var location: String?
    /// 服务类型 NT
    var serviceType: String?
    /// 服务是否可用 NTS
    var serviceAvaliable: String?
    /// 由设备上的 操作系统/版本 UPnP/1.0 服务名/服务版本 组成
    var server: String?
    /// 服务的唯一标识 USN
    var serviceUniqueId: String?
    public init() {}
    public init(_ response: String) {
        parse(response: response)
    }
    public mutating func parse(response: String) {
        let propertys = response.split(separator: "\r\n")
        for property in propertys {
            if property.hasPrefix("Location:") {
                location = property.replacingOccurrences(of: "Location: ", with: "")
                continue
            }
            if property.hasPrefix("LOCATION:") {
                location = property.replacingOccurrences(of: "LOCATION: ", with: "")
                continue
            }
            if property.hasPrefix("NTS:") {
                serviceAvaliable = property.replacingOccurrences(of: "NTS: ", with: "")
                continue
            }
            if property.hasPrefix("USN:") {
                serviceUniqueId = property.replacingOccurrences(of: "USN: ", with: "")
                continue
            }
            if property.hasPrefix("NT:") {
                serviceType = property.replacingOccurrences(of: "NT: ", with: "")
                continue
            }
            if property.hasPrefix("SERVER:") {
                server = property.replacingOccurrences(of: "SERVER: ", with: "")
                continue
            }
            if property.hasPrefix("CACHE-CONTROL:") {
                change_control = property.replacingOccurrences(of: "CACHE-CONTROL: ", with: "")
                continue
           }
       }
    }
}
