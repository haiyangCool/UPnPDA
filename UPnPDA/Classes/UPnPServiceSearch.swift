//
//  UPnPDeviceSearch.swift
//  NetWork
//
//  Created by 王海洋 on 2018/5/23.
//  Copyright © 2020 王海洋. All rights reserved.
//

/**
 UPnP发现可用设备（逻辑设备：提供了可用服务）通过简单服务发现协议（SSDP）在同一局域网内搜索提供所需服务的设备。SSDP是UPnP核心服务之一，提供了在局域网内发现设备的机制。
 通过SSDP, 控制点通过 HTTPMU  (HTTPMU:是基于 MulticastUDP传输的HTTP协议的变体)发出一个多播请求，（请求消息中包含自己感兴趣的设备或者服务的标识），如果提服务的设备监听到请求中的标识与自己的服务匹配则通过HTTPU (HTTPU是基于UDP传输的HTTP协议的变体），使用单播方式向控制点发出响应，声明自己的存在和自己所能提供的服务（搜索-响应方式，SSDP提供的其中一种方式），
 另一种方式则是服务通过HTTPMU协议把自己的服务信息多播通知出去，让网络中的控制点都能接收到（控制点在SSDP预留的地址和端口上监听）--（主动通知方式）
 */

/// 如果遇到 Address in use 的错误，请确认 该App允许使用WiFi网络 ，如果手机上的其他App 也正在使用 DLNA(底层使用了UPnP)功能，当开启 UPnP 监听 UPD 端口时，也会造成 Address in use  的错误【端口被占用】，需要关闭同一手机上其他使用该标准协议的App

import Foundation
import CocoaAsyncSocket


/// 搜索服务：通过HTTPMU 发送多播消息 (通过HTTP协议扩展M-SEARCH实现)
/// SSDP 搜索消息的起始行
let M_SEARCH_HEADER = "M-SEARCH * HTTP/1.1"

/// 多播地址，为UPnP标准设备预留的地址，该地址为固定的，服务在此地址上监听搜索消息
let M_SEARCH_HOST = "239.255.255.250"

/// ipv4 端口
let M_SEARCH_IPV4_PORT = 1900

/// ipv6 端口
let M_SEARCH_IPV6_PORT = "FF0X::C"

/// 查询类型 必须为 ssdp:discover
let M_SEARCH_MAN = "\"ssdp:discover\""

/// 设备响应的最长等待时间
let M_SEARCH_MX = 3

/// UPnP扩展字段，可以填写一些厂商信息： 格式 OS UPnP/1.1 产品/版本
let M_SEARCH_USER_AGENT = "iOS/10 UPnP/1.1 Develop/1.0"

/// 搜索目标 ，必须为下面几种类型
public struct M_SEARCH_Targert{
        
    /// 查询所有服务设备
    static public func all() -> String {
        return "ssdp:all"
    }
    
    /// 查询网络中的根设备
    static public func rootDevice() -> String {
        return "upnp:rootdevice"
    }
    
    /// 查询UUID对应标识的设备
    /// - Parameter uuid: uuid
    static public func uuid(_ uuid: String) -> String {
        return "uuid:device-\(uuid)"
    }
    
    /// 查询 指定的设备类型及版本
    /// - Parameters:
    ///   - deviceType: deviceType
    ///   - code: version code
    static public func deviceType(_ deviceType: String, version code: Int) -> String {
        return "urn:schemas-upnp-org:device:\(deviceType):\(code)"
    }
    
    /// 查询指定服务类型及版本 EXP:投屏  AVTransport   1
    /// - Parameters:
    ///   - serviceType: serviceType
    ///   - code: version code
    static func serviceType(_ serviceType: String, version code: Int) -> String {
        return "urn:schemas-upnp-org:service:\(serviceType):\(code)"
    }
    
}

/// UPnP  服务主动通知 服务是否可用（不可用）
/// 服务可用
let UPnPSERVICEAVALIABLE = "ssdp:alive"
/// 服务消失
let UPnPSERVICEBYEBYE = "ssdp:byebye"


/// 搜索服务的多播消息（M-SEARCH）
public struct M_Search {
    
