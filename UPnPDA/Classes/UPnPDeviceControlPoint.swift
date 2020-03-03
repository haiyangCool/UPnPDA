//
//  UPnPDeviceControlPoint.swift
//  NetWork
//
//  Created by 王海洋 on 2020/2/13.
//  Copyright © 2020 王海洋. All rights reserved.
//

/// UPnP 设备控制点
/// UPnP标准规定 控制点和服务之间的信息遵守 简单对象访问协议（Simple Object Access Protocol,SOAP)的格式
/// SOAP 的底层协议一般也是HTTP, 在 UPnP中， SOAP 信息分为3中UPnP Action Request （动作调用）、UPnP Action Response-Success、 UPnP Action Response-Error
/// SOAP 协议与 SSDP稍有不同，SOAP 使用的HTTP消息是需要 Body 内容的在Body中写入想要调用的动作
/// 传递必要的参数（如果需要），服务受到动作请求后，必须进行回应，可以执行或者无法执行（错误响应）

import UIKit
import AEXML
/// 动作
/// Envelope: SOAP 规定使用的元素，必须包含下面的两个属性 xmls 和 encodingStyle，
/// 他们的属性值分别必须为 http://schemas.xmlsoap.org/soap/envelope/ 和 http://schemas.xmlsoap.org/soap/encoding/
/// 动作Body
/// Body : SOAP 规定使用的元素， 在body中必须包含 动作的名称，相关动作参数(如果需要)
/// 比如 投屏动作 SetAVTransportURI
/*
 <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
     <s:Body>
         <u:SetAVTransportURI>
             <InstanceID>0</InstanceID>
             <CurrentURI>http://v.tiaooo.com/llbizosAzGhJPXC0H4AHLTGHl42W</CurrentURI>
             <CurrentURIMetaData></CurrentURIMetaData>
         </u:SetAVTransportURI>
     </s:Body>
 </s:Envelope>
 */


/// UPnP控制动作
public struct UPnPAction {
    
    private(set) var controlUrl: String
    private(set) var serviceType: String
    private(set) var name: String?
    
    /// SOAP 消息信封
    private(set) var soap: AEXMLDocument
    
    private var envelope: AEXMLElement?
    
    
    /// SOAP 动作
    private var action: AEXMLElement?
    
    public init(controlUrl: String,
                serviceType type: String) {
        self.controlUrl = controlUrl
        self.serviceType = type
        self.soap = AEXMLDocument()
        
    }
    
    public mutating func setAction(_ name: String) {
        self.name = name
        action = AEXMLElement(name: "u:\(name)")
        
    }
    
    public mutating func setArgument(_ value: String, for key: String) {
        
        if let action = action {
            action.addChild(name: key, value: value)
        }
    }
    
    /// request 请求
    public mutating func request() -> URLRequest? {
        
        if let url = URL(string: controlUrl), let actionName = name {
            
            let soapAction = "\"\(serviceType)#\(actionName)\""
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
            urlRequest.httpBody = xml().data(using: .utf8)
            return urlRequest
        }
        return nil
    }

}

extension UPnPAction {
    
    /// 获取SOAP 消息的 xml
    private mutating func xml() -> String {
           
       envelope = self.soapEnvelope(serviceType: self.serviceType)
       if let envelop = envelope, let action = action {
           let body = AEXMLElement(name: "s:Body")
           body.addChild(action)
           envelop.addChild(body)
           soap.addChild(envelop)
       }
       return soap.xml
    }
    
    /// SOAP 消息信封 动作所属的服务类型
    private mutating func soapEnvelope(serviceType: String) -> AEXMLElement {
        
        let attributes = [
            "s:encodingStyle" : "http://schemas.xmlsoap.org/soap/encoding/",
            "xmlns:s" : "http://schemas.xmlsoap.org/soap/envelope/",
            "xmlns:u" : serviceType
        ]
        let envelop = soap.addChild(name: "s:Envelope", attributes: attributes)
        return envelop
    }
}

@objc public protocol UPnPDeviceControlPointDelegate {
    
    /// 控制得到相应 （业务层需解析具体数据，查看相应数据是否为成功数据）
    /// - Parameters:
    ///   - controlPoint:
    ///   - data: data
    func controlSuccess(_ controlPoint: UPnPDeviceControlPoint, response data: Data)
    /// 错误
    func controlFaild(_ controlPoint: UPnPDeviceControlPoint, error: Error)
}
/// UPnP 标准设备控制点
public class UPnPDeviceControlPoint: NSObject {
    
    public weak var delegate: UPnPDeviceControlPointDelegate?
    
    public override init() {}
    
    public func invoke(action: UPnPAction) {
       
        var upnpAction = action
        if let request = upnpAction.request() {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    self.faild(error!)
                }
                if let data = data {
                    self.success(data)
                }
            }
            task.resume()
        }else {
            faild(UPnPError(message: "Request 生成错误"))
        }
    }
    
    private func success(_ data: Data) {
        if let delegate = delegate {
            delegate.controlSuccess(self, response: data)
        }
    }
    
    private func faild(_ error: Error) {
        
        if let delegate = delegate {
            delegate.controlFaild(self, error: error)
        }
    }
}
