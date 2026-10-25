import 'package:flutter/material.dart';
import 'package:http_wrap/http_wrap.dart';
import 'package:http_wrap_example/main.dart';

class HttpRequestView extends StatefulWidget {
  const HttpRequestView({super.key});

  @override
  State<HttpRequestView> createState() => _HttpRequestViewState();
}

class _HttpRequestViewState extends State<HttpRequestView> {
  final _postIdCtrl = TextEditingController(text: '1');

  late Future<HttpResponse> _getServerData;

  @override
  void initState() {
    super.initState();
    _getServerData = _getData();
  }

  @override
  void dispose() {
    _postIdCtrl.dispose();
    super.dispose();
  }

  Future<HttpResponse> _getData() async {
    if (_postIdCtrl.text.isEmpty) {
      _postIdCtrl.text = '1';
    }

    return httpWrapPlugin.request(
      method: .get,
      endpoint: '/comments',
      queryParams: {
        'postId': _postIdCtrl.text,
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

        if (snapshot.hasError || snapshot.data?.success != true) {
          return Center(
            child: Column(
              spacing: 4,
              mainAxisSize: .min,
              children: [
                Text(
                  snapshot.data?.message ??
                      snapshot.error?.toString() ??
                      'Could not load comments.',
                ),
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

        final comments = (snapshot.data?.data as List?) ?? [];

        return Center(
          child: SingleChildScrollView(
            padding: const .all(8),
            child: Column(
              spacing: 12,
              children: [
                const Text('Enter a post ID to load its comments'),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _postIdCtrl,
                    textAlign: .center,
                    keyboardType: TextInputType.number,
                    decoration: const .new(
                      labelText: 'Post ID',
                      hintText: 'e.g. 1',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _getServerData = _getData();
                    setState(() {});
                  },
                  child: const Text('Load Comments'),
                ),
                if (comments.isEmpty)
                  const Text('No comments found for this post.'),
                ...comments.map(
                  (comment) => Container(
                    alignment: Alignment.topLeft,
                    padding: const .all(12),
                    decoration: const BoxDecoration(
                      borderRadius: .all(.circular((16))),
                      boxShadow: [
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
                          'Comment #${comment['id']} · Post #${comment['postId']}',
                        ),
                        Text(
                          comment['name'],
                          style: const .new(
                            fontSize: 16,
                            fontWeight: .bold,
                          ),
                        ),
                        Text(
                          comment['email'],
                          style: const .new(fontWeight: .bold),
                        ),
                        Text(comment['body']),
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
