//
//  HiBaseAPIManager.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/1.
//  Copyright © 2017 王海洋. All rights reserved.
//

import UIKit

/// Success Closure
public typealias SuccessCallback = (_ response: HiURLResponse?) -> Void
/// Faild Closure
public typealias FaildCallback = (_ errorType:  HiAPIManagerError, _ response: HiURLResponse?) ->Void

// MARK: Hi Base Api Manager 
open class HiBaseAPIManager: NSObject {

     /// APIManager 的子类必须实现该协议
     weak public var delegate: HiAPIManagerChildProtocol?
     
     /// 服务
     public var service: HiAPIManagerService?
     
     /// 参数提供
     weak public var paramsSource: HiAPIManagerParameterDelegate?
     
     /// 验证器，对参数和Api返回数据进行验证
     weak public var validator: HiAPIManagerValidator?
     
     /// 拦截器
     weak public var interceptor: HiAPIManagerInterceptor?
     
     /// 结果回调
     weak public var resultDelegate: HiAPIManagerResultDelegate?
     
     
     /// 请求超时时间
     public var requestTimeout: TimeInterval = 15
     
     /// 请求方式
     public var requestType: HiAPIManagerRequestType = .GET
     
     /// 缓存保留时间
     public var memoryCacheTime: TimeInterval = 1*60
     public var diskCacheTime: TimeInterval = 1*60
     
     /// 避免重复加载同一资源，如果API 正在执行，则不执行新的API
     private var isLoading:Bool = false
    
     /// 是否忽略缓存，如果为false, 即使该Api请求存在缓存数据，也会发起新的请求
     public var isIgnoreCache:Bool = false
     
     /// 缓存策略
     public var cachePolicy: HiAPIManagerCachePolicy = .none
     
     /// Response
     public var urlResponse: HiURLResponse? = nil
     
     /// 错误类型和信息
     public var errorType: HiAPIManagerError = .default
     
     /// 缓存管理器
     private lazy var cacheManager = HiCacheManager.shared
     
     /// Api请求生成的id列表
     private lazy var requestIdList:[Int] = []
     
     /// 网络连接检查
     private lazy var netWorkReachability = HiNetReachability.shared
     
     /// CallBack
     fileprivate var successCallback: SuccessCallback?
     fileprivate var faildCallback: FaildCallback?
     
     public override init() {
         super.init()
         delegate = nil
         paramsSource = nil
         service = nil
         validator = nil
         interceptor = nil
         resultDelegate = nil
     }
}

extension HiBaseAPIManager {
    
    /// 开始加载
    public func loadData() -> Int {
        if let ds = paramsSource {
           return loadDataWith(ds.parameters(self))
        }
        return loadDataWith(nil)
        
    }
    
    /// 直接请求，通过闭包返回数据
    public func loadDataWith(_ params:[String:String]?,successCallBack success: @escaping  SuccessCallback, faildCallBack faild: @escaping FaildCallback) -> Int {
        successCallback = success
        faildCallback = faild
        return loadDataWith(params)
    }
    
    /// Api执行成功后，获取返回的数据
    /// 通过Reformer解析
    /// - Parameter reformer: reformer
    public func fetchData(with reformer: HiAPIManagerResponseReformer?) -> Any {
        
        guard let ref = reformer else {
            return urlResponse?.content as Any
        }
        
        return ref.transform(self, response: urlResponse?.content)
    }
    
    /// 获取Api执行失败的类型
    public func faildType() -> HiAPIManagerError {
        return errorType
    }
    
    /// 取消Api请求
    public func cancelRequest(_ requestId:Int) {
        if requestIdList.contains(requestId) {
            HiNetworkProxy.shared.cancel(requestId)
            requestIdList.removeAll{ $0 == requestId }
        }
    }
    
    /// 取消所有的Api请求
    public func cancelAllRequest() {
        HiNetworkProxy.shared.cancelAllRequest()
        requestIdList.removeAll()
    
    }
}

// MARK:- Private Methods
extension HiBaseAPIManager {
    
    /// 是否为标准子类
    private func isStandardChildManager() {
    
        assert(delegate != nil && service != nil, "子类(继承自APIManager)必须实现APIManagerDelegate协议,\n并且需要设置服务提供方（APIManagerService协议）")
    }
    
    private func loadDataWith(_ params:[String:String]?) -> Int {
    
        /// 要使用该API ,必须实现子类规定的协议，并且提供一个Service(协议), 否则在编译器强制crash
        isStandardChildManager()
        var requestId = 0
        if isLoading {
            return requestId
        }
        let finalParams = delegate?.reformeParams(params)
        
        /// 允许执行该Api调用
        if shouldPerformApiWithParams(self, params: finalParams) {

            let errorType = validator?.paramsIsCorrect(self, params: finalParams)
            if let err = errorType, err != .default {
                /// 参数错误，直接退出
                faildCallApi(nil, errorType: .parameterError)
                return requestId
            }
            
            var vResponse: HiURLResponse?
            /// 不忽略缓存，直接加载缓存(如果缓存过期，则进行新的请求)
            if !isIgnoreCache {
                cachePolicy = delegate!.cachePolicy()
                if cachePolicy == .memory {
                    vResponse = fetchCache(.memory)
                }
                if cachePolicy == .disk {
                    vResponse = fetchCache(.disk)
                }
                /// if cache not empty, direct return cache data
                if vResponse != nil {
                    successCallApi(with: vResponse!)
                    return requestId
                }
            }
               
            /// 开启API请求 调用
            if isReachability() {
                isLoading = true
                requestType = delegate!.requestType()
                if let request = service!.urlRequest(apiAddress: delegate!.apiAddress(), apiParams: finalParams,requestTimeout: requestTimeout, reuqestType: requestType) {
                    requestId = HiNetworkProxy.shared.call(request, success: { (successResponse) in
                        self.successCallApi(with: successResponse)
                    }) { (faildResponse) in
                        self.faildCallApi(faildResponse, errorType: .default)
                    }
                    requestIdList.append(requestId)
                    afterPerformApiWithParams(self, params: finalParams)
                    return requestId
                }else {
                    faildCallApi(nil, errorType: .requestError)
                    return requestId
                }
                                
            }else {
                faildCallApi(nil, errorType: .unconnectedNetwork)
                return requestId
            }
                
        }
        return requestId
    
    }
    
