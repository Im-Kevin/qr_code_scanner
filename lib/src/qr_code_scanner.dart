import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../qr_code_scanner.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);

class QRView extends StatefulWidget {
  const QRView({
    required Key key,
    required this.onQRViewCreated,
    this.overlay,
  })  : super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final QrScannerShapeBase? overlay;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  QRViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        if (widget.overlay != null)
          Container(
            decoration: ShapeDecoration(
              shape: widget.overlay!,
            ),
          )
        else
          Container(),
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    _controller = QRViewController._(id, widget.key as GlobalKey, widget.overlay!);
    widget.onQRViewCreated(_controller!);
  }
}

class _CreationParams {
  _CreationParams({required this.width,required this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  QRViewController._(
    int id,
    GlobalKey qrKey,
    QrScannerShapeBase overlay,
  ) : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var scanRect =
          Rect.fromLTWH(0, 0, qrKey.currentContext!.size!.width, qrKey.currentContext!.size!.height);
      if (overlay != null) {
        scanRect = overlay.getScannerRect(qrKey.currentContext!.size!);
      }
      _channel.invokeMethod('init', {
        'width': qrKey.currentContext!.size!.width,
        'height': qrKey.currentContext!.size!.height,
        'scannerRect': {
          'left': scanRect.left,
          'top': scanRect.top,
          'width': scanRect.width,
          'height': scanRect.height
        }
      });
    }
    _channel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              _scanUpdateController.sink.add(call.arguments.toString());
            }
        }
      },
    );
  }

  static const scanMethodCall = 'onRecognizeQR';

  final MethodChannel _channel;

  final StreamController<String> _scanUpdateController =
      StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  void flipCamera() {
    _channel.invokeMethod('flipCamera');
  }

  void toggleFlash() {
    _channel.invokeMethod('toggleFlash');
  }

  void pauseCamera() {
    _channel.invokeMethod('pauseCamera');
  }

  void resumeCamera() {
    _channel.invokeMethod('resumeCamera');
  }

  void dispose() {
    _scanUpdateController.close();
  }

  void _setScanRect(Rect rect) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _channel.invokeMethod('setScanRect', {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      });
    }
  }
}
