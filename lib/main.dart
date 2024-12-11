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

    // // Kiểm tra nếu quyền bị từ chối
    // if (statuses.values.any((status) => status.isDenied)) {
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: const Text("Quyền bị từ chối"),
    //       content: const Text(
    //           "Ứng dụng cần quyền camera và microphone để hoạt động."),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: const Text("Đồng ý"),
    //         ),
    //       ],
    //     ),
    //   );
    // }
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
            // TextField(
            //   controller: ipcUuidController,
            //   decoration: const InputDecoration(labelText: "IPC UUID"),
            // ),
            // TextField(
            //   controller: usernameController,
            //   decoration: const InputDecoration(labelText: "Username"),
            // ),
            // TextField(
            //   controller: passwordController,
            //   decoration: const InputDecoration(labelText: "Password"),
            //   obscureText: true,
            // ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // if (!webrtcService.isConnected) {
                //  await requestPermissions(); // Đảm bảo quyền trước khi kết nối
                webrtcService.connect(
                  ipcUuid: "662e3a00-6b61-11ef-8b20-d73bd8821410",
                  username: "demo2@epcb.vn",
                  password: "demo2@123",
                );
                // } else {
                //   webrtcService.disconnect();
                // }
              },
              child: Text(webrtcService.isConnected ? "Stop" : "Connect"),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: webrtcService.isConnected
                    ? RTCVideoView(
                        webrtcService.remoteRenderer,
                      )
                    : const Center(
                        child: Text(
                          "No Connection",
                          style: TextStyle(color: Colors.white),
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
