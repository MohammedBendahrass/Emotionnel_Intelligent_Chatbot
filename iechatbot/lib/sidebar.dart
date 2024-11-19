import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_page.dart';

class Sidebar extends StatefulWidget {
  final String token;

  const Sidebar({Key? key, required this.token}) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  // Fetch chat history from the backend
  Future<void> _fetchChatHistory() async {
    final url = Uri.parse('http://127.0.0.1:8000/history');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _chatHistory = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch session messages for a specific session
  Future<List<Map<String, dynamic>>> _fetchSessionMessages(String sessionId) async {
    final url = Uri.parse('http://127.0.0.1:8000/session/$sessionId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); // Decode properly
        final messages = List<Map<String, dynamic>>.from(data['messages']);
        return messages;
      } else {
        debugPrint('Failed to load session messages for $sessionId: ${response.body}');
        throw Exception('Failed to load session messages');
      }
    } catch (e) {
      debugPrint('Error fetching session messages: $e');
      return [];
    }
  }

  // Create a new session and navigate to a new ChatPage
  Future<void> _startNewConversation() async {
    final url = Uri.parse('http://127.0.0.1:8000/start_new_session');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': widget.token}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newSessionId = responseData['session_id'];

        // Navigate to a new ChatPage with the new session
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              token: widget.token,
              sessionId: newSessionId,
              initialChatMessages: [], // New conversation starts empty
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start a new conversation.')),
        );
      }
    } catch (e) {
      debugPrint('Error starting new session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to start a new conversation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Chat History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final session = _chatHistory[index];
                final sessionId = session['session_id'];
                final firstMessage = session['messages'].isNotEmpty
                    ? session['messages'][0]['query']
                    : 'No messages';

                return ListTile(
                  title: Text('Session $sessionId'),
                  subtitle: Text(firstMessage),
                  onTap: () async {
                    final messages = await _fetchSessionMessages(sessionId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          token: widget.token,
                          sessionId: sessionId,
                          initialChatMessages: messages, // Pass the fetched messages
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _startNewConversation, // Start a new conversation
              child: const Text('New Conversation'),
            ),
          ),
        ],
      ),
    );
  }
}
