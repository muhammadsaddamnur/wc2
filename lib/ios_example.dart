import 'dart:convert';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect_v2_flutter/wc2_client.dart';
import 'package:wallet_connect_v2_flutter/models/peer_meta.dart';
import 'package:wallet_connect_v2_flutter/models/session_proposal.dart';
import 'package:wallet_connect_v2_flutter/models/session_request.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import 'method_channel_ios.dart';
import 'models/sign/WCEthereumTransaction.dart';

class IosExample extends StatefulWidget {
  const IosExample({Key? key}) : super(key: key);

  @override
  State<IosExample> createState() => _IosExampleState();
}

class _IosExampleState extends State<IosExample> {
  TextEditingController textEditingController = TextEditingController();

  bool isBottomSheet = false;

  List? sessions;

  late WC2Client eventChannelIOS;

  final _web3client = Web3Client(
    // 'https://rpc-mainnet.maticvigil.com/v1/140d92ff81094f0f3d7babde06603390d7e581be',
    'https://kovan.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
    http.Client(),
  );
  String privateKey =
      'eb3b5c1dcaee30f5d060440e72665f49e00f6d3078075c827d7c0f46a9e366c2';

  String walletAddress = '';

  @override
  void initState() {
    createWalletAddress();

    eventChannelIOS = WC2Client(
      onSessionProposal: (v) {
        onSessionProposal(v);
      },
      onDelete: (v) {
        reloadSession();
      },
      onEthSignTransaction: (chainId, tx) async {
        onEthSignTransaction(chainId, tx);
      },
      onPersonalSign: (message) {
        onPersonalSigning(message);
      },
      onEthSign: (message) {
        onEthSign(message);
      },
      onEthSignTypedData: (message) {
        onEthSignTypedData(message);
      },
      onFailure: (v) {},
    );

    eventChannelIOS.initialize(
      peerMeta: PeerMeta(
        metadataDescription: "wallet description",
        metadataIcons: [
          "https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"
        ],
        metadataName: "Example Wallet",
        metadataUrl: "example.wallet",
        projectId: "4af2e046c7a7cbff0a96dc0f594b7e13",
        relayHost: "relay.walletconnect.com",
      ),
    );

    checkSessionSettled();

    super.initState();
  }

  createWalletAddress() async {
    /// create credential wallet from private key
    Credentials credentials = EthPrivateKey.fromHex(privateKey);

    /// create address wallet from credentials
    var address = await credentials.extractAddress();

    /// set wallet address
    walletAddress = address.hex;
  }

  checkSessionSettled() async {
    sessions = await eventChannelIOS.sessionStore();
    setState(() {});
    if (sessions != null) {
      await eventChannelIOS.pair('');
    }
  }

  reloadSession() async {
    sessions = await eventChannelIOS.sessionStore();
    setState(() {});
  }

