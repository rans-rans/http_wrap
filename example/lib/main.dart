import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http_wrap/http_wrap.dart';

final httpWrapPlugin = HttpWrap();
void main() {
  runApp(const MyApp());
  httpWrapPlugin.config(baseUrl: "https://sendgrid-v3-api.mock.beeceptor.com");
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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<HttpResponse> _getData() async {
    return await httpWrapPlugin.request(
      method: .get,
      endpoint: "/v3/user/scheduled_sends/${_batchIdCtrl.text}",
      headers: {"on-behalf-of": "Excepteur veniam"},
    );
  }

  @override
  Widget build(context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
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

            final requestData = (snapshot.data?.data as List<Map>?) ?? [];
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.1,
                      child: TextField(
                        controller: _batchIdCtrl,
                        keyboardType: .number,
                        decoration: const InputDecoration(
                          hintText: "Enter a batch number",
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
                      (e) => ListTile(
                        title: Text(e['batch_id']),
                        subtitle: Text(
                          e['status'],
                          style: const .new(fontWeight: .bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
