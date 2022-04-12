import UIKit
import Flutter
import WalletConnect
import WalletConnectUtils

@UIApplicationMain
/// extend FlutterStreamHandler
@objc class AppDelegate: FlutterAppDelegate, WalletConnectClientDelegate,  FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
//    var sessionItems: [ActiveSessionItem] = []
    var currentProposal: Session.Proposal?
    var currentRequest: Request?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        /// ini method channel
        let methodChannel = FlutterMethodChannel(name: "wallet_connect_2",
                                                 binaryMessenger: controller.binaryMessenger)
        prepareMethodHandler(methodChannel: methodChannel)
        
        
        /// ini event channel
        let EventChannel1 = FlutterEventChannel(name: "stream1",binaryMessenger: controller.binaryMessenger)
        EventChannel1.setStreamHandler(self)
        
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    /// method channel
    private func prepareMethodHandler(methodChannel: FlutterMethodChannel) {
        methodChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "initialize" {
                let args = call.arguments as! Dictionary<String, Any>
                
                self.metadataName = args["metadataName"] as? String
                self.metadataDescription = args["metadataDescription"] as? String
                self.metadataUrl = args["metadataUrl"] as? String
                self.metadataIcons = args["metadataIcons"] as? Array<String>
                self.projectId = args["projectId"] as? String
                self.relayHost = args["relayHost"] as? String
                
                self.initalize(result: result)
            } else if call.method == "pair" {
                let args = call.arguments as! Dictionary<String, Any>
                let uri = args["uri"] as! String
                self.pair(result: result, uri: uri)
            } else if call.method == "approve" {
                let args = call.arguments as! Dictionary<String, Any>
                let account = args["account"] as! String
                self.approve(result: result, currentProposal: self.currentProposal!, account: account)
            } else if call.method == "reject" {
                self.reject(result: result,currentProposal: self.currentProposal!)
            } else if call.method == "disconnect" {
                //sementara selagi blm ditentuin mau multi session apa engga
                //                let settledSessions = self.client!.getSettledSessions()
                //                self.disconnect(result: result, topic: settledSessions.first!.topic)
                
                let args = call.arguments as! Dictionary<String, Any>
                let topic = args["topic"] as! String
                self.disconnect(result: result, topic: topic)
            } else if call.method == "respondRequest" {
                let args = call.arguments as! Dictionary<String, Any>
                let sign = args["sign"] as! String
                self.respondRequest(result: result, sign: sign)
            } else if call.method == "rejectRequest" {
                self.rejectRequest(result: result)
            } else if call.method == "reloadSessions" {
                self.reloadSessions(result: result)
            } else if call.method == "update" {
                let args = call.arguments as! Dictionary<String, Any>
                let account = args["account"] as! String
                let topic = args["topic"] as! String
                self.update(result: result, currentProposal: self.currentProposal!,topic: topic,  account: account)
            } else if call.method == "upgrade" {
                let args = call.arguments as! Dictionary<String, Any>
                let topic = args["topic"] as! String
                self.upgrade(result: result, currentProposal: self.currentProposal!,topic: topic)
            } else if call.method == "ping" {
                let args = call.arguments as! Dictionary<String, Any>
                let topic = args["topic"] as! String
                self.ping(result: result, topic: topic)
            }
            else {
                result(FlutterMethodNotImplemented)
                return
            }
            
        })
    }
    
    /// reload ketika pertama dibuka