  Transaction _wcEthTxToWeb3Tx(WCEthereumTransaction ethereumTransaction) {
    return Transaction(
      from: EthereumAddress.fromHex(ethereumTransaction.from),
      to: EthereumAddress.fromHex(ethereumTransaction.to),
      maxGas: ethereumTransaction.gasLimit != null
          ? int.tryParse(ethereumTransaction.gasLimit!)
          : null,
      gasPrice: ethereumTransaction.gasPrice != null
          ? EtherAmount.inWei(BigInt.parse(ethereumTransaction.gasPrice!))
          : null,
      value: EtherAmount.inWei(BigInt.parse(ethereumTransaction.value ?? '0')),
      data: hexToBytes(ethereumTransaction.data),
      nonce: ethereumTransaction.nonce != null
          ? int.tryParse(ethereumTransaction.nonce!)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          TextField(
            controller: textEditingController,
          ),
          const SizedBox(
            height: 20,
          ),
          const Text('Session'),
          if (sessions != null)
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: sessions!.map((e) {
                var value = json.decode(e)['value'];
                return ListTile(
                  leading: Image.network(value['icons'][0], width: 30),
                  title: Text(value['name']),
                  subtitle: Text(value['url']),
                  trailing: IconButton(
                      onPressed: () async {
                        await eventChannelIOS.disconnect(value['topic']);
                        reloadSession();
                      },
                      icon: Icon(Icons.close)),
                );
              }).toList(),
            ),
          ElevatedButton(
            child: const Text('Pair'),
            onPressed: () async {
              await eventChannelIOS.pair(textEditingController.text);
            },
          ),
          ElevatedButton(
            child: const Text('reloadSessions'),
            onPressed: () async {
              reloadSession();
            },
          ),
          ElevatedButton(
            child: const Text('update'),
            onPressed: () async {
              var update = await eventChannelIOS.update(
                topic:
                    '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
                account: walletAddress,
                chains: [
                  "eip155:80001",
                  "eip155:42",
                  "eip155:44787",
                  "solana:8E9rvCKLFQia2Y35HXjjpWzj8weVo44K",
                  "eip155:69",
                  "eip155:421611"
                ],
              );
              print(update);
            },
          ),
          ElevatedButton(
            child: const Text('upgrade'),
            onPressed: () async {
              var upgrade = await eventChannelIOS.upgrade(
                topic:
                    '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
                chains: [
                  "eip155:80001",
                  "eip155:42",
                  "eip155:44787",
                  "solana:8E9rvCKLFQia2Y35HXjjpWzj8weVo44K",
                  "eip155:69",
                  "eip155:421611"
                ],
                methods: [
                  "eth_signTransaction",
                  "solana_signMessage",
                  "personal_sign",
                  "eth_signTypedData",
                  "eth_sendTransaction",
                  "eth_sign",
                  "solana_signTransaction"
                ],
              );
              print(upgrade);
            },
          ),
          ElevatedButton(
            child: const Text('ping'),
            onPressed: () async {
              sessions = await eventChannelIOS.ping(
                '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
              );
            },
          ),
        ],
      ),
    );
  }

  void onSessionProposal(SessionProposal value) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              Text('Session Proposal'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Image.network(value.value!.icons!.first ?? ''),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value.value!.name ?? ''),
                          Text(
                            value.value!.url ?? '',
                          )
                        ],
                      )
                    ],
                  ),
                  Divider(),
                  Text(
                    'Blockchain(s)',
                  ),
                  Text(
                    value.value!.chains.toString(),
                  ),
                  Divider(),
                  Text(
                    'Relay Protocol',
                  ),
                  Text(
                    value.value!.relayProtocol ?? '',
                  ),
                  Divider(),
                  Text(
                    'Method',
                  ),
                  Text(
                    value.value!.methods.toString(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          // await eventChannelIOS.approve(
                          //     '0x022c0c42a80bd19EA4cF0F94c4F9F96645759716');
                          await eventChannelIOS.approve(walletAddress);
                          reloadSession();
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await eventChannelIOS.reject();
                          reloadSession();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }

  onPersonalSigning(String message) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              const Text('Personal Signing'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(String.fromCharCodes(hexToBytes(message))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          String signedDataHex = '';

                          final creds = EthPrivateKey.fromHex(privateKey);
                          final encodedMessage = hexToBytes(message);
                          final signedData =
                              await creds.signPersonalMessage(encodedMessage);
                          signedDataHex =
                              bytesToHex(signedData, include0x: true);

                          await eventChannelIOS.respondRequest(signedDataHex);
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await eventChannelIOS.rejectRequest();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }

  onEthSignTransaction(int chainId, WCEthereumTransaction tx) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              const Text('EthSignTransaction'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(String.fromCharCodes(hexToBytes(message))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          final creds = EthPrivateKey.fromHex(privateKey);
                          final signedDataHex =
                              await _web3client.signTransaction(
                            creds,
                            _wcEthTxToWeb3Tx(tx),
                            chainId: chainId,
                          );

                          await eventChannelIOS.respondRequest(
                              bytesToHex(signedDataHex, include0x: true));
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await eventChannelIOS.rejectRequest();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }

  onEthSign(String message) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              const Text('EthSignTransaction'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(String.fromCharCodes(hexToBytes(message))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          String signedDataHex = '';

                          final creds = EthPrivateKey.fromHex(privateKey);
                          final encodedMessage = hexToBytes(message);
                          final signedData =
                              await creds.signPersonalMessage(encodedMessage);
                          signedDataHex =
                              bytesToHex(signedData, include0x: true);

                          await eventChannelIOS.respondRequest(signedDataHex);
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await eventChannelIOS.rejectRequest();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }

  onEthSignTypedData(String message) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              const Text('EthSignTransaction'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(String.fromCharCodes(hexToBytes(message))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          String signedDataHex = '';

                          signedDataHex = EthSigUtil.signTypedData(
                            privateKey: privateKey,
                            jsonData: message,
                            version: TypedDataVersion.V4,
                          );

                          await eventChannelIOS.respondRequest(signedDataHex);
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await eventChannelIOS.rejectRequest();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }
}
