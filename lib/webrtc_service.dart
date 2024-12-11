import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WebRTCService extends ChangeNotifier {
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool isConnected = false;

  final String endpointBase = "https://demo.espitek.com";
  final String endpointRPC = "/api/rpc/twoway";
  final String endpointLogin = "/api/auth/login";

  String? jwtToken;
  String clientId = _generateRandomId(10);

  WebRTCService() {
    remoteRenderer.initialize();
  }

  static String _generateRandomId(int length) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return List.generate(length, (index) {
      final randomIndex = random.nextInt(characters.length);
      return characters[randomIndex];
    }).join();
  }

  Future<void> connect({
    required String ipcUuid,
    required String username,
    required String password,
  }) async {
    try {
      jwtToken = await AuthService.login(
        endpointLogin: endpointBase + endpointLogin,
        username: username,
        password: password,
      );

      final offer = await _sendRPC(
        method: "WEBRTC_REQUEST",
        uuid: ipcUuid,
        params: {"ClientId": clientId, "type": "request"},
      );
      print("clientid: $clientId");
      print("offer: $offer");
      print(jwtToken);
      await _handleOffer(ipcUuid, offer);
      isConnected = true;
      notifyListeners();
    } catch (error) {
      print("Connection error: $error");
      disconnect();
    }
  }

  Future<void> disconnect() async {
    isConnected = false;
    _peerConnection?.close();
    _peerConnection = null;
    remoteRenderer.srcObject = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _sendRPC({
    required String method,
    required String uuid,
    required Map<String, dynamic> params,
  }) async {
    try {
      final url = "$endpointBase$endpointRPC/$uuid";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({
          "method": method,
          "params": params,
          "persistent": false,
          "timeout": 10000,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: ${response.body}");
      } else {
        throw Exception("Failed to send RPC: ${response.body}");
      }
    } catch (error) {
      print("Failed to send RPC: $error");
      throw Exception("Failed to send RPC: $error");
    }
  }

  Future<void> _handleOffer(String uuid, Map<String, dynamic> offer) async {
    _peerConnection = await _createPeerConnection();
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(
      offer['sdp'],
      offer['type'],
    ));

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    print("answer: ${answer.toMap()}");
    await _sendRPC(
      method: "WEBRTC_ANSWER",
      uuid: uuid,
      params: {
        "ClientId": clientId,
        "type": answer.type,
        "sdp": answer.sdp,
      },
    );
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:demo.espitek.com:3478'},
        {
          'urls': 'turn:demo.espitek.com:3478',
          'username': 'demo2@epcb.vn',
          'credential': 'demo2@123'
        },
      ],
    };
    final pc = await createPeerConnection(config);

    print("pc: $pc");
    pc.onTrack = (RTCTrackEvent event) {
      remoteRenderer.srcObject = event.streams.first;
    };

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      print("ICE Candidate: ${candidate.toMap()}");
    };

    return pc;
  }
}
