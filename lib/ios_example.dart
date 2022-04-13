import 'dart:convert';

import 'package:flutter/material.dart';

import 'method_channel_ios.dart';

class IosExample extends StatefulWidget {
  const IosExample({Key? key}) : super(key: key);

  @override
  State<IosExample> createState() => _IosExampleState();
}

class _IosExampleState extends State<IosExample> {
  TextEditingController textEditingController = TextEditingController();

  MethodChannelIOS methodChannelIOS = MethodChannelIOS();

  bool isBottomSheet = false;

  dynamic dec;

  List? sessions;

  @override
  void initState() {
    methodChannelIOS.initialize();
    checkSessionSettled();
    methodChannelIOS.eventChannel.receiveBroadcastStream().listen(_onEvent);

    super.initState();
  }

  checkSessionSettled() async {
    sessions = await methodChannelIOS.reloadActiveSessions();
    setState(() {});
    if (sessions != null) {
      await methodChannelIOS.pair('', () {}, () {});
    }
  }

  reloadSession() async {
    sessions = await methodChannelIOS.reloadActiveSessions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // ElevatedButton(
          //   onPressed: () {
          //     methodChannelIOS.test();
          //   },
          //   child: Text('wkwk'),
          // ),
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
              physics: NeverScrollableScrollPhysics(),
              children: sessions!.map((e) {
                var value = json.decode(e)['value'];
                return ListTile(
                  leading: Image.network(value['icons'][0], width: 30),
                  title: Text(value['name']),
                  subtitle: Text(value['url']),
                  trailing: IconButton(
                      onPressed: () async {
                        await methodChannelIOS.disconnect(value['topic']);
                        reloadSession();
                      },
                      icon: Icon(Icons.close)),
                );
              }).toList(),
            ),
          ElevatedButton(
            child: const Text('Pair'),
            onPressed: () async {
              await methodChannelIOS.pair(
                  textEditingController.text, () {}, () {});
            },
          ),

          // ElevatedButton(
          //   child: const Text('Disconnect'),
          //   onPressed: () async {
          //     await methodChannelIOS.disconnect();
          //   },
          // ),
          ElevatedButton(
            child: const Text('reloadSessions'),
            onPressed: () async {
              reloadSession();
            },
          ),
          ElevatedButton(
            child: const Text('update'),
            onPressed: () async {
              var update = await methodChannelIOS.update(
                '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
                '0x022c0c42a80bd19EA4cF0F94c4F9F96645759716',
                [
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
              var upgrade = await methodChannelIOS.upgrade(
                '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
                [
                  "eip155:80001",
                  "eip155:42",
                  "eip155:44787",
                  "solana:8E9rvCKLFQia2Y35HXjjpWzj8weVo44K",
                  "eip155:69",
                  "eip155:421611"
                ],
                [
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
              sessions = await methodChannelIOS.ping(
                '764936a660195446d92bc300bcee9a512b903b87335978f591b787df89c6dd60',
              );
            },
          ),
        ],
      ),
    );
  }

  void _onEvent(event) {
    if (event != null) {
      print(event);
      dec = json.decode(event.toString().trim());
      // print(event.toString().trim());
      switch (dec["T"]) {
        case "sessionProposal":
          runBSProposal();
          break;
        case "sessionRequest":
          runBSRequest();
          break;
        default:
      }
      print("wk" + dec['T'].toString());
    }
  }

  void runBSProposal() {
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
                        child: Image.network(dec['value']['icons'][0]),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dec['value']['name']),
                          Text(
                            dec['value']['url'],
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
                    dec['value']['chains'][0],
                  ),
                  Divider(),
                  Text(
                    'Relay Protocol',
                  ),
                  Text(
                    dec['value']['relayProtocol'],
                  ),
                  Divider(),
                  Text(
                    'Method',
                  ),
                  Text(
                    dec['value']['methods'].toString(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          await methodChannelIOS.approve(
                              '0x022c0c42a80bd19EA4cF0F94c4F9F96645759716');
                          reloadSession();
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await methodChannelIOS.reject();
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

  void runBSRequest() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              Text('Session Request'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   children: [
                  //     CircleAvatar(
                  //       child: Image.network(dec['value']['icons'][0]),
                  //     ),
                  //     SizedBox(
                  //       width: 5,
                  //     ),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(dec['value']['name']),
                  //         Text(
                  //           dec['value']['url'],
                  //         )
                  //       ],
                  //     )
                  //   ],
                  // ),
                  // Divider(),
                  // Text(
                  //   'Blockchain(s)',
                  // ),
                  // Text(
                  //   dec['value']['chains'][0],
                  // ),
                  // Divider(),
                  // Text(
                  //   'Relay Protocol',
                  // ),
                  // Text(
                  //   dec['value']['relayProtocol'],
                  // ),
                  // Divider(),
                  // Text(
                  //   'Method',
                  // ),
                  // Text(
                  //   dec['value']['methods'].toString(),
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          await methodChannelIOS.respondRequest(
                              '0xa3f20717a250c2b0b729b7e5becbff67fdaef7e0699da4de7ca5895b02a170a12d887fd3b17bfdce3481f10bea41f45ba9f709d39ce8325427b57afcfc994cee1b');
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await methodChannelIOS.rejectRequest();
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
