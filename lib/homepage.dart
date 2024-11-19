import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

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

    final url = 'http://$_streamIp/stream'; // Construct the video stream URL
    WebUri webUri = WebUri(url);

    _webViewController.loadUrl(urlRequest: URLRequest(url: webUri));
    setState(() {
      _errorMessage = ''; // Clear any previous error message
    });
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
                    onPressed: _startStreaming,
                    child: Text('Start Stream'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_isPlaying) {
                        _stopAudio();
                      } else {
                        _playAudio();
                      }
                    },
                    child: Text(_isPlaying ? 'Stop Audio' : 'Play Audio'),
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
