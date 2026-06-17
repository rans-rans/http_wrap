import 'dart:async';

import 'package:http_wrap/download_state.dart';
import 'package:http_wrap/downloader.dart';

class DownloadController {
  final Downloader _downloader;
  final Stream<DownloadInfo> progressStream;

  DownloadController(this._downloader, this.progressStream);

  double get progress => _downloader.progress;

  void pause() => _downloader.pause();
  void resume() => _downloader.resume();
}
