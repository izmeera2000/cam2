import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  bool isRecording = false;
  late final AudioRecorder _audioRecorder;
  String? _audioPath;
  String? _speakerIP;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();
    super.initState();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
      growable: false,
    ).join();
  }

  Future<void> _startRecording() async {
    try {
      String filePath = await getApplicationDocumentsDirectory()
          .then((value) => '${value.path}/${_generateRandomId()}.wav');

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
        ),
        path: filePath,
      );

      setState(() {
        isRecording = true;
        _audioPath = filePath;
      });

      debugPrint('Recording started, saving to: $filePath');
    } catch (e) {
      debugPrint('Error while starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stop();

      setState(() {
        isRecording = false;
        _audioPath = path;
      });

      debugPrint('Recording stopped, file saved at: $path');

      if (path != null) {
        await _sendAudioToServer(path);
      }
    } catch (e) {
      debugPrint('Error while stopping recording: $e');
    }
  }

  Future<void> _sendAudioToServer(String filePath) async {
    try {
      debugPrint("Preparing to send audio to server...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      _speakerIP = prefs.getString('speaker_ip');

      if (_speakerIP == null || _speakerIP!.isEmpty) {
        debugPrint("Speaker IP is not set in SharedPreferences.");
        return;
      }

      final _serverUrl = 'http://$_speakerIP/audio';
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      debugPrint("Sending audio to server...");
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      debugPrint("Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("Audio sent successfully");
      } else {
        debugPrint("Failed to send audio: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error while sending audio to server: $e");
    }
  }

  void _record() async {
    if (!isRecording) {
      final status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        await _startRecording();
      } else if (status == PermissionStatus.permanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Microphone access is required. Please enable it in the app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else {
        debugPrint('Microphone permission denied.');
      }
    } else {
      await _stopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isRecording
                ? const Icon(Icons.mic, size: 100, color: Colors.red)
                : const Icon(Icons.mic_off, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _record,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            if (_audioPath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recording saved at:\n$_audioPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
