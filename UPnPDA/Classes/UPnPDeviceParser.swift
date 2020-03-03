//
//  UPnPDevice.swift
//  NetWork
//
//  Created by 王海洋 on 2018/5/23.
//  Copyright © 2020 王海洋. All rights reserved.
//
/// UPnP标准的设备（嵌入式设备）
/// 一台标准设备可能包含多个嵌入式设备，在搜索到包含特定服务的设备，或者嵌入式设备后 ，
/// 都将他们作为一台独立的设备处理，方便对服务进行管理
///
/// Device Description Document (DDD), 格式由UPnP厂商决定，采用XML编写，并遵守标准UPnP设备模板
/// 包含设备基础的信息描述，和提供的服务信息列表

import Foundation


/// 可以使用 KVC  设置值得属性Key
protocol KVCPropertyProtocol {
    
    /// kvc avaliable keys
    func kvcAvaliableKeys() -> [String]
}

public class UPnPDeviceDescriptionDocument: NSObject {
    /// 在UPnP1.0中，应该包含URLBase,
    /// 该节点在 device 节点外
    /// 用于和其他的相对路径构建绝对路径的URL,这有设备厂商决定，在1.1版本中，已经去除该标签。
    /// 如果没有URLBase 节点，使用 获取location的 IP，和服务中的控制、事件订阅等相对地址进行拼接
    @objc public var URLBase: String? // depatch after UPnP 1.1
    
    /// 在UPnP 1.1 之后的版本中，URLBase 不再使用, 所以在这里使用IP,Port 组合成urlBase
    public var ip: String?
    public var port: String?
    /// UPnP 1.1 之后使用
    public var urlBase_for_highVersion: String?
    
    /// 服务类型:
    public var serviceIdentifier: String?
    
    /**
     必有字段  UPnP设备类型
        由UPnP定义的标准设备类型，必须以urn:schemas-upnp-org:device开始，后面带有设备类型和版本（整数）
        标准设备 urn:schemas-upnp-org:device:MediaRenderer:1
        由UPnP设备厂商指定的非标准设备，必须以 urn: 开头，后面跟厂商的域名，然后是 :device: 后面是设备类型和版本（整数）
        非标准设备 urn:mi-com:service:RController:1
     */
    @objc public var deviceType: String?

    /// 必有字段 提供给用户的简短描述 有UPnP厂商决定
    @objc public var friendlyName: String?
    
    /// 必有字段 制造商名称 有UPnP厂商决定
    @objc public var manufacture: String?
    
    /// 必有字段 制造商网站 有UPnP厂商决定
    @objc public var manufactureURL: String?
    
    /// 推荐使用：给用户阅读的详细描述 有UPnP厂商决定
    @objc public var modelDescription: String?
    
    /// 必有字段 型号名称
    @objc public var modelName: String?
    
    /// 必有字段 型号字符串
    @objc public var modelNumber: String?
    
    /// 可选 有型号信息的网站URL
    @objc public var modelURL: String?
    
    /// 必有字段 唯一设备名称（设备UUID）值以uuid: 开头
    @objc public var UDN: String?
    
    /// 可选 通用产品代码 12位全数字代码，用于确定销售包装，内容由厂商决定
    @objc public var UPC: String?
        
    /// 可选，当设备提供服务时
    @objc public var serviceBriefList: [UPnPServiceBrief]?
    
    public override init() {}

}

extension UPnPDeviceDescriptionDocument: KVCPropertyProtocol {
    
    func kvcAvaliableKeys() -> [String] {
        return [
            "deviceType",
            "friendlyName",
            "manufacture",
            "manufactureURL",
            "modelDescription",
            "modelName",
            "modelNumber",
            "modelURL",
            "UDN",
            "UPC"
        ]
    }
}

/// 服务概览
public class UPnPServiceBrief: NSObject {
    
    /** 必有字段  UPnP服务类型
        由UPnP定义的标准服务类型，必须以urn:schemas-upnp-org:service开始，后面带有设备类型和版本（整数）
        标准设备 urn:schemas-upnp-org:device:AVTransport:1
        由UPnP设备厂商指定的非标准设备，必须以 urn: 开头，后面跟厂商的域名，然后是 :device: 后面是设备类型和版本（整数）
        非标准设备 urn:mi-com:service:RController:1
     */
     @objc public var serviceType: String?
    
    /** 必有字段  服务标识符，服务实例的唯一标识
        对于由UPnP定义的标准服务，必须以 urn:UPnP-org:serviceId: 开头，后面是服务id最后后缀
        标准服务：urn:upnp-org:serviceId:AVTransport
        对于由UPnP设备厂商指定的非标准服务，必须以 urn: 开头，跟厂商域名，然后是 :serviceId:,接着是服务id后缀
        非标准服务：urn:domain-name:serviceId:AVTransport
     */
    @objc public var serviceId: String?

    /// 必有字段 向服务发出控制消息的URL
    @objc public var controlURL: String?
    
    /// 必有字段 订阅该服务的URL
    @objc public var eventSubURL: String?
    
    /// 必有字段 (Service Control Protocol Description URL) , 是获取服务描述文档 -Service Description Document （SDD）的URL
    @objc public var SCPDURL: String?
    
