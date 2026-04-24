import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiAssistanceScreen extends StatefulWidget {
  const AiAssistanceScreen({super.key});

  @override
  State<AiAssistanceScreen> createState() => _AiAssistanceScreenState();
}

class _AiAssistanceScreenState extends State<AiAssistanceScreen>
    with SingleTickerProviderStateMixin {
  // ==================== GOOGLE GEMINI AI CONFIG ====================
  // API Key updated March 2026 — project: Gemini ProjectNew Rakshak AI (gen-lang-client-0775975953)
  // Model: gemini-flash-latest (verified working with text + vision/image analysis)
  // If you hit quota again, go to https://aistudio.google.com/apikey and create a new project + key.
  static const String _geminiApiKey = 'AIzaSyCK7PsfrJCbKK_CgGZJPQSiG_1LGgzoJGo';
  static const String _geminiModel = 'gemini-flash-latest';
  static String get _geminiApiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey';

  static const String _systemPrompt = '''
You are Rakshak AI — the intelligent safety assistant of the Suraksha Kavach emergency response system.

Your role:
- Provide instant, accurate guidance on fire safety, gas leak emergencies, evacuation protocols, and first aid.
- Analyze uploaded images of affected areas and assess damage/risk.
- Recommend safety measures, evacuation routes, and emergency contacts.
- Speak with authority and urgency during active emergencies.
- Be concise but thorough. Lives depend on your accuracy.

You are NOT a general-purpose chatbot. Stay focused on safety, emergency response, and hazard management.
Always respond in a structured, clear format. Use bullet points for action items.
If you detect a life-threatening situation, always start with the most critical action first.
Always include relevant Indian emergency numbers: Fire: 101, Ambulance: 102/108, Police: 100, Disaster: 112.
''';

  // ==================== STATE ====================
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  File? _selectedImage;
  late AnimationController _typingController;

  final List<String> _suggestions = [
    "🔥 Fire Safety Tips",
    "🩹 First Aid Guide",
    "📞 Emergency Contacts",
    "🚪 Evacuation Plan",
    "⛽ Gas Leak Protocol",
  ];

  @override
  void initState() {
    super.initState();
    
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Initial greeting
    _messages.add(ChatMessage(
      text: "I am **Rakshak AI** — your emergency safety assistant.\n\n"
          "I can help you with:\n"
          "• 🔥 Fire safety protocols\n"
          "• ⛽ Gas leak emergency response\n"
          "• 🩹 First aid guidance\n"
          "• 🚪 Evacuation procedures\n\n"
          "Upload a photo of the affected area.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _typingController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== GOOGLE GEMINI API ====================
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // Add user message
    setState(() {
      _loading = true;
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        imageFile: _selectedImage,
      ));
    });

    _textController.clear();
    _scrollToBottom();

    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // Build Gemini conversation history
      final List<Map<String, dynamic>> contents = [];

      // Add last 10 messages for context (skip the initial greeting)
      final historyStart = _messages.length > 1 ? 1 : 0;
      final historyMessages = _messages.length > 11
          ? _messages.sublist(_messages.length - 10)
          : _messages.sublist(historyStart);

      for (final msg in historyMessages) {
        final role = msg.isUser ? 'user' : 'model';

        if (msg.isUser && msg.imageFile != null && msg == _messages.last) {
          // Current message with image — send as multimodal
          final List<Map<String, dynamic>> parts = [];
          parts.add({
            "inline_data": {
              "mime_type": "image/jpeg",
              "data": base64Image,
            }
          });
          parts.add({
            "text": text.isEmpty
                ? "Analyze this image for safety risks and damage assessment. Guide me on how to evacuate."
                : text,
          });
          contents.add({"role": role, "parts": parts});
        } else if (msg.text.isNotEmpty) {
          contents.add({
            "role": role,
            "parts": [{"text": msg.text}],
          });
        }
      }

      // Build Gemini request body
      final requestBody = {
        "system_instruction": {
          "parts": [{"text": _systemPrompt}]
        },
        "contents": contents,
        "generationConfig": {
          "temperature": 0.5,
          "maxOutputTokens": 2048,
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"},
        ],
      };

      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          final aiText = parts?.map((p) => p['text'] ?? '').join('') ?? 
              'No response generated.';

          setState(() {
            _messages.add(ChatMessage(
              text: aiText,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        } else {
          final feedback = data['promptFeedback'];
          final blockReason = feedback?['blockReason'] ?? 'Unknown';
          setState(() {
            _messages.add(ChatMessage(
              text: "⚠️ **Response Blocked**: The query was filtered (Reason: $blockReason).\n\nPlease rephrase your question.",
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        }
      } else if (response.statusCode == 429) {
          setState(() {
            _messages.add(ChatMessage(
              text: "⚠️ **Rate Limit Exceeded (429)**: Your Gemini API Key has exhausted its quota.\n\nGo to **aistudio.google.com/apikey** to generate a fresh, free API key and replace it in the code.",
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
      } else {
        String errorMsg;
        try {
          final errorBody = jsonDecode(response.body);
          errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
        } catch (_) {
          errorMsg = response.body;
        }
        setState(() {
          _messages.add(ChatMessage(
            text: "⚠️ **API Error (${response.statusCode})**: $errorMsg\n\nPlease try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } on TimeoutException {
      setState(() {
        _messages.add(ChatMessage(
          text: "⚠️ **Timeout**: The server took too long to respond.\n\nPlease check your internet connection and try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } on SocketException catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "⚠️ **Network Error**: No internet connection.\n\nDetails: ${e.message}",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } on HttpException catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "⚠️ **HTTP Error**: ${e.message}\n\nPlease try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "⚠️ **Connection Error**: Unable to reach Rakshak AI servers.\n\nError: ${e.runtimeType}",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _loading = false;
        _selectedImage = null;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Copied to clipboard"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _loading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Image preview
          if (_selectedImage != null) _buildImagePreview(),

          // Suggestion chips
          if (!_loading && _messages.length <= 2) _buildSuggestionChips(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF003366),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Color(0xFFFF9933), size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Rakshak AI",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text("Powered Shuraksha Kavach",
                  style: TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () {
            setState(() {
              _messages.removeRange(1, _messages.length);
            });
          },
          tooltip: "Clear Chat",
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final offset = (_typingController.value * 3 - i).clamp(0.0, 1.0);
                  final bounce = (offset < 0.5)
                      ? offset * 2
                      : 2 - offset * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Transform.translate(
                      offset: Offset(0, -4 * bounce),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366)
                              .withValues(alpha: 0.3 + bounce * 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF004C99)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.shield_rounded,
          color: Color(0xFFFF9933), size: 16),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr =
        "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAiAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress:
                  !isUser ? () => _copyToClipboard(message.text) : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF003366) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(message.imageFile!,
                              height: 200, fit: BoxFit.cover),
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      isUser
                          ? Text(
                              message.text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14, height: 1.4),
                            )
                          : MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(0xFF212121)),
                                strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003366)),
                                listBullet: const TextStyle(
                                    color: Color(0xFFFF9933)),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.shade100,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white54
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyToClipboard(message.text),
                            child: Icon(Icons.copy_rounded,
                                size: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF9933),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedImage!, height: 60, width: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          const Text("Image attached",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          return ActionChip(
            label: Text(_suggestions[index],
                style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.white,
            side: BorderSide(color: const Color(0xFF003366).withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              // Remove emoji prefix for actual query
              _textController.text =
                  _suggestions[index].replaceAll(RegExp(r'^[^\w]+'), '').trim();
              _sendMessage();
            },
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Image picker buttons
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF003366), size: 20),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF003366), size: 20),
                    onPressed: () => _pickImage(ImageSource.camera),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Ask Rakshak AI...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF004C99)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003366).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: _sendMessage,
                constraints:
                    const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DATA MODEL ====================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? imageFile;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageFile,
  });
}
