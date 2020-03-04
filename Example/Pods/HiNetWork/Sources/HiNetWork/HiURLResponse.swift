//
//  HiURLResponse.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/1.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation
import UIKit
/// URL Response
/// Api 请求成功后原始数据返回，在 APIManager 中不对数据的合法性进行验证，仅对原始数据进行解析
public enum HiURLResponseState {
    
    case success           // 成功
    case requestTimeOut    // 请求超时
    case requestCancel     // 请求取消
    case netException      // 网络异常，当因为其他原因造成请求失败时，统一定义为网络错误
}

public class HiURLResponse: NSObject {

    /// 请求数据是否成功状态
    public var state: HiURLResponseState = .success
    
    /// API进行网络访问时，系统错误
    public var error:Error?
    
    /// 数据是否为缓存
    public var isCache:Bool?
    
    /// 数据对应的api地址
    public var url:String?
    
    /// Api 请求方式
    public var requestType:String?
    
    /// Api 请求参数
    public var params:Dictionary<String,Any>?
    
    /// 响应数据的几种存在方式
    /// 字符串
    public var responseStr:String?
    /// 字典
    public var content:Dictionary<String,Any>?
    /// Data
    public var data:Data?
    
    /// Log
    public var log:String?
    
    
    public override init() {}
    
    /// 初始化 响应数据
    /// - Parameters:
    ///   - string: 原始数据字符串
    ///   - request: 请求
    ///   - err: 错误
    public init(responsesString string:String?,
                urlRequest request:URLRequest,
                error err: Error?) {
        super.init()
        responseStr = string
        error = err
        isCache = false

        if let urlAddress:URL = request.url {
            url = urlAddress.absoluteString
        }
        if let type:String = request.httpMethod {
            requestType = type
        }
    
        if let body:Data = request.httpBody {
            params =  try? JSONSerialization.jsonObject(with: body, options: .allowFragments) as? Dictionary<String, Any>
        }
        
        if let data = responseStr?.data(using: .utf8) {
            self.data = data
            content =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any>
        }
    
        state = self.responseState(error: self.error)
        log = self.reformLog()
    }
    
    /// 通过缓存初始化响应数据
    /// - Parameter data: data
    public init(data:Data?) {
        super.init()
        if data != nil && !data!.isEmpty {
            state = .success
            error = nil
            isCache = true
            url = nil
            params = nil
            requestType = nil
            self.data = data
            responseStr = String.init(data: data!, encoding: .utf8)
            content = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String, Any>
        }
        log = self.reformLog()
        
    }
    
}

extension HiURLResponse {
    
    /// 错误状态
    /// - Parameter error: error
    private func responseState(error: Error?) -> HiURLResponseState {
        if error == nil {
            return .success
        }
        if let urlError:URLError = error as? URLError {
            if urlError.code == URLError.timedOut {
                return .requestTimeOut
            }
            if urlError.code == URLError.cancelled {
                return .requestCancel
            }
        }
        return .netException
    }
    
    private func reformLog() -> String {
        
        var log = "Response:\n"
        
        log += "\t\t\t    state: \(String(describing: state))\n"
        log += "\t\t\t      url: \(String(describing: url))\n"
        log += "\t\t\t    param: \(String(describing: params))\n"
        log += "\t\t\t     type: \(String(describing: requestType))\n"
        log += "\t\t\t  isCache: \(String(describing: isCache))\n"
        log += "\t\t\t response: \(responseStr ?? "noData")"
        
        return log
    
    }
}
