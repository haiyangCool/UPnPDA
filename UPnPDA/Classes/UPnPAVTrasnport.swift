//
//  AVTrasnport.swift
//  NetWork
//
//  Created by 王海洋 on 2020/2/13.
//  Copyright © 2020 王海洋. All rights reserved.
//
/// DLNA 最重要的标准就是音视频的定义
/// DLNA 对音视频的共享进行了严格的定义

import UIKit
import AEXML
/// DLNA 控制中最重要的两个服务类型
/// urn:schemas-upnp-org:service:AVTransport:1
public let AVTRANSPORTSERVICE = M_SEARCH_Targert.serviceType("AVTransport", version: 1)
/// urn:schemas-upnp-org:service:RenderingControl:1
public let RENDERINGCONTROLSERVICE = M_SEARCH_Targert.serviceType("RenderingControl", version: 1)


/// Seek 寻址 Unit的几种类型
public let SeekUnit_ABS_TIME = "ABS_TIME"
public let SeekUnit_REL_TIME = "REL_TIME"
public let SeekUnit_ABS_COUNT = "ABS_COUNT"
public let SeekUnit_REL_COUNT = "REL_COUNT"
public let SeekUnit_TRACK_NR = "TRACK_NR"
public let SeekUnit_CHANNEL_FREQ = "CHANNEL_FREQ"
public let SeekUnit_TAPE_INDEX = "TAPE-INDEX"
public let SeekUnit_FRAME = "TAPE-FRAME"

///播放模式 3 种模式
public enum UPnPPlayMode: String {
    
    /// 正常模式
    case NORMAL
    /// 全部重复播放
    case REPEAT_ALL
    /// 简介, 一般只播放前面的一段
    case INTRO
}

/// 动作 Response
private enum AVTransprotActionResponse: String {
    
    /// AVTransport
    /// 设置投屏地址
    case SetAVTransportURIResponse
    /// 播放
    case PlayResponse
    /// 暂停
    case PauseResponse
    /// 停止投屏
    case StopResponse
    /// 下一个
    case NextResponse
    /// 上一个
    case PreviousResponse
    /// Seek 寻址
    case SeekResponse
    /// 获取播放时间信息
    case GetPositionInfoResponse
    /// 获取播放状态信息（播放、暂停）
    case GetTransportInfoResponse
    /// 获取媒体信息
    case GetMediaInfoResponse
    /// 获取当前动作
    case GetCurrentTransportActionsResponse
    
    /// Rendering Action Response
    /// 设置音量
    case SetVolumeResponse
    /// 获取音量
    case GetVolumeResponse
}

public struct UPnpActionError: Error {
    
    /// Fault
    public let faultCode: String
    /// UPnPError
    public let faultString: String
    /// Detail
    /// 错误码
    public let errorCode: String
    /// 错误描述
    public let errorDescription: String
    
    init(faultCode: String,
         faultString: String,
         errorCode: String,
         errorDescription: String) {
        self.faultCode = faultCode
        self.faultString = faultString
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }
}

public struct UPnPMediaPositionInfo {
    
    public var durationString: String?
    public var durationValue: Float?

    public var playbackTimeString: String?
    public var playbackTimeValue: Float?
    
    init() {}
    
    init(durationStr: String, duration: Float, playbackTimeStr: String, playbackTime: Float) {
        
        self.durationString = durationStr
        self.durationValue = duration
        self.playbackTimeString = playbackTimeStr
        self.playbackTimeValue = playbackTime
    }
}

public struct UPnPMediaInfo {
    public var durationStr: String?
    public var duration: Float?
    public var currentUri: String?
    public var currentUriMetaDataInfo: String?
    public var nextUri: String?
    public var nextUriMetaDataInfo: String?
    public var playMedium: String?
    public var recordMedium: String?
    public var writeStatus: String?
    
    init() {}
}

public protocol UPnPAVTrasnportDelegate: NSObjectProtocol {
    
