//
//  UPnPService.swift
//  NetWork
//
//  Created by 王海洋 on 2020/2/12.
//  Copyright © 2020 王海洋. All rights reserved.
//
/** SDD ( Service Description Document) 服务描述文档
   SDD 是对服务功能的基本信息说明，包括该服务上的动作以及参数，还有状态变量及其数据类型、取值范围等
   获取方式： 在获取DDD之后，设备可以从 SCPDURL 中获取针对某个服务的描述文档url, 通过HTTP Get 方式获取
*/

/// 服务文档解析：可以作为了解服务详情的说明文档，她提供了服务所提供的动作名称，以及
/// 执行该动作所需要必要参数，该文档一般作为控制设备的参考，无需自动解析，所以在搜索到设备后
/// 可以通过服务描述文档的URL (DDD的某个具体服务的SCPDURL) 来解析 服务描述文档来获得服务的详细信息 ，
/// 或者直接通过设备描述文档解析某个具体的服务获得服务描述文档
/// UPnPServiceParser 提供了这两种方式，以及直接解析服务XML data(Data)的方式

import UIKit

public class UPnPServiceDescriptionDocument {
    
    /// 仅当服务带有动作时需要该字段
    public var actionList: [UPnPServiceAction]?
    /// 必有字段 （服务可以不包含任何状态变量，字段为空）
    public var serviceStateTable: UPnPServiceStateTable?
}

public class UPnPServiceAction: NSObject, KVCPropertyProtocol {
    
    /// 动作名称
    @objc public var name: String?
    /// 参数 仅当动作定义参数时需要该字段
    public var argumentList: [UPnPActionArgument]?
    
    func kvcAvaliableKeys() -> [String] {
        return ["name"]
    }
    
    /// 通过KVC 安全的设置属性值
    func safeSet(value: Any, forKey key: String) {
        if kvcAvaliableKeys().contains(key) {
            self.setValue(value, forKey: key)
        }
    }
    
}

public class UPnPActionArgument: NSObject, KVCPropertyProtocol {
    
    /// 必有字段 参数名
    @objc public var name: String?
    
    /// 必有字段 无论变量是输入还是输出参数，取值必须为in 或者 out，所有的in变量必须列在所有out变量之后
    @objc public var direction: String?
    
    /// 必有字段 必须是同一服务描述中状态变量的名称，声明本参数和某个状态变量有关。
    @objc public var relatedStateVariable: String?
    
    
    func kvcAvaliableKeys() -> [String] {
         return [
            "name",
            "direction",
            "relatedStateVariable"
        ]
    }
    
    /// 通过KVC 安全的设置属性值
     func safeSet(value: Any, forKey key: String) {
         if kvcAvaliableKeys().contains(key) {
             self.setValue(value, forKey: key)
         }
     }
    
}

public class UPnPServiceStateTable: NSObject {
    
    public var stateVariableList: [UPnPStateVariable]?
}

public class UPnPStateVariable: NSObject, KVCPropertyProtocol {
    
    /**必选属性 定义当这一状态发生变化时是否生成事件消息
     对于UPnP论坛定义的标准状态变量，只有论坛自己可以决定其属性值，而对于设备厂商自己定义的
     默认yes
     非标准状态变量，厂商可以自己决定
     */
    @objc public var sendEvents = "yes"

    /** 可选属性 事件发生时，该消息是采用单播还是多播方式发出，默认为no，
     为yes时，必须同时采用多播和单播
     */
    @objc public var multicast = "no"
    
    /// 必有字段 状态变量名称
    @objc public var name: String?
    
    /// 必有字段 状态变量的取值类型
    @objc public var dataType: String?
    
    /// 默认值
    @objc public var defaultValue: String?

    /// 推荐使用 默认初始值 同时必须满足 allowedValueList 或者 allowedValueRange 的限制
    var allowedValueList: [UPnPStateAllowedValue]?
    var allowedValueRange: UPnPStateAllowedValueRange?

    func kvcAvaliableKeys() -> [String] {
        return [
            "name",
            "dataType",
            "defaultValue"
        ]
    }
    
    /// 通过KVC 安全的设置属性值
    func safeSet(value: Any, forKey key: String) {
        if kvcAvaliableKeys().contains(key) {
            self.setValue(value, forKey: key)
        }
    }
}

