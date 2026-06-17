import 'package:flutter/material.dart';
import 'package:http_wrap/http_wrap.dart';
import 'package:http_wrap_example/main.dart';

class HttpRequestView extends StatefulWidget {
  const HttpRequestView({super.key});

  @override
  State<HttpRequestView> createState() => _HttpRequestViewState();
}

class _HttpRequestViewState extends State<HttpRequestView> {
  final _batchIdCtrl = TextEditingController(text: '1');

  late Future<HttpResponse> _getServerData;

  @override
  void initState() {
    super.initState();
    _getServerData = _getData();
  }

  @override
  void dispose() {
    _batchIdCtrl.dispose();
    super.dispose();
  }

  Future<HttpResponse> _getData() async {
    if (_batchIdCtrl.text.isEmpty) {
      _batchIdCtrl.text = '1';
    }

    return httpWrapPlugin.request(
      method: .get,
      endpoint: '/api/v2/books',
      queryParams: {
        '_quantity': _batchIdCtrl.text,
        '_locale': 'en_US',
      },
    );
  }

  @override
  Widget build(context) {
    return FutureBuilder<HttpResponse>(
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
                  child: const Text('Retry'),
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
        final requestData = data['data'] as List? ?? [];

        return Center(
          child: SingleChildScrollView(
            padding: const .all(8),
            child: Column(
              spacing: 12,
              children: [
                const Text('Enter a number and press the button'),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.2,
                  child: TextField(
                    controller: _batchIdCtrl,
                    textAlign: .center,
                    keyboardType: TextInputType.number,
                    decoration: const .new(hintText: 'Eg; 1'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _getServerData = _getData();
                    setState(() {});
                  },
                  child: const Text('Make Request'),
                ),
                ...requestData.map(
                  (e) => Container(
                    alignment: Alignment.topLeft,
                    padding: const .all(12),
                    decoration: BoxDecoration(
                      borderRadius: .all(.circular((16))),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 0.7,
                          blurStyle: .outer,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          e['title'],
                          style: const .new(
                            fontSize: 16,
                            fontWeight: .bold,
                          ),
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
        );
      },
    );
  }
}
