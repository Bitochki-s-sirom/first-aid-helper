import 'dart:io';
import 'dart:typed_data';
import '../widgets/docimage.dart';
import 'package:flutter/material.dart';
import '../colors/colors.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> filteredDocuments = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedDoctor = 'Все';
  late String _token = '';
  Set<String> _allDoctors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndDocuments();
  }

  Future<void> _loadTokenAndDocuments() async {
    setState(() => _isLoading = true);

    try {
      final authData = await LocalStorage.getAuthData();
      if (authData == null) {
        setState(() => _isLoading = false);
        return;
      }

      _token = authData['token'];

      try {
        final docsFromServer = await ApiService.getDocuments(token: _token);
        setState(() {
          documents = docsFromServer;
          _allDoctors = documents
              .map((m) => (m['doctor'] ?? 'Без врача').toString())
              .toSet();
          filteredDocuments = List.from(documents);
        });
        await LocalStorage.saveDocuments(documents);
      } catch (e) {
        // Логируем ошибку для отладки
        debugPrint('Ошибка загрузки документов с сервера: $e');

        // Пробуем загрузить из локального хранилища
        final docsLocal = await LocalStorage.getDocuments();
        setState(() {
          documents = docsLocal;
          _allDoctors = documents
              .map((m) => (m['doctor'] ?? 'Без врача').toString())
              .toSet();
          filteredDocuments = List.from(documents);
        });

        // Показываем пользователю только понятное сообщение
        showErrorSnackBar(context,
            'Не удалось загрузить актуальные документы. Показаны сохранённые данные.');
      }
    } catch (e) {
      debugPrint('Общая ошибка инициализации: $e');
      showErrorSnackBar(context, 'Ошибка инициализации документов');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument(Map<String, dynamic> newDoc) async {
    if (_token == '') return;

    try {
      final photoFile = newDoc['photoFile'] as File?;
      final docData = Map<String, dynamic>.from(newDoc)..remove('photoFile');

      // Добавляем дату создания, если не указана
      if (!docData.containsKey('date') ||
          docData['date'] == null ||
          docData['date'].isEmpty) {
        docData['date'] = DateTime.now().toIso8601String().substring(0, 10);
      }

      final success = await ApiService.addDocumentWithPhoto(
        token: _token,
        document: docData,
        photoFile: photoFile,
      );

      if (success) {
        await _loadTokenAndDocuments();
        showSuccessSnackBar(context, 'Документ успешно добавлен');
      } else {
        showErrorSnackBar(context, 'Не удалось добавить документ');
      }
    } catch (e) {
      showErrorSnackBar(context, 'Ошибка при добавлении: $e');
    }
  }

  Future<void> _removeDocument(dynamic id) async {
    if (_token == '') return;

    try {
      final success = await ApiService.removeDocument(token: _token, id: id);
      if (success) {
        setState(() {
          documents.removeWhere((doc) => doc['id'] == id);
          filteredDocuments.removeWhere((doc) => doc['id'] == id);
        });
        await LocalStorage.saveDocuments(documents);
        showSuccessSnackBar(context, 'Документ удален');
      } else {
        showErrorSnackBar(context, 'Не удалось удалить документ');
      }
    } catch (e) {
      showErrorSnackBar(context, 'Ошибка при удалении: $e');
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      filteredDocuments = documents.where((doc) {
        final matchesName =
            doc['name'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesDoctor = _selectedDoctor == 'Все' ||
            (doc['doctor'] ?? '') == _selectedDoctor;
        return matchesName && matchesDoctor;
      }).toList();
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

  void showSuccessSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showDoctorFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSidebarColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final doctors = ['Все', ..._allDoctors.where((d) => d.isNotEmpty)];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Фильтр по врачу:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarIconColor
                        : kDarkSidebarIconColor),
              ),
              const SizedBox(height: 20),
              ...doctors.map((doctor) => ListTile(
                    title: Text(
                      doctor,
                      style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? kSidebarIconColor
                                  : kDarkSidebarIconColor),
                    ),
                    leading: Radio(
                      value: doctor,
                      groupValue: _selectedDoctor,
                      onChanged: (value) {
                        setState(() => _selectedDoctor = value.toString());
                        Navigator.pop(context);
                        _filterDocuments(_searchController.text);
                      },
                      activeColor: kSidebarActiveColor,
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: buildDocumentImage(doc['file_data']),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (doc['doctor'] != null &&
                        doc['doctor'].toString().isNotEmpty)
                      _buildDetailRow('Врач:', doc['doctor']),
                    if (doc['type'] != null &&
                        doc['type'].toString().isNotEmpty)
                      _buildDetailRow('Описание:', doc['type']),
                    if (doc['date'] != null &&
                        doc['date'].toString().isNotEmpty)
                      _buildDetailRow('Дата:', doc['date']),
                    if (doc['name'] != null &&
                        doc['name'].toString().isNotEmpty)
                      _buildDetailRow('Название:', doc['name']),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddDocumentDialog(
        onAdd: (newDoc) => _addDocument(newDoc),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
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
        onPressed: () => _showAddDocumentDialog(context),
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
                    onChanged: _filterDocuments,
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
                  onPressed: _showDoctorFilterOptions,
                  tooltip: 'Фильтр по врачу',
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: kSidebarActiveColor,
                ),
              ),
            )
          else if (filteredDocuments.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Документы не найдены',
                  style: TextStyle(
                    fontSize: 18,
                    color: kSidebarActiveColor,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200
                      ? 6
                      : MediaQuery.of(context).size.width > 800
                          ? 4
                          : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio:
                      0.95, // Увеличено для дополнительного пространства
                ),
                itemCount: filteredDocuments.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocuments[index];
                  return _buildDocumentCard(doc);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isHovered ? 1.03 : 1.0,
            child: GestureDetector(
              onTap: () => _showDocumentDetails(doc),
              child: Card(
                elevation: isHovered ? 8 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isHovered
                        ? kSidebarActiveColor
                        : kSidebarActiveColor.withOpacity(0.2),
                    width: isHovered ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 110,
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: buildDocumentImage(doc['file_data']),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Название документа
                          Text(
                            doc['name'] ?? 'Без названия',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: kSidebarActiveColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  doc['doctor'] ?? 'Без врача',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Кнопка удаления
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20), // Уменьшен размер
                        onPressed: () => _removeDocument(doc['id']),
                        tooltip: 'Удалить документ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddDocumentDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  const AddDocumentDialog({super.key, required this.onAdd});

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _dateController = TextEditingController();
  final _doctorController = TextEditingController();
  File? _photoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _dateController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    widget.onAdd({
      'name': _nameController.text.trim(),
      'type': _typeController.text.trim(),
      'date': _dateController.text.trim(),
      'doctor': _doctorController.text.trim(),
      'photoFile': _photoFile,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Добавить документ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.light
                          ? kSidebarIconColor.withOpacity(0.5)
                          : kDarkSidebarIconColor.withOpacity(0.5),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Название*',
                  labelStyle: TextStyle(
                      color: accent.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 1.5)),
                  floatingLabelStyle: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 4.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                  filled: false,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Укажите название' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _typeController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Описание*',
                  labelStyle: TextStyle(
                      color: accent.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 1.5)),
                  floatingLabelStyle: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 4.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                  filled: false,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Укажите описание' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dateController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Дата (ГГГГ-ММ-ДД)*',
                  labelStyle: TextStyle(
                      color: accent.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 1.5)),
                  floatingLabelStyle: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 4.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                  hintText: 'Например: 1234-12-31',
                  hintStyle: TextStyle(
                      color: kSidebarActiveColor.withOpacity(0.5),
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  filled: false,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Укажите дату';
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                    return 'Используйте формат ГГГГ-ММ-ДД';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _doctorController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Врач',
                  labelStyle: TextStyle(
                      color: accent.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 1.5)),
                  floatingLabelStyle: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 4.0,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                  filled: false,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.image, color: accent),
                      label: Text(
                          _photoFile != null ? 'Фото выбрано' : 'Выбрать фото'),
                      onPressed: _pickPhoto,
                    ),
                  ),
                ],
              ),
              if (_photoFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: Image.file(_photoFile!),
                  ),
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
