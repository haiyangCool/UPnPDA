//
//  HiNetworkProtocols.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/1.
//  Copyright © 2017 王海洋. All rights reserved.
//

import Foundation
import UIKit

/// 发起请求的方式
@objc public enum HiAPIManagerRequestType: Int {
    
    /// Get
    case GET
    
    /// Post
    case POST
}

/// Service 管理自己的api 的开发环境
@objc public enum HiAPIServiceEnvironment: Int {
    
    /// 调试
    case develop
    
    /// 发布
    case release
}

/// 缓存策略
@objc public enum HiAPIManagerCachePolicy: Int {
    
    /// 内存
    case memory
    
    /// 硬盘
    case disk
    
    /// 不执行缓存
    case none
}

/// Api  Manager Error
@objc public enum HiAPIManagerError: Int, Error {
    
    /// 未执行Api
    case `default`
    
    /// 未连接到网络
    case unconnectedNetwork

    /// 参数错误，该错误由业务层validator验证确定
    case parameterError

    /// 请求结果不可用， 该错误由业务层验证确定
    case resultUnavailable
    
    /// Request 错误，一般由Url不合法造成，比如 URL中带有空格等
    case requestError

    /// 请求超时
    case requestTimeout
    
    /// 请求被取消
    case requestCanceled

    /// 网络错误，造成该问题的原因有很多，这里不做具体区分
    /// 一个比较常见的http问题：App Transport Security policy requires the use of a secure connection
    /// 1、使用https
    /// 2、在 info.plist 加入
    /**
    <key>NSAppTransportSecurity</key>
    <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    </dict>
     */
    case networkAnomalies
    
    /// 请求太多造成的网络拥塞
    case networwCongestion
    
    /// 需要登录
    case needLogin
    
    /// Token 过期
    case accessTokenOutTime
}


// MARK: HiNetwork Protocols

/// HiAPIManager 的子类必须实现该协议，否则HiAPIManager会Crash.
@objc public protocol HiAPIManagerChildProtocol {
    
    /// Api 访问地址
    func apiAddress() -> String
    
    /// Api 请求方式
    func requestType() -> HiAPIManagerRequestType
    
    /// Api 请求结果的缓存策略
    func cachePolicy() -> HiAPIManagerCachePolicy
    
    /// 服务 ID，组件化开发时，必须为 管理该Api 的Service 类名
    /// 非组件化开发无需实现，内部使用默认标识符
    @objc optional func serviceIdentifier() -> String
    
    /// 参数修改、提供基础默认参数（如果有需要）
    @objc optional func reformeParams(_ params:[String:String]?) -> [String:String]?
    
}

/// APIManagerChildProtocol Extension
private let HiAPIManagerDefaultServiceID = "APIManagerDefaultServiceID"
extension HiAPIManagerChildProtocol {
    
    func serviceIdentifier() -> String {
        return HiAPIManagerDefaultServiceID
    }
    
    func reformeParams(_ params:[String:String]?) -> [String:String]? {
        return params
    }
    
}

/// API 服务提供方必须实现该协议，配置一个简单的标准服务
@objc public protocol HiAPIManagerService {
    
    /// 当前开发环境
    func environment() -> HiAPIServiceEnvironment
    
    /// 服务提供的域名地址
    func serviceAddress() -> String
    
    /// 服务是否处理API请求出现的错误，处理则返回 true
    func isHandleApiManagerError(_ manager: HiBaseAPIManager,
                                 errorType type: HiAPIManagerError, errorContent content: Dictionary<String,Any>?) -> Bool
    
    /// 生成URLRequest
    @objc optional func urlRequest(apiAddress address: String,
                    apiParams params:[String:String]?,
                    requestTimeout timeInterval:TimeInterval,
                    reuqestType type: HiAPIManagerRequestType) -> URLRequest?
    
    
    /// Get 参数转变为 ?key=value&key2=value 的默认格式
    /// - Parameter params:
    @objc optional func paramsStringOfGet(_ params:[String:String]?) -> String
    
    /// Post 参数转变为Data
    /// - Parameter params:
    @objc optional func paramsDataOfPOST(_ params:[String:String]?) -> Data?
    
}

/// APIManagerService Extension
extension HiAPIManagerService {
    
    func urlRequest(apiAddress address: String,
                    apiParams params:[String:String]?,
                    requestTimeout timeInterval:TimeInterval,
                    reuqestType type: HiAPIManagerRequestType) -> URLRequest? {
    
        
        if type == .GET {
            let fullApiAddress = self.serviceAddress() + address + paramsStringOfGet(params)
            if let url = URL(string: fullApiAddress) {
                var request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeInterval)
                request.httpMethod = "GET"
                return request
            }
            
        }
        if type == .POST {
            var request = URLRequest.init(url: URL(string: address)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeInterval)
            request.httpMethod = "POST"
            request.httpBody = paramsDataOfPOST(params)
            return request
        }
        