public class UPnPStateAllowedValue: NSObject, KVCPropertyProtocol {
    
    @objc public var allowedValue: String?
    
    func kvcAvaliableKeys() -> [String] {
        return ["allowedValue"]
    }
    
    /// 通过KVC 安全的设置属性值
    func safeSet(value: Any, forKey key: String) {
        if kvcAvaliableKeys().contains(key) {
            self.setValue(value, forKey: key)
        }
    }
    
}

public class UPnPStateAllowedValueRange: NSObject, KVCPropertyProtocol {
    
    /// 保存时，统一保存为字符串类型，使用时
    @objc public var minimum: String?
    @objc public var maximum: String?
    /// 可选
    @objc public var step: String?
    
    
    func kvcAvaliableKeys() -> [String] {
        return [
            "minimum",
            "maximum",
            "step"
        ]
    }
    
    /// 通过KVC 安全的设置属性值
    func safeSet(value: Any, forKey key: String) {
        if kvcAvaliableKeys().contains(key) {
            self.setValue(value, forKey: key)
        }
    }
    
}

/// 解析成功后 返回 设备描述文档对象
public typealias ParseServicdSuccessCallBack = (_ device: UPnPServiceDescriptionDocument) -> Void
public typealias ParseServiceFaildCallBack = (_ error: Error) -> Void
/// 负责服务描述文档的解析，并生成 服务描述文档的简单模型
public class UPnPServiceParser: NSObject {

    public var successCallBack: ParseServicdSuccessCallBack?
    public var faildCallBack: ParseServiceFaildCallBack?
    
    /// 需要解析的数据最小根节点
    private var targetElement = "scpd"
    
    /// 当前节点
    private var currentElement = "scpd"
    
    /// 服务描述文档
    private var serviceDesDoc =  UPnPServiceDescriptionDocument()
    
    /// 动作列表 ------------------------------------------------------------
    private var actionList: [UPnPServiceAction] = []
    /// 动作
    private var action = UPnPServiceAction()
    
    /// 动作的参数列表
    private var argumentList: [UPnPActionArgument] = []
    /// 参数
    private var argument = UPnPActionArgument()
    
    /// 服务状态表
    private var serviceStateTable = UPnPServiceStateTable()
    
    private var stateVariableList: [UPnPStateVariable] = []
    private var stateVariable = UPnPStateVariable()
    
    /// 状态的可用值列表
    private var allowedValueList: [UPnPStateAllowedValue] = []
    private var allowedValue = UPnPStateAllowedValue()
    /// 状态的可用值范围
    private var allowedValueRange = UPnPStateAllowedValueRange()

    
    public override init() {}
    
    
    /// 通过服务所在地址，加载HTTP 请求，并解析描述文档
    /// - Parameters:
    ///   - url: 服务地址 url
    ///   - success: success closure
    ///   - faild: faild closure
    public func load(url: URL,
                     successCallBack success: @escaping ParseServicdSuccessCallBack,
                     faildCallBack faild: @escaping ParseServiceFaildCallBack) {
        let request = UPnPHTTPURLRequest(url: url)
        let httpManager = UPnPHTTPManager()
        httpManager.load(urlRequest: request, successCallBack: { (successData) in
          
            self.parse(successData, successCallBack: success, faildCallBack: faild)
           
        }) {(error) in
            self.onError(error: error)
        }
    }
    
    /// 通过设备描述文档，解析目标 服务类型的 服务描述文档
    /// - Parameters:
    ///   - deviceDoc: DDD 设备描述文档
    ///   - type: 服务类型
    ///   - success: success closure
    ///   - faild: faild closure
    public func parse(_ deviceDoc: UPnPDeviceDescriptionDocument,
                      aimServiceType type: String,
                      successCallBack success: @escaping ParseServicdSuccessCallBack,
                      faildCallBack faild: @escaping ParseServiceFaildCallBack ) {
        if let serviceList = deviceDoc.serviceBriefList {
            for service in serviceList {
                if let serviceType = service.serviceType, serviceType == type {
                    
                    if let urlBase = deviceDoc.URLBase, let specUrl = service.SCPDURL {
                        if let url = URL(string: urlBase+specUrl) {
                            load(url: url, successCallBack: success, faildCallBack: faild)
                        }
                    }
                }
            }
        }
    }
    