    /// 发出动作指令后， 如果UPnP设备发回执行成功的响应后，会回调响应的动作执行成功的回调方法
    /// 如果UPnP设备执行动作指令失败， 则回调错误方法
    /// 设置投屏地址执行成功
    /// - Parameter result: success or faild
    func setAVTransportUriActionRunSuccess()
    
    /// 播放执行执行成功
    /// - Parameter isSuccess:
    func playActionRunSuccess()
    
    /// 暂停动作执行成功
    /// - Parameter isSuccess:
    func pauseActionRunSuccess()
    
    /// 停止投屏成功
    func stopActionRunSuccess()
    
    /// 下一个
    func nextActionRunSuccess()
    
    /// 上一个
    func previousActionRunSuccess()

    /// 跳转播放
    func seekActionRunSuccess()
    
    /// 获取当前的播放时间轴信息成功
    /// - Parameter position:
    func getPositionInfoActionRunSuccess(position: UPnPMediaPositionInfo)
    
    /// TransportInfo 状态 Play or Play
    func getTransportInfoActionRunSuccess(state: String)
    
    /// 获取媒体资源信息成功
    func getMediaInfoActionRunSuccess(mediaInfo: UPnPMediaInfo)
    
    /// 音量获取成功
    /// - Parameter volume:
    func getVolumeActionRunSuccess(volume: Int)
    
    /// 这只音量成功
    func setVolumeActionRunSuccess()
    /// 动作执行出错，错误信息
    func error(_ avTransport: UPnPAVTrasnport, error: Error)
    
}

open class UPnPAVTrasnport: NSObject {
    
    weak var delegate: UPnPAVTrasnportDelegate?
    private var deviceDesDoc: UPnPDeviceDescriptionDocument?
    private(set) var urlBase: String = ""
    private(set) var avTransportControlUrl: String = ""
    private(set) var renderingControlUrl: String = ""
    public override init() {}
    
    public func control(_ deviceDescriptionDocument: UPnPDeviceDescriptionDocument) {
        self.deviceDesDoc = deviceDescriptionDocument
        
        if let baseUrl = self.deviceDesDoc?.URLBase,let serviceBriefList = self.deviceDesDoc?.serviceBriefList {
            urlBase = baseUrl
            
            for serviceBrief in serviceBriefList {
                if let serviceType = serviceBrief.serviceType, serviceType == AVTRANSPORTSERVICE {
                    if let controlUrl = serviceBrief.controlURL {
                        avTransportControlUrl = controlUrl
                    }
                }
                
                if let serviceType = serviceBrief.serviceType, serviceType == RENDERINGCONTROLSERVICE {
                    if let controlUrl = serviceBrief.controlURL {
                        renderingControlUrl = controlUrl
                    }
                }
            }
        }
    }
   
}

// MARK: Public methods
extension UPnPAVTrasnport {
    
    /// 设置投屏地址播放
    /// 动作名：SetAVTransportURI
    /// 输入参数列表：
    /// InstanceID:     id
    /// CurrentURI ： 播放地址
    /// CurrentURIMetaData: 可为空
    public func setAVTransportUri(uri: String) {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("SetAVTransportURI")
        action.setArgument("0", for: "InstanceID")
        action.setArgument(uri, for: "CurrentURI")
        action.setArgument("", for: "CurrentURIMetaData")
        sendAction(action: action)
    }

    /// 设置下一条数据
    /// - Parameter uri: location
    public func setNextAVTransportUri(uri: String) {
      
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("SetNextAVTransportURI")
        action.setArgument("0", for: "InstanceID")
        action.setArgument(uri, for: "NextURI")
        action.setArgument("", for: "NextURIMetaData")
        sendAction(action: action)
    }
    