    /// 设备展示的URL
    @objc public var presentationURL: String?
    
    public override init() {}
}

extension UPnPServiceBrief: KVCPropertyProtocol {
    
    func kvcAvaliableKeys() -> [String] {
        return [
            "serviceType",
            "serviceId",
            "controlURL",
            "eventSubURL",
            "SCPDURL",
            "presentationURL"
        ]
    }
}

/// 解析成功后 返回 设备描述文档对象
public typealias ParseDeviceSuccessCallBack = (_ device: UPnPDeviceDescriptionDocument) -> Void
public typealias ParseDeviceFaildCallBack = (_ error: Error) -> Void


/// UPnPDevice 负责解析 DDD, 成功后返回 设备描述文档模型
public class UPnPDeviceParser: NSObject {
    
    /// 当前节点
    var currentElementName = "root"
   
    /// 目标节点（包含其他需要的节点数据 比如 device  serviceList）
    var currentTragetElementName = "root"
   
    /// UPnP Device Description Document (DDD)
    var deviceDescriptionDoc = UPnPDeviceDescriptionDocument()
   
    /// UPnP Devices Brief
    var serviceBrief = UPnPServiceBrief()
   
    /// URLBase
    var urlBase: String?
    
    /// 在1.1版本中，已经移除了URLBase标签，从外部传递location，在URLBase 不存在时使用location解析ip和port作为替代
    public var location: String?
    
    /// 服务简述
    var serviceBriefList: [UPnPServiceBrief] = []
    
    /// 解析回调闭包
    var successCallBack: ParseDeviceSuccessCallBack?
    var faildCallBack: ParseDeviceFaildCallBack?
    
    public override init() {}
    
    public func parse(_ data: Data,
                          successCallBack success: @escaping ParseDeviceSuccessCallBack,
                          faildCallBack faild: @escaping ParseDeviceFaildCallBack) {
        successCallBack = success
        faildCallBack = faild
        
        parseLocation(location)
        /// 解析 XML Data
        let xmlParser = XMLParser.init(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
    }
}

extension UPnPDeviceParser: XMLParserDelegate {
    
    public func parserDidStartDocument(_ parser: XMLParser) {}
        
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
        switch currentElementName {
        case "device":
            currentTragetElementName = currentElementName
            break
        case "service":
            currentTragetElementName = currentElementName
            /// 遇到新的service节点时，创建一个新的service
            serviceBrief = UPnPServiceBrief()
            break
        case "URLBase":
            currentTragetElementName = currentElementName
            break
        default:
            break
        }
    }
        
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let elementValue = string
        if elementValue.isEmpty || elementValue.count < 1 || elementValue.hasPrefix("\n"){
            return
        }
        switch currentTragetElementName {
        case "device":
            setDeviceElement(elementValue)
            break
        case "service":
            setServiceElement(elementValue)
            break
        case "URLBase":
            deviceDescriptionDoc.URLBase = elementValue
            break
        default:
            break
        }
    }
        
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "device":
            break
        case "service":
            serviceBriefList.append(serviceBrief)
            break
        default:
            break
        }
    }
        
    public func parserDidEndDocument(_ parser: XMLParser) {
        /// 组成最后的服务列表
        deviceDescriptionDoc.serviceBriefList = serviceBriefList
        if let successCallback = successCallBack {
            successCallback(deviceDescriptionDoc)
        }
            
    }
        
    /// 解析出现错误
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        onError(error: parseError)
    }
        
    // 出现错误
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        onError(error: validationError)
    }
}

// MARK: Private methods
extension UPnPDeviceParser {
    
    /// 设置 UPnP 设备的属性
    /// - Parameter value:
    private func setDeviceElement(_ value: String) {
    
        for element in deviceDescriptionDoc.kvcAvaliableKeys() {
            if element == currentElementName {
                deviceDescriptionDoc.setValue(value, forKey: element)
            }
        }
    }
    
    private func setServiceElement(_ value: String) {
    
        for element in serviceBrief.kvcAvaliableKeys() {
            if element == currentElementName {
                serviceBrief.setValue(value, forKey: element)
            }
        }
    }
    
    private func onError(error: Error) {
        if let faild = faildCallBack {
            faild(error)
        }
    }
    
    private func parseLocation(_ locationStr: String?) {
        /// http://192.168.0.101:63065/upnp/dev/xxxx....
        if let locationAddress = locationStr, locationAddress.hasPrefix("http://") {
            let newLocation = locationAddress.replacingOccurrences(of: "http://", with: "")
            
            let locationItems = newLocation.split(separator: "/")
            if locationItems.count > 0 {
                var ip = "172.0.0.1"
                var port = "80"
                let ipPort = locationItems[0]
                let ipItems = ipPort.split(separator: ":")
                if ipItems.count > 0 {
                    ip = String(ipItems[0])
                    deviceDescriptionDoc.ip = ip
                }
                if ipItems.count > 1 {
                    port = String(ipItems[1])
                    deviceDescriptionDoc.port = port
                }
                deviceDescriptionDoc.urlBase_for_highVersion = "http://\(ip):\(port)"
            }
        }
      
    }
}