    /// 网络是否通畅
    private func isReachability() -> Bool {
        return netWorkReachability.isReachable()
    }
}

/// Result 回调
extension HiBaseAPIManager {
    
    /// 调用Api 成功
    /// - Parameter response:
    private func successCallApi(with response: HiURLResponse) {
        
        isLoading = false
        urlResponse = response
        let errType = validator?.responseIsCorrect(self, response: urlResponse?.content)
        if errType == nil || errType == .some(.default) {
            if cachePolicy == .memory && response.isCache == false {
                cacheManager.save(response, serviceIdentifier: delegate!.serviceIdentifier(), apiName: delegate!.apiAddress(), parameter: paramsSource?.parameters(self), cacheTime: memoryCacheTime, cacheType: .memory)
            }
            
            if cachePolicy == .disk && response.isCache == false {
                cacheManager.save(response, serviceIdentifier: delegate!.serviceIdentifier(), apiName: delegate!.apiAddress(), parameter: paramsSource?.parameters(self), cacheTime: diskCacheTime, cacheType: .disk)
            }
            
            if beforePerformSuccessWithResponse(self, response: urlResponse) == .default {
                DispatchQueue.main.async {
                    self.resultDelegate?.success(self)
                    if self.successCallback != nil {
                        self.successCallback!(response)
                    }
                }
            }
            afterPerformFaildWithResponse(self, response: urlResponse)
            
        }else {
            faildCallApi(response, errorType: .resultUnavailable)
        }
    }
    
    /// 调用Api失败
    /// - Parameters:
    ///   - response: faild resonse
    ///   - type: error type
    private func faildCallApi(_ response: HiURLResponse?,
                              errorType type: HiAPIManagerError) {
        
        isLoading = false
        urlResponse = response
        self.errorType = type
        if response?.state == .some(.netException) {
            self.errorType = .networkAnomalies
        }
        if response?.state == .some(.requestCancel) {
            self.errorType = .requestCanceled
        }
        if response?.state == .some(.requestTimeOut) {
            self.errorType = .requestTimeout
        }
        if service!.isHandleApiManagerError(self, errorType: errorType, errorContent: urlResponse?.content) {
            return
        }
        
        if interceptor != nil && interceptor!.beforePerformApiFaild(self, with: urlResponse) == .default {
            return
        }
        
        DispatchQueue.main.async {
            self.resultDelegate?.faild(self)
            if self.faildCallback != nil {
                self.faildCallback!(self.errorType,response!)
            }
        }
        
        afterPerformFaildWithResponse(self, response: urlResponse)
    }
}

/// 获取Api的缓存数据
extension HiBaseAPIManager {
    
    /// 获取内存或者磁盘的缓存数据（如果缓存不为空，并且缓存数据没有过期）
    private func fetchCache(_ cacheType: HiAPIManagerCachePolicy) -> HiURLResponse? {
        
        return cacheManager.fetchData(serviceIdentifier: self.delegate!.serviceIdentifier(), apiName: self.delegate!.apiAddress(), parameter: self.paramsSource?.parameters(self), cacheTime: memoryCacheTime, cacheType: cacheType)
    }

}

/// 这里对Api请求的各个阶段（切面AOP）添加了拦截器
extension HiBaseAPIManager {
    
    private func shouldPerformApiWithParams(_ manager: HiBaseAPIManager, params: [String : String]?) -> Bool {
        
        if let itp = interceptor {
            return itp.shouldPerformApi(self, with: params)
        }
        
        return true
    }
    
    private func afterPerformApiWithParams(_ manager: HiBaseAPIManager, params: [String : String]?) {
        
        if let itp = interceptor {
            itp.afterPerformApi(self, with: params)
        }
    }
    
    private func beforePerformSuccessWithResponse(_ manager: HiBaseAPIManager, response: HiURLResponse?) -> HiAPIManagerError {
        
        if let itp = interceptor {
            return itp.beforePerformApiSuccess(self, with: response)
        }
        
        return .default
    }
    
    private func afterPerformSuccessWithResponse(_ manager: HiBaseAPIManager, response: HiURLResponse?) {
        
        if let itp = interceptor {
            itp.afterPerformApiSuccess(self, with: response)
        }
    }
    
    private func beforePerformFaildWithResponse(_ manager: HiBaseAPIManager, response: HiURLResponse?) -> HiAPIManagerError {
        if let itp = interceptor {
            return itp.beforePerformApiFaild(self, with: response)
        }
        return .default
    }
    
    private func afterPerformFaildWithResponse(_ manager: HiBaseAPIManager, response: HiURLResponse?) {
        if let itp = interceptor {
            itp.afterPerformApiFaild(self, with: response)
        }
    }
    
    private func didReceiveResponse(_ manager: HiBaseAPIManager, response: HiURLResponse?) {
        if let itp = interceptor {
            itp.didReceiveResponse(manager, response: response)
        }
    }
}

