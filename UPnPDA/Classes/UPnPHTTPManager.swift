//
//  HTTPManager.swift
//  NetWork
//
//  Created by 王海洋 on 2018/5/23.
//  Copyright © 2020 王海洋. All rights reserved.
//
/// HTTP Manager 管理简单的 HTTP 请求
/// GET
/// POST
import UIKit

/// 请求方式
public enum UPnPHTTPMethod: String {
    case GET
    case POST
}
public struct UPnPHTTPURLRequest {
    
    var request: URLRequest
    var httpMethod: UPnPHTTPMethod {
        get {
            return method
        }
        set {
            method = newValue
            request.httpMethod = newValue.rawValue
        }
    }
    private var method: UPnPHTTPMethod = .GET
    
    public init(url: URL) {

        request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
    }
    
    /// Set value for Header Field
    public mutating func addValue(_ value: String, forHeaderField field: String) {
        request.addValue(value, forHTTPHeaderField: field)
    }

    /// 设置 Body 请求体
    /// - Parameter data: data of http body
    public mutating func setHttpBody(data: Data?) {
        if let httpBody = data {
            request.httpBody = httpBody
        }
    }
}
///  HTTP 请求结果回调
public protocol UPnPHTTPManagerDelegate {
    
    func success(_ httpManager: UPnPHTTPManager)
    func faild(_ httpManager: UPnPHTTPManager)
}

public typealias SuccessCallBack = (_ response: Data) -> Void
public typealias FaildCallBack = (_ error: Error) -> Void

public class UPnPHTTPManager: NSObject {

    /// HTTP 请求结果回调
    public var delegate: UPnPHTTPManagerDelegate?
    
    /// 回调闭包
    /// 成功
    public var successCallback: SuccessCallBack?
    /// 失败
    public var faildCallback: FaildCallBack?
    
    public override init() {}
}

// MARK: public methods
extension UPnPHTTPManager {
    
    public func load(urlRequest: UPnPHTTPURLRequest, successCallBack succss: @escaping SuccessCallBack, faildCallBack faild: @escaping FaildCallBack) {
        
        successCallback = succss
        faildCallback = faild
        invokeHttpRequest(request: urlRequest.request)
        
    }
}

// MARK: Private methods
extension UPnPHTTPManager {
    
    /// 发起HTTP请求
    private func invokeHttpRequest(request: URLRequest) {
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.onError(error: error!)
            }
            
            if let _ = response, let data = data {
                self.onSuccess(data: data)
            }
        }
        task.resume()
        
    }
    
    /// HTTP 请求发生错误
    private func onError(error: Error) {
        if let delegate = delegate {
            delegate.faild(self)
        }
        
        if let faild = faildCallback {
            faild(error)
        }
    }
    
    /// HTTP 请求成功
    /// - Parameter data: response data
    private func onSuccess(data: Data) {
        if let delegate = delegate {
            delegate.success(self)
        }
        
        if let success = successCallback {
            success(data)
        }
    }
 
}
