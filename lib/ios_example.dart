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
                var value = json.decode(e);
                return ListTile(
                  leading: Image.network(value['iconURL'], width: 30),
                  title: Text(value['dappName']),
                  subtitle: Text(value['dappURL']),
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
                  '3b521cc2f1b374e8f16afb0c9c86081baefe22042598491b4aab1be73f9b4a55',
                  '0x022c0c42a80bd19EA4cF0F94c4F9F96645759716');
              print(update);
            },
          ),
          ElevatedButton(
            child: const Text('upgrade'),
            onPressed: () async {
              var upgrade = await methodChannelIOS.upgrade(
                '3b521cc2f1b374e8f16afb0c9c86081baefe22042598491b4aab1be73f9b4a55',
              );
              print(upgrade);
            },
          ),
          ElevatedButton(
            child: const Text('ping'),
            onPressed: () async {
              sessions = await methodChannelIOS.ping(
                '3b521cc2f1b374e8f16afb0c9c86081baefe22042598491b4aab1be73f9b4a55',
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
        case "onSessionProposal":
          runBSProposal();
          break;
        case "onSessionRequest":
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
