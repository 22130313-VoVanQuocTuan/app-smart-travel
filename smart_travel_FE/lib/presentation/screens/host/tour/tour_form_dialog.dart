// lib/presentation/screens/host/tour/tour_form_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/service/tour_service.dart';

class TourFormDialog extends StatefulWidget {
  final int homestayId;
  final Map<String, dynamic>? tour;
  final VoidCallback onSuccess;

  const TourFormDialog({
    super.key,
    required this.homestayId,
    this.tour,
    required this.onSuccess,
  });

  @override
  State<TourFormDialog> createState() => _TourFormDialogState();
}

class _TourFormDialogState extends State<TourFormDialog> {
  late TourService _tourService;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _existingGalleryImages = [];
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationDaysController = TextEditingController();
  final _durationNightsController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxPeopleController = TextEditingController();
  final _minPeopleController = TextEditingController();

  // Images
  File? _thumbnailImage;
  List<File> _galleryImages = [];

  // Included & Excluded
  final List<String> _included = [];
  final List<String> _excluded = [];
  final _includedController = TextEditingController();
  final _excludedController = TextEditingController();

  // Schedules
  final List<Map<String, dynamic>> _schedules = [];

  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    _tourService = TourService(dioClient);
    _isEdit = widget.tour != null;

    if (_isEdit) {
      _loadTourData();
    }
  }

  void _loadTourData() {
    final tour = widget.tour!;
    _nameController.text = tour['name'] ?? '';
    _descriptionController.text = tour['description'] ?? '';
    _durationDaysController.text = tour['durationDays']?.toString() ?? '';
    _durationNightsController.text = tour['durationNights']?.toString() ?? '';
    _priceController.text = tour['pricePerPerson']?.toString() ?? '';
    _maxPeopleController.text = tour['maxPeople']?.toString() ?? '';
    _minPeopleController.text = tour['minPeople']?.toString() ?? '1';

    _included.addAll(List<String>.from(tour['included'] ?? []));
    _excluded.addAll(List<String>.from(tour['excluded'] ?? []));
    _existingGalleryImages = List<String>.from(tour['images'] ?? []);

    final schedules = tour['schedules'] as List? ?? [];
    for (var schedule in schedules) {
      _schedules.add({
        'dayNumber': schedule['dayNumber'],
        'title': schedule['title'],
        'activities': schedule['activities'],
        'accommodation': schedule['accommodation'],
        'meals': List<String>.from(schedule['meals'] ?? []),
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationDaysController.dispose();
    _durationNightsController.dispose();
    _priceController.dispose();
    _maxPeopleController.dispose();
    _minPeopleController.dispose();
    _includedController.dispose();
    _excludedController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _thumbnailImage = File(image.path));
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) setState(() => _galleryImages.addAll(images.map((img) => File(img.path))));
  }

  void _removeGalleryImage(int index) => setState(() => _galleryImages.removeAt(index));

  void _addIncluded() {
    final item = _includedController.text.trim();
    if (item.isNotEmpty && !_included.contains(item)) {
      setState(() {
        _included.add(item);
        _includedController.clear();
      });
    }
  }

  void _removeIncluded(int index) => setState(() => _included.removeAt(index));

  void _addExcluded() {
    final item = _excludedController.text.trim();
    if (item.isNotEmpty && !_excluded.contains(item)) {
      setState(() {
        _excluded.add(item);
        _excludedController.clear();
      });
    }
  }

  void _removeExcluded(int index) => setState(() => _excluded.removeAt(index));

  void _addSchedule() {
    showDialog(
      context: context,
      builder: (ctx) => _ScheduleDialog(
        onSave: (schedule) => setState(() => _schedules.add(schedule)),
      ),
    );
  }

  void _editSchedule(int index) {
    showDialog(
      context: context,
      builder: (ctx) => _ScheduleDialog(
        schedule: _schedules[index],
        onSave: (updated) => setState(() => _schedules[index] = updated),
      ),
    );
  }

  void _removeSchedule(int index) => setState(() => _schedules.removeAt(index));

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnailImage == null && !_isEdit) {
      _showSnackBar('Vui lòng chọn ảnh thumbnail', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = FormData();

      // Text fields
      formData.fields.addAll([
        MapEntry('name', _nameController.text.trim()),
        MapEntry('description', _descriptionController.text.trim()),
        MapEntry('durationDays', _durationDaysController.text.trim()),
        MapEntry('durationNights', _durationNightsController.text.trim()),
        MapEntry('pricePerPerson', _priceController.text.trim()),
        MapEntry('maxPeople', _maxPeopleController.text.trim()),
        MapEntry('minPeople', _minPeopleController.text.trim()),
        MapEntry('homestayId', widget.homestayId.toString()),
      ]);

      // Included
      for (int i = 0; i < _included.length; i++) {
        formData.fields.add(MapEntry('included[$i]', _included[i]));
      }

      // Excluded
      for (int i = 0; i < _excluded.length; i++) {
        formData.fields.add(MapEntry('excluded[$i]', _excluded[i]));
      }

      // Schedules
      for (int i = 0; i < _schedules.length; i++) {
        final s = _schedules[i];
        formData.fields.addAll([
          MapEntry('schedules[$i].dayNumber', s['dayNumber'].toString()),
          MapEntry('schedules[$i].title', s['title']),
          MapEntry('schedules[$i].activities', s['activities']),
          MapEntry('schedules[$i].accommodation', s['accommodation'] ?? ''),
        ]);

        final meals = List<String>.from(s['meals'] ?? []);
        for (int j = 0; j < meals.length; j++) {
          formData.fields.add(MapEntry('schedules[$i].meals[$j]', meals[j]));
        }
      }

      // Thumbnail
      if (_thumbnailImage != null) {
        formData.files.add(MapEntry('thumbnail', await MultipartFile.fromFile(_thumbnailImage!.path)));
      }

      // Gallery images
      for (var image in _galleryImages) {
        formData.files.add(MapEntry('images', await MultipartFile.fromFile(image.path)));
      }

      if (_isEdit) {
        // Thêm 2 field này khi update
        formData.fields.add(MapEntry('syncGalleryImages', 'true'));

        // Gửi danh sách ảnh cũ cần giữ lại
        for (final existingUrl in _existingGalleryImages) {
          formData.fields.add(MapEntry('keepImageUrls', existingUrl));
        }

        await _tourService.updateTour(widget.tour!['id'], formData);
      } else {
        await _tourService.createTour(formData);
      }

      _showSnackBar(_isEdit ? 'Cập nhật tour thành công' : 'Tạo tour thành công', AppColors.green);
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      _showSnackBar('Lỗi: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Chỉnh sửa Tour' : 'Thêm Tour Mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      _buildTextField(_nameController, 'Tên tour', Icons.title),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Mô tả', Icons.description, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_durationDaysController, 'Số ngày', Icons.calendar_today, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_durationNightsController, 'Số đêm', Icons.nightlight, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_priceController, 'Giá/người (VNĐ)', Icons.attach_money, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_maxPeopleController, 'Max người', Icons.group, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_minPeopleController, 'Min người', Icons.people, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),

                      // Included
                      _buildListSection('Bao gồm', _included, _includedController, _addIncluded, _removeIncluded),
                      const SizedBox(height: 16),

                      // Excluded
                      _buildListSection('Không bao gồm', _excluded, _excludedController, _addExcluded, _removeExcluded),
                      const SizedBox(height: 16),

                      // Schedules
                      _buildScheduleSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isEdit ? 'Cập nhật' : 'Thêm mới'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Ảnh đại diện
        const Text('Ảnh đại diện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickThumbnail,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: _thumbnailImage != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_thumbnailImage!, fit: BoxFit.cover))
                : (_isEdit && widget.tour?['thumbnail'] != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.tour!['thumbnail'], fit: BoxFit.cover))
                : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.cloud_upload, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Chọn ảnh đại diện', style: TextStyle(color: Colors.grey[600])),
            ]))),
          ),
        ),
        const SizedBox(height: 12),

        // Ảnh bộ sưu tập
        const Text('Ảnh bộ sưu tập', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),

        //HIỂN THỊ CẢ ẢNH CŨ VÀ ẢNH MỚI
        GestureDetector(
          onTap: _pickGalleryImages,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: (_existingGalleryImages.isNotEmpty || _galleryImages.isNotEmpty)
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingGalleryImages.length + _galleryImages.length,
              itemBuilder: (context, index) {
                // Ảnh cũ ở đầu, ảnh mới ở sau
                if (index < _existingGalleryImages.length) {
                  final imageUrl = _existingGalleryImages[index];
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _existingGalleryImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  final imageIndex = index - _existingGalleryImages.length;
                  final imageFile = _galleryImages[imageIndex];
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(imageFile),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _galleryImages.removeAt(imageIndex);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Chọn ảnh bộ sưu tập', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items, TextEditingController controller, VoidCallback onAdd, Function(int) onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nhập nội dung...', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onAdd, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Icon(Icons.add, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: items.asMap().entries.map((entry) {
          return Chip(label: Text(entry.value), onDeleted: () => onRemove(entry.key), deleteIcon: const Icon(Icons.close, size: 16));
        }).toList()),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch trình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: _addSchedule, icon: const Icon(Icons.add), label: const Text('Thêm lịch trình'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schedules.length,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('Ngày ${_schedules[index]['dayNumber']}: ${_schedules[index]['title']}'),
              subtitle: Text(_schedules[index]['activities']),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editSchedule(index)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeSchedule(index)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập $label' : null,
    );
  }
}

// Dialog thêm/sửa lịch trình
class _ScheduleDialog extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final Function(Map<String, dynamic>) onSave;

  const _ScheduleDialog({this.schedule, required this.onSave});

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dayNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _activitiesController = TextEditingController();
  final _accommodationController = TextEditingController();
  final List<String> _meals = [];
  final _mealController = TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.schedule != null;
    if (_isEdit) {
      _dayNumberController.text = widget.schedule!['dayNumber']?.toString() ?? '';
      _titleController.text = widget.schedule!['title'] ?? '';
      _activitiesController.text = widget.schedule!['activities'] ?? '';
      _accommodationController.text = widget.schedule!['accommodation'] ?? '';
      _meals.addAll(List<String>.from(widget.schedule!['meals'] ?? []));
    }
  }

  void _addMeal() {
    final meal = _mealController.text.trim();
    if (meal.isNotEmpty && !_meals.contains(meal)) {
      setState(() { _meals.add(meal); _mealController.clear(); });
    }
  }

  void _removeMeal(int index) => setState(() => _meals.removeAt(index));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'dayNumber': int.parse(_dayNumberController.text),
      'title': _titleController.text.trim(),
      'activities': _activitiesController.text.trim(),
      'accommodation': _accommodationController.text.trim(),
      'meals': _meals,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Chỉnh sửa lịch trình' : 'Thêm lịch trình'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(controller: _dayNumberController, decoration: const InputDecoration(labelText: 'Ngày thứ'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Nhập số ngày' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tiêu đề'), validator: (v) => v?.isEmpty == true ? 'Nhập tiêu đề' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _activitiesController, decoration: const InputDecoration(labelText: 'Hoạt động'), maxLines: 3),
                const SizedBox(height: 12),
                TextFormField(controller: _accommodationController, decoration: const InputDecoration(labelText: 'Nơi ở')),
                const SizedBox(height: 12),
                const Text('Bữa ăn', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  Expanded(child: TextField(controller: _mealController, decoration: const InputDecoration(hintText: 'Thêm bữa ăn...'))),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _addMeal, child: const Icon(Icons.add)),
                ]),
                Wrap(spacing: 8, children: _meals.asMap().entries.map((entry) => Chip(label: Text(entry.value), onDeleted: () => _removeMeal(entry.key))).toList()),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Lưu')),
      ],
    );
  }
}