import 'package:flutter/material.dart';
import '../widgets/squareavatar.dart';
import '../colors/colors.dart';
import '../services/local_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String firstName = 'Гость';
  late String email = 'Почта';
  late String blood = '1 группа';
  late String chronic = 'Синусит';
  late String pass = '1';
  late String snils = '1';
  bool _isChronicExpanded = false;

  late TextEditingController _bloodController;
  late TextEditingController _passController;
  late TextEditingController _snilsController;
  late TextEditingController _chronicController;

  late FocusNode _bloodFocusNode;
  late FocusNode _passFocusNode;
  late FocusNode _snilsFocusNode;
  late FocusNode _chronicFocusNode;

  late String _originalBlood;
  late String _originalPass;
  late String _originalSnils;
  late String _originalChronic;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _bloodController = TextEditingController(text: blood);
    _passController = TextEditingController(text: pass);
    _snilsController = TextEditingController(text: snils);
    _chronicController = TextEditingController(text: chronic);

    _bloodFocusNode = FocusNode();
    _passFocusNode = FocusNode();
    _snilsFocusNode = FocusNode();
    _chronicFocusNode = FocusNode();

    _originalBlood = blood;
    _originalPass = pass;
    _originalSnils = snils;
    _originalChronic = chronic;
  }

  @override
  void dispose() {
    _bloodController.dispose();
    _passController.dispose();
    _snilsController.dispose();
    _chronicController.dispose();

    _bloodFocusNode.dispose();
    _passFocusNode.dispose();
    _snilsFocusNode.dispose();
    _chronicFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authData = await LocalStorage.getAuthData();
      if (mounted) {
        setState(() {
          firstName = authData?['name'] ?? 'Гость';
          email = authData?['email'] ?? 'Гость';
          blood = authData?['blood_type'] ?? 'не указан';
          chronic = authData?['chronic_cond'] ?? 'не указан';
          pass = authData?['passport'] ?? 'не указан';
          snils = authData?['snils'] ?? 'не указан';

          _bloodController.text = blood;
          _passController.text = pass;
          _snilsController.text = snils;
          _chronicController.text = chronic;

          _originalBlood = blood;
          _originalPass = pass;
          _originalSnils = snils;
          _originalChronic = chronic;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          firstName = 'Ошибка загрузки';
        });
      }
    }
  }

  Widget _buildEditableField(
    String label,
    String value,
    TextEditingController controller,
    FocusNode focusNode,
    Function() onSave,
    String originalValue,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasChanges = controller.text != originalValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? kDarkBackgroundColor : kSidebarActiveColor,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 290,
                child: TextField(
                  cursorColor: kSidebarActiveColor,
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontSize: 16,
                    color: kSidebarActiveColor,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: value.isEmpty
                        ? 'Нажми сюда, чтобы редактировать'
                        : null,
                    hintStyle: TextStyle(
                      color: kSidebarActiveColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.check,
                  size: 20,
                  color: hasChanges
                      ? kSidebarActiveColor
                      : Theme.of(context).brightness == Brightness.light
                          ? kBackgroundColor
                          : kDarkSidebarIconColor,
                ),
                onPressed: hasChanges
                    ? () async {
                        onSave();
                        await _loadUserData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            width: 268,
                            content: Center(
                                child: Text(
                              'Изменения сохранены',
                              style: TextStyle(color: kSidebarIconColor),
                            )),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: kSidebarActiveColor,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChronicConditions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasChanges = _chronicController.text != _originalChronic;

    return Column(
      children: [
        ListTile(
          title: Text(
            'Хронические заболевания',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? kDarkBackgroundColor : kSidebarActiveColor,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              _isChronicExpanded ? Icons.expand_less : Icons.expand_more,
              color: kSidebarActiveColor,
            ),
            onPressed: () {
              setState(() {
                _isChronicExpanded = !_isChronicExpanded;
              });
            },
          ),
        ),
        if (_isChronicExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    cursorColor: kSidebarActiveColor,
                    controller: _chronicController,
                    focusNode: _chronicFocusNode,
                    maxLines: 10,
                    style: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: kSidebarActiveColor.withOpacity(0.7),
                          width: 1,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: kSidebarActiveColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: kSidebarActiveColor,
                          width: 4.0,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? kDarkBackgroundColor : kSidebarColor,
                      hintText: chronic.isEmpty
                          ? 'Нажми сюда, чтобы редактировать'
                          : null,
                      hintStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: hasChanges ? kSidebarActiveColor : kBackgroundColor,
                  ),
                  onPressed: hasChanges
                      ? () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              width: 268,
                              content: Center(
                                  child: Text(
                                'Изменения сохранены',
                                style: TextStyle(color: kSidebarIconColor),
                              )),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: kSidebarActiveColor,
                            ),
                          );
                          await _loadUserData();
                          await LocalStorage.updateAuthData({
                            'blood_type': blood,
                            'passport': pass,
                            'snils': snils,
                            'chronic_cond': chronic,
                          });
                          FocusScope.of(context).unfocus();
                        }
                      : null,
                ),
              ],
            ),
          ),
        Divider(
          height: 1,
          color: isDark
              ? kDarkBackgroundColor.withOpacity(0.2)
              : kBackgroundColor.withOpacity(0.2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://example.com/your-background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: isDark ? kDarkBackgroundColor : kBackgroundColor,
                );
              },
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                bottom: 14, right: 14, top: 160, left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: SquareAvatarWithFallback(
                    imageUrl: '',
                    name: firstName,
                    size: 120,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kSidebarColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        firstName,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? kDarkBackgroundColor
                              : kSidebarActiveColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? kDarkBackgroundColor.withOpacity(0.7)
                              : kSidebarActiveColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildEditableField(
                        'Группа крови',
                        blood,
                        _bloodController,
                        _bloodFocusNode,
                        () async {
                          setState(() => blood = _bloodController.text);
                          await LocalStorage.updateAuthData({
                            'blood_type': blood,
                            'passport': pass,
                            'snils': snils,
                            'chronic_cond': chronic,
                          });
                          FocusScope.of(context).unfocus();
                        },
                        _originalBlood,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildEditableField(
                        'Паспорт',
                        pass,
                        _passController,
                        _passFocusNode,
                        () async {
                          setState(() => pass = _passController.text);
                          await LocalStorage.updateAuthData({
                            'blood_type': blood,
                            'passport': pass,
                            'snils': snils,
                            'chronic_cond': chronic,
                          });
                          FocusScope.of(context).unfocus();
                        },
                        _originalPass,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildEditableField(
                        'СНИЛС',
                        snils,
                        _snilsController,
                        _snilsFocusNode,
                        () async {
                          setState(() => snils = _snilsController.text);
                          await LocalStorage.updateAuthData({
                            'blood_type': blood,
                            'passport': pass,
                            'snils': snils,
                            'chronic_cond': chronic,
                          });
                          FocusScope.of(context).unfocus();
                        },
                        _originalSnils,
                      ),
                      const SizedBox(height: 20),
                      _buildChronicConditions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