    /// 播放
    /// 动作名：Play
    /// 输入参数列表：
    /// InstanceID:     id
    /// Speed ：播放为1
    public func play() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Play")
        action.setArgument("0", for: "InstanceID")
        action.setArgument("1", for: "Speed")
        sendAction(action: action)
    }
    
    /// 暂停
    /// 动作名：Pause
    /// 输入参数列表：
    /// InstanceID:     id
    public func pause() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Pause")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    /// 停止投屏
    /// 动作名：Stop
    /// 输入参数列表：
    /// InstanceID:     id
    public func stop() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Stop")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    /// 下一个
    /// 动作名：Next
    /// 输入参数列表：
    /// InstanceID:     id
    public func next() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Next")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    /// 上一个
    /// 动作名：Previous
    /// 输入参数列表：
    /// InstanceID:     id
    public func previous() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Previous")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    /// 设置音量
    /// 动作名：SetVolume
    /// 输入参数列表：
    /// InstanceID:          id
    /// Channel:             Master
    /// DesiredVolume:  音量
    public func setVolume(_ volum: Int) {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: RENDERINGCONTROLSERVICE), serviceType: RENDERINGCONTROLSERVICE)
        action.setAction("SetVolume")
        action.setArgument("0", for: "InstanceID")
        action.setArgument("Master", for: "Channel")
        action.setArgument("\(volum)", for: "DesiredVolume")
        sendAction(action: action)
    }
    
    /// 在UPnP设备发回响应后，在代理方法中取得返回值
    /// 动作名：GetVolume
    /// 输入参数列表：
    /// InstanceID:          id
    /// Channel:             Master
    public func getVolume() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: RENDERINGCONTROLSERVICE), serviceType: RENDERINGCONTROLSERVICE)
        action.setAction("GetVolume")
        action.setArgument("0", for: "InstanceID")
        action.setArgument("Master", for: "Channel")
        sendAction(action: action)
    }
    
    /// 跳转时间
    /// 动作名：Seek
    /// 输入参数列表：
    /// InstanceID:          id
    /// Unit
    ///     <allowedValue>ABS_TIME</allowedValue>
    ///     <allowedValue>REL_TIME</allowedValue>
    ///     <allowedValue>ABS_COUNT</allowedValue>
    ///     <allowedValue>REL_COUNT</allowedValue>
    ///     <allowedValue>TRACK_NR</allowedValue>
    ///     <allowedValue>CHANNEL_FREQ</allowedValue>
    ///     <allowedValue>TAPE-INDEX</allowedValue>
    ///     <allowedValue>FRAME</allowedValue>
    /// Target
    public func seek(time: String) {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("Seek")
        action.setArgument("0", for: "InstanceID")
        action.setArgument(SeekUnit_REL_TIME, for: "Unit")
        action.setArgument(time, for: "Target")
        sendAction(action: action)
    }
    
    
    /// Seek real time
    /// - Parameter time: float value
    public func seek(time: Float) {
        
        seek(time: realTime(time: time))
        
    }
    
    /// 设置播放模式
    /// 动作名：SetPlayMode
    /// 输入参数列表：
    /// InstanceID:          id
    /// NewPlayMode:    NORMAL \ REPEAT_ALL \ INTRO 三种模式
    public func setPlayMode(_ mode: UPnPPlayMode = .NORMAL) {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("SetPlayMode")
        action.setArgument("0", for: "InstanceID")
        action.setArgument("\(mode.rawValue)", for: "NewPlayMode")
        sendAction(action: action)
    }
    
    /// 获取当前正在执行的Transport动作
    /// 动作名：GetCurrentTransportActions
    /// 输入参数列表：
    /// InstanceID:          id
    /// 输出参数列表:  在设备响应信息中解析获取
    /// Actions:
    
    /**
    public func getCurrentTransportActions() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("GetCurrentTransportActions")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    */
    
    /// 获取媒体信息 （一班不会使用）
    /// 动作名：GetMediaInfo
    /// 输入参数列表：
    /// InstanceID:          id
    /// 输出参数列表: 在设备响应信息中解析获取
    /// NrTracks、MediaDuration、CurrentURI、CurrentURIMetaData、NextURI、NextURIMetaData、PlayMedium、RecordMedium、WriteStatus
    public func getMediaInfo() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("GetMediaInfo")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    /// 获取播放的位置信息
    /// 动作名：GetPositionInfo
    /// 输入参数列表：
    /// InstanceID:          id
    /// 输出参数列表: 在设备响应信息中解析获取
    /// Track、
    /// TrackDuration（视频时长）、
    /// TrackMetaData、
    /// TrackURI（播放地址）、
    /// RelTime、AbsTime -- 「播放时间」
    /// RelCount、AbsCount  「播放时间毫」
    public func getPositionInfo() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("GetPositionInfo")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    ///  获取 Transport 信息, 标识当前的播放状态
    /// 动作名：GetTransportInfo
    /// 输入参数列表：
    /// InstanceID:          id
    /// 输出参数列表: 在设备响应信息中解析获取
    /// CurrentTransportState   : 当前状态
    /// CurrentTransportStatus ：OK
    /// CurrentSpeed:
    public func getTransportInfo() {
        var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
        action.setAction("GetTransportInfo")
        action.setArgument("0", for: "InstanceID")
        sendAction(action: action)
    }
    
    ///  获取 Transport 设置
    /// 动作名：GetTransportSettings
    /// 输入参数列表：
    /// InstanceID:          id
    /// 输出参数列表: 在设备响应信息中解析获取
    /// PlayMode   :  播放模式
    /// RecQualityMode
    /**
    public func getTransportSettings() {
         var action = UPnPAction(controlUrl: controlUrl(serviceType: AVTRANSPORTSERVICE), serviceType: AVTRANSPORTSERVICE)
         action.setAction("GetTransportSettings")
         action.setArgument("0", for: "InstanceID")
         sendAction(action: action)
     }
     */


}

