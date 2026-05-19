// lib/presentation/screens/host/homestay/homestay_form_dialog.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_travel/domain/entities/destination.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/service/destination_service.dart';
import 'package:smart_travel/service/homestay_service.dart';

class HomestayFormDialog extends StatefulWidget {
  final Homestay? homestay;
  final VoidCallback? onSuccess;

  const HomestayFormDialog({
    super.key,
    this.homestay,
    this.onSuccess,
  });

  @override
  State<HomestayFormDialog> createState() => _HomestayFormDialogState();
}

class _HomestayFormDialogState extends State<HomestayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late HomestayService _homestayService;
  late DestinationService _destinationService;

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _starsController = TextEditingController();
  final _pricePerNightController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Dropdown and Image
  Destination? _selectedDestination;
  List<Destination> _destinations = [];
  File? _thumbnailImage;
  final List<String> _existingGalleryImages = [];
  List<File> _galleryImages = [];

  // Amenities
  final List<String> _amenities = [];
  final _amenityController = TextEditingController();

  // Room Types
  final List<Map<String, dynamic>> _roomTypes = [];

  bool _isLoading = false;
  bool _isEdit = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    _homestayService = HomestayService(dioClient);
    _destinationService = DestinationService(dioClient);
    _isEdit = widget.homestay != null;

    // Load destinations trước, sau đó mới load homestay data
    _loadDestinationsAndData();
  }

  Future<void> _loadDestinationsAndData() async {
    // Load destinations trước
    await _loadDestinations();
    // Sau đó load homestay data
    if (_isEdit && mounted) {
      await _loadHomestayData();
    }
  }


  Future<void> _loadDestinations() async {
    try {
      final destinations = await _destinationService.getAllDestinations();
      if (mounted) {
        setState(() {
          _destinations = destinations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách địa điểm: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadHomestayData() async {
    final homestay = widget.homestay!;
    _nameController.text = homestay.name?? "";
    _addressController.text = homestay.address?? "";
    _descriptionController.text = homestay.description ?? '';
    _phoneController.text = homestay.phone ?? '';
    _emailController.text = homestay.email ?? '';
    _starsController.text = homestay.stars.toString();
    _pricePerNightController.text = homestay.pricePerNight?.toString() ?? '';
    _latitudeController.text = homestay.latitude?.toString() ?? '';
    _longitudeController.text = homestay.longitude?.toString() ?? '';
    _amenities.addAll(homestay.amenities??[]);

    // Load danh sách loại phòng từ API
    await _loadRoomTypesFromApi();


    // Tìm destination theo ID
    if (homestay.destinationId != null && _destinations.isNotEmpty) {
      try {
        final matched = _destinations.firstWhere(
              (d) => d.id == homestay.destinationId,
          orElse: () => _destinations.first, // Nếu không tìm thấy thì lấy cái đầu
        );
        _selectedDestination = matched;
      } catch (e) {
        print('Error finding destination: $e');
        _selectedDestination = null;
      }
    }
  }


  Future<void> _loadRoomTypesFromApi() async {
    if (!_isEdit || widget.homestay == null) return;

    setState(() => _isLoading = true);
    try {
      // Gọi API get detail - trả về Homestay entity
      final homestayDetail = await _homestayService.getHomestayDetail(
        widget.homestay!.id,
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
      );
      // Lấy danh sách ảnh gallery (không bao gồm thumbnail)
      final existingImages = (homestayDetail.images ?? [])
          .where((url) => url.isNotEmpty && url != homestayDetail.thumbnail)
          .toList();

      // Lấy rooms từ homestayDetail
      final rooms = homestayDetail.rooms ?? [];
      final List<Map<String, dynamic>> loadedRoomTypes = [];

      for (var room in rooms) {
        loadedRoomTypes.add({
          'id': room.id.toString(),
          'name': room.name,
          'capacity': room.capacity,
          'price': room.price,
          'totalRooms': room.totalRooms,
          'amenities': room.amenities,
        });
      }

      setState(() {
        _roomTypes.clear();
        _roomTypes.addAll(loadedRoomTypes);
        _existingGalleryImages
          ..clear()
          ..addAll(existingImages);
        _updateMinPrice();
        _isLoading = false;
      });

      print('Loaded ${loadedRoomTypes.length} room types');
      print('Loaded ${existingImages.length} gallery images');
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading room types: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải loại phòng: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _starsController.dispose();
    _pricePerNightController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _amenityController.dispose();
    super.dispose();
  }

  // Chọn ảnh từ máy
  Future<void> _pickThumbnail() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _thumbnailImage = File(image.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      setState(() {
        _galleryImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
  }

  void _removeExistingGalleryImage(int index) {
    setState(() {
      _existingGalleryImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    // Auto-commit amenity text
    final pendingAmenity = _amenityController.text.trim();
    if (pendingAmenity.isNotEmpty && !_amenities.contains(pendingAmenity)) {
      _amenities.add(pendingAmenity);
      _amenityController.clear();
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa điểm'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_roomTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một loại phòng'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_thumbnailImage == null && !_isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh thumbnail'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo FormData để gửi cả file và JSON
      final formData = FormData();

      // Thêm text fields
      formData.fields.addAll([
        MapEntry('name', _nameController.text.trim()),
        MapEntry('address', _addressController.text.trim()),
        MapEntry('description', _descriptionController.text.trim()),
        MapEntry('phone', _phoneController.text.trim()),
        MapEntry('email', _emailController.text.trim()),
        MapEntry('stars', _starsController.text.trim()),
        MapEntry('latitude', _latitudeController.text.trim()),
        MapEntry('longitude', _longitudeController.text.trim()),
        MapEntry('destinationId', _selectedDestination!.id.toString()),
      ]);

      for (final amenity in _amenities) {
        formData.fields.add(MapEntry('amenities', amenity));
      }

      if (_isEdit) {
        formData.fields.add(const MapEntry('syncGalleryImages', 'true'));
        for (final existingUrl in _existingGalleryImages) {
          formData.fields.add(MapEntry('keepImageUrls', existingUrl));
        }
      }

      for (int i = 0; i < _roomTypes.length; i++) {
        final rt = _roomTypes[i];
        formData.fields.addAll([
          MapEntry('roomTypes[$i].name', rt['name']?.toString() ?? ''),
          MapEntry('roomTypes[$i].capacity', rt['capacity'].toString()),
          MapEntry('roomTypes[$i].price', rt['price'].toString()),
          MapEntry('roomTypes[$i].totalRooms', rt['totalRooms'].toString()),
        ]);

        final roomAmenities = (rt['amenities'] as List?)?.cast<String>() ?? const <String>[];
        for (int j = 0; j < roomAmenities.length; j++) {
          formData.fields.add(MapEntry('roomTypes[$i].amenities[$j]', roomAmenities[j]));
        }
      }

      // Thêm file thumbnail
      if (_thumbnailImage != null) {
        formData.files.add(MapEntry(
          'thumbnail',
          await MultipartFile.fromFile(_thumbnailImage!.path),
        ));
      }

      // Thêm gallery images
      for (var image in _galleryImages) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(image.path),
        ));
      }

      if (_isEdit) {
        await _homestayService.updateHomestayWithFiles(widget.homestay!.id, formData);
      } else {
        await _homestayService.createHomestayWithFiles(formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Cập nhật homestay thành công' : 'Tạo homestay thành công'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addAmenity() {
    final amenity = _amenityController.text.trim();
    if (amenity.isNotEmpty && !_amenities.contains(amenity)) {
      setState(() {
        _amenities.add(amenity);
        _amenityController.clear();
      });
    }
  }

  void _removeAmenity(int index) {
    setState(() {
      _amenities.removeAt(index);
    });
  }

  void _updateMinPrice() {
    if (_roomTypes.isEmpty) {
      _pricePerNightController.text = '';
      return;
    }

    double? minPrice;
    for (var rt in _roomTypes) {
      final price = rt['price'] as double?;
      if (price != null) {
        if (minPrice == null || price < minPrice) {
          minPrice = price;
        }
      }
    }

    if (minPrice != null) {
      _pricePerNightController.text = minPrice.toStringAsFixed(0);
    }
  }

  void _addRoomType() {
    showDialog(
      context: context,
      builder: (ctx) => _RoomTypeDialog(
        onSave: (roomType) {
          setState(() {
            _roomTypes.add(roomType);
            _updateMinPrice();
          });
        },
      ),
    );
  }

  void _editRoomType(int index) {
    final roomType = _roomTypes[index];
    showDialog(
      context: context,
      builder: (ctx) => _RoomTypeDialog(
        roomType: roomType,
        onSave: (updatedRoomType) {
          setState(() {
            _roomTypes[index] = updatedRoomType;
            _updateMinPrice();
          });
        },
      ),
    );
  }

  void _removeRoomType(int index) {
    setState(() {
      _roomTypes.removeAt(index);
      _updateMinPrice();
    });
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Chỉnh sửa Homestay' : 'Thêm Homestay Mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ẢNH
                      const Text('Hình ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Thumbnail
                      const Text('Ảnh đại diện (Thumbnail)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _pickThumbnail,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _thumbnailImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_thumbnailImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                              : (_isEdit && widget.homestay?.thumbnail != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.homestay!.thumbnail!, fit: BoxFit.cover, width: double.infinity),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Chọn ảnh đại diện', style: TextStyle(color: Colors.grey[600])),
                            ],
                          )),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Gallery Images
                      const Text('Ảnh bộ sưu tập', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _pickGalleryImages,
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _buildGalleryPreview(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thông tin cơ bản
                      const Text('Thông tin cơ bản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildTextField(_nameController, 'Tên homestay', Icons.home, validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên' : null),
                      const SizedBox(height: 12),
                      _buildTextField(_addressController, 'Địa chỉ', Icons.location_on, validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập địa chỉ' : null),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Mô tả', Icons.description, maxLines: 3),
                      const SizedBox(height: 12),

                      // Destination Dropdown
                      _buildDestinationDropdown(),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _buildTextField(_phoneController, 'Số điện thoại', Icons.phone)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_emailController, 'Email', Icons.email)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _starsController, 'Số sao (1-5)', Icons.star,
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.isEmpty == true ? 'Nhập số sao' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _pricePerNightController, 'Giá tham khảo (VNĐ)', Icons.attach_money,
                              keyboardType: TextInputType.number,
                              enabled: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _latitudeController, 'Latitude', Icons.map,
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.isEmpty == true ? 'Nhập latitude' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _longitudeController, 'Longitude', Icons.map,
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.isEmpty == true ? 'Nhập longitude' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amenities
                      const Text('Tiện ích', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amenityController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tiện ích (VD: WiFi, Parking...)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addAmenity,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _amenities.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String amenity = entry.value;
                          return Chip(
                            label: Text(amenity),
                            onDeleted: () => _removeAmenity(idx),
                            deleteIcon: const Icon(Icons.close, size: 16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Room Types
                      const Text('Loại phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addRoomType,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm loại phòng'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _roomTypes.length,
                        itemBuilder: (context, index) {
                          final rt = _roomTypes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(rt['name']),
                              subtitle: Text('SL: ${rt['totalRooms']} | Giá: ${rt['price']} VNĐ | Sức chứa: ${rt['capacity']} người'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editRoomType(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeRoomType(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Cập nhật' : 'Thêm mới'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationDropdown() {
    return DropdownButtonFormField<Destination>(
      isExpanded: true,
      key: ValueKey(_selectedDestination?.id),
      initialValue: _selectedDestination,
      decoration: InputDecoration(
        labelText: 'Địa điểm',
        prefixIcon: const Icon(Icons.tour, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _destinations.map((destination) {
        return DropdownMenuItem(
          value: destination,
          child: Text('${destination.name}${destination.province != null ? ' - ${destination.province}' : ''}'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedDestination = value),
      validator: (v) => v == null ? 'Vui lòng chọn địa điểm' : null,
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        bool enabled = true,
      }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildGalleryPreview() {
    if (_existingGalleryImages.isEmpty && _galleryImages.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Chọn ảnh bộ sưu tập', style: TextStyle(color: Colors.grey[600])),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_existingGalleryImages.isNotEmpty) ...[
              const Text('Ảnh hiện có', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingGalleryImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = _existingGalleryImages[index];
                    return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.network(
                              url,
                              width: 100,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 88,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                onPressed: () => _removeExistingGalleryImage(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_galleryImages.isNotEmpty) ...[
              if (_existingGalleryImages.isNotEmpty) const SizedBox(height: 8),
              const Text('Ảnh mới thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryImages.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_galleryImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          onPressed: () => _removeGalleryImage(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Dialog thêm/sửa loại phòng (giữ nguyên như cũ)
class _RoomTypeDialog extends StatefulWidget {
  final Map<String, dynamic>? roomType;
  final Function(Map<String, dynamic>) onSave;

  const _RoomTypeDialog({this.roomType, required this.onSave});

  @override
  State<_RoomTypeDialog> createState() => _RoomTypeDialogState();
}

class _RoomTypeDialogState extends State<_RoomTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final List<String> _amenities = [];
  final _amenityController = TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.roomType != null;
    if (_isEdit) {
      _nameController.text = widget.roomType!['name'] ?? '';
      _capacityController.text = widget.roomType!['capacity']?.toString() ?? '';
      _priceController.text = widget.roomType!['price']?.toString() ?? '';
      _totalRoomsController.text = widget.roomType!['totalRooms']?.toString() ?? '';
      _amenities.addAll(List<String>.from(widget.roomType!['amenities'] ?? []));
    }
  }

  void _addAmenity() {
    final amenity = _amenityController.text.trim();
    if (amenity.isNotEmpty && !_amenities.contains(amenity)) {
      setState(() {
        _amenities.add(amenity);
        _amenityController.clear();
      });
    }
  }

  void _removeAmenity(int index) {
    setState(() {
      _amenities.removeAt(index);
    });
  }

  void _save() {
    // Auto-commit room amenity text currently typed but not added yet.
    final pendingAmenity = _amenityController.text.trim();
    if (pendingAmenity.isNotEmpty && !_amenities.contains(pendingAmenity)) {
      _amenities.add(pendingAmenity);
      _amenityController.clear();
    }

    if (!_formKey.currentState!.validate()) return;

    final roomType = {
      'name': _nameController.text.trim(),
      'capacity': int.parse(_capacityController.text),
      'price': double.parse(_priceController.text),
      'totalRooms': int.parse(_totalRoomsController.text),
      'amenities': _amenities,
    };

    widget.onSave(roomType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Chỉnh sửa loại phòng' : 'Thêm loại phòng'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên loại phòng', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(labelText: 'Sức chứa (người)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập sức chứa' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Giá (VNĐ)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập giá' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalRoomsController,
                  decoration: const InputDecoration(labelText: 'Tổng số phòng', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập số phòng' : null,
                ),
                const SizedBox(height: 12),
                const Text('Tiện ích phòng', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amenityController,
                        decoration: const InputDecoration(hintText: 'Thêm tiện ích...', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addAmenity,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _amenities.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String amenity = entry.value;
                    return Chip(
                      label: Text(amenity),
                      onDeleted: () => _removeAmenity(idx),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    );
                  }).toList(),
                ),
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