import 'package:flutter/material.dart';
import '../colors/colors.dart';

// Модель одного сообщения
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// Модель чата
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}

class ChatHelperPage extends StatefulWidget {
  const ChatHelperPage({super.key});

  @override
  State<ChatHelperPage> createState() => _ChatHelperPageState();
}

class _ChatHelperPageState extends State<ChatHelperPage> {
  final TextEditingController _messageController = TextEditingController();

  // Список всех чатов
  List<ChatSession> _chats = [];
  String? _selectedChatId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Можно загрузить чаты из локального хранилища или с бэка
    _chats = [
      ChatSession(id: 'chat1', title: 'Мой первый чат', messages: []),
    ];
    _selectedChatId = _chats.first.id;
  }

  ChatSession get _currentChat =>
      _chats.firstWhere((c) => c.id == _selectedChatId);

  void _addNewChat() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _chats.add(ChatSession(
        id: newId,
        title: 'Чат ${_chats.length + 1}',
        messages: [],
      ));
      _selectedChatId = newId;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _currentChat.messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _messageController.clear();
    });

    // Отправка сообщения на бэк (замените на свой API)
    try {
      // final response = await ApiService.sendAiMessage(
      //   chatId: _currentChat.id,
      //   message: text,
      // );
      // final aiReply = response['reply'] ?? 'Нет ответа';
      await Future.delayed(const Duration(seconds: 1)); // имитация задержки
      final aiReply = 'Ответ ИИ на: "$text"';

      setState(() {
        _currentChat.messages.add(ChatMessage(text: aiReply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка общения с ИИ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? kSidebarColor
          : kDarkSidebarIconColor,
      appBar: AppBar(
        backgroundColor: kSidebarActiveColor,
        title: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedChatId,
                  dropdownColor: kSidebarActiveColor,
                  icon: Icon(Icons.arrow_drop_down, color: kSidebarIconColor),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarIconColor
                        : kDarkSidebarIconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  items: _chats
                      .map((chat) => DropdownMenuItem(
                            value: chat.id,
                            child: Text(chat.title),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedChatId = val!;
                    });
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: 'Создать новый чат',
              icon: Icon(Icons.add, color: kSidebarIconColor),
              onPressed: _addNewChat,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.light
                  ? kSidebarColor
                  : kDarkSidebarIconColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentChat.messages.length,
                itemBuilder: (context, index) {
                  final msg = _currentChat.messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? kSidebarActiveColor.withOpacity(0.8)
                            : Theme.of(context).brightness == Brightness.light
                                ? const Color.fromARGB(255, 136, 155, 143)
                                    .withOpacity(0.3)
                                : kSidebarIconColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? kSidebarIconColor
                                  : kDarkSidebarIconColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(color: kSidebarActiveColor),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    cursorColor: kSidebarActiveColor,
                    style: TextStyle(color: kSidebarActiveColor),
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      hintStyle: TextStyle(
                          color: kSidebarActiveColor.withOpacity(0.2)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: kSidebarActiveColor, width: 1)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: kSidebarActiveColor),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
