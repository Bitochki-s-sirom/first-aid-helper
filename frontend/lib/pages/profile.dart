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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authData = await LocalStorage.getAuthData();
      if (mounted) {
        setState(() {
          firstName = authData?['name'] ?? 'Гость';
          email = authData?['email'] ?? 'Гость';
          blood = authData?['blood_type'] ?? 'Гость';
          chronic = authData?['chronic_cond'] ?? 'Гость';
          pass = authData?['passport'] ?? 'Гость';
          snils = authData?['snils'] ?? 'Гость';
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

  Future<void> _showEditDialog(BuildContext context, String title,
      String currentValue, Function(String) onSave) async {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kSidebarColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Изменить $title',
            style: TextStyle(
              color: isDark ? kDarkBackgroundColor : kBackgroundColor,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? kDarkBackgroundColor : Colors.white,
            ),
            style: TextStyle(
              color: isDark ? kDarkBackgroundColor : kBackgroundColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: kSidebarActiveColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: kSidebarActiveColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoField(String label, String value, {bool editable = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? kDarkBackgroundColor : kBackgroundColor,
            ),
          ),
          GestureDetector(
            onTap: editable
                ? () => _showEditDialog(
                      context,
                      label.toLowerCase(),
                      value,
                      (newValue) async {
                        setState(() {
                          if (label == 'Группа крови') blood = newValue;
                          if (label == 'Паспорт') pass = newValue;
                          if (label == 'СНИЛС') snils = newValue;
                          if (label == 'Хронические заболевания') {
                            chronic = newValue;
                          }
                        });
                        await LocalStorage.updateAuthData({
                          'blood_type': blood,
                          'passport': pass,
                          'snils': snils,
                          'chronic_cond': chronic,
                        });
                      },
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? kDarkBackgroundColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Text(
                    value.isNotEmpty ? value : 'Не указано',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kDarkBackgroundColor : kBackgroundColor,
                    ),
                  ),
                  if (editable) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: kSidebarActiveColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
                          color:
                              isDark ? kDarkBackgroundColor : kBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? kDarkBackgroundColor.withOpacity(0.7)
                              : kBackgroundColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildInfoField('Имя', firstName, editable: false),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildInfoField('Почта', email, editable: false),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildInfoField('Группа крови', blood),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      ExpansionPanelList(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            _isChronicExpanded = isExpanded;
                          });
                        },
                        children: [
                          ExpansionPanel(
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                title: Text(
                                  'Хронические заболевания',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? kDarkBackgroundColor
                                        : kBackgroundColor,
                                  ),
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: TextField(
                                controller:
                                    TextEditingController(text: chronic),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? kDarkBackgroundColor
                                      : Colors.white,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: kSidebarActiveColor,
                                    ),
                                    onPressed: () => _showEditDialog(
                                      context,
                                      'хронические заболевания',
                                      chronic,
                                      (newValue) async {
                                        setState(() => chronic = newValue);
                                        await LocalStorage.updateAuthData({
                                          'chronic_cond': newValue,
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark
                                      ? kDarkBackgroundColor
                                      : kBackgroundColor,
                                ),
                              ),
                            ),
                            isExpanded: _isChronicExpanded,
                          ),
                        ],
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildInfoField('Паспорт', pass),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildInfoField('СНИЛС', snils),
                      const SizedBox(height: 20),
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
