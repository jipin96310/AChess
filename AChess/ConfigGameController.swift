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
    
    var masterServerID: MCPeerID?
    
    var gameConfig = settingStruct(isShareBoard: true, playerNumber: 2, isMaster: false, enableHandTracking: true, enableGestureRecognizer: true, enableButtonGestureControl: true)
    var currentSlaveId:[playerStruct] = [playerStruct(playerName: UIDevice.current.name, curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: false, playerID: MCPeerID(displayName: UIDevice.current.name)),
        playerStruct(playerName: "动保", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil)
    ]
    
    @IBOutlet weak var playerNumberLabel: UILabel!
    @IBOutlet weak var playerNumberStepper: UIStepper!
    @IBOutlet weak var shareBoardSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingTableView: UITableView!
    
    @IBOutlet weak var handDetectSwitch: UISwitch!
    @IBOutlet weak var buttonGestureSwitch: UISwitch!
    @IBOutlet weak var gestureSwitch: UISwitch!
    
    @IBOutlet weak var gestureSwitchView: UIStackView!
    @IBOutlet weak var buttonGestureView: UIStackView!
    @IBOutlet weak var handView: UIStackView!
    
    
    var multipeerSession: multiUserSession!
    var timer : Timer? //定时刷新在线玩家
    let computerPlayer = [
        playerStruct(playerName: "动保", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "武术家", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "植物人", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "素食主义者", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "科学家", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "道士", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
        playerStruct(playerName: "鬼魂", curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: true, playerID: nil),
    ]
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == settingTableView {
            return 5
        } else {
            return gameConfig.playerNumber
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
        handDetectSwitch.addTarget(self, action: #selector(handChange), for: .valueChanged)
        gestureSwitch.addTarget(self, action: #selector(gestureChange), for: .valueChanged)
        buttonGestureSwitch.addTarget(self, action: #selector(buttonGestureChange), for: .valueChanged)
        playerNumberStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        
        
        multipeerSession = multiUserSession(receivedDataHandler: receivedData)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        stopTimer()
        multipeerSession.stopBrosingForPeers()
        multipeerSession.stopAdvertisingPeer()
    }
    
    
    //定时操作
    @objc func updataSecond() {
        if multipeerSession != nil {
            var newConnectedPeers = [playerStruct(playerName: UIDevice.current.name, curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: false, playerID: multipeerSession.getMyId())]
            multipeerSession.connectedPeers.forEach{(peerId) in
                newConnectedPeers.append(playerStruct(playerName: peerId.displayName, curCoin: 3, curLevel: 1, curBlood: GlobalCommonNumber.maxBlood, curChesses: [], curAura: [], isComputer: false, playerID: peerId))
            }
//            newConnectedPeers += multipeerSession.connectedPeers
            if newConnectedPeers.count < gameConfig.playerNumber {
                for i in 0 ..< (gameConfig.playerNumber - newConnectedPeers.count) {
                    newConnectedPeers.append(computerPlayer[i])
                }
            }
            currentSlaveId = newConnectedPeers
            tableView.reloadData()
        }
    }
    
    @objc func handChange() { //是否启用手部追踪
        gameConfig.enableHandTracking = handDetectSwitch.isOn
    }
    @objc func gestureChange() { //是否启用手势识别
        gameConfig.enableGestureRecognizer = gestureSwitch.isOn
        if gameConfig.enableGestureRecognizer {
            handDetectSwitch.isEnabled = true
            //handDetectSwitch.isOn = true
            buttonGestureSwitch.isEnabled = true
            //buttonGestureSwitch.isOn = true
        } else {
            handDetectSwitch.isEnabled = false
            handDetectSwitch.isOn = false
            buttonGestureSwitch.isEnabled = false
            buttonGestureSwitch.isOn = false
        }
        handChange()
        buttonGestureChange()
    }
    @objc func switchChange() { //是否共享棋盘
        gameConfig.isShareBoard = shareBoardSwitch.isOn
    }
    @objc func buttonGestureChange() { //是否开启手势控制按键
        gameConfig.enableButtonGestureControl = buttonGestureSwitch.isOn
    }
    @objc func stepperChanged(_ stepper:UIStepper) { //玩家数量
        gameConfig.playerNumber = Int(stepper.value)
        playerNumberLabel.text = String(gameConfig.playerNumber)
    }
    
    func stopTimer() {
       if timer != nil {
            timer!.invalidate() //销毁timer
            timer = nil
        }
    }
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            let decoder = JSONDecoder()
            if let masterConfig = try? decoder.decode(settingStruct.self, from: data){ //如果是解析的游戏配置文件 说明自己是从机
                masterServerID = peer //记录主机id
                DispatchQueue.main.async {
                   self.performSegue(withIdentifier: "StartGameSlave", sender: masterConfig)
                }
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    //在这个方法中给新页面传递参数
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartGamtDetail"{ //你按下了开始 你成为了主机
            let controller = segue.destination as! ViewController
            var masterConfig = gameConfig
            masterConfig.isMaster = true
            controller.gameConfigStr = masterConfig
            controller.currentSlaveId = currentSlaveId
            //发送游戏配置给所有从机
            let encoder = JSONEncoder()
            let encoded = try? encoder.encode(gameConfig)
            self.multipeerSession.sendToAllPeers(encoded!)
            self.multipeerSession.stopBrosingForPeers()
            
            controller.multipeerSession = multipeerSession
        } else if segue.identifier == "StartGameSlave"{ //你成为了从机
            let controller = segue.destination as! ViewController
            var slaveConfig = gameConfig
            slaveConfig.isMaster = false
            
            controller.gameConfigStr = slaveConfig
            controller.curMasterID = masterServerID
            
            controller.multipeerSession = multipeerSession
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if tableView == settingTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "shareBoardCell") ?? UITableViewCell()
            
            return cell
            
            
        } else {
            //var cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as UITableViewCell
            
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,reuseIdentifier: "cellID")
            
            var curPlayerName = ""
            var curPlayerType = ""
            if indexPath.row < currentSlaveId.count {
                curPlayerName = currentSlaveId[indexPath.row].playerName
                curPlayerType = currentSlaveId[indexPath.row].isComputer ? "AI".localized : "Player".localized
            }
            
            cell.textLabel?.text="\(curPlayerName)"
            cell.detailTextLabel?.text = "\(curPlayerType)"
            
           
            
            return cell
        }
    }
    

    

    
    
}
