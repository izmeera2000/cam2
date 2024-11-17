import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

class SpeakerPage extends StatefulWidget {
  @override
  _SpeakerPageState createState() => _SpeakerPageState();
}

class _SpeakerPageState extends State<SpeakerPage> {
  bool isScanning = false;
  List<Map<String, dynamic>> devices = [];
  String? selectedIp;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedIp = prefs.getString('speaker_ip');
    });
  }

  Future<void> _saveIp(String ip, int port) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('speaker_ip', '$ip:$port');
  }

  Future<void> scanNetwork() async {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();
    final subnet = wifiIP?.substring(0, wifiIP.lastIndexOf('.'));

    if (subnet == null) {
      setState(() {
        isScanning = false;
      });
      return;
    }

    final ports = [80, 81, 82, 83, 3000];
    final timeout = Duration(milliseconds: 50);

    for (var i = 1; i < 255; i++) {
      final host = '$subnet.$i';
      for (var port in ports) {
        try {
          final socket = await Socket.connect(host, port, timeout: timeout);
          socket.destroy();
          setState(() {
            devices.add({'ip': host, 'port': port});
          });
        } catch (_) {}
      }
    }

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speaker  Details'),
      ),
      body: Column(
        children: [
          if (selectedIp != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Selected IP: $selectedIp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton(
            onPressed: isScanning ? null : scanNetwork,
            child: Text(isScanning ? 'Scanning...' : 'Scan Network'),
          ),
          if (isScanning)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text('IP: ${device['ip']}'),
                  subtitle: Text('Port: ${device['port']}'),
                  onTap: () {
                    final ipPort = '${device['ip']}:${device['port']}';
                    _saveIp(device['ip'], device['port']);
                    Navigator.pop(context, ipPort);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
