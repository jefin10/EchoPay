import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:highlight_text/highlight_text.dart';
import '../services/intent_service.dart';

void main() {
  runApp(const VoiceToTextApp());
}

class VoiceToTextApp extends StatelessWidget {
  const VoiceToTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Voice Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'send': HighlightedWord(
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'balance': HighlightedWord(
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'payment': HighlightedWord(
      textStyle: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    ),
    'request': HighlightedWord(
      textStyle: const TextStyle(
        color: Colors.purple,
        fontWeight: FontWeight.bold,
      ),
    ),
  };
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isProcessing = false;
  bool _serverConnected = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  
  // Intent prediction results
  String? _predictedIntent;
  double? _intentConfidence;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkServerConnection();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _checkServerConnection() async {
    final isConnected = await IntentService.checkServerHealth();
    setState(() {
      _serverConnected = isConnected;
    });
  }

  void _startListening() async {
    await _speech.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
      _errorMessage = null;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) async {
    setState(() {
      _text = result.recognizedWords;
      _confidence = result.confidence;
    });

    // Predict intent when speech is complete
    if (result.finalResult && _text.isNotEmpty && _serverConnected) {
      await _predictIntent(_text);
    }
  }

  Future<void> _predictIntent(String text) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await IntentService.predictIntent(text);
      
      if (result != null && result['status'] == 'success') {
        setState(() {
          _predictedIntent = result['predicted_intent'];
          _intentConfidence = result['confidence'];
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to predict intent';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _clearText() {
    setState(() {
      _text = 'Press the button and start speaking';
      _predictedIntent = null;
      _intentConfidence = null;
      _errorMessage = null;
    });
  }

  Color _getIntentColor(String? intent) {
    switch (intent?.toLowerCase()) {
      case 'send_money':
        return Colors.green;
      case 'check_balance':
        return Colors.blue;
      case 'request_money':
        return Colors.purple;
      case 'payment_history':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatIntent(String? intent) {
    if (intent == null) return '';
    if (intent == "transfer_money") return "Payment Successful";
    if (intent == "check_balance") return "Your Balance is 1000";
    if (intent == "request_money") return "The amount has been requested";
    return intent.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('UPI Voice Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _serverConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _serverConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkServerConnection,
            tooltip: _serverConnected ? 'Server Connected' : 'Server Disconnected',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.blue,
        child: FloatingActionButton(
          onPressed: _speechEnabled
              ? (_isListening ? _stopListening : _startListening)
              : null,
          backgroundColor: _isListening ? Colors.red : Colors.blue,
          child: Icon(_isListening ? Icons.mic_off : Icons.mic),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Server status indicator
              if (!_serverConnected)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Server not connected. Intent prediction unavailable.',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Speech confidence
              if (_speechEnabled && _confidence != 1.0)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Speech Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Speech text display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: GestureDetector(
                  onTap: _clearText,
                  child: Column(
                    children: [
                      if (_text == 'Press the button and start speaking')
                        Text(
                          _text,
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        TextHighlight(
                          text: _text,
                          words: _highlights,
                          textStyle: const TextStyle(
                            fontSize: 24.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Intent prediction results
              if (_isProcessing)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Processing Please wait...'),
                      ],
                    ),
                  ),
                )
              else if (_predictedIntent != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: _getIntentColor(_predictedIntent),
                            ),
                            const SizedBox(width: 8),
                            // const Text(
                            //   'Detected Intent:',
                            //   style: TextStyle(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getIntentColor(_predictedIntent).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getIntentColor(_predictedIntent),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _formatIntent(_predictedIntent),
                            style: TextStyle(
                              color: _getIntentColor(_predictedIntent),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_intentConfidence != null)
                          Row(
                            children: [
                              const Icon(Icons.analytics, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Confidence: ${(_intentConfidence! * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
