import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:huawei_push/huawei_push.dart';

/**
 *  CURL for testing
 */

///OBTAIN OAUTH TOKEN

/// curl --location --request GET 'https://oauth-login.cloud.huawei.com/oauth2/v2/token' \
/// --header 'Content-Type: application/x-www-form-urlencoded' \
/// --data-urlencode 'grant_type=client_credentials' \
/// --data-urlencode 'client_secret=*****' \
/// --data-urlencode 'client_id= 102949247'

///SEND PUSH MESSAGE

/// curl --location --request POST 'https://push-api.cloud.huawei.com/v1/102949247/messages:send' \
/// --header 'Content-Type: application/json;charset=utf-8' \
/// --header 'Authorization: Bearer *****' \
/// --data-raw '{
/// "validate_only": false,
/// "message": {
/// "android": {
/// "bi_tag": "the_sample_bi_tag_for_receipt_service",
/// "collapse_key": -1,
/// "ttl": "10000s",
/// "urgency": "HIGH"
/// },
/// "data": "{\"inAppToastMessage\":\"#wayoftheminki!\", \"title\":\"New Message!\", \"body\":\"This is just a test.\"}",
/// "token": [
/// "IQAAAACy0aKvAADrdEYXMU4HI1f0jGOVBbC60Ls7uK4-EkPTLjznD0we17rKDqrQpAHvgtsnd1z9XCzaleUkuA1MMOunjlV0c4BLfNp9MrWShuUM9Q"
/// ]
/// }
/// }'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// It's important to declare this method in the top level of file, so it can be seen by background flutter isolate
void backgroundMessageHandler(RemoteMessage remoteMessage) async {
  myPrint("Push received in background: $remoteMessage");
  final String data = remoteMessage.data ?? '';

  myPrint("Received data: $data");

  final String title = remoteMessage.dataOfMap?['title'] ?? '';
  final String body = remoteMessage.dataOfMap?['body'] ?? '';

  Push.localNotification({
    HMSLocalNotificationAttr.TITLE: title,
    HMSLocalNotificationAttr.MESSAGE: body,
    HMSLocalNotificationAttr.DATA: json.decode(data),
  });
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    Push.setAutoInitEnabled(true)
        .then((value) => {
          myPrint("HMS Push AutoInit enabled $value")
        });

    Push.getTokenStream.listen((event) {
      myPrint("New HMS push token: $event");
    }, onError: (error) {
      myPrint("Failed to retrieve HMS push token $error");
    });

    Push.getToken('');

    /**
     * App is in foreground and receives notification
     */
    Push.onMessageReceivedStream.listen((RemoteMessage hmsRemoteMessage) {
      myPrint("Push received in foreground");
      showToast(hmsRemoteMessage.dataOfMap);
    },
        onError: (error) {
          myPrint("Failed to retrieve HMS push message $error");
    });

    Push.registerBackgroundMessageHandler(backgroundMessageHandler);

    /**
     * App was dead and received background notification, get initial notification data this way after user taps on notification
     */
    Push.getInitialNotification().then((value) {
      myPrint('Got initial notification after app start');
      var dataMap = parseJsonStringFromNotificationBlob(value);
      if(dataMap != null) {
        showToast(dataMap);
      }
    });

    /**
     * App is alive but in background, this is triggered after user taps on notification
     */
    Push.onNotificationOpenedApp.listen((event) {
      myPrint('On Notification opened App');
      var dataMap = parseJsonStringFromNotificationBlob(event);
      if(dataMap != null) {
        showToast(dataMap);
      }
    });
  }

  Map<String, dynamic>? parseJsonStringFromNotificationBlob(dynamic blob) {
    String? jsonString = (((blob as Map?)?['extras'] as Map?)?['notification'] as Map?)?['data'];
    myPrint('On received jsonString: ' + (jsonString ?? 'null'));

    if(jsonString != null) {
      final Map<String, dynamic> dataMap = json.decode(jsonString);
      return dataMap;
    } else {
      return null;
    }
  }

  void showToast(Map<String, dynamic>? map) {
    final String toastMessage = map?['inAppToastMessage'] ?? '';
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(toastMessage),
      ),
    );
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

void myPrint(String log) {
  print("----- PushDemo: " + log);
}