    public init() {}
    
    /// 默认搜索全部设备
    /// - Parameter searchTarget: searchTarget 为空时，默认搜索全部设备
    public static func info(searchTarget: String) -> String {
//        let st = searchTarget ?? M_SEARCH_Targert.serviceType("AVTransport", version: 1)
        return "\(M_SEARCH_HEADER)\r\nHOST: \(M_SEARCH_HOST):\(M_SEARCH_IPV4_PORT)\r\nMAN: \(M_SEARCH_MAN)\r\nMX: \(M_SEARCH_MX)\r\nST: \(searchTarget)\r\nUSER-AGENT: \(M_SEARCH_USER_AGENT)\r\n\r\n"
    }
}

/// 搜索服务结果
@objc public protocol UPnPServiceSearchDelegate {
    
    /// 搜索到提供服务的设备后，返回包含该服务的设备描述文档
    /// 每当搜索到一台设备，该方法会执行一次
    /// - Parameters:
    ///   - serviceSearch: UPnPServiceSearch
    ///   - devices: devices list
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, upnpDevices devices: [UPnPDeviceDescriptionDocument])
    
    
    /// 搜索设备时发生错误
    /// - Parameters:
    ///   - serviceSearch: UPnPServiceSearch
    ///   - error: error
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, dueTo error: Error)

}

/// UPnP 错误
public struct UPnPError: Error {
    
    private var message: String
    public init(message: String) {
        self.message = message
    }
}

/// 搜索服务
open class UPnPServiceSearch: NSObject {
    
    /// UDP , 通过UDP多播的方式发出搜索请求消息
    lazy var udp: GCDAsyncUdpSocket  = {
        let udp = GCDAsyncUdpSocket.init(delegate: self,
                                         delegateQueue: DispatchQueue.init(label: "com.hyw.udp"))
        return udp
    }()
    
    /// 用来处理搜索结果的串行队列
    lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue.init(label: "serial.com.udp")
        return queue
    }()
    /// 搜索结果的回调代理
    weak public var delegate: UPnPServiceSearchDelegate?
    
    /// 搜索目标， 默认搜所全部设备
    public var searchTarget: String = M_SEARCH_Targert.serviceType("AVTransport", version: 1)
    //M_SEARCH_Targert.all()
    //M_SEARCH_Targert.serviceType("AVTransport", version: 1)
    
    /// 搜索结果，通过服务的唯一标识存放提供该服务的设备（嵌入式设备）
    private lazy var result: [String: UPnPDeviceDescriptionDocument] = [:]
    
    /// 搜索结果列表
    private lazy var deviceList: [UPnPDeviceDescriptionDocument] = []
    
    public override init() {}
}

// MARK:- Public methods
/// 搜索、
/// 结束搜索
extension UPnPServiceSearch {
    
    /// 开始搜索
    public func start() {

        updBind()
        let st = M_Search.info(searchTarget: searchTarget)
        print("Search Target:\n\(st)")
        guard let m_search_data = st.data(using: .utf8) else {
            onError(error: UPnPError(message: "M_SEARCH搜索消息编码失败"))
            return
        }
        /// 发送搜索多播搜索消息
        udp.send(m_search_data, toHost: M_SEARCH_HOST, port: UInt16(M_SEARCH_IPV4_PORT), withTimeout: 0, tag: 1)
    }
    
    /// 停止搜索
    public func stop() {
        if !udp.isClosed() {
            udp.close()
        }
    }
    
}

// MARK:- GCDAsyncUdpSocketDelegate
extension UPnPServiceSearch: GCDAsyncUdpSocketDelegate {
    
    /// 搜索到提供服务的设备，或者设备主动通知提供所需服务
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        parse(responseData: data)
    }
    
    /// 消息发送成功
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("UPnP Search Message Send Success")
    }
    
    /// 消息发送失败
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        onError(error: error ?? UPnPError(message: "UPnP Search Message Send Faild"))
    }
    
    /// UDP 关闭
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if let err = error {
            onError(error: err)
        }
    }
}

// MARK:- Private methods
extension UPnPServiceSearch {
    
