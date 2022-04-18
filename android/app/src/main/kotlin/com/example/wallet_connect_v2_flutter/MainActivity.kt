package com.example.wallet_connect_v2_flutter

import android.app.Application
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.walletconnect.walletconnectv2.client.WalletConnect
import com.walletconnect.walletconnectv2.client.WalletConnectClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*


interface DelegateValue {
    fun setValue(resVal:Map<String, Any?>)
}

private fun resultOnSuccess(res : Map<String, Any?>) : String {
    val result: Map<String, Any?> = mapOf(
        "T" to "onSuccess",
        "value" to res
    )
    return JSONObject(result).toString()
}

private fun sessionResponse(T: String, session: WalletConnect.Model.SettledSession) : String{
    val appMetadata = session.peerAppMetaData

    val result: Map<String, Any?> =
        mapOf(
            "T" to T,
            "value" to mapOf (
                "accounts" to session.accounts,
                "chains" to  session.permissions.blockchain.chains,
                "description" to (appMetadata?.description ?: ""),
                "icons" to (appMetadata?.icons ?: listOf()),
                "isController" to  "",
                "methods" to  session.permissions.jsonRpc.methods,
                "name" to (appMetadata?.name ?: ""),
                "proposerPublicKey" to  "",
                "relayProtocol" to  "",
                "topic" to session.topic,
                "ttl" to  "",
                "url" to (appMetadata?.url ?: "")
            )
        )

    return JSONObject(result).toString()

//   return """
//       {
//            "T" : "$T",
//            "value" : {
//                "accounts" : ${session.accounts},
//                "chains" : ${session.permissions.blockchain.chains},
//                "description" : ${appMetadata?.description ?: ""},
//                "icons" : ${appMetadata?.icons ?: listOf()},
//                "isController" : "",
//                "methods" : ${session.permissions.jsonRpc.methods},
//                "name" : ${appMetadata?.name ?: ""},
//                "proposerPublicKey" : "",
//                "relayProtocol" : "",
//                "topic" : ${session.topic},
//                "ttl" : "",
//                "url" : ${appMetadata?.url ?: ""}
//            }
//        }
//   """
}

private lateinit var messager :  io.flutter.plugin.common.BinaryMessenger

private lateinit var sPairing: WalletConnect.Model.SettledPairing

private lateinit var currentProposal: WalletConnect.Model.SessionProposal

private lateinit var  currentRequest: WalletConnect.Model.SessionRequest

private lateinit var rSession: WalletConnect.Model.RejectedSession

private lateinit var dSession: WalletConnect.Model.DeletedSession

private lateinit var sNotification: WalletConnect.Model.SessionNotification

private lateinit var sSession: WalletConnect.Model.SettledSession

private lateinit var upSession: WalletConnect.Model.UpdatedSession

private lateinit var ugSession: WalletConnect.Model.UpgradedSession

class MainActivity: FlutterActivity() {

