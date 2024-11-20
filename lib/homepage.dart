import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InAppWebViewController _webViewController;
  late AudioPlayer _audioPlayer;
  String _errorMessage = '';
  String? _streamIp;
  String? _micIp;
  bool _isPlaying = false;
  bool _isPlayingcam = false;

  bool isRecording = false;
  late final AudioRecorder _audioRecorder;
  String? _audioPath;
  String? _speakerIP;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioRecorder = AudioRecorder();

    // Listen to the player's state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false; // Reset playing state when audio completes
        });
      } else {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    // Load IP addresses from SharedPreferences
    _loadIpAddresses();
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

      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != null && hasVibrator) {
        Vibration.vibrate(duration: 100);
      }

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

  // Function to load IP addresses from SharedPreferences
  Future<void> _loadIpAddresses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _streamIp = prefs.getString('camera_ip');
      _micIp = prefs.getString('microphone_ip');
    });
  }

  void _startStreaming() {
    if (_streamIp == null || _streamIp!.isEmpty) {
      setState(() {
        _errorMessage = 'No camera IP found. Please configure the IP.';
      });
      return;
    }
    _isPlayingcam = false;

    final url = 'http://$_streamIp/stream'; // Construct the video stream URL
    WebUri webUri = WebUri(url);

    _webViewController.loadUrl(urlRequest: URLRequest(url: webUri));
    setState(() {
      _errorMessage = ''; // Clear any previous error message
    });
  }

  void _stopStreaming() {
    setState(() {
      _isPlayingcam = false;
    });

    // Clear the current stream and load a blank page
    _webViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri('about:blank')));
  }

  Future<void> _playAudio() async {
    try {
      if (_micIp == null || _micIp!.isEmpty) {
        setState(() {
          _errorMessage = 'No mic IP found. Please configure the IP.';
        });
        return;
      }
      final url2 = 'http://$_micIp/audio'; // Construct the audio stream URL

      await _audioPlayer.setUrl(url2);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio: $e")),
      );
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print("Error stopping audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error stopping audio: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32-CAM Video Stream'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                    url: WebUri('about:blank')), // Start with a blank page
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadError: (controller, url, code, message) {
                  setState(() {
                    _errorMessage = 'Error loading stream: $message';
                  });
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  setState(() {
                    _errorMessage = 'HTTP Error: $statusCode - $description';
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_isPlayingcam) {
                        _startStreaming();
                      } else {
                        _stopStreaming();
                      }
                    },
                    child:
                        Icon(_isPlaying ? Icons.videocam_off : Icons.videocam),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_isPlaying) {
                        _stopAudio();
                      } else {
                        _playAudio();
                      }
                    },
                    child:
                        Icon(_isPlaying ? Icons.volume_mute : Icons.volume_up),
                  ),
                  GestureDetector(
                    onLongPress: _record,
                    onLongPressEnd: (LongPressEndDetails details) async {
                      await _stopRecording();
                    },
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Icon(isRecording ? Icons.mic_off : Icons.mic),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
