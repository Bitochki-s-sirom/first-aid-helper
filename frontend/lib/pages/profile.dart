import 'package:flutter/material.dart';
import '../widgets/squareavatar.dart';
import '../colors/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = 'Сергей';
  String lastName = 'Иванов';
  String middleName = 'Петрович';

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

  Widget _buildEditableField(
      String label, String value, Function(String) onEdit) {
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
            onTap: () => onEdit(value),
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
                  ),
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
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: kSidebarActiveColor,
                  ),
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        '$lastName $firstName $middleName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? kDarkBackgroundColor : kBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildEditableField(
                        'Фамилия',
                        lastName,
                        (value) => _showEditDialog(
                          context,
                          'фамилию',
                          lastName,
                          (newValue) => setState(() => lastName = newValue),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildEditableField(
                        'Имя',
                        firstName,
                        (value) => _showEditDialog(
                          context,
                          'имя',
                          firstName,
                          (newValue) => setState(() => firstName = newValue),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? kDarkBackgroundColor.withOpacity(0.2)
                            : kBackgroundColor.withOpacity(0.2),
                      ),
                      _buildEditableField(
                        'Отчество',
                        middleName,
                        (value) => _showEditDialog(
                          context,
                          'отчество',
                          middleName,
                          (newValue) => setState(() => middleName = newValue),
                        ),
                      ),
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
