import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http_wrap/http_wrap.dart';
import 'package:http_wrap_example/http_request_view.dart';
import 'package:http_wrap_example/item_download_view.dart';

final httpWrapPlugin = HttpWrap()..config(baseUrl: 'https://fakerapi.it');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// https://vscode.download.prss.microsoft.com/dbazure/download/stable/
// 6928394f91b684055b873eecb8bc281365131f1c/code_1.124.2-1781225536_amd64.deb
class _MyAppState extends State<MyApp> {
  int _selectedIndex = 1;

  @override
  Widget build(context) {
    return MaterialApp(
      theme: ThemeData(
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('HTTP WRAP')),
        body: Column(
          children: [
            CupertinoSegmentedControl(
              onValueChanged: (value) {
                setState(() => _selectedIndex = value);
              },
              children: {
                0: Text("Http Request"),
                1: Text("Download Item"),
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const HttpRequestView(),
                  ItemDownloadView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
