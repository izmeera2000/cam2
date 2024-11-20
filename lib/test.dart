import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:shared_preferences/shared_preferences.dart';

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _filePath;
  String? _speakerIP;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  // Initialize the recorder
  Future<void> _initializeRecorder() async {
    try {
      await _audioRecorder?.openRecorder();
    } catch (e) {
      print("Error opening audio recorder: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _audioRecorder?.closeRecorder();
  }

  // Get file path for saving the audio file
  Future<String> _getFilePath() async {
    final directory =
        await getApplicationDocumentsDirectory(); // Get the document directory
    String path =
        '${directory.path}/audio_recording.wav'; // Path for the audio file

    // Ensure the directory exists before saving the file
    final directoryExists = await Directory(directory.path).exists();
    if (!directoryExists) {
      await Directory(directory.path)
          .create(recursive: true); // Create directory if not exists
    }

    return path;
  }

  // Start recording
  Future<void> _startRecording() async {
    if (_audioRecorder != null && !_isRecording) {
      try {
        // Get the file path dynamically before starting the recording
        _filePath = await _getFilePath();
        print('Recording to file: $_filePath'); // Debugging output
        await _audioRecorder?.startRecorder(
            toFile: _filePath); // Start recording to the path
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print("Error starting recorder: $e");
      }
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    if (_audioRecorder != null && _isRecording) {
      try {
        // Ensure the file path is correctly set before stopping the recorder
        if (_filePath == null) {
          _filePath = await _getFilePath();
        }

        print('Stopping recording. File path: $_filePath'); // Debugging output

        // Stop the recorder and retrieve the path
        await _audioRecorder
            ?.stopRecorder(); // Stop recording without waiting for the path

        // Manually set the file path after stopping
        String? path = _filePath;
        print('Recording stopped. Path: $path'); // Check the manually set path

        setState(() {
          _isRecording = false;
        });

        if (path != null && path.isNotEmpty) {
          print("File path is not empty, calling sendAudioToServer");
          await _sendAudioToServer(path); // Send the audio to the server
        } else {
          print("Path is empty, skipping sendAudioToServer");
        }
      } catch (e) {
        print("Error stopping recorder: $e");
      }
    }
  }

  // Send audio file to the server
  Future<void> _sendAudioToServer(String filePath) async {
    print("Preparing to send audio to server..."); // Debugging output

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
       _speakerIP = prefs.getString('speaker_ip');
    });
    final _serverUrl = 'http://$_speakerIP/audio';
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();

    print("Sending audio to server..."); // Debugging output
    final response = await http.post(
      Uri.parse(_serverUrl!),
      headers: {
        'Content-Type': 'application/octet-stream',
      },
      body: fileBytes,
    );

    print("Response status: ${response.statusCode}"); // Debugging output
    if (response.statusCode == 200) {
      print("Audio sent successfully");
    } else {
      print("Failed to send audio: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Audio Recording')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
