import 'package:flutter/material.dart';
import '../colors/colors.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';

class MedicationsRunoutPage extends StatefulWidget {
  const MedicationsRunoutPage({super.key});

  @override
  State<MedicationsRunoutPage> createState() => _MedicationsRunoutPageState();
}

class _MedicationsRunoutPageState extends State<MedicationsRunoutPage> {
  bool isHovered = false;
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> filteredMedications = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Все';
  late String _token = '';

  @override
  void initState() {
    super.initState();
    _loadTokenAndMedications();
  }

  Future<void> _loadTokenAndMedications() async {
    final authData = await LocalStorage.getAuthData();
    if (authData == null) return;
    _token = authData['token'];

    try {
      final medsFromServer = await ApiService.getDrugs(token: _token);
      setState(() {
        medications = medsFromServer;
        medications.sort((a, b) =>
            DateTime.parse(a['expiry']).compareTo(DateTime.parse(b['expiry'])));
        filteredMedications = List.from(medications);
      });
      await LocalStorage.saveMeds(medications);
    } catch (e) {
      final medsLocal = await LocalStorage.getMeds();
      setState(() {
        medications = medsLocal;
        filteredMedications = List.from(medications);
      });
      print('$e');
      showErrorSnackBar(context, 'Ошибка загрузки лекарств');
    }
  }

  Future<void> _addMedication(Map<String, dynamic> newMed) async {
    if (_token == '') return;
    try {
      final success = await ApiService.addDrug(token: _token, drug: newMed);
      if (success) {
        final medsFromServer = await ApiService.getDrugs(token: _token);
        setState(() {
          medications = medsFromServer;
          medications.sort((a, b) => DateTime.parse(a['expiry'])
              .compareTo(DateTime.parse(b['expiry'])));
          _filterMedications(_searchController.text);
        });
        await LocalStorage.saveMeds(medications);
      } else {
        showErrorSnackBar(context, 'Не удалось добавить лекарство');
      }
    } catch (e) {
      print('$e');
      showErrorSnackBar(context, 'Ошибка при добавлении');
    }
  }

  Future<void> _removeMedication(int id) async {
    if (_token == '') return;
    try {
      final success = await ApiService.removeDrug(token: _token, id: id);
      if (success) {
        final medsFromServer = await ApiService.getDrugs(token: _token);
        setState(() {
          medications = medsFromServer;
          _filterMedications(_searchController.text);
        });
        await LocalStorage.saveMeds(medications);
      } else {
        showErrorSnackBar(context, 'Не удалось удалить лекарство');
      }
    } catch (e) {
      print('$e');
      showErrorSnackBar(context, 'Ошибка при удалении');
    }
  }

  void _filterMedications(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMedications = List.from(medications);
      } else {
        filteredMedications = medications.where((med) {
          return med['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      if (_selectedFilter == 'Скоро истекает') {
        filteredMedications = filteredMedications.where((med) {
          final expiryDate = DateTime.parse(med['expiry']);
          final daysLeft = expiryDate.difference(DateTime.now()).inDays;
          return daysLeft < 7;
        }).toList();
      }
    });
  }

