import UIKit
import Flutter
import WalletConnect
import WalletConnectUtils

@UIApplicationMain
/// extend FlutterStreamHandler
@objc class AppDelegate: FlutterAppDelegate, WalletConnectClientDelegate,  FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
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
                let chains = Set<String>(args["chains"] as! Array)
                self.update(result: result, chains: chains,topic: topic,  account: account)
                
            } else if call.method == "upgrade" {
                let args = call.arguments as! Dictionary<String, Any>
                let topic = args["topic"] as! String
                let chains = Set<String>(args["chains"] as! Array)
                let methods = Set<String>(args["methods"] as! Array)
                let notifications = args["notifications"] as! Array<String> 
                self.upgrade(result: result, chains: chains, methods: methods,notifications: notifications ,topic: topic)
                
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
    
    
    /// method channel
    private func getActiveSessionString(for settledSessions: [Session]) -> [String] {
        return settledSessions.map { session -> String in
              sessionResponse(T: "reloadSession", session: session)
        }
    }
    
    /// method channel
    private func reloadSessions(result: FlutterResult) {
        let settledSessions = client!.getSettledSessions()
        let activeSessions = getActiveSessionString(for: settledSessions)
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
        do {
            client!.delegate = self
            try client!.pair(uri: uri)
            result(uri)
        } catch {
            result("[PROPOSER] Pairing connect error: \(error)")
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
        result("respondRequest")
    }
    
    /// method channel
    func rejectRequest(result: FlutterResult){
        let response = JSONRPCErrorResponse(id: currentRequest!.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        client!.respond(topic: currentRequest!.topic, response: .error(response))
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
    
    /// method channel
    func update(result: FlutterResult, chains: Set<String>, topic: String, account: String){
        let accounts = Set(chains.compactMap{ Account($0+":\(account)") })
        do {
            try client!.update(topic: topic, accounts: accounts)
        } catch {
            result("update error")
        }
        result("update")
    }
    
    /// method channel
    func upgrade(result: FlutterResult, chains: Set<String>, methods: Set<String>, notifications: [String], topic: String){
        let permission =  Session.Permissions(blockchains: chains, methods: methods, notifications: notifications)
        do {
            try client!.upgrade(topic: topic, permissions: permission)
        } catch {
            result("upgrade error")
        }
        result("upgrade")
    }
    
    
    func sessionResponse(T: String, session: Session) -> String{
        let appMetadata = session.peer
        return """
                {
                    "T" : "\(T)",
                    "value": {
                        "accounts": [],
                        "chains":  \(session.permissions.blockchains),
                        "description":  "\((appMetadata.description ?? ""))",
                        "icons" : \(appMetadata.icons ?? []),
                        "isController":  "",
                        "methods":  \(session.permissions.methods),
                        "name":  "\(appMetadata.name ?? "")",
                        "proposerPublicKey":  "",
                        "relayProtocol":  "",
                        "topic": "\(session.topic)",
                        "ttl":  "",
                        "url": "\(appMetadata.url ?? "")"
                    }
                }
            """
    }
    
    /// ===================================================================
    
    /// event channel
    func onListen(withArguments arguments: Any?,
                  eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    /// event channel
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    /// event channel
    func didSettle(session: Session) {
        self.eventSink!(sessionResponse(T: "settle", session: session))
    }
    
    /// event channel
    func didDelete(sessionTopic: String, reason: Reason) {
        self.eventSink!("""
             {
                "T" : "delete",
                "value": {
                     "topic" : "\(sessionTopic)",
                     "reason" : {
                        "code" : "\(reason.code)",
                        "message" : "\(reason.message)"
                     }
                }
             }
            """)
    }
    
    /// event channel
    func didUpdate(sessionTopic: String, accounts: Set<Account>) {
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
        let appMetadata = sessionProposal.proposer
        self.eventSink!("""
            {
                "T" : "sessionProposal",
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
        self.eventSink!("""
            {
                "T" : "sessionRequest",
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
        self.eventSink!("""
             {
                "T" : "reject",
                "value": {
                     "pendingSessionTopic" : "\(pendingSessionTopic)",
                      "reason" : {
                         "code" : "\(reason.code)",
                         "message" : "\(reason.message)"
                      }
                }
             }
            """)
    }
}
