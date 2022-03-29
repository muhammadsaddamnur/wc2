package com.example.wallet_connect_v2_flutter

import androidx.annotation.NonNull
import com.walletconnect.walletconnectv2.client.WalletConnect
import com.walletconnect.walletconnectv2.client.WalletConnectClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*


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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when(call.method){
                "pair"-> {
                    val uri = call.argument<String>("uri");
                    pair(uri.toString(), result)
                }
                "delegate" -> delegate(result)
                "disconnect" -> disconnect(result)
                "approve" -> approve(result)
                "reject" -> reject(result)
                "respondRequest" -> respondRequest(result)
                "rejectRequest" -> rejectRequest(result)
                "sessionUpdate" -> sessionUpdate(result)
                "sessionUpgrade" -> sessionUpgrade(result)
                "sessionPing" -> sessionPing(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pair(uri:String, result: MethodChannel.Result){
        val pair = WalletConnect.Params.Pair(uri.trim())
        WalletConnectClient.pair(pair, object : WalletConnect.Listeners.Pairing {
            override fun onSuccess(settledPairing: WalletConnect.Model.SettledPairing) {
                //Settled pairing
                println("=================== pair")
                sPairing = settledPairing
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }


    private fun delegate(result: MethodChannel.Result){
        val walletDelegate = object : WalletConnectClient.WalletDelegate {
            override fun onSessionProposal(sessionProposal: WalletConnect.Model.SessionProposal) {
                sProposal = sessionProposal
//                result.success("onSessionProposal")
            }

            override fun onSessionRequest(sessionRequest: WalletConnect.Model.SessionRequest) {
                sRequest = sessionRequest
//                result.success("onSessionRequest")
            }

            override fun onSessionDelete(deletedSession: WalletConnect.Model.DeletedSession) {
                dSession = deletedSession
//                result.success("onSessionDelete")
            }

            override fun onSessionNotification(sessionNotification: WalletConnect.Model.SessionNotification) {
                sNotification = sessionNotification
//                result.success("onSessionNotification")
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
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun approve(result: MethodChannel.Result){
        // Session Proposal object sent by Dapp after pairing was successful
        val accounts = sProposal.chains.map { chainId -> "$chainId:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716" }
        val approve = WalletConnect.Params.Approve(sProposal, accounts)

        WalletConnectClient.approve(approve, object : WalletConnect.Listeners.SessionApprove {
            override fun onSuccess(settledSession: WalletConnect.Model.SettledSession) {
                sSession = settledSession
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
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
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun respondRequest(result: MethodChannel.Result){
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcResult(
                sRequest.request.id,
                "0xa3f20717a250c2b0b729b7e5becbff67fdaef7e0699da4de7ca5895b02a170a12d887fd3b17bfdce3481f10bea41f45ba9f709d39ce8325427b57afcfc994cee1b"
            )
        )

        WalletConnectClient.respond(response, object : WalletConnect.Listeners.SessionPayload {
            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun rejectRequest(result: MethodChannel.Result) {
        val response = WalletConnect.Params.Response(
            sessionTopic = sRequest.topic,
            jsonRpcResponse = WalletConnect.Model.JsonRpcResponse.JsonRpcError(
                sRequest.request.id,
                WalletConnect.Model.JsonRpcResponse.Error(500, "Flutter Wallet Error")
            )
        )

        WalletConnectClient.respond(response, object : WalletConnect.Listeners.SessionPayload {
            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionUpdate(result: MethodChannel.Result) {
        val update = WalletConnect.Params.Update(
            sessionTopic = sSession.topic,
            sessionState = WalletConnect.Model.SessionState(accounts = listOf("${sProposal.chains[0]}:0xa0A6c118b1B25207A8A764E1CAe1635339bedE62"))
        )

        WalletConnectClient.update(update, object : WalletConnect.Listeners.SessionUpdate {
            override fun onSuccess(updatedSession: WalletConnect.Model.UpdatedSession) {
                upSession = updatedSession
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionUpgrade(result: MethodChannel.Result) {
        val permissions =
            WalletConnect.Model.SessionPermissions(
                blockchain = WalletConnect.Model.Blockchain(chains = listOf("eip155:80001")),
                jsonRpc = WalletConnect.Model.Jsonrpc(listOf("eth_sign"))
            )
        val upgrade = WalletConnect.Params.Upgrade(topic = sSession.topic, permissions = permissions)

        WalletConnectClient.upgrade(upgrade, object : WalletConnect.Listeners.SessionUpgrade {
            override fun onSuccess(upgradedSession: WalletConnect.Model.UpgradedSession) {
                ugSession = upgradedSession
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }

    private fun sessionPing(result: MethodChannel.Result) {
        val ping = WalletConnect.Params.Ping(sSession.topic)

        WalletConnectClient.ping(ping, object : WalletConnect.Listeners.SessionPing {
            override fun onSuccess(topic: String) {
                result.success("onSuccess")
            }

            override fun onError(error: Throwable) {
                result.error("onError", error.message,error)
            }
        })
    }
}