    private val CHANNEL = "wallet_connect_2"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messager =flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messager, CHANNEL).setMethodCallHandler {
                call, result ->
            when(call.method){
                "initialize" -> {
                    this.metadataName = call.argument<String>("metadataName")
                    this.metadataDescription = call.argument<String>("metadataDescription")
                    this.metadataUrl = call.argument<String>("metadataUrl")
                    this.metadataIcons = call.argument<List<String>>("metadataIcons")
                    this.projectId = call.argument<String>("projectId")
                    this.relayHost = call.argument<String>("relayHost")
                    initialize(result)
                }

                "delegate"-> {
                    delegate()
                }

                "pair"-> {
                    val uri = call.argument<String>("uri")
                    pair(result, uri.toString())
                }

                "approve" -> {
                    val account = call.argument<String>("account")
                    approve(account!!)
                }

                "reject" -> reject()

                "disconnect" -> {
                    val topic = call.argument<String>("topic")
                    disconnect(topic!!)
                }

                "respondRequest" -> {
                    val sign = call.argument<String>("sign")
                    respondRequest(sign!!)
                }

                "rejectRequest" -> rejectRequest()

                "sessionStore" -> sessionStore(result)

                "update" -> {
                    val account = call.argument<String>("account")
                    val topic = call.argument<String>("topic")
                    val chains = call.argument<List<String>>("chains")

                    update(chains!!, topic!!, account!!)
                }

                "upgrade" -> {
                    val topic = call.argument<String>("topic")
                    val chains = call.argument<List<String>>("chains")
                    val methods = call.argument<List<String>>("methods")
                    val notifications = call.argument<List<String>>("notifications")

                    upgrade(chains!!,methods!!, notifications!!, topic!!)
                }

                "ping" -> {
                    val topic = call.argument<String>("topic")
                    ping(result, topic!!)
                }


                else -> result.notImplemented()
            }
        }

        EventChannel(messager, "streamDelegate").setStreamHandler(StreamDelegate)
        EventChannel(messager, "streamPair").setStreamHandler(StreamPair)
        EventChannel(messager, "streamDisconnect").setStreamHandler(StreamDisconnect)
        EventChannel(messager, "streamApprove").setStreamHandler(StreamApprove)
        EventChannel(messager, "streamReject").setStreamHandler(StreamReject)
        EventChannel(messager, "streamRespondRequest").setStreamHandler(StreamRespondRequest)
        EventChannel(messager, "streamRejectRequest").setStreamHandler(StreamRejectRequest)
        EventChannel(messager, "streamSessionUpdate").setStreamHandler(StreamSessionUpdate)
        EventChannel(messager, "streamSessionUpgrade").setStreamHandler(StreamSessionUpgrade)
        EventChannel(messager, "streamSessionPing").setStreamHandler(StreamSessionPing)
    }

    /// method channel
    private fun getActiveSessionString(settledSessions: List<WalletConnect.Model.SettledSession>) : List<String> {
        return settledSessions.map { session ->
                sessionResponse(T= "reloadSession", session= session)
        }
    }
    private fun sessionStore(result: MethodChannel.Result){
        val settledSessions =  WalletConnectClient.getListOfSettledSessions()
        result.success(getActiveSessionString(settledSessions).toString())
    }

    /// method channel
    var client: WalletConnectClient = WalletConnectClient
    var metadataName: String? = null
    var metadataDescription: String? = null
    var metadataUrl: String? = null
    var metadataIcons: List<String>? = null
    var projectId: String? = null
    var relayHost: String? = null
    private fun initialize(result: MethodChannel.Result,){
//        val initWallet = WalletConnect.Params.Init(
//            application = this.application,
//            relayServerUrl = "wss://${this.relayHost!!}?projectId=${this.projectId!!}",
//            isController = true,
//            metadata = WalletConnect.Model.AppMetaData(
//                name = this.metadataName!!,
//                description = this.metadataDescription!!,
//                url = this.metadataUrl!!,
//                icons = this.metadataIcons!!
//            )
//        )
//
//        WalletConnectClient.initialize(initWallet)
//        client = WalletConnectClient
        result.success("init")
    }


    /// method channel
    private fun pair(result: MethodChannel.Result, uri:String){
        val pair = WalletConnect.Params.Pair(uri.trim())
        WalletConnectClient.pair(pair, StreamPair)
        result.success("paired")
    }

    private fun delegate(){
        val walletDelegate = object : WalletConnectClient.WalletDelegate {
            override fun onSessionProposal(sessionProposal: WalletConnect.Model.SessionProposal) {
                currentProposal = sessionProposal
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "sessionProposal",
                    "value" to mapOf(
                        "accounts" to currentProposal.accounts,
                        "chains" to currentProposal.chains,
                        "description" to currentProposal.description,
                        "icons" to currentProposal.icons,
                        "isController" to currentProposal.isController.toString(),
                        "methods" to currentProposal.methods,
                        "name" to currentProposal.name,
                        "proposerPublicKey" to currentProposal.proposerPublicKey,
                        "relayProtocol" to currentProposal.relayProtocol,
                        "topic" to currentProposal.topic,
                        "ttl" to currentProposal.ttl.toString(),
                        "types" to currentProposal.types,
                        "url" to currentProposal.url,

                        )
                ))
            }

            override fun onSessionRequest(sessionRequest: WalletConnect.Model.SessionRequest) {
                currentRequest = sessionRequest
                // T for Response Type
                val listParams = currentRequest.request.params.removePrefix("[").removeSuffix ("]").split(", ")

                StreamDelegate.setValue(mapOf(
                    "T" to "sessionRequest",
                    "value" to mapOf(
                        "chainId" to currentRequest.chainId,
                        "request" to mapOf<String, Any?>(
                            "method" to currentRequest.request.method,
                            "id" to currentRequest.request.id,
                            "params" to JSONArray(currentRequest.request.params),
                        ),
                        "topic" to currentRequest.topic,
                    )

                ))
            }

            override fun onSessionDelete(deletedSession: WalletConnect.Model.DeletedSession) {
                dSession = deletedSession
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "delete",
                    "value" to mapOf(
                        "reason" to dSession.reason,
                        "topic" to dSession.topic,
                    )
                ))
            }

            override fun onSessionNotification(sessionNotification: WalletConnect.Model.SessionNotification) {
                sNotification = sessionNotification
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "notification",
                    "value" to mapOf(
                        "data" to sNotification.data,
                        "topic" to sNotification.topic,
                        "type" to sNotification.type,
                    )
                ))
            }
        }
        WalletConnectClient.setWalletDelegate(walletDelegate)
    }

    /// method channel
    private fun approve(account:String){
        // Session Proposal object sent by Dapp after pairing was successful
        val accounts = currentProposal.chains.map { chainId -> "$chainId:$account" }
        val approve = WalletConnect.Params.Approve(currentProposal, accounts)
        WalletConnectClient.approve(approve, StreamApprove)
    }

    /// method channel
    private fun reject() {
        val rejectionReason = "User rejected the session."
        val proposalTopic: String = currentProposal.topic
        val reject = WalletConnect.Params.Reject(rejectionReason, proposalTopic)

        WalletConnectClient.reject(reject, StreamReject)
    }

    /// method channel
    private fun disconnect(topic: String) {
        val disconnect = WalletConnect.Params.Disconnect(
            sessionTopic = topic,
            reason = "User disconnect the session.",
            reasonCode = 0
        )

        WalletConnectClient.disconnect(disconnect, StreamDisconnect)
    }

    /// method channel
    private fun respondRequest(sign:String){
        val response = WalletConnect.Params.Response(
            sessionTopic = currentRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcResult(
                currentRequest.request.id,
                sign
            )
        )
        WalletConnectClient.respond(response, StreamRespondRequest)
    }

    /// method channel
    private fun rejectRequest() {
        val response = WalletConnect.Params.Response(
            sessionTopic = currentRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcError(
                currentRequest.request.id,
                WalletConnect.Model.JsonRpcResponse.Error(0, "User rejected the request.")
            )
        )

        WalletConnectClient.respond(response, StreamRejectRequest)
    }

    /// event channel
    private fun ping(result: MethodChannel.Result, topic: String) {
        val ping = WalletConnect.Params.Ping(topic)

        WalletConnectClient.ping(ping, StreamSessionPing)
    }

    /// method channel
    private fun update(chains: List<String>, topic: String, account:String) {
        val accounts = chains.map { chainId -> "$chainId:$account" }
        val update = WalletConnect.Params.Update(
            sessionTopic = topic,
            sessionState = WalletConnect.Model.SessionState(accounts = accounts)
        )

        WalletConnectClient.update(update, StreamSessionUpdate)
    }

    /// method channel
    private fun upgrade(chains: List<String>, methods: List<String>, notifications: List<String>,  topic: String ) {
        val permissions =
            WalletConnect.Model.SessionPermissions(
                blockchain = WalletConnect.Model.Blockchain(chains = chains),
                jsonRpc = WalletConnect.Model.Jsonrpc(methods),
                notification = WalletConnect.Model.Notifications(notifications),
            )
        val upgrade = WalletConnect.Params.Upgrade(topic = topic, permissions = permissions)

        WalletConnectClient.upgrade(upgrade, StreamSessionUpgrade)
    }

}


