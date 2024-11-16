import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorbell ESP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VideoStreamScreen(),
    );
  }
}

class VideoStreamScreen extends StatefulWidget {
  @override
  _VideoStreamScreenState createState() => _VideoStreamScreenState();
}

class _VideoStreamScreenState extends State<VideoStreamScreen> {
  late InAppWebViewController _webViewController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _ipController2 = TextEditingController();
  String _errorMessage = '';
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    // Listen to the player's state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      // Check if the audio has completed
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false; // Set to false when audio completes
        });
      } else {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });
  }

  void _startStreaming() {
    final ip = _ipController.text;
    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid IP address';
      });
      return;
    }

    final url = 'http://$ip:81/stream'; // Construct the video stream URL

    // Use WebUri instead of Uri for compatibility with flutter_inappwebview
    WebUri webUri = WebUri(url);

    // Load the URL using InAppWebViewController
    _webViewController.loadUrl(urlRequest: URLRequest(url: webUri));
    setState(() {
      _errorMessage = ''; // Clear any previous error message
    });
  }

  Future<void> _playAudio() async {
    try {
      final ip2 = _ipController2.text;
      if (ip2.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a valid IP address';
        });
        return;
      }
      final url2 = 'http://$ip2:82/audio'; // Construct the video stream URL

      // const streamUrl = 'http://192.168.0.101:3000/audio'; // Update this URL
      await _audioPlayer.setUrl(url2);
      await _audioPlayer.play(); // This triggers the `playerStateStream`
    } catch (e) {
      print("Error playing audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio: $e")),
      );
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop(); // This triggers the `playerStateStream`
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
            // TextField to enter IP address
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Camera IP',
                border: OutlineInputBorder(),
              ),
              
            ),TextField(
              controller: _ipController2,
              decoration: InputDecoration(
                labelText: 'Mic IP',
                border: OutlineInputBorder(),
              ),
              
            ),
            SizedBox(height: 10),
            // Button to start the stream
            ElevatedButton(
              onPressed: _startStreaming,
              child: Text('Start Stream'),
            ),
            SizedBox(height: 20),
            // Error message display
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            // WebView to show the video stream
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
                onLoadStop: (controller, url) {
                  // Optionally handle any post-load logic here
                },
              ),
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
    );
  }
}