  void showErrorSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSidebarColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Фильтровать по:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarIconColor
                        : kDarkSidebarIconColor),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(
                  'Все лекарства',
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? kSidebarIconColor
                          : kDarkSidebarIconColor),
                ),
                leading: Radio(
                  value: 'Все',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value.toString());
                    Navigator.pop(context);
                    _filterMedications(_searchController.text);
                  },
                  activeColor: kSidebarActiveColor,
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return kSidebarActiveColor;
                      }
                      return kSidebarActiveColor;
                    },
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'Скоро истекают (<7 дней)',
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? kSidebarIconColor
                          : kDarkSidebarIconColor),
                ),
                leading: Radio(
                  value: 'Скоро истекает',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value.toString());
                    Navigator.pop(context);
                    _filterMedications(_searchController.text);
                  },
                  activeColor: kSidebarActiveColor,
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return kSidebarActiveColor;
                      }
                      return kSidebarActiveColor;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMedicationDetails(Map<String, dynamic> medication) {
    showDialog(
      context: context,
      barrierColor: Colors.black54.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? const Color.fromARGB(238, 255, 255, 255)
              : const Color.fromARGB(241, 81, 81, 81),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      medication['name'],
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kSidebarActiveColor),
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow(
                        'Производитель:', medication['manufacturer']),
                    _buildDetailRow('Дозировка:', medication['dose']),
                    _buildDetailRow(
                        'Количество:', '${medication['amount']} шт'),
                    _buildDetailRow('Описание:', medication['description']),
                    _buildDetailRow('Тип:', medication['type'] ?? ''),
                    _buildDetailRow(
                        'Местоположение:', medication['location'] ?? ''),
                    const SizedBox(height: 20),
                    _buildExpiryIndicator(DateTime.parse(medication['expiry'])),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close,
                      size: 28, color: kSidebarActiveColor),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Закрыть',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationDialog(
        onAdd: (newMed) => _addMedication(newMed),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kSidebarActiveColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: kSidebarActiveColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryIndicator(DateTime expiryDate) {
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    Color color;
    String status;

    if (daysLeft < 0) {
      color = Colors.red;
      status = 'ПРОСРОЧЕНО';
    } else if (daysLeft < 7) {
      color = Color.fromARGB(255, 128, 0, 0);
      status = 'Истекает через $daysLeft дн.';
    } else if (daysLeft < 30) {
      color = const Color.fromARGB(255, 179, 103, 82);
      status = 'Истекает через $daysLeft дн.';
    } else {
      color = const Color.fromARGB(255, 95, 95, 95);
      status = 'Истекает через ${daysLeft ~/ 30} мес.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: color),
          const SizedBox(width: 10),
          Text(
            'Срок годности: ${expiryDate.day}.${expiryDate.month}.${expiryDate.year}',
            style: TextStyle(fontSize: 16, color: color),
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        backgroundColor: kSidebarActiveColor,
        child: Icon(
          Icons.add,
          weight: 4,
          color: Theme.of(context).brightness == Brightness.light
              ? kSidebarIconColor
              : kDarkSidebarIconColor,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    cursorColor: kSidebarActiveColor,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? kDarkSidebarIconColor
                            : kSidebarIconColor),
                    controller: _searchController,
                    onChanged: _filterMedications,
                    decoration: InputDecoration(
                      labelStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      floatingLabelStyle: TextStyle(
                        color: kSidebarActiveColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: kSidebarActiveColor,
                          width: 4.0,
                        ),
                      ),
                      labelText: 'Поиск...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: kSidebarActiveColor, width: 1)),
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.filter_list, color: kSidebarActiveColor),
                  onPressed: _showFilterOptions,
                  tooltip: 'Фильтры',
                ),
              ],
            ),
          ),
          if (filteredMedications.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Лекарства не найдены',
                  style: TextStyle(color: kSidebarActiveColor),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: filteredMedications.length,
                itemBuilder: (context, index) {
                  final med = filteredMedications[index];
                  final daysLeft = DateTime.parse(med['expiry'])
                      .difference(DateTime.now())
                      .inDays;
                  final isExpiringSoon = daysLeft < 7;

                  return _buildMedicationCard(med, isExpiringSoon);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med, bool isExpiringSoon) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 100),
            tween: Tween(begin: 1.0, end: isHovered ? 1.05 : 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _showMedicationDetails(med),
              child: Stack(
                children: [
                  Card(
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarIconColor
                        : const Color.fromARGB(179, 81, 81, 81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isHovered
                            ? kSidebarActiveColor
                            : kSidebarActiveColor.withOpacity(0.3),
                        width: isHovered ? 2 : 1,
                      ),
                    ),
                    elevation: isHovered ? 8 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['name'],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kSidebarActiveColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            med['manufacturer'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.medical_services,
                                  size: 14, color: kSidebarActiveColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${med['dose']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kSidebarActiveColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 14, color: kSidebarActiveColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${med['amount']} шт',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kSidebarActiveColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildExpiryDate(
                              DateTime.parse(med['expiry']), isExpiringSoon),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.delete,
                          color: kSidebarActiveColor, size: 22),
                      tooltip: 'Удалить',
                      onPressed: () => _removeMedication(med['id']),
                      splashRadius: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiryDate(DateTime expiryDate, bool isExpiringSoon) {
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? Color.fromARGB(255, 128, 0, 0).withOpacity(0.1)
            : kSidebarActiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpiringSoon
              ? Color.fromARGB(255, 128, 0, 0)
              : kSidebarActiveColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: isExpiringSoon
                ? Color.fromARGB(255, 128, 0, 0)
                : kSidebarActiveColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${expiryDate.day}.${expiryDate.month}.${expiryDate.year}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isExpiringSoon
                    ? Color.fromARGB(255, 128, 0, 0)
                    : kSidebarActiveColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${daysLeft.abs()} дн.)',
            style: TextStyle(
              fontSize: 10,
              color: isExpiringSoon
                  ? Color.fromARGB(255, 128, 0, 0)
                  : kSidebarActiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AddMedicationDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  const AddMedicationDialog({super.key, required this.onAdd});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _doseController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _expiryDate;
  bool _expiryDateError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(),
            textTheme: TextTheme(
                bodySmall: TextStyle(color: kSidebarActiveColor),
                displayMedium: TextStyle(fontSize: 16),
                titleMedium: TextStyle(color: kSidebarActiveColor)),
            colorScheme: ColorScheme.light(
                primary: Theme.of(context).brightness == Brightness.light
                    ? kDarkSidebarIconColor
                    : kSidebarColor,
                onPrimary: kSidebarActiveColor,
                onSurface: kSidebarActiveColor,
                surface: Theme.of(context).brightness == Brightness.light
                    ? kSidebarIconColor
                    : kDarkSidebarIconColor),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kSidebarActiveColor,
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    setState(() {
      _expiryDateError = _expiryDate == null;
    });

    if (_formKey.currentState?.validate() != true || _expiryDate == null) {
      return;
    }

    widget.onAdd({
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': _typeController.text.trim(),
      'name': _nameController.text.trim(),
      'expiry': _expiryDate!.toUtc().toIso8601String(),
      'manufacturer': _manufacturerController.text.trim(),
      'dose': _doseController.text.trim(),
      'amount': (int.tryParse(_quantityController.text) ?? 1).toString(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = kSidebarActiveColor;

    return Dialog(
      backgroundColor: kSidebarColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Добавить лекарство',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.light
                          ? kSidebarIconColor.withOpacity(0.5)
                          : kDarkSidebarIconColor.withOpacity(0.5),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _nameController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Название',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Укажите название' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _manufacturerController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Производитель',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _typeController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Тип',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Укажите тип' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _doseController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Дозировка',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _quantityController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Количество',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null
                    ? 'Введите число'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _locationController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Местоположение',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
              ),
              const SizedBox(height: 15),
              TextFormField(
                style: TextStyle(color: const Color.fromARGB(160, 87, 83, 83)),
                controller: _descriptionController,
                cursorColor: kSidebarActiveColor,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: kSidebarActiveColor, width: 1.5)),
                    floatingLabelStyle: TextStyle(
                      color: kSidebarActiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kSidebarActiveColor,
                        width: 4.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: kSidebarActiveColor, width: 1),
                    ),
                    filled: false,
                    labelText: 'Описание',
                    labelStyle: TextStyle(
                        color: kSidebarActiveColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _expiryDate == null
                              ? 'Срок годности не выбран'
                              : 'Срок годности: ${_expiryDate!.day}.${_expiryDate!.month}.${_expiryDate!.year}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _expiryDateError
                                ? const Color.fromARGB(255, 191, 53, 53)
                                : null,
                          ),
                        ),
                        if (_expiryDateError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Пожалуйста, выберите дату',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 191, 53, 53),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickExpiryDate,
                    child:
                        Text('Выбрать дату', style: TextStyle(color: accent)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Добавить',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
