import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sidebar.dart'; // Import Sidebar

class ChatPage extends StatefulWidget {
  final String token;
  final List<Map<String, dynamic>>? initialChatMessages;

  const ChatPage({Key? key, required this.token, this.initialChatMessages}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isTyping = false;
  late AnimationController _dotsController;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize chat history with passed data if available
    if (widget.initialChatMessages != null) {
      _chatMessages = widget.initialChatMessages!;
    }

    // Initialize animation for typing dots
    _dotsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _dotsAnimation = IntTween(begin: 1, end: 3).animate(_dotsController);
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  // Send query to the model and get the response
  Future<void> _queryModel(String query) async {
    final url = Uri.parse('http://127.0.0.1:8000/chatbot');
    try {
      setState(() {
        _chatMessages.add({'user_message': query, 'bot_response': ''});
        _isTyping = true; // Show typing indicator
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query, 'token': widget.token}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _chatMessages.last['bot_response'] = responseData['response'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get a response from the chatbot')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        _isTyping = false; // Hide typing indicator
      });
    }
  }

  // Build a styled chat bubble
  Widget _buildChatBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: isUser ? Radius.circular(10) : Radius.zero,
            bottomRight: isUser ? Radius.zero : Radius.circular(10),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Build a typing indicator as a message bubble
  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.only(
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
        title: Text('Sentiva'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the sidebar
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length + (_isTyping ? 1 : 0), // Add 1 for typing bubble
              itemBuilder: (context, index) {
                if (_isTyping && index == _chatMessages.length) {
                  return _buildTypingBubble(); // Show typing bubble
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
                      labelText: 'Ask me something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final query = _queryController.text.trim();
                    if (query.isNotEmpty) {
                      _queryModel(query);
                      _queryController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Sidebar(token: widget.token), // Attach Sidebar as a Drawer
    );
  }
}
