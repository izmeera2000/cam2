import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32-CAM Stream with Audio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Video-related variables
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  TextEditingController _ipController = TextEditingController();
  bool _isStreaming = false;

  // Audio-related variables (flutter_sound)
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _ipController.dispose();
    super.dispose();
  }

  // Initialize video player with the ESP32-CAM IP stream
  Future<void> _initializeVideo(String ipAddress) async {
    String videoUrl = 'http://$ipAddress:81/stream';
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: true,
    );

    setState(() {
      _isStreaming = true;
    });
  }

  // Initialize audio (flutter_sound)
  Future<void> _initializeAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  // Start recording audio
  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _audioFilePath = '${directory.path}/audio.aac';
      if (await Vibration.hasVibrator() == true) {
    Vibration.vibrate(duration: 100); // Vibrate for 100ms
  }
    await _recorder!.startRecorder(toFile: _audioFilePath);
  }

  // Stop recording audio
  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    _playRecording();  // Automatically play the recording after stopping
  }

  // Play the recorded audio
  Future<void> _playRecording() async {
    if (_audioFilePath != null) {
      await _player!.startPlayer(fromURI: _audioFilePath);
    }
  }

  // Handle button press: start recording
  void _onRecordButtonPressed() {
    _startRecording();
  }

  // Handle button release: stop recording
  void _onRecordButtonReleased() {
    _stopRecording();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32-CAM Stream with Audio'),
      ),
      body: Column(
        children: [
          // IP Address Input Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ipController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter ESP32-CAM IP Address',
                hintText: 'e.g. 192.168.1.100',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              String ipAddress = _ipController.text.trim();
              if (ipAddress.isNotEmpty) {
                _initializeVideo(ipAddress);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid IP address')),
                );
              }
            },
            child: Text("Start Stream"),
          ),
          _isStreaming && _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? Expanded(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                )
              : Center(
                  child: Text('Enter IP and Start the Stream'),
                ),
          SizedBox(height: 10),
          // Audio Control Section: Single Press-Hold Button
          Text(
            "Hold to Talk",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onLongPress: _onRecordButtonPressed,
            onLongPressUp: _onRecordButtonReleased,
            child: Container(
              margin: EdgeInsets.all(20),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "Hold",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
