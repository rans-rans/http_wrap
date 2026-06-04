import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http_wrap/http_wrap.dart';

final httpWrapPlugin = HttpWrap()..config(baseUrl: "https://fakerapi.it");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _batchIdCtrl = TextEditingController(text: "1");

  late Future<HttpResponse> _getServerData;

  @override
  void initState() {
    super.initState();
    _getServerData = _getData();
  }

  @override
  void dispose() {
    super.dispose();
    _batchIdCtrl.dispose();
  }

  /// Platform messages are asynchronous, so we initialize in an async method.
  Future<HttpResponse> _getData() async {
    if (_batchIdCtrl.text.isEmpty) {
      _batchIdCtrl.text = "1";
    }
    return await httpWrapPlugin.request(
      method: .get,
      endpoint: "/api/v2/books",
      queryParams: {
        "_quantity": _batchIdCtrl.text,
        "_locale": "en_US",
      },
    );
  }

  @override
  Widget build(context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('HTTP WRAP')),
        body: FutureBuilder(
          future: _getServerData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == .waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  spacing: 4,
                  mainAxisSize: .min,
                  children: [
                    ElevatedButton(
                      child: const Text("Retry"),
                      onPressed: () {
                        _getServerData = _getData();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }

            final data = (snapshot.data?.data as Map?) ?? {};
            final requestData = data['data'] as List;
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const .all(8.0),
                  child: Column(
                    spacing: 12,
                    children: [
                      Text("Enter a number and make press the button"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.2,
                        child: TextField(
                          controller: _batchIdCtrl,
                          textAlign: .center,
                          keyboardType: .number,
                          decoration: const InputDecoration(
                            hintText: "Eg; 3",
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        child: const Text("Make Request"),
                        onPressed: () {
                          _getServerData = _getData();
                          setState(() {});
                        },
                      ),

                      ...requestData.map(
                        (e) => Container(
                          alignment: .topLeft,
                          padding: .all(12),
                          decoration: BoxDecoration(
                            borderRadius: .all(.circular(16)),
                            boxShadow: [
                              .new(blurRadius: 0.7, blurStyle: .outer),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                e['title'],
                                style: .new(fontSize: 16, fontWeight: .bold),
                              ),
                              Text(
                                e['author'],
                                style: const .new(fontWeight: .bold),
                              ),
                              Text(e['description']),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
