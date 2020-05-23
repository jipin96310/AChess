//
//  ConfigGameController.swift
//  AChess
//
//  Created by zhaoheng sun on 5/16/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import  UIKit
import MultipeerConnectivity

class ConfigGameController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    var gameConfig = settingStruct(isShareBoard: true, playerNumber: 2)
    var currentSlaveId:[MCPeerID] = [MCPeerID(displayName: UIDevice.current.name)]
    
    @IBOutlet weak var playerNumberLabel: UILabel!
    @IBOutlet weak var playerNumberStepper: UIStepper!
    @IBOutlet weak var shareBoardSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var userStackView: UIStackView!
    var multipeerSession: multiUserSession!
    var timer : Timer? //定时刷新在线玩家
    
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == settingTableView {
            return 3
        } else {
            return 8
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updataSecond), userInfo: nil, repeats: true)
        timer!.fire()
        
        //监听设置组件
        shareBoardSwitch.addTarget(self, action: #selector(switchChange), for: .valueChanged)
        playerNumberStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        
        multipeerSession = multiUserSession(receivedDataHandler: receivedData)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        stopTimer()
    }
    
    //定时操作
    @objc func updataSecond() {
        if multipeerSession != nil {
            var newConnectedPeers = [MCPeerID(displayName: UIDevice.current.name)]
            newConnectedPeers += multipeerSession.connectedPeers
            currentSlaveId = newConnectedPeers
            print(currentSlaveId)
            tableView.reloadData()
        }
    }
    
    @objc func switchChange() { //是否共享棋盘
        gameConfig.isShareBoard = shareBoardSwitch.isOn
    }
    @objc func stepperChanged(_ stepper:UIStepper) { //玩家数量
        gameConfig.playerNumber = stepper.value
        playerNumberLabel.text = String(Int(stepper.value))
    }
    
    func stopTimer() {
       if timer != nil {
            timer!.invalidate() //销毁timer
            timer = nil
        }
    }
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        print("unknown data recieved from \(peer)")
        
        do {
            print("unknown data recieved from \(peer)")
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    //在这个方法中给新页面传递参数
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartGamtDetail"{
            let controller = segue.destination as! ViewController
            controller.gameConfigStr = gameConfig
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if tableView == settingTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "shareBoardCell") ?? UITableViewCell()
            
            return cell
            
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
            var curPlayerName = ""
            
            if indexPath.row < currentSlaveId.count {
                curPlayerName = currentSlaveId[indexPath.row].displayName
            }
            
            cell.textLabel?.text="\(curPlayerName)"
            return cell
        }
    }
    
    

    
    
}
