import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wallet_connect_v2_flutter/ios_example.dart';
import 'package:wallet_connect_v2_flutter/method_channel_impl.dart';
import 'package:wallet_connect_v2_flutter/backup/method_channel_ios.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const IosExample(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MethodChannelImpl methodChannelImpl = MethodChannelImpl();

  String message = '';
  TextEditingController textEditingController = TextEditingController();
  bool isBottomSheet = false;
  dynamic dec;

  @override
  void initState() {
    super.initState();
  }

  stream() {
    methodChannelImpl.streamDelegate().asBroadcastStream().listen((event) {
      print('listen');
      if (event != null) {
        dec = json.decode(event.toString());

        switch (dec['T']) {
          case "onSessionProposal":
            if (isBottomSheet == false) {
              isBottomSheet = true;
              runBSProposal();
            }
            break;
          case "onSessionRequest":
            if (isBottomSheet == false) {
              isBottomSheet = true;
              runBSProposal();
            }
            break;
          default:
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Text(message),
            // ElevatedButton(
            //   child: const Text('Init'),
            //   onPressed: _init,
            // ),
            TextField(
              controller: textEditingController,
            ),
            ElevatedButton(
              child: const Text('Pair'),
              onPressed: () async {
                await methodChannelImpl.pair(
                    textEditingController.text, () {}, () {});

                methodChannelImpl.delegate();
                stream();
                print("woyy");
                methodChannelImpl
                    .streamDelegate()
                    .asBroadcastStream()
                    .listen((event) {
                  print('listen');
                  if (event != null) {
                    dec = json.decode(event.toString());
                    if (dec['T'] == "onSessionProposal") {
                      if (isBottomSheet == false) {
                        isBottomSheet = true;
                        runBSProposal();
                      }
                    }
                  }
                });
              },
            ),
            StreamBuilder(
              stream: methodChannelImpl.streamDelegate().asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // stream();
                  dec = json.decode(snapshot.data.toString());
                  // if (dec['T'] == "onSessionRequest") {
                  //   switch (dec['value']['request']['method']) {
                  //     case :

                  //       break;
                  //     default:
                  //   }
                  // }
                  return Column(
                    children: [
                      Text(dec.toString()),
                      if (dec['T'] == "onSessionRequest")
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                methodChannelImpl.rejectRequest(
                                  () {},
                                  () {},
                                );
                              },
                              child: Text('Reject'),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // String sign = dec['value']['request']['params']
                                //     .toString()
                                //     .replaceAll('[', '')
                                //     .replaceAll(']', '')
                                //     .split(',')[0];
                                // print(sign);
                                methodChannelImpl.respondRequest(
                                  '0xa3f20717a250c2b0b729b7e5becbff67fdaef7e0699da4de7ca5895b02a170a12d887fd3b17bfdce3481f10bea41f45ba9f709d39ce8325427b57afcfc994cee1b',
                                  () {},
                                  () {},
                                );
                              },
                              child: Text('Approve'),
                            ),
                          ],
                        )
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
            ElevatedButton(
              child: const Text('Session Update'),
              onPressed: () async {
                isBottomSheet = false;
                // List chains = dec['value']['chains'];
                List chains = ["eip155:42"]; // example Ethereum Kovan
                await methodChannelImpl.sessionUpdate(
                  chains.map((chainId) {
                    return "$chainId:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716";
                  }).toList(),
                  () {},
                  () {},
                );
                setState(() {});
              },
            ),
            ElevatedButton(
              child: const Text('Session Upgrade'),
              onPressed: () async {
                isBottomSheet = false;
                // List chains = dec['value']['chains'];
                List<String> chains = ["eip155:42"]; // example Ethereum Kovan
                List<String> jsonrpc = ["eth_sign"];
                await methodChannelImpl.sessionUpgrade(
                  chains,
                  jsonrpc,
                  () {},
                  () {},
                );
                setState(() {});
              },
            ),
            ElevatedButton(
              child: const Text('Session Ping'),
              onPressed: () async {
                isBottomSheet = false;

                await methodChannelImpl.sessionPing(
                  () {},
                  () {},
                );
                setState(() {});
              },
            ),
            ElevatedButton(
              child: const Text('Disconnect'),
              onPressed: () async {
                isBottomSheet = false;

                await methodChannelImpl.disconnect(() {}, () {});
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
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
                        child: const Text('Reject'),
                        onPressed: () async {
                          isBottomSheet = false;
                          await methodChannelImpl.reject(() {}, () {});
                          Navigator.pop(context);
                          setState(() {});
                        },
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.red)),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () async {
                          isBottomSheet = false;
                          List chains = dec['value']['chains'];
                          await methodChannelImpl.approve(
                            chains.map((chainId) {
                              return "$chainId:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716";
                            }).toList(),
                            () {},
                            () {},
                          );
                          Navigator.pop(context);
                          setState(() {});
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
