// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'webrtc_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  } else if (WebRTC.platformIsAndroid) {
    //startForegroundService();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebRTCService(),
      child: MaterialApp(
        home: WebRTCPage(),
      ),
    );
  }
}

class WebRTCPage extends StatefulWidget {
  @override
  State<WebRTCPage> createState() => _WebRTCPageState();
}

class _WebRTCPageState extends State<WebRTCPage> {
  final TextEditingController ipcUuidController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Yêu cầu quyền khi ứng dụng khởi chạy
  }

  Future<void> requestPermissions() async {
    // Yêu cầu quyền camera, microphone và storage
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final webrtcService = Provider.of<WebRTCService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("WebRTC Example")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            webrtcService.isConnected
                ? InkWell(
                    onTap: () {
                      webrtcService.disconnect();
                    },
                    child: Text("Stop"))
                : InkWell(
                    onTap: () {
                      webrtcService.connect(
                        ipcUuid: "662e3a00-6b61-11ef-8b20-d73bd8821410",
                        username: "demo2@epcb.vn",
                        password: "demo2@123",
                      );
                    },
                    child: Text("Connect")),
            Expanded(
              child: GestureDetector(
                onScaleStart: (details) {
                  _previousScale = _scale;
                  _previousOffset = _offset;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _scale = (_previousScale * details.scale).clamp(1.0, 3.0);
                    if (_scale > 1.0) {
                      _offset =
                          _previousOffset + details.focalPointDelta / _scale;
                    } else {
                      _offset = Offset.zero;
                    }
                  });
                },
                onScaleEnd: (details) {
                  _previousOffset = _offset;
                },
                child: Container(
                  color: Colors.black,
                  child: ClipRect(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translate(_offset.dx, _offset.dy)
                        ..scale(_scale),
                      child: webrtcService.isConnected
                          ? RTCVideoView(
                              webrtcService.remoteRenderer,
                              mirror: false,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitContain,
                            )
                          : const Center(
                              child: Text(
                                "No Connection",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