//    private func getActiveSessionItem(for settledSessions: [Session]) -> [ActiveSessionItem] {
//        return settledSessions.map { session -> ActiveSessionItem in
//            let app = session.peer
//            return ActiveSessionItem(
//                dappName: app.name ?? "",
//                dappURL: app.url ?? "",
//                iconURL: app.icons?.first ?? "",
//                topic: session.topic)
//        }
//    }
//
//    private func reloadActiveSessions() {
//        let settledSessions = client!.getSettledSessions()
//        let activeSessions = getActiveSessionItem(for: settledSessions)
//        self.sessionItems = activeSessions
//    }
    
    /// reload tampil di ui
    private func getActiveSessionString(for settledSessions: [Session]) -> [String] {
        
        return settledSessions.map { session -> String in
            let app = session.peer
            return """
                {
                    "dappName": "\(app.name ?? "")",
                    "dappURL":  "\(app.url ?? "")",
                    "iconURL":  "\(app.icons?.first ?? "")",
                    "topic" :  "\(session.topic)"
                }
            """
        }
    }
    
    private func reloadSessions(result: FlutterResult) {
        let settledSessions = client!.getSettledSessions()
        let activeSessions = getActiveSessionString(for: settledSessions)
        
        //        self.sessionItems = activeSessions
        result("\(activeSessions)")
    }
    
    /// method channel
    var client: WalletConnectClient?
    var metadataName: String?
    var metadataDescription: String?
    var metadataUrl: String?
    var metadataIcons: Array<String>?
    var projectId: String?
    var relayHost: String?
    func initalize(result: FlutterResult){
        client =   {
            let metadata = AppMetadata(
                name: metadataName,
                description: metadataDescription,
                url: metadataUrl,
                icons: metadataIcons)
            return WalletConnectClient(
                metadata: metadata,
                projectId: projectId!,
                relayHost: relayHost!
            )
        }()
    }
    
    /// method channel
    func pair(result: FlutterResult, uri:String){
        print("[RESPONDER] Pairing to: \(uri)")
        do {
            client!.delegate = self
            try client!.pair(uri: uri)
            print("oke")
            result(uri)
        } catch {
            print("[PROPOSER] Pairing connect error: \(error)")
        }
    }
    
    /// method channel
    /// kita hanya ngasih alamatnya aja berupa string, chainIdnya dari currentproposal
    func approve(result: FlutterResult, currentProposal: Session.Proposal, account: String){
        let accounts = Set(currentProposal.permissions.blockchains.compactMap{ Account($0+":\(account)") })
        client!.approve(proposal: currentProposal, accounts: accounts)
        print("oke")
        result("approve")
    }
    
    /// method channel
    func reject(result: FlutterResult, currentProposal: Session.Proposal){
        client!.reject(proposal: currentProposal, reason: .disapprovedChains)
        print("oke")
        result("reject")
    }
    
    /// method channel
    func disconnect(result: FlutterResult, topic: String){
        client!.disconnect(topic: topic, reason: Reason(code: 0, message: "disconnect"))
        print("oke")
        result("disconnect")
    }
    
    /// method channel
    func respondRequest(result: FlutterResult, sign: String){
        let response = JSONRPCResponse<AnyCodable>(id: currentRequest!.id, result: AnyCodable(sign))
        client!.respond(topic: currentRequest!.topic, response: .response(response))
        print("oke")
        result("respondRequest")
    }
    
    /// method channel
    func rejectRequest(result: FlutterResult){
        let response = JSONRPCErrorResponse(id: currentRequest!.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        client!.respond(topic: currentRequest!.topic, response: .error(response))
        
        print("oke")
        result("rejectRequest")
    }
    
    
    func ping(result: FlutterResult, topic: String){
     client!.ping(topic: topic, completion: { value in
            switch value {
            case .success():
                self.eventSink!("""
                    {
                        "T" : "ping",
                        "value": {
                             "status" : "ping"
                        }
                    }
                """)
                print("received ping response")
            case .failure(let error):
                self.eventSink!("""
                    {
                        "T" : "ping",
                        "value": {
                             "status" : "\(error)"
                        }
                    }
                """)
                print(error)
            }
        })
    }
    
    func update(result: FlutterResult, currentProposal: Session.Proposal, topic: String, account: String){
        let accounts = Set(currentProposal.permissions.blockchains.compactMap{ Account($0+":\(account)") })
        do {
            try client!.update(topic: topic, accounts: accounts)
        } catch {
            result("update error")
        }
        result("update")
    }
    
    func upgrade(result: FlutterResult, currentProposal: Session.Proposal, topic: String){
        do {
            try client!.upgrade(topic: topic, permissions: currentProposal.permissions)
        } catch {
            result("upgrade error")
        }
        result("upgrade")
    }
    
    /// ===================================================================
    
    /// event channel
    func onListen(withArguments arguments: Any?,
                  eventSink: @escaping FlutterEventSink) -> FlutterError? {
        print("On Listen Call")
        self.eventSink = eventSink
        //        eventSink("wkwkaskdoaksdoko")
        return nil
    }
    
    /// event channel
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        debugPrint("On cancel Call")
        self.eventSink = nil
        return nil
    }
    
    /// event channel
    func didSettle(session: Session) {
        print("ini settle")
//        reloadActiveSessions()
        print(session)
        self.eventSink!("""
             {
                "T" : "settle",
                "value": {
                     "session" : "\(session)"
                }
             }
            """)
    }
    

    /// event channel
    func didDelete(sessionTopic: String, reason: Reason) {
        print(sessionTopic)
        //        self.eventSink!("ondelete")
    }
    
    /// event channel
    func didUpdate(sessionTopic: String, accounts: Set<Account>) {
        print(sessionTopic)
        let accountsArray = accounts.compactMap { "\($0)" }

        self.eventSink!("""
             {
                "T" : "update",
                "value": {
                     "sessionTopic" : "\(sessionTopic)",
                     "accounts" : \(accountsArray)
                }
             }
             """)
    }
    
    
    /// event channel
    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
        print(sessionTopic)
        self.eventSink!("""
             {
                "T" : "upgrade",
                "value": {
                    "sessionTopic" : "\(sessionTopic)",
                    "chains":  \(permissions.blockchains),
                    "methods":  \(permissions.methods)
                 }
             }
             """)
    }
    
    /// event channel
    func didReceive(sessionProposal: Session.Proposal) {
        print("sessionProposal===========>")
        print(sessionProposal)
        print("<===========")
        
        let appMetadata = sessionProposal.proposer
        self.eventSink!("""
            {
                "T" : "onSessionProposal",
                "value": {
                    "accounts": [],
                    "chains":  \(sessionProposal.permissions.blockchains),
                    "description":  "\((appMetadata.description ?? ""))",
                    "icons" : \(appMetadata.icons ?? []),
                    "isController":  "",
                    "methods":  \(sessionProposal.permissions.methods),
                    "name":  "\(appMetadata.name ?? "")",
                    "proposerPublicKey":  "",
                    "relayProtocol":  "",
                    "topic":  "",
                    "ttl":  "",
                    "url": "\(appMetadata.url ?? "")"
                }
            }
        """)
        currentProposal = sessionProposal
    }
    
    /// event channel
    func didReceive(sessionRequest: Request) {
        print("request =================>")
        print(sessionRequest)
        
        print("request===========>")
        print(sessionRequest)
        print("<===========")
        
        
        self.eventSink!("""
            {
                "T" : "onSessionRequest",
                "value": {
                    "chainId":  "\(sessionRequest.chainId ?? "")",
                    "topic":  "\((sessionRequest.topic))",
                    "request": {
                        "method": "\(sessionRequest.method)",
                        "id": \(sessionRequest.id),
                        "params": \(try! sessionRequest.params.json())
                    }
                }
            }
        """)
        currentRequest = sessionRequest
    }
    
    /// event channel
    func didReject(pendingSessionTopic: String, reason: Reason) {
        print(reason)
    }
}

//
//
//struct ActiveSessionItem {
//    let dappName: String
//    let dappURL: String
//    let iconURL: String
//    let topic: String
//}
//
