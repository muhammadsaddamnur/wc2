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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                print("woyy");
                methodChannelImpl
                    .streamDelegate()
                    .asBroadcastStream()
                    .listen((event) {
                  if (event == "onSessionProposal") {
                    if (isBottomSheet == false) {
                      isBottomSheet = true;
                      runBottomSheet();
                    }
                  }
                });
              },
            ),
            ElevatedButton(
                onPressed: () async {
                  await methodChannelImpl.approve(() {}, () {});
                },
                child: const Text('Approve')),
            StreamBuilder(
                stream: methodChannelImpl.streamDelegate(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data.toString());
                  }
                  return const SizedBox();
                }),
            ElevatedButton(
              child: const Text('Stream'),
              onPressed: () async {
                runBottomSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void runBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.amber,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Appprove?'),
                ElevatedButton(
                  child: const Text('Approve'),
                  onPressed: () async {
                    isBottomSheet = false;
                    await methodChannelImpl.approve(() {}, () {});
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