object StreamDelegate : EventChannel.StreamHandler, DelegateValue {
    var res: Map<String, Any?> = mapOf()
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        sink?.success(
            JSONObject(res).toString()
        )
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun setValue(resVal:Map<String, Any?>) {
        res = resVal
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            println("value delegate")
            sink?.success(
                JSONObject(res).toString()
            )
        }
    }

}

object StreamPair : EventChannel.StreamHandler, WalletConnect.Listeners.Pairing  {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null


    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(settledPairing: WalletConnect.Model.SettledPairing) {
        //Settled pairing
        sPairing = settledPairing
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            println("=================== pair")
            if(settledPairing.metaData!= null){
                println("=================== 1")
                sink?.success(resultOnSuccess(
                    mapOf(
                        "metaData" to mapOf(
                            "description" to sPairing.metaData!!.description,
                            "icons" to sPairing.metaData!!.icons,
                            "name" to sPairing.metaData!!.name,
                            "url" to sPairing.metaData!!.url,
                        ),
                        "topic" to sPairing.topic,
                        )
                ))
            } else {
                println("=================== 2")
                sink?.success(resultOnSuccess(
                    mapOf(
                        "metaData" to sPairing.metaData,
                        "topic" to sPairing.topic,
                        )
                ))
            }
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamDisconnect : EventChannel.StreamHandler, WalletConnect.Listeners.SessionDelete {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(deletedSession: WalletConnect.Model.DeletedSession) {
        dSession = deletedSession
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            println("=================== disconnect")
            sink?.success(
                JSONObject(
                    mapOf(
                        "T" to "delete",
                        "value" to mapOf(
                            "reason" to dSession.reason,
                            "topic" to dSession.topic,
                        )
                    )
                ).toString()
            )
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamApprove : EventChannel.StreamHandler, WalletConnect.Listeners.SessionApprove {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(settledSession: WalletConnect.Model.SettledSession) {
        println("=================== approve")
        sSession = settledSession
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.success(
                  sessionResponse(T = sSession.topic, session = settledSession)
            )
        }

    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamReject : EventChannel.StreamHandler,WalletConnect.Listeners.SessionReject {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(rejectedSession: WalletConnect.Model.RejectedSession) {
        println("=================== reject")
        rSession = rejectedSession
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.success(
                resultOnSuccess(
                    mapOf(
                        "reason" to rSession.reason,
                        "topic" to rSession.topic,
                    )
                )
            )
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamRespondRequest : EventChannel.StreamHandler, WalletConnect.Listeners.SessionPayload {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamRejectRequest : EventChannel.StreamHandler , WalletConnect.Listeners.SessionPayload {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamSessionUpdate : EventChannel.StreamHandler ,WalletConnect.Listeners.SessionUpdate {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(updatedSession: WalletConnect.Model.UpdatedSession) {
        println("=================== session update")
        upSession = updatedSession
        handler = Handler(Looper.getMainLooper())
        println(updatedSession.accounts)
        println(updatedSession.topic)
        handler!!.post {
            sink?.success(
                resultOnSuccess(
                    mapOf(
                        "accounts" to upSession.accounts,
                        "topic" to upSession.topic,
                    )
                )
            )
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamSessionUpgrade : EventChannel.StreamHandler, WalletConnect.Listeners.SessionUpgrade {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(upgradedSession: WalletConnect.Model.UpgradedSession) {
        println("=================== session upgrade")
        ugSession = upgradedSession
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.success(
                resultOnSuccess(
                    mapOf(
                        "permissions" to mapOf(
                            "blockchain" to mapOf(
                                "chains" to ugSession.permissions.blockchain.chains,
                            ),
                            "jsonRpc" to mapOf(
                                "methods" to ugSession.permissions.jsonRpc.methods
                            ),
                            "notification" to ugSession.permissions.notification,
                        ),
                        "topic" to ugSession.topic,
                    )
                )
            )
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }
}

object StreamSessionPing : EventChannel.StreamHandler, WalletConnect.Listeners.SessionPing {
    var sink: EventChannel.EventSink? = null
    var handler: Handler? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onSuccess(topic: String) {
        println("=================== session ping")
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.success(
                resultOnSuccess(
                    mapOf(
                        "topic" to topic,
                    )
                )
            )
        }
    }

    override fun onError(error: Throwable) {
        println(error.message)
        handler = Handler(Looper.getMainLooper())
        handler!!.post {
            sink?.error("onError", error.message, error)
        }
    }

}

