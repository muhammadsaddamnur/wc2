package com.example.wallet_connect_v2_flutter

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.walletconnect.walletconnectv2.client.WalletConnect
import com.walletconnect.walletconnectv2.client.WalletConnectClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
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

private lateinit var messager :  io.flutter.plugin.common.BinaryMessenger

private lateinit var sPairing: WalletConnect.Model.SettledPairing

private lateinit var sProposal: WalletConnect.Model.SessionProposal

private lateinit var  sRequest: WalletConnect.Model.SessionRequest

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
                "pair"-> {
                    val uri = call.argument<String>("uri");
                    pair(uri.toString())
                }
                "delegate" -> delegate()
                "disconnect" -> disconnect()
                "approve" -> {
                    val accounts = call.argument<List<String>>("accounts")
                    approve(accounts!!)
                }
                "reject" -> reject()
                "respondRequest" -> {
                    val sign = call.argument<String>("sign")
                    respondRequest(sign!!)
                }
                "rejectRequest" -> rejectRequest()
                "sessionUpdate" -> {
                    val accounts = call.argument<List<String>>("accounts")
                    sessionUpdate(accounts!!)
                }
                "sessionUpgrade" -> {
                    val chains = call.argument<List<String>>("chains")
                    val jsonrpc = call.argument<List<String>>("jsonrpc")
                    sessionUpgrade(chains!!, jsonrpc!!)
                }
                "sessionPing" -> sessionPing(result)
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


    private fun pair(uri:String){
        val pair = WalletConnect.Params.Pair(uri.trim())
        WalletConnectClient.pair(pair, StreamPair)
    }

    private fun delegate(){
        val walletDelegate = object : WalletConnectClient.WalletDelegate {
            override fun onSessionProposal(sessionProposal: WalletConnect.Model.SessionProposal) {
                sProposal = sessionProposal
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "onSessionProposal",
                    "value" to mapOf(
                        "accounts" to sProposal.accounts,
                        "chains" to sProposal.chains,
                        "description" to sProposal.description,
                        "icons" to sProposal.icons,
                        "isController" to sProposal.isController,
                        "methods" to sProposal.methods,
                        "name" to sProposal.name,
                        "proposerPublicKey" to sProposal.proposerPublicKey,
                        "relayProtocol" to sProposal.relayProtocol,
                        "topic" to sProposal.topic,
                        "ttl" to sProposal.ttl,
                        "types" to sProposal.types,
                        "url" to sProposal.url,
                    )
                ))
            }

            override fun onSessionRequest(sessionRequest: WalletConnect.Model.SessionRequest) {
                sRequest = sessionRequest
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "onSessionRequest",
                    "value" to mapOf(
                        "chainId" to sRequest.chainId,
                        "request" to mapOf<String, Any?>(
                            "method" to sRequest.request.method,
                            "id" to sRequest.request.id,
                            "params" to sRequest.request.params,
                        ),
                        "topic" to sRequest.topic,
                    )
                ))
            }

            override fun onSessionDelete(deletedSession: WalletConnect.Model.DeletedSession) {
                dSession = deletedSession
                // T for Response Type
                StreamDelegate.setValue(mapOf(
                    "T" to "onSessionDelete",
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
                    "T" to "onSessionNotification",
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

    private fun disconnect() {
        val disconnect = WalletConnect.Params.Disconnect(
            sessionTopic = sSession.topic,
            reason = "User disconnects",
            reasonCode = 1000
        )

        WalletConnectClient.disconnect(disconnect, StreamDisconnect)
    }

    // accounts is List<String> of chainId:address
    // example :
    // ["eip155:1:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"]
    private fun approve(accounts:List<String>){
        // Session Proposal object sent by Dapp after pairing was successful
        // val accounts = sProposal.chains.map { chainId -> "$chainId:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716" }
        val approve = WalletConnect.Params.Approve(sProposal, accounts)

        WalletConnectClient.approve(approve, StreamApprove)
    }

    private fun reject() {
        val rejectionReason = "Reject Session"
        val proposalTopic: String = sProposal.topic
        val reject = WalletConnect.Params.Reject(rejectionReason, proposalTopic)

        WalletConnectClient.reject(reject, StreamReject)
    }

    private fun respondRequest(sign:String){
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcResult(
                sRequest.request.id,
                sign
            )
        )
        WalletConnectClient.respond(response, StreamRespondRequest)
    }

    private fun rejectRequest() {
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcError(
                sRequest.request.id,
                WalletConnect.Model.JsonRpcResponse.Error(500, "Reject Request")
            )
        )

        WalletConnectClient.respond(response, StreamRejectRequest)
    }

    private fun sessionUpdate(accounts:List<String>) {
        val update = WalletConnect.Params.Update(
            sessionTopic = sSession.topic,
            // sessionState = WalletConnect.Model.SessionState(accounts = listOf("${sProposal.chains[0]}:0xa0A6c118b1B25207A8A764E1CAe1635339bedE62"))
            sessionState = WalletConnect.Model.SessionState(accounts = accounts)
        )

        WalletConnectClient.update(update, StreamSessionUpdate)
    }

    private fun sessionUpgrade(chains:List<String>, jsonrpc : List<String>) {
        val permissions =
            WalletConnect.Model.SessionPermissions(
                // blockchain = WalletConnect.Model.Blockchain(chains = listOf("eip155:80001")),
                // jsonRpc = WalletConnect.Model.Jsonrpc(listOf("eth_sign"))
                blockchain = WalletConnect.Model.Blockchain(chains = chains),
                jsonRpc = WalletConnect.Model.Jsonrpc(jsonrpc)
            )
        val upgrade = WalletConnect.Params.Upgrade(topic = sSession.topic, permissions = permissions)

        WalletConnectClient.upgrade(upgrade, StreamSessionUpgrade)
    }

    private fun sessionPing(result: MethodChannel.Result) {
        val ping = WalletConnect.Params.Ping(sSession.topic)

        WalletConnectClient.ping(ping, StreamSessionPing)

//        WalletConnectClient.ping(ping, object : WalletConnect.Listeners.SessionPing {
//            override fun onSuccess(topic: String) {
//                result.success(resultOnSuccess(
//                    mapOf(
//                        "topic" to topic,
//                    )
//                ))
//            }
//
//            override fun onError(error: Throwable) {
//                println(error.message)
//                result.error("onError", error.message,error)
//            }
//        })
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
            sink?.success(resultOnSuccess(
                mapOf(
                    "reason" to dSession.reason,
                    "topic" to dSession.topic,
                )
            ))
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
                resultOnSuccess(
                    mapOf(
                        "accounts" to sSession.accounts,
                        "peerAppMetaData" to sSession.peerAppMetaData,
                        "permissions" to mapOf(
                            "blockchain" to mapOf(
                                "chains" to sSession.permissions.blockchain.chains,
                            ),
                            "jsonRpc" to mapOf(
                                "methods" to sSession.permissions.jsonRpc.methods
                            ),
                            "notifications" to mapOf(
                                "types" to sSession.permissions.notifications.types
                            ),
                        ),
                        "topic" to sSession.topic,
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

