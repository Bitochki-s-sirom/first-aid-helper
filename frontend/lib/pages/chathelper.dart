import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../colors/colors.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class ChatMessage {
  String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] ?? '',
        isUser: json['isUser'] ?? false,
      );
}

class ChatSession {
  final int id;
  String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        title: json['title'] ?? '',
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class ChatHelperPage extends StatefulWidget {
  const ChatHelperPage({super.key});

  @override
  State<ChatHelperPage> createState() => _ChatHelperPageState();
}

class _ChatHelperPageState extends State<ChatHelperPage> {
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<String>? _aiResponseSubscription;
  List<ChatSession> _chats = [];
  int? _selectedChatId;
  bool _isLoading = false;
  String? _token;
  int? _lastAnimatedAiMsgChatId;
  int? _lastAnimatedAiMsgIndex;

  @override
  void dispose() {
    _aiResponseSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final authData = await LocalStorage.getAuthData();
    if (authData == null) return;
    _token = authData['token'];

    final localChats = await LocalStorage.getChats();
    if (localChats.isNotEmpty) {
      _chats = localChats.map((json) => ChatSession.fromJson(json)).toList();
      setState(() {
        _selectedChatId = _chats.isNotEmpty ? _chats.first.id : null;
      });
    }

    try {
      final chats = await ApiService.getChats(token: _token!);
      _chats = [];
      for (final chat in chats) {
        final id =
            chat['id'] is int ? chat['id'] : int.parse(chat['id'].toString());
        final title = chat['title'] ?? 'Без названия';
        final messages = await _loadMessages(id);
        _chats.add(ChatSession(id: id, title: title, messages: messages));
      }

      // Если чатов нет, создаем первый чат
      if (_chats.isEmpty) {
        await _addNewChat();
        return;
      }

      setState(() {
        _selectedChatId = _chats.isNotEmpty ? _chats.first.id : null;
      });
      await _saveChatsToLocal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чатов: $e')),
      );
    }
  }

  Future<void> _saveChatsToLocal() async {
    await LocalStorage.saveChats(_chats.map((c) => c.toJson()).toList());
  }

  Future<List<ChatMessage>> _loadMessages(int chatId) async {
    if (_token == null) return [];
    try {
      final msgs =
          await ApiService.getChatMessages(token: _token!, chatId: chatId);
      return msgs
          .map((m) => ChatMessage(
                text: m['text'] ?? '',
                isUser: m['sender'] == 1,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  ChatSession? get _currentChat =>
      _chats.firstWhereOrNull((c) => c.id == _selectedChatId);

  Future<void> _addNewChat() async {
    if (_token == null) return;
    setState(() => _isLoading = true);
    try {
      final newId = await ApiService.createChat(token: _token!);
      final messages = await _loadMessages(newId);
      setState(() {
        _chats.add(ChatSession(
            id: newId, title: 'Чат ${_chats.length + 1}', messages: messages));
        _selectedChatId = newId;
        _isLoading = false;
      });
      await _saveChatsToLocal();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания чата: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentChat == null || _token == null) return;

    setState(() {
      _currentChat!.messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _messageController.clear();
    });
    await _saveChatsToLocal();

    try {
      final aiMessage = ChatMessage(text: '', isUser: false);
      setState(() {
        _currentChat!.messages.add(aiMessage);
        // Запоминаем, что это новое сообщение ИИ для анимации
        _lastAnimatedAiMsgChatId = _currentChat!.id;
        _lastAnimatedAiMsgIndex = _currentChat!.messages.length - 1;
      });

      _aiResponseSubscription = ApiService.sendAiMessageStream(
        token: _token!,
        chatId: _currentChat!.id,
        message: text,
      ).listen((chunk) {
        if (chunk == '[DONE]') {
          setState(() => _isLoading = false);
          _saveChatsToLocal();

          // Update chat title if first message
          if (_currentChat!.messages.where((m) => m.isUser).length == 1) {
            final newTitle =
                text.length > 20 ? '${text.substring(0, 20)}...' : text;
            setState(() => _currentChat!.title = newTitle);
          }
        } else {
          setState(() => aiMessage.text += chunk);
        }
      }, onError: (e) {
        setState(() {
          _isLoading = false;
          aiMessage.text = 'Error: $e';
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = _currentChat;
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
                child: DropdownButton<int>(
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
              onPressed: _isLoading ? null : _addNewChat,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat == null
                ? Center(
                    child: Text('Нет чатов',
                        style: TextStyle(color: kSidebarActiveColor)))
                : Container(
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarColor
                        : kDarkSidebarIconColor,
                    child: ListView.builder(
                      key: ValueKey(chat.id),
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chat.messages[index];
                        final bool shouldAnimate = !msg.isUser &&
                            chat.id == _lastAnimatedAiMsgChatId &&
                            index == _lastAnimatedAiMsgIndex;
                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: ChatMessageWidget(
                              text: msg.text,
                              isUser: msg.isUser,
                              animate: shouldAnimate,
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

/// Виджет для плавной анимации и поддержки markdown у сообщений
class ChatMessageWidget extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool animate;

  const ChatMessageWidget({
    required this.text,
    required this.isUser,
    this.animate = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey<String>(text),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser
              ? kSidebarActiveColor.withOpacity(0.8)
              : Theme.of(context).brightness == Brightness.light
                  ? const Color.fromARGB(255, 136, 155, 143).withOpacity(0.3)
                  : kSidebarIconColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isUser
            ? Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? kSidebarIconColor
                      : kDarkSidebarIconColor,
                  fontSize: 16,
                ),
              )
            : animate
                ? AnimatedMarkdownText(text: text)
                : MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  ),
      ),
    );
  }
}

/// Виджет для "печати" markdown текста буква за буквой
class AnimatedMarkdownText extends StatefulWidget {
  final String text;
  final Duration duration;

  const AnimatedMarkdownText({
    Key? key,
    required this.text,
    this.duration = const Duration(milliseconds: 25),
  }) : super(key: key);

  @override
  State<AnimatedMarkdownText> createState() => _AnimatedMarkdownTextState();
}

class _AnimatedMarkdownTextState extends State<AnimatedMarkdownText> {
  String _visibleText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _currentIndex = 0;
      _visibleText = '';
      _timer?.cancel();
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex <= widget.text.length) {
        setState(() {
          _visibleText = widget.text.substring(0, _currentIndex);
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _visibleText,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
    );
  }
}

extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
