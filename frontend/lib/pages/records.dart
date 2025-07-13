import 'dart:io';
import 'package:flutter/material.dart';
import '../colors/colors.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _loadTokenAndDocuments();
  }

  Future<void> _loadTokenAndDocuments() async {
    final authData = await LocalStorage.getAuthData();
    if (authData == null) return;
    _token = authData['token'];

    try {
      final docsFromServer = await ApiService.getDocuments(token: _token);
      setState(() {
        documents = docsFromServer;
        _allDoctors =
            documents.map((m) => (m['doctor'] ?? '').toString()).toSet();
        filteredDocuments = List.from(documents);
      });
      await LocalStorage.saveDocuments(documents);
    } catch (e) {
      final docsLocal = await LocalStorage.getDocuments();
      setState(() {
        documents = docsLocal;
        _allDoctors =
            documents.map((m) => (m['doctor'] ?? '').toString()).toSet();
        filteredDocuments = List.from(documents);
      });
      showErrorSnackBar(context, 'Ошибка загрузки записей: $e');
    }
  }

  Future<void> _addDocument(Map<String, dynamic> newDoc) async {
    if (_token == '') return;
    try {
      final photoFile = newDoc['photoFile'] as File?;
      final docData = Map<String, dynamic>.from(newDoc)..remove('photoFile');
      final success = await ApiService.addDocumentWithPhoto(
        token: _token,
        document: docData,
        photoFile: photoFile,
      );
      if (success) {
        final docsFromServer = await ApiService.getDocuments(token: _token);
        setState(() {
          documents = docsFromServer;
          _allDoctors =
              documents.map((m) => (m['doctor'] ?? '').toString()).toSet();
          _filterDocuments(_searchController.text);
        });
        await LocalStorage.saveDocuments(documents);
      } else {
        showErrorSnackBar(context, 'Не удалось добавить запись');
      }
    } catch (e) {
      showErrorSnackBar(context, 'Ошибка при добавлении: $e');
    }
  }

  Future<void> _removeDocument(int id) async {
    if (_token == '') return;
    try {
      final success = await ApiService.removeDocument(token: _token, id: id);
      if (success) {
        final docsFromServer = await ApiService.getDocuments(token: _token);
        setState(() {
          documents = docsFromServer;
          _allDoctors =
              documents.map((m) => (m['doctor'] ?? '').toString()).toSet();
          _filterDocuments(_searchController.text);
        });
        await LocalStorage.saveDocuments(documents);
      } else {
        showErrorSnackBar(context, 'Не удалось удалить запись');
      }
    } catch (e) {
      showErrorSnackBar(context, 'Ошибка при удалении: $e');
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      filteredDocuments = documents.where((doc) {
        final matchesName = doc['shortDescription']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(child: buildDocumentImage(doc['photo'], size: 180)),
                    const SizedBox(height: 15),
                    if (doc['doctor'] != null &&
                        doc['doctor'].toString().isNotEmpty)
                      Text(
                        'Врач: ${doc['doctor']}',
                        style: const TextStyle(
                            fontSize: 16, color: kSidebarActiveColor),
                      ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Краткое описание:', doc['shortDescription']),
                    _buildDetailRow('Полное описание:', doc['fullDescription']),
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

  void _showAddDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddDocumentDialog(
        onAdd: (newDoc) => _addDocument(newDoc),
      ),
    );
  }

  Widget buildDocumentImage(String? photoBase64, {double size = 36}) {
    if (photoBase64 == null || photoBase64.isEmpty) {
      return Icon(Icons.image_not_supported,
          size: size, color: Colors.grey[400]);
    }
    if (photoBase64.startsWith('data:image')) {
      final base64Str = photoBase64.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    }
    return Icon(Icons.image_not_supported, size: size, color: Colors.grey[400]);
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
          if (filteredDocuments.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Записи не найдены',
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
              onTap: () => _showDocumentDetails(doc),
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(child: SizedBox()),
                          if (doc['doctor'] != null &&
                              doc['doctor'].toString().isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 17, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    doc['doctor'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          if (doc['shortDescription'] != null &&
                              doc['shortDescription'].toString().isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.description,
                                    size: 16, color: kSidebarActiveColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    doc['shortDescription'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: kSidebarActiveColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: buildDocumentImage(doc['photo']),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.delete,
                          color: kSidebarActiveColor, size: 22),
                      tooltip: 'Удалить',
                      onPressed: () => _removeDocument(doc['id']),
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
}

class AddDocumentDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  const AddDocumentDialog({super.key, required this.onAdd});

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _fullDescController = TextEditingController();
  final _photoNameController = TextEditingController();
  File? _photoFile;

  @override
  void dispose() {
    _doctorController.dispose();
    _shortDescController.dispose();
    _fullDescController.dispose();
    _photoNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
        _photoNameController.text = picked.name;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    widget.onAdd({
      'id': DateTime.now().millisecondsSinceEpoch,
      'doctor': _doctorController.text.trim(),
      'shortDescription': _shortDescController.text.trim(),
      'fullDescription': _fullDescController.text.trim(),
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
              Text('Добавить запись',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.light
                          ? kSidebarIconColor.withOpacity(0.5)
                          : kDarkSidebarIconColor.withOpacity(0.5),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Укажите врача' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _shortDescController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Короткое описание',
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
                    v == null || v.trim().isEmpty ? 'Введите описание' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _fullDescController,
                cursorColor: accent,
                decoration: InputDecoration(
                  labelText: 'Полное описание',
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
                    v == null || v.trim().isEmpty ? 'Введите описание' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _photoNameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Имя файла фото (jpg)',
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
                          _photoFile == null ? 'Выберите jpg-файл' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Фото'),
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
