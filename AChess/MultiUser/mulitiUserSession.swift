//
//  mulitiUserSession.swift
//  AChess
//
//  Created by zhaoheng sun on 5/17/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import MultipeerConnectivity

/// - Tag: MultipeerSession
class multiUserSession: NSObject {
    static let serviceType = "ar-chess"
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private var receivedDataHandler: (Data, MCPeerID) -> Void
    
    /// - Tag: MultipeerSetup
    init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void ) {
        self.receivedDataHandler = receivedDataHandler
        
        super.init()
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: multiUserSession.serviceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: multiUserSession.serviceType)
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
    
    func changeHandler(newHandler: @escaping (Data, MCPeerID) -> Void) {
        self.receivedDataHandler = newHandler
    }
    
    func getMyId() -> MCPeerID{
        return myPeerID
    }
    func sendToPeer(_ data: Data, _ selectPeers: [MCPeerID]) {
        do {
            try session.send(data, toPeers: selectPeers, with: .reliable)
        } catch {
            print("error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    func sendToAllPeers(_ data: Data) {
        do {
            print("connectpeers", session.connectedPeers)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("error sending data to peers: \(error.localizedDescription)")
        }
    }
    func stopBrosingForPeers() {
        serviceBrowser.stopBrowsingForPeers()
    }
    func stopAdvertisingPeer() {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
}

extension multiUserSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // not used
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedDataHandler(data, peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}

extension multiUserSession: MCNearbyServiceBrowserDelegate {
    
    /// - Tag: FoundPeer
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Invite the new peer to the session.
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // This app doesn't do anything with non-invited peers, so there's nothing to do here.
    }
    
}

extension multiUserSession: MCNearbyServiceAdvertiserDelegate {
    
    /// - Tag: AcceptInvite
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Call handler to accept invitation and join the session.
        invitationHandler(true, self.session)
    }

}
