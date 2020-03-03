//
//  AVTransportViewController.swift
//  UPnPDA_Example
//
//  Created by 王海洋 on 2020/2/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import UPnPDA
let ScreenWidth = UIScreen.main.bounds.width
let ScreenHeight = UIScreen.main.bounds.height

let CoverHeight = ScreenWidth*9.0/16.0

let VideoAddress = "http://v.tiaooo.com/llbizosAzGhJPXC0H4AHLTGHl42W"


class AVTransportViewController: UIViewController {

    var deviceDesDoc: UPnPDeviceDescriptionDocument?
    
    
    private lazy var avtransport: UPnPAVTrasnport = {
        let transport = UPnPAVTrasnport()
        return transport
    }()
    
    private lazy var coverView: UIView = {
        let cover = UIView()
        cover.backgroundColor = .black
        return cover
    }()
    
    private lazy var playBtn: UIButton = {
        let button = UIButton()
        button.backgroundColor = .brown
        button.setTitle("Pause", for: .normal)
        button.setTitle("Play", for: .selected)
        button.addTarget(self, action: #selector(play(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var stopBtn: UIButton = {
        let button = UIButton()
        button.backgroundColor = .brown
        button.setTitle("结束投屏", for: .normal)
        button.addTarget(self, action: #selector(stop(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .brown
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var seekBar: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 1
        slider.minimumValue = 0
        slider.value = 0
        slider.isContinuous = false
        slider.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
        return slider
    }()
    
    private var durationValue: Float = 0
    private var timer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(coverView)
        coverView.addSubview(playBtn)
        coverView.addSubview(seekBar)
        coverView.addSubview(timeLabel)
        view.addSubview(stopBtn)
        layoutUi()
        
        if let ddd = deviceDesDoc {
            avtransport.control(ddd)
            
            avtransport.setAVTransportUri(uri: VideoAddress) { [weak self] (isSuccess, response, error) in
                if isSuccess {
                    print("播放设置成功")
                    self?.getPositionInfo()
                }
            }
            
            
        }
        
     
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: Public methods
extension AVTransportViewController {
    
    private func position(_ position: UPnPMediaPositionInfo) {
        
        DispatchQueue.main.async {
            if let playBackTime = position.playbackTimeString, let duration = position.durationString {
                self.timeLabel.text = "\(playBackTime) / \(duration)"
                
                if let durValue = position.durationValue, let playBackValue = position.playbackTimeValue {
                    self.durationValue = durValue
                    self.seekBar.value = playBackValue/durValue
                }
            }
        }

        
    }
    
    @objc func play(sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            /// Pause
            avtransport.pause { (isSuccess, response, error) in
                if isSuccess {
                    print("暂停设置成功")
                }
            }
        }else {
            /// Play
            avtransport.play { (isSuccess, response, error) in
                if isSuccess {
                    print("播放设置设置成功")
                }
            }
        }
    }
    
    /// 结束投屏
    @objc private func stop(sender: UIButton) {
        
        avtransport.stop { (isSuccess, response, error) in
            if isSuccess {
                print("结束投屏")
                self.timer?.invalidate()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func valueChanged(sender: UISlider) {
        let playbackTime = sender.value * durationValue
        
        avtransport.seek(time: playbackTime) { (isSuccess, response, error) in
            if isSuccess {
                
                print("寻址成功")
            }
        }
        
    }
    
    private func getPositionInfo() {
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[weak self](timer) in
                self?.avtransport.getPositionInfo(complete: { (isSuccess, response, error) in
                    if isSuccess {
                        if let positionInfo: UPnPMediaPositionInfo = response as? UPnPMediaPositionInfo {
                            self?.position(positionInfo)
                        }
                    }
                })
            }
            timer?.fire()
        } else {
            // Fallback on earlier versions
        }
        
    }
}

// MARK: Private methods
extension AVTransportViewController {

    private func layoutUi() {
        coverView.snp.makeConstraints { (mk) in
            mk.center.equalTo(self.view.snp_center)
            mk.width.equalTo(ScreenWidth)
            mk.height.equalTo(CoverHeight)
        }
        
        playBtn.snp.makeConstraints { (mk) in
            mk.center.equalTo(coverView.snp_center)
            mk.width.height.equalTo(60)
        }
        
        stopBtn.snp.makeConstraints { (mk) in
            mk.top.equalTo(coverView.snp_bottom).offset(40)
            mk.centerX.equalTo(coverView.snp_centerX)
            mk.width.equalTo(160)
            mk.height.equalTo(60)

        }
        
        timeLabel.snp.makeConstraints { (mk) in
            mk.centerX.equalTo(coverView.snp_centerX)
            mk.top.equalTo(coverView.snp_top)
            mk.width.equalTo(200)
            mk.height.equalTo(30)
        }
        
        seekBar.snp.makeConstraints { (mk) in
            mk.bottom.equalTo(coverView.snp_bottom).offset(-20)
            mk.left.equalTo(coverView.snp_left).offset(30)
            mk.right.equalTo(coverView.snp_right).offset(-30)
            mk.height.equalTo(20)
        }
        
    }

}
