import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iechatbot/chat_page.dart';

class Sidebar extends StatefulWidget {
  final String token;

  const Sidebar({Key? key, required this.token}) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  // Fetch chat history from the backend
  Future<void> _fetchChatHistory() async {
    final url = Uri.parse('http://127.0.0.1:8000/history?token=${widget.token}');
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> historyData = json.decode(response.body);
        setState(() {
          _chatHistory = historyData.map((message) {
            return {
              'query': message['query'] ?? '',
              'response': message['response'] ?? '',
            };
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat history')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Truncate the query text if it is too long
  String _truncateText(String text, int maxLength) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }

  // Build the sidebar content for chat history
  Widget _buildSidebar() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final chat = _chatHistory[index];
              return ListTile(
                title: Text(
                  'Conversation ${index + 1}: ${_truncateText(chat['query']!, 30)}',
                ),
                subtitle: Text(_truncateText(chat['response']!, 50)),
                onTap: () {
                  // Pass the full conversation to the ChatPage when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        token: widget.token,
                        initialChatMessages: [
                          {
                            'user_message': chat['query'],
                            'bot_response': chat['response']
                          }
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Sidebar title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Chat History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Conversation list
          Expanded(child: _buildSidebar()),
          // New Conversation Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      token: widget.token,
                      initialChatMessages: [], // Start a new empty conversation
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: Text(
                'New Conversation',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
