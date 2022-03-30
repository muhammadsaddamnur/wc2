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

class MainActivity: FlutterActivity() {

    private val CHANNEL = "wallet_connect_2"

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



    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messager =flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messager, CHANNEL).setMethodCallHandler {
                call, result ->
            when(call.method){
                "pair"-> {
                    val uri = call.argument<String>("uri");
                    pair(uri.toString(), result)
                }
                "delegate" -> delegate(result)
                "disconnect" -> disconnect(result)
                "approve" -> {
                    val accounts = call.argument<List<String>>("accounts")
                    approve(accounts!!, result)
                }
                "reject" -> reject(result)
                "respondRequest" -> {
                    val sign = call.argument<String>("sign")
                    respondRequest(sign!!, result)
                }
                "rejectRequest" -> rejectRequest(result)
                "sessionUpdate" -> {
                    val accounts = call.argument<List<String>>("accounts")
                    sessionUpdate(accounts!!, result)
                }
                "sessionUpgrade" -> {
                    val chains = call.argument<List<String>>("chains")
                    val jsonrpc = call.argument<List<String>>("jsonrpc")
                    sessionUpgrade(chains!!, jsonrpc!!,result)
                }
                "sessionPing" -> sessionPing(result)
                else -> result.notImplemented()
            }
        }

        EventChannel(messager, "streamDelegate").setStreamHandler(StreamDelegate)
    }

    object StreamDelegate : EventChannel.StreamHandler, DelegateValue {
        var res: Map<String, Any?> = mapOf()
        var sink: EventChannel.EventSink? = null
        var handler: Handler? = null

        override fun setValue(resVal:Map<String, Any?>) {
            res = resVal
            handler = Handler(Looper.getMainLooper())
            handler!!.post {
                sink?.success(
                    JSONObject(res).toString()
                )
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sink = events
            sink?.success(
                JSONObject(res).toString()
            )
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }

    }

   private fun resultOnSuccess(res : Map<String, Any?>) : String {
      val result: Map<String, Any?> = mapOf(
           "T" to "onSuccess",
           "value" to res
       )
       return JSONObject(result).toString()
   }

    private fun pair(uri:String, result: MethodChannel.Result){
        val pair = WalletConnect.Params.Pair(uri.trim())
        WalletConnectClient.pair(pair, object : WalletConnect.Listeners.Pairing {
            override fun onSuccess(settledPairing: WalletConnect.Model.SettledPairing) {
                //Settled pairing
                println("=================== pair")
                sPairing = settledPairing
                if(sPairing.metaData!= null){
                    result.success(resultOnSuccess(
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
                    result.success(resultOnSuccess(
                        mapOf(
                            "metaData" to sPairing.metaData,
                            "topic" to sPairing.topic,
                        )
                    ))
                }

            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }


    private fun delegate(result: MethodChannel.Result){
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

    private fun disconnect(result: MethodChannel.Result) {
        val disconnect = WalletConnect.Params.Disconnect(
            sessionTopic = sSession.topic,
            reason = "User disconnects",
            reasonCode = 1000
        )

        WalletConnectClient.disconnect(disconnect, object : WalletConnect.Listeners.SessionDelete {
            override fun onSuccess(deletedSession: WalletConnect.Model.DeletedSession) {
                dSession = deletedSession
                result.success(resultOnSuccess(
                    mapOf(
                        "reason" to dSession.reason,
                        "topic" to dSession.topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    // accounts is List<String> of chainId:address
    // example :
    // ["eip155:1:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"]
    private fun approve(accounts:List<String>, result: MethodChannel.Result){
        // Session Proposal object sent by Dapp after pairing was successful
        // val accounts = sProposal.chains.map { chainId -> "$chainId:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716" }
        val approve = WalletConnect.Params.Approve(sProposal, accounts)

        WalletConnectClient.approve(approve, object : WalletConnect.Listeners.SessionApprove {
            override fun onSuccess(settledSession: WalletConnect.Model.SettledSession) {
                sSession = settledSession
                result.success(resultOnSuccess(
                    mapOf(
                        "accounts" to sSession.accounts,
                        "peerAppMetaData" to sSession.peerAppMetaData,
                        "permissions" to mapOf(
                            "blockchain" to  mapOf(
                                "chains" to sSession.permissions.blockchain.chains,
                            ),
                            "jsonRpc" to  mapOf(
                                "methods" to sSession.permissions.jsonRpc.methods
                            ),
                            "notifications" to  mapOf(
                                "types" to sSession.permissions.notifications.types
                            ),
                        ),
                        "topic" to sSession.topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun reject(result: MethodChannel.Result) {
        val rejectionReason = "Reject Session"
        val proposalTopic: String = sProposal.topic
        val reject = WalletConnect.Params.Reject(rejectionReason, proposalTopic)

        WalletConnectClient.reject(reject, object : WalletConnect.Listeners.SessionReject {
            override fun onSuccess(rejectedSession: WalletConnect.Model.RejectedSession) {
                rSession = rejectedSession
                result.success(resultOnSuccess(
                    mapOf(
                        "reason" to rSession.reason,
                        "topic" to rSession.topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun respondRequest(sign:String, result: MethodChannel.Result){
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcResult(
                sRequest.request.id,
                sign
            )
        )

        WalletConnectClient.respond(response, object : WalletConnect.Listeners.SessionPayload {
            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun rejectRequest(result: MethodChannel.Result) {
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcError(
                sRequest.request.id,
                WalletConnect.Model.JsonRpcResponse.Error(500, "Reject Request")
            )
        )

        WalletConnectClient.respond(response, object : WalletConnect.Listeners.SessionPayload {
            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionUpdate(accounts:List<String>, result: MethodChannel.Result) {
        val update = WalletConnect.Params.Update(
            sessionTopic = sSession.topic,
            // sessionState = WalletConnect.Model.SessionState(accounts = listOf("${sProposal.chains[0]}:0xa0A6c118b1B25207A8A764E1CAe1635339bedE62"))
            sessionState = WalletConnect.Model.SessionState(accounts = accounts)
        )

        WalletConnectClient.update(update, object : WalletConnect.Listeners.SessionUpdate {
            override fun onSuccess(updatedSession: WalletConnect.Model.UpdatedSession) {
                upSession = updatedSession
                result.success(resultOnSuccess(
                    mapOf(
                        "accounts" to upSession.accounts,
                        "topic" to upSession.topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionUpgrade(chains:List<String>, jsonrpc : List<String>, result: MethodChannel.Result) {
        val permissions =
            WalletConnect.Model.SessionPermissions(
                // blockchain = WalletConnect.Model.Blockchain(chains = listOf("eip155:80001")),
                // jsonRpc = WalletConnect.Model.Jsonrpc(listOf("eth_sign"))
                blockchain = WalletConnect.Model.Blockchain(chains = chains),
                jsonRpc = WalletConnect.Model.Jsonrpc(jsonrpc)
            )
        val upgrade = WalletConnect.Params.Upgrade(topic = sSession.topic, permissions = permissions)

        WalletConnectClient.upgrade(upgrade, object : WalletConnect.Listeners.SessionUpgrade {
            override fun onSuccess(upgradedSession: WalletConnect.Model.UpgradedSession) {
                ugSession = upgradedSession
                result.success(resultOnSuccess(
                    mapOf(
                        "permissions" to mapOf(
                            "blockchain" to  mapOf(
                                "chains" to ugSession.permissions.blockchain.chains,
                            ),
                            "jsonRpc" to  mapOf(
                                "methods" to ugSession.permissions.jsonRpc.methods
                            ),
                            "notification" to ugSession.permissions.notification,
                        ),
                        "topic" to ugSession.topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionPing(result: MethodChannel.Result) {
        val ping = WalletConnect.Params.Ping(sSession.topic)

        WalletConnectClient.ping(ping, object : WalletConnect.Listeners.SessionPing {
            override fun onSuccess(topic: String) {
                result.success(resultOnSuccess(
                    mapOf(
                        "topic" to topic,
                    )
                ))
            }

            override fun onError(error: Throwable) {
                println(error.message)
                result.error("onError", error.message,error)
            }
        })
    }
}