extension UPnPAVTrasnport: UPnPDeviceControlPointDelegate {
    
    public func controlSuccess(_ controlPoint: UPnPDeviceControlPoint, response data: Data) {
        
        parse(data)
    }
    
    public func controlFaild(_ controlPoint: UPnPDeviceControlPoint, error: Error) {
        
        onError(error)
    }
}



// MARK: Private methods
extension UPnPAVTrasnport {

    /// 发送动作请求
    private func sendAction(action: UPnPAction) {
        let controlPoint = UPnPDeviceControlPoint()
        controlPoint.delegate = self
        controlPoint.invoke(action: action)
    }
    
    private func parse(_ data: Data) {
        
        do {
            let xmlDoc = try AEXMLDocument(xml: data, options: AEXMLOptions())
            print("response xml : \(xmlDoc.xml)")

            let children = xmlDoc.root.children
            if children.count > 0 {
                let bodyElement = children[0]
                if bodyElement.name.hasSuffix("Body") {
                    parseBodyElement(element: bodyElement)
                }
            }
        } catch {
            // error
            let upnpError = UPnpActionError(faultCode: "-", faultString: "-", errorCode: "", errorDescription: "Parse XML data error : \(error.localizedDescription)")
            onError(upnpError)
        }
    }
    
    private func parseBodyElement(element: AEXMLElement) {
        
        for childElement in element.children {
            let elementName = childElement.name
            print("动作名：\(childElement.xml)")
            
            if elementName.hasSuffix("Fault") {
                /// 动作执行失败后，返回的错误信息
                let faultdCode = childElement["faultcode"].value ?? "None"
                let faultString = childElement["faultstring"].value ?? "None"
                /// detail
                let errorCode = childElement["detail"]["UPnPError"]["errorCode"].value ?? "None"
                let errorDescription = childElement["detail"]["UPnPError"]["errorDescription"].value ?? "None"
                let upnpError = UPnpActionError(faultCode: faultdCode, faultString: faultString, errorCode: errorCode, errorDescription: errorDescription)
                onError(upnpError)
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.SetAVTransportURIResponse.rawValue) {
                /// 投屏连接成功
                delegate.setAVTransportUriActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.PlayResponse.rawValue) {
                /// 播放成功
                delegate.playActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.PauseResponse.rawValue) {
                /// 暂停成功
                delegate.pauseActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.StopResponse.rawValue) {
                /// 结束投屏成功
                delegate.stopActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.SetVolumeResponse.rawValue) {
                /// 设置音量 成功
                delegate.setVolumeActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.GetVolumeResponse.rawValue) {
                /// 获取音量成功
                if let currentVolume = childElement["CurrentVolume"].value {
                    let volume = Int(currentVolume) ?? 0
                    delegate.getVolumeActionRunSuccess(volume: volume)
                }
            
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.NextResponse.rawValue) {
                /// 下一个 成功
                delegate.nextActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.PreviousResponse.rawValue) {
                /// 上一个 成功
                delegate.previousActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.SeekResponse.rawValue) {
                /// Seek 寻址播放
                delegate.seekActionRunSuccess()
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.GetPositionInfoResponse.rawValue) {
                /// 获取播放位置信息成功
                if  let duration = childElement["TrackDuration"].value, let playbackTime = childElement["RelTime"].value {
                    
                    let durationSeconds = timeValue(time: duration)
                    let playbackTimeSeconds = timeValue(time: playbackTime)
                    let positionInfo = UPnPMediaPositionInfo(durationStr: duration, duration: durationSeconds, playbackTimeStr: playbackTime, playbackTime: playbackTimeSeconds)
                    
                    delegate.getPositionInfoActionRunSuccess(position: positionInfo)
                }
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.GetTransportInfoResponse.rawValue) {
                /// 获取当前播放状态 信息 成功
                /// 播放 or 暂停
                if let currentState = childElement["CurrentTransportState"].value {
                    delegate.getTransportInfoActionRunSuccess(state: currentState)
                }
                
            }
            
            if let delegate = delegate, elementName.hasSuffix(AVTransprotActionResponse.GetMediaInfoResponse.rawValue) {
                /// 过去媒体资源信息
                var mediaInfo = UPnPMediaInfo()
                
                if let durationStr = childElement["MediaDuration"].value {
                    mediaInfo.durationStr = durationStr
                    let duration = timeValue(time: durationStr)
                    mediaInfo.duration = duration
                }
                
                mediaInfo.currentUri = childElement["CurrentURI"].value
                mediaInfo.currentUriMetaDataInfo = childElement["CurrentURIMetaData"].value
                mediaInfo.nextUri = childElement["NextURI"].value
                mediaInfo.nextUriMetaDataInfo = childElement["NextURIMetaData"].value
                mediaInfo.playMedium = childElement["PlayMedium"].value
                mediaInfo.recordMedium = childElement["RecordMedium"].value
                mediaInfo.writeStatus = childElement["WriteStatus"].value

                delegate.getMediaInfoActionRunSuccess(mediaInfo: mediaInfo)
            }
            
        }
    }
    
