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
  
  // Voice assistant results
  String? _predictedIntent;
  double? _intentConfidence;
  String? _errorMessage;
  String? _assistantResponse;
  Map<String, dynamic>? _entities;

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

    // Process voice command when speech is complete using enhanced voice assistant
    if (result.finalResult && _text.isNotEmpty && _serverConnected) {
      await _processEnhancedVoiceCommand(_text);
    }
  }

  Future<void> _processEnhancedVoiceCommand(String text) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _assistantResponse = null;
      _entities = null;
    });

    try {
      // Use the enhanced voice command processing
      final result = await IntentService.processVoiceCommand(text);
      
      if (result != null && result['status'] == 'success') {
        setState(() {
          _predictedIntent = result['predicted_intent'];
          _intentConfidence = result['confidence'];
          _assistantResponse = result['assistant_message'];
          _entities = result['entities'];
          _isProcessing = false;
        });
        
        // Show success snackbar for successful operations
        if (result['action'] != 'general_conversation') {
          _showSnackBar(_assistantResponse ?? 'Operation completed successfully!', Colors.green);
        }
        
      } else {
        setState(() {
          _errorMessage = result?['error'] ?? 'Failed to process command';
          _assistantResponse = result?['assistant_message'] ?? 'Sorry, I could not process your request.';
          _isProcessing = false;
        });
        
        // Show error snackbar
        _showSnackBar(_errorMessage ?? 'Processing failed', Colors.red);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _assistantResponse = 'Sorry, I encountered an error processing your request.';
        _isProcessing = false;
      });
      
      // Show error snackbar
      _showSnackBar('Connection error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearText() {
    setState(() {
      _text = 'Press the button and start speaking';
      _predictedIntent = null;
      _intentConfidence = null;
      _errorMessage = null;
      _assistantResponse = null;
      _entities = null;
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
    
    switch (intent.toLowerCase()) {
      case 'transfer_money':
        return 'Money Transfer';
      case 'check_balance':
        return 'Balance Check';
      case 'request_money':
        return 'Money Request';
      default:
        return intent.replaceAll('_', ' ').toUpperCase();
    }
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

              // Enhanced voice assistant results
              if (_isProcessing)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        const Text('Processing your request...'),
                        const Spacer(),
                        Icon(Icons.mic, color: Colors.blue[600]),
                      ],
                    ),
                  ),
                )
              else if (_assistantResponse != null)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assistant response header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.assistant,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Voice Assistant',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            if (_predictedIntent != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getIntentColor(_predictedIntent).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getIntentColor(_predictedIntent),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatIntent(_predictedIntent),
                                  style: TextStyle(
                                    color: _getIntentColor(_predictedIntent),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Main assistant response
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[25]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            _assistantResponse!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        
                        // Show entities if available
                        if (_entities != null && _entities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, 
                                         size: 16, 
                                         color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Extracted Information:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _entities!.entries.map((entry) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        '${entry.key}: ${entry.value}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Show confidence if available
                        if (_intentConfidence != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.analytics, 
                                   size: 16, 
                                   color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'Confidence: ${(_intentConfidence! * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 60,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.grey[300],
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _intentConfidence,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: _intentConfidence! > 0.7 
                                          ? Colors.green 
                                          : _intentConfidence! > 0.5 
                                              ? Colors.orange 
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