    /// 绑定端口，开启UDP 消息监听
    private func updBind() {
        
        do {
            /// 绑定UDP 端口 ，并开始接收该端口数据
            try udp.bind(toPort: UInt16(M_SEARCH_IPV4_PORT))
            try udp.beginReceiving()
            try udp.joinMulticastGroup(M_SEARCH_HOST)
        } catch {
            onError(error: error)
            return
        }
    }
    
    /// 错误
    /// - Parameter message: error message
    private func onError(error: Error) {
        if let delegate = delegate {
            delegate.serviceSearch(self, dueTo: error)
        }
    }
    
    private func parse(responseData: Data) {
        /// 转化设备数据
         func transformDevice(data: Data,
                                    location: String,
                                    serviceIdentifier id: String) {
            
            let parser = UPnPDeviceParser()
            parser.location = location
            parser.parse(data, successCallBack: {[weak self] (ddd) in
                self?.result[id] = ddd
                ddd.serviceIdentifier = id
                self?.addDevice(device: ddd)
                
            }) {[weak self] (error) in
                self?.onError(error: error)
            }
            
            DispatchQueue.main.async {
                if let delegate = self.delegate {
//                    delegate.serviceSearch(self, upnpDevices: self.result.values.reversed() )
                    delegate.serviceSearch(self, upnpDevices: self.deviceList )

                }
            }
        }
        /// 加载设备信息
        func loadDeviceInfo(address: String, serviceIdentifier id: String) {
            serialQueue.async {
                if let url = URL(string: address) {
                    let request = UPnPHTTPURLRequest(url: url)
                    let httpManager = UPnPHTTPManager()
                    httpManager.load(urlRequest: request, successCallBack: { (successData) in
                         transformDevice(data: successData, location: address, serviceIdentifier: id)
                    }) {[weak self] (error) in
                        self?.onError(error: error)
                    }
                }
            }
        }
        
        guard let responseStr = String(data: responseData, encoding: .utf8) else {
            onError(error: UPnPError(message: "Search Resulf Decode Faild"))
            return
        }
        /// 主动通知消息开始行 必须为NOTIFY
        if responseStr.hasPrefix("NOTIFY") {
            let response = UPnPServiceAutoNotify(responseStr)
            /// 如果主动通知的服务可用，而且提供的服务类型为搜索服务类型
            /// 获取搜索到的设备的location，在此地址通过http获取设备描述文档: Device Description Document （DDD）
            if let serviceAvaliable = response.serviceAvaliable, let serviceType = response.serviceType, let location = response.location,let usn = response.serviceUniqueId {
                
                if searchTarget == M_SEARCH_Targert.all() || serviceType == searchTarget {
                 
                    if serviceAvaliable == UPnPSERVICEAVALIABLE {
                        loadDeviceInfo(address: location, serviceIdentifier: usn)
                    }else if (serviceAvaliable == UPnPSERVICEBYEBYE){
                        /// 通知服务不可用时，把该服务对应的设备（逻辑设备）移除
                        if result.keys.contains(usn) {
                            result.removeValue(forKey: usn)
                            removeDevice(identifier: usn)
                        }
                    }
                }
            }
        }
        /// 搜索响应开始行
        if responseStr.hasPrefix("HTTP") {
            //http://192.168.0.101:49152/description.xml
            let response = UPnPServiceSearchResponse(responseStr)
            /// 获取搜索到的设备的location，在此地址通过http获取设备描述文档: Device Description Document （DDD）
            if let location = response.location, let usn = response.serviceUniqueId {
                loadDeviceInfo(address: location, serviceIdentifier: usn)
            }
        }
    }

    /// 添加搜索到的设备到设备列表
       /// - Parameter device: 服务标识 ：设备信息
       private func addDevice(device: UPnPDeviceDescriptionDocument) {
           
           deviceList.append(device)
       }
       
       /// 移除服务标识的设备
       /// - Parameter identifier: service id
       private func removeDevice(identifier: String?) {
           
           if let id = identifier {
               for index in 0..<deviceList.count {
                   if let deviceId = deviceList[index].serviceIdentifier, deviceId == id {
                       deviceList.remove(at: index)
                   }
               }
           }
       }

}
