//
//  VVNetApiProxy.swift
//  NetWork
//
//  Created by 王海洋 on 2017/8/8.
//  Copyright © 2019 王海洋. All rights reserved.
//

import UIKit

/// 存储请求task 的Key前缀
let APIIdPrefix = "HiAPIIdPrefix"

/// Callback
typealias ResponseCallBack = (_ response: HiURLResponse) -> Void

/// 网络代理
public class HiNetworkProxy: NSObject {
    
    lazy var dataTaskList: [String:URLSessionDataTask] = [:]
    static let shared = HiNetworkProxy()
    private override init() {}
}


extension HiNetworkProxy {
    
    func call(_ request:URLRequest,success: @escaping ResponseCallBack,faild: @escaping ResponseCallBack) -> Int {
        var requestId = 0
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data,
            response, error) in
            
            if error != nil {
                let errResponse = HiURLResponse(responsesString: nil, urlRequest: request, error: error)
                faild(errResponse)
                return
            }
            
            if let responeData:Data = data, let responseStr:String = String.init(data: responeData, encoding: .utf8) {
               
                if let httpResponse: HTTPURLResponse = response as? HTTPURLResponse {
                    let vResponse = HiURLResponse.init(responsesString: responseStr, urlRequest: request, error: error)
                    switch httpResponse.statusCode {
                    case 200...400:
                        success(vResponse)
                        break
                    default:
                        faild(vResponse)
                        break
                    }
                }
                
            }else {
                faild(HiURLResponse())
            }
        }
        dataTask.resume()
        requestId = dataTask.taskIdentifier
        dataTaskList["\(APIIdPrefix)\(requestId)"] = dataTask
        return requestId
    }
    
    /// 取消一个请求
    /// - Parameter requestId: request id
    func cancel(_ requestId:Int) {
        
        let requestKey = APIIdPrefix + "\(requestId)"
        if dataTaskList.contains(where: { (requestIdr,dataTask) -> Bool in
            requestKey == requestIdr
        }) {
            dataTaskList[requestKey]?.cancel()
        }
    }

    /// 取消所有未完成的requst
    func cancelAllRequest() {
        for dataTask in dataTaskList.values.reversed() {
            dataTask.cancel()
        }
        dataTaskList.removeAll()
    }
}
