import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wallet_connect_v2_flutter/method_channel_impl.dart';

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
            // ElevatedButton(
            //     onPressed: () async {
            //       await methodChannelImpl.approve(() {}, () {});
            //     },
            //     child: const Text('Approve')),
            ElevatedButton(
                onPressed: () {
                  runBSProposal();
                },
                child: Text('Bottom')),
            StreamBuilder(
              stream: methodChannelImpl.streamDelegate().asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // stream();
                  return Text(snapshot.data.toString());
                }
                return const SizedBox();
              },
            ),
            // ElevatedButton(
            //   child: const Text('Stream'),
            //   onPressed: () async {
            //     runBottomSheet();
            //   },
            // ),
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
                        child: Image.network(dec['icons'][0]),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dec['name']),
                          Text(
                            dec['url'],
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
                    dec['chains'][0],
                  ),
                  Divider(),
                  Text(
                    'Relay Protocol',
                  ),
                  Text(
                    dec['relayProtocol'],
                  ),
                  Divider(),
                  Text(
                    'Method',
                  ),
                  Text(
                    dec['methods'].toString(),
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
                          await methodChannelImpl.approve(() {}, () {});
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
              Text('Session Proposal'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Image.network(dec['icons'][0]),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dec['name']),
                          Text(
                            dec['url'],
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
                    dec['chains'][0],
                  ),
                  Divider(),
                  Text(
                    'Relay Protocol',
                  ),
                  Text(
                    dec['relayProtocol'],
                  ),
                  Divider(),
                  Text(
                    'Method',
                  ),
                  Text(
                    dec['methods'].toString(),
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
                          await methodChannelImpl.approve(() {}, () {});
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