        return nil
    }
    
    func paramsStringOfGet(_ params:[String:String]?) -> String {
        if params == nil || params!.isEmpty { return "" }
        var paramStr:String = "?"
        for (k,v) in params! {
            if !v.isEmpty {
                paramStr += "\(k)=\(v)&"
            }else {
                paramStr += "\(k)=\("&")"
            }
        }
        return String.init(paramStr.dropLast(1))
    }
    
    func paramsDataOfPOST(_ params:[String:String]?) -> Data? {
        if params == nil || params!.isEmpty { return nil }

        let paramData = try? JSONSerialization.data(withJSONObject: params!, options: .prettyPrinted)
        return paramData
    }
}

/// 发起API 请求所需参数
public protocol HiAPIManagerParameterDelegate: NSObjectProtocol {
    
    /// 参数接口
    /// - Parameter manager: APIManager
    func parameters(_ manager: HiBaseAPIManager) -> [String:String]?
}

/// 验证协议 ，对发起请求的参数、和请求成功后的结果进行验证
public protocol HiAPIManagerValidator: NSObjectProtocol {
    
    /// 参数是否正确
    func paramsIsCorrect(_ manager: HiBaseAPIManager,
                         params: [String:String]?) -> HiAPIManagerError
    
    /// 数据响应是否正确可用
    func responseIsCorrect(_ manager: HiBaseAPIManager,
                                    response: Dictionary<String, Any>?) -> HiAPIManagerError
}

/// API 请求的结果回调
public protocol HiAPIManagerResultDelegate: NSObjectProtocol {
    
    /// 成功，业务层在接收到该接口的回调后，通过 manager 的 fetch方法获取数据
    /// - Parameter apiManager: APIManager
    func success(_ manager: HiBaseAPIManager)
    
    /// 失败
    /// - Parameter apiManager: APIManager
    func faild(_ manager: HiBaseAPIManager)
}

/// 业务层可以通过实现该协议，为已有的类型添加解析请求数据的能力
public protocol HiAPIManagerResponseReformer: NSObjectProtocol {
    
    func transform(_ manager: HiBaseAPIManager,
                      response:Dictionary<String,Any>?) -> AnyObject
}

/// 这里为加载下一页功能提供了一个简单协议
@objc public protocol HiAPIManagerLoadNextPage {

    /// 当前页码
    var currentPage:Int { get set }
    
    ///  每页的数据量
    var pageSize: Int { get set }
    
    /// 是否是第一页
    var isFirstPage:Bool { get set }
    
    /// 是否是最后一页
    var isLastPage:Bool { get set }
    
    /// 加载下一页
    func loadNextPage()
}

/// 面向切面添加拦截器
@objc public protocol HiAPIManagerInterceptor {
    
    /// 是否可以起调API
    @objc optional func shouldPerformApi(_ manager: HiBaseAPIManager,
                          with params: [String:String]?) ->Bool
       
    /// 执行API后
    @objc optional func afterPerformApi(_ manager: HiBaseAPIManager,
                         with params: [String:String]?)
       
    /// 执行API成功前
    @objc optional func beforePerformApiSuccess(_ manager: HiBaseAPIManager,
                                 with response: HiURLResponse?) -> HiAPIManagerError
       
    /// 执行API成功后
    @objc optional func afterPerformApiSuccess(_ manager: HiBaseAPIManager,
                             with response: HiURLResponse?)
       
       
    /// 执行API失败前
    @objc optional func beforePerformApiFaild(_ manager: HiBaseAPIManager,
                            with response: HiURLResponse?) -> HiAPIManagerError
       
    /// 执行API失败后
    @objc optional func afterPerformApiFaild(_ manager: HiBaseAPIManager,
                           with response: HiURLResponse?)
       
    /// 接收到数据后
    @objc optional func didReceiveResponse(_ manager: HiBaseAPIManager,
                            response: HiURLResponse?)
}

extension HiAPIManagerInterceptor {
    
    /// 是否可以起调API
    func shouldPerformApi(_ manager: HiBaseAPIManager,
                         with params: [String:String]?) ->Bool {
        return true
    }
      
    /// 执行API后
    func afterPerformApi(_ manager: HiBaseAPIManager,
                        with params: [String:String]?) {}
      
    /// 执行API成功前
    func beforePerformApiSuccess(_ manager: HiBaseAPIManager,
                                    with response: HiURLResponse?) -> HiAPIManagerError {
        return .default
    }
      
   /// 执行API成功后
   func afterPerformApiSuccess(_ manager: HiBaseAPIManager,
                               with response: HiURLResponse?) {}
      
      
   /// 执行API失败前
   func beforePerformApiFaild(_ manager: HiBaseAPIManager,
                              with response: HiURLResponse?) -> HiAPIManagerError {
        return .default
    }
      
   /// 执行API失败后
   func afterPerformApiFaild(_ manager: HiBaseAPIManager,
                             with response: HiURLResponse?) {}
      
   /// 接收到数据后
   func didReceiveResponse(_ manager: HiBaseAPIManager,
                           response: HiURLResponse?) {}
}