    private func onError(_ error: Error) {
        
        if let delegate = delegate {
            delegate.error(self, error: error)
        }
    }
    
    private func controlUrl(serviceType: String) -> String {
        
        if serviceType == AVTRANSPORTSERVICE {
            
            if !avTransportControlUrl.hasPrefix("/") {
                return urlBase+"/"+avTransportControlUrl
            }
        }
        
        if serviceType == RENDERINGCONTROLSERVICE {
            if !renderingControlUrl.hasPrefix("/") {
                return urlBase+"/"+renderingControlUrl
            }
        }
        return ""
    }
}

// Seek time For target
extension UPnPAVTrasnport {
    
    private func realTime(time: Float) -> String {
        let hour = Int(time/3600.0)
        let min = Int(fmodf(time, 3600.0) / 60.0)
        let second = Int(fmodf(time, 60.0))
        return "\(hour):\(min):\(second)"
    }
    
    /// "01:23:12" 转化为 秒
    private func timeValue(time: String?) -> Float {
        
        func adder(valueString: String, index: Int) -> Float{
            
            var tempStr = valueString
            
            if tempStr == "00" {
               return 0
            }
            
            if tempStr.hasPrefix("0") {
                tempStr.removeFirst()
            }
            
            let value = Float(tempStr) ?? 0
            if index == 0 {
                return value
            }else {
                return value * powf(60, Float(index))
            }
        }
        
        guard let time = time else { return 0 }
        /// "01:23:12"  "00:03:12"
        var hms = time.split(separator: ":")
        hms.reverse()
        var seconds: Float = 0
        for index in 0..<hms.count {
            seconds = seconds + adder(valueString: String(hms[index]), index: index)
        }
        return seconds
    }
}