    /// 解析服务描述文档
    /// - Parameters:
    ///   - data: data of SDD
    ///   - success: success closure
    ///   - faild: faild closure
    public func parse(_ data: Data,
                      successCallBack success: @escaping ParseServicdSuccessCallBack,
                      faildCallBack faild: @escaping ParseServiceFaildCallBack) {
        successCallBack = success
        faildCallBack = faild
        /// 解析 XML Data
        if let serviceDesDoc = String(data: data, encoding: .utf8) {
            print("Service Description Document xml :\n \(serviceDesDoc)")
        }
        let xmlParser = XMLParser.init(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
    
    }
}

// MARK: XMLParserDelegate
extension UPnPServiceParser: XMLParserDelegate {
    
    public func parserDidStartDocument(_ parser: XMLParser) {
//        print("Start Decode SDD XML")
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //print("Start Decode ElementNode \(elementName)")
        
        currentElement = elementName
        switch elementName {
        case "action":
            targetElement = elementName
            /// 每解析一个action节点，就创建一个新的动作
            // 清空参数列表
            argumentList = []
            let newAction = UPnPServiceAction()
            action = newAction
            break
        case "argument":
            targetElement = elementName
            /// 每解析一个参数节点，就h创建一个新的参数变量
            let newArgument = UPnPActionArgument()
            argument = newArgument
            break
        case "stateVariable":
            targetElement = elementName
            let stateAttrKeys = attributeDict.keys
            let newStateVariable = UPnPStateVariable()
            stateVariable = newStateVariable
            if stateAttrKeys.contains("sendEvents") {
                stateVariable.sendEvents = attributeDict["sendEvents"] ?? "no"
            }
            if stateAttrKeys.contains("multicast") {
                stateVariable.multicast = attributeDict["multicast"] ?? "no"
            }
            
            allowedValueList = []
            break
        case "allowedValue":
            targetElement = elementName
            let newAllowedValue = UPnPStateAllowedValue()
            allowedValue = newAllowedValue
            break
        case "allowedValueRange":
            targetElement = elementName
            let newAllowedValueRange = UPnPStateAllowedValueRange()
            allowedValueRange = newAllowedValueRange
            break
        default:
            break
        }
       
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        /// 动作节点
        if targetElement == "action" {
            action.safeSet(value: string, forKey: currentElement)
        }
        if targetElement == "argument" {
            argument.safeSet(value: string, forKey: currentElement)
        }
    
        /// 状态节点
        if targetElement == "stateVariable" {
            stateVariable.safeSet(value: string, forKey: currentElement)
        }
        if targetElement == "allowedValue" {
            allowedValue.safeSet(value: string, forKey: currentElement)
        }
        if targetElement == "allowedValueRange" {
            allowedValueRange.safeSet(value: string, forKey: currentElement)
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        //print("End Decode ElementNode \(elementName)")
     
        /// 参数节点结束放入参数列表
        if elementName == "argument" {
            argumentList.append(argument)
        }
        /// 一个动作节点结束
        if elementName == "action" {
            action.argumentList = argumentList
            actionList.append(action)
        }
        
        /// 状态Tabel
        if elementName == "allowedValue" {
            allowedValueList.append(allowedValue)
        }
        
        if elementName == "allowedValueRange" {
            stateVariable.allowedValueRange = allowedValueRange
        }
        /// stateVariable 结束
        if elementName == "stateVariable" {
            stateVariable.allowedValueList = allowedValueList
            stateVariableList.append(stateVariable)
        }
      
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
//        print("End Decode SDD XML")
        serviceDesDoc.actionList = actionList
        serviceStateTable.stateVariableList = stateVariableList
        serviceDesDoc.serviceStateTable = serviceStateTable
                
        if let successCallback = successCallBack {
            successCallback(serviceDesDoc)
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        onError(error: parseError)
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        onError(error: validationError)
    }
}

// MARK: Private methods
extension UPnPServiceParser {
    
    private func onError(error: Error) {
        if let faildCallback = faildCallBack {
            faildCallback(error)
        }
    }
}
