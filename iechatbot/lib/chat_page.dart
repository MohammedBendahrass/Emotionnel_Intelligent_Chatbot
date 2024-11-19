import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sidebar.dart';
import 'screens/login_page.dart';

class ChatPage extends StatefulWidget {
  final String token;
  final String sessionId;
  final List<Map<String, dynamic>>? initialChatMessages;

  const ChatPage({
    Key? key,
    required this.token,
    required this.sessionId,
    this.initialChatMessages,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isTyping = false;
  late AnimationController _dotsController;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize chat messages with proper mapping
    if (widget.initialChatMessages != null && widget.initialChatMessages!.isNotEmpty) {
      _chatMessages = widget.initialChatMessages!
          .map((message) => {
        'user_message': message['query'], // Ensure no extra encoding here
        'bot_response': message['response'],
      })
          .toList();
    }

    debugPrint("Loaded Session Messages: $_chatMessages");

    // Initialize animation for typing dots
    _dotsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _dotsAnimation = IntTween(begin: 1, end: 3).animate(_dotsController);

    // Scroll to bottom after messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Logout function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  // Query the model and handle the response
  Future<void> _queryModel(String query) async {
    final url = Uri.parse('http://127.0.0.1:8000/chatbot');
    try {
      setState(() {
        _chatMessages.add({'user_message': query, 'bot_response': ''});
        _isTyping = true;
      });

      _scrollToBottom();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'token': widget.token,
          'session_id': widget.sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _chatMessages.last['bot_response'] = responseData['response'] ?? 'No response';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get a response from the chatbot.')),
        );
      }
    } catch (error) {
      debugPrint('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to send message. Please try again.')),
      );
    } finally {
      setState(() {
        _isTyping = false;
      });

      _scrollToBottom();
    }
  }

  // Scroll to the bottom of the list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Build a styled chat bubble
  Widget _buildChatBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isUser ? const Radius.circular(10) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(10),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Build a typing indicator as a message bubble
  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: AnimatedBuilder(
          animation: _dotsAnimation,
          builder: (context, child) {
            String dots = '.' * _dotsAnimation.value;
            return Text(
              "Typing$dots",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentiva'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Sidebar(token: widget.token),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/chat_background.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Chat content
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _chatMessages.length) {
                      return _buildTypingBubble();
                    }
                    final chat = _chatMessages[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (chat['user_message'] != null)
                          _buildChatBubble(chat['user_message']!, true),
                        if (chat['bot_response'] != null && chat['bot_response']!.isNotEmpty)
                          _buildChatBubble(chat['bot_response']!, false),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8), // Semi-transparent white background
                          labelText: 'Ask me something...',
                          labelStyle: const TextStyle(color: Colors.black), // Text color for label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                          ),
                        ),
                        style: const TextStyle(color: Colors.black), // Input text color
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.blueAccent, // Match the color to the theme
                      onPressed: () {
                        final query = _queryController.text.trim();
                        if (query.isNotEmpty) {
                          _queryModel(query);
                          _queryController.clear();
                        }
                      },
                      tooltip: 'Send message',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
