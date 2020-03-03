//
//  UPnPDeviceSearchViewController.swift
//  UPnPDA_Example
//
//  Created by 王海洋 on 2020/2/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import UPnPDA
private let UPnPDeviceCellId = "UPnPDeviceCellId"
class UPnPDeviceSearchViewController: UIViewController {

    
    lazy var table: UITableView = {
        let table = UITableView(frame: view.bounds, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: UPnPDeviceCellId)
        return table
    }()
    
    lazy var serviceSearcher: UPnPServiceSearch = {
        let search = UPnPServiceSearch()
//        search.searchTarget = M_SEARCH_Targert.all()
        search.delegate = self
        return search
    }()
    
    private var upnpDeviceList:[UPnPDeviceDescriptionDocument] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(table)
        serviceSearcher.start()
    
        
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

// MARK: UITableView DataSource and Delegate Methods
extension UPnPDeviceSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upnpDeviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UPnPDeviceCellId, for: indexPath)
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        let device = upnpDeviceList[indexPath.row]
        let nameLabel = UILabel(frame: CGRect(x: 20, y: 0, width: 300, height: 50))
        nameLabel.numberOfLines = 0
        if let name = device.friendlyName, let ip = device.ip {
            nameLabel.text = "\(name) \n \(ip)"
        }
        cell.contentView.addSubview(nameLabel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let deviceDecDoc = upnpDeviceList[indexPath.row]
        
        let avTransPortVc = AVTransportViewController()
        avTransPortVc.deviceDesDoc = deviceDecDoc
        navigationController?.show(avTransPortVc, sender: self)
        
        
    }
    
}

// MARK: UPnP Device Search Delegate
extension UPnPDeviceSearchViewController: UPnPServiceSearchDelegate {
    
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, upnpDevices devices: [UPnPDeviceDescriptionDocument]) {
        upnpDeviceList = devices
        table.reloadData()
    }
    
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, dueTo error: Error) {
        print(" Search Occur Error \(error)")
    }
    
    
}
