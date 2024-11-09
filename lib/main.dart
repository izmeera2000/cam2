import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32-CAM Video Stream',
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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize WebView for both iOS and Android
    InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  void _startStreaming() {
    final ip = _ipController.text;
    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid IP address';
      });
      return;
    }

    final url = 'http://$ip:81/stream';  // Construct the video stream URL

    // Use WebUri instead of Uri for compatibility with flutter_inappwebview
    WebUri webUri = WebUri(url);

    // Load the URL using InAppWebViewController
    _webViewController.loadUrl(urlRequest: URLRequest(url: webUri));
    setState(() {
      _errorMessage = ''; // Clear any previous error message
    });
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
                labelText: 'Enter ESP32 IP Address',
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
                initialUrlRequest: URLRequest(url: WebUri('about:blank')),  // Start with a blank page
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
          ],
        ),
      ),
    );
  }
}
