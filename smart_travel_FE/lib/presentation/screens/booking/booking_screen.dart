// lib/presentation/screens/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';
import 'package:smart_travel/domain/entities/voucher.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/screens/payment/payment_screen.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/presentation/widgets/common/custom_button.dart';
import 'package:smart_travel/presentation/screens/booking/booking_args.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_state.dart';
import 'package:smart_travel/service/room_service.dart';
import 'voucher_selection_modal.dart';

class BookingScreen extends StatefulWidget {
  final BookingArgs args;

  const BookingScreen({Key? key, required this.args}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _couponController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat('#,###');
  double _taxRate = 0;

  // State cho Hotel
  DateTimeRange? _dateRange;
  int _numberOfPeople = 1;
  int _numberOfRooms = 1;

  // State cho Voucher
  double _discountAmount = 0;
  bool _isCheckingVoucher = false;
  bool _isVoucherApplied = false;

  // State cho Room Availability
  int _maxAvailableRooms = 0;
  bool _isCheckingRooms = false;
  String? _roomError;

  // State cho Tour
  final Map<int, DateTime> _selectedTourDates = {};

  @override
  void initState() {
    super.initState();
    _initDefaultValues();
    _loadSystemTaxRate();
    _checkRoomAvailability();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _initDefaultValues() {
    _numberOfPeople = widget.args.roomCapacity;
    _numberOfRooms = 1;

    final today = DateTime.now();
    for (var tour in widget.args.selectedTours ?? []) {
      _selectedTourDates[tour.id] = today.add(const Duration(days: 1));
    }
  }

  Future<void> _loadSystemTaxRate() async {
    try {
      final response = await context.read<DioClient>().get('/system-config');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawTaxRate = data['tax_rate'] ?? data['taxRate'] ?? 0;
        final taxRate = rawTaxRate is num
            ? rawTaxRate.toDouble()
            : double.tryParse(rawTaxRate.toString()) ?? 0;

        if (!mounted) return;
        setState(() {
          _taxRate = taxRate;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _taxRate = 0;
      });
    }
  }

  Future<void> _checkRoomAvailability() async {
    if (_dateRange == null || widget.args.roomTypeId == null) return;

    setState(() {
      _isCheckingRooms = true;
      _roomError = null;
    });

    try {
      final roomService = RoomService(context.read<DioClient>());
      final available = await roomService.getAvailableRooms(
        roomTypeId: widget.args.roomTypeId!,
        checkIn: _dateRange!.start,
        checkOut: _dateRange!.end,
      );

      setState(() {
        _maxAvailableRooms = available;
        _isCheckingRooms = false;

        if (_numberOfRooms > _maxAvailableRooms) {
          _numberOfRooms = _maxAvailableRooms > 0 ? _maxAvailableRooms : 1;
          if (_maxAvailableRooms == 0) {
            _roomError = 'Phòng đã hết trống trong khoảng thời gian này';
          }
        }
      });
    } catch (e) {
      setState(() {
        _roomError = e.toString();
        _isCheckingRooms = false;
      });
    }
  }

  double _calculateTotalPrice() {
    double total = 0;
    int nights = 1;

    if (_dateRange != null) {
      nights = _dateRange!.end.difference(_dateRange!.start).inDays;
      if (nights < 1) nights = 1;
    }
    total = widget.args.price * _numberOfRooms * nights;

    for (var tour in widget.args.selectedTours ?? []) {
      total += tour.pricePerPerson * _numberOfPeople;
    }

    return total;
  }

  double _calculateTourTotalPrice() {
    double total = 0;
    for (var tour in widget.args.selectedTours ?? []) {
      total += tour.pricePerPerson * _numberOfPeople;
    }
    return total;
  }

  void _updateTourDate(int tourId, DateTime newDate) {
    setState(() {
      _selectedTourDates[tourId] = newDate;
    });
  }

  bool _isDateInStayRange(DateTime date) {
    if (_dateRange == null) return true;
    return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
  }

  void _showRoomQuantityModal() {
    if (_dateRange == null) {
      _showSnackBar('Vui lòng chọn thời gian lưu trú trước');
      return;
    }

    if (_maxAvailableRooms == 0) {
      _showSnackBar('Hiện không còn phòng trống trong khoảng thời gian này');
      return;
    }

    _showQuantitySelectionModal(
      title: "Số lượng phòng",
      initialValue: _numberOfRooms,
      maxValue: _maxAvailableRooms,
      subtitle: 'Tối đa $_maxAvailableRooms phòng',
      onConfirm: (val) => setState(() => _numberOfRooms = val),
    );
  }

  void _showPeopleQuantityModal() {
    if (_dateRange == null) {
      _showSnackBar('Vui lòng chọn thời gian lưu trú trước');
      return;
    }

    final roomCapacity = widget.args.roomCapacity;
    final maxPeople = roomCapacity * _numberOfRooms;

    _showQuantitySelectionModal(
      title: "Số lượng người",
      initialValue: _numberOfPeople,
      maxValue: maxPeople,
      subtitle: 'Tối đa $maxPeople người ($roomCapacity người/phòng)',
      onConfirm: (val) => setState(() => _numberOfPeople = val),
    );
  }

  void _showQuantitySelectionModal({
    required String title,
    required int initialValue,
    required int maxValue,
    required String subtitle,
    required Function(int) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int tempValue = initialValue;
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempValue > 1 ? () => setModalState(() => tempValue--) : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        color: AppColors.primary,
                        disabledColor: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$tempValue',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: tempValue < maxValue ? () => setModalState(() => tempValue++) : null,
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        color: AppColors.primary,
                        disabledColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Xác nhận',
                    onPressed: () {
                      onConfirm(tempValue);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openVoucherModal() async {
    final profileState = context.read<ProfileBloc>().state;
    int? userId;
    if (profileState is ProfileLoaded) userId = profileState.user.id;
    else if (profileState is ProfileUpdateSuccess) userId = profileState.user.id;

    if (userId == null) {
      _showSnackBar('Vui lòng đăng nhập để dùng voucher');
      return;
    }

    final Voucher? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherSelectionModal(userId: userId!),
    );

    if (result != null) {
      double currentTotal = _calculateTotalPrice();

      if (result.discountAmount > currentTotal) {
        bool? confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text("Lưu ý"),
              ],
            ),
            content: Text(
              "Voucher giảm ${_currencyFormatter.format(result.discountAmount)}đ lớn hơn giá trị đơn hàng (${_currencyFormatter.format(currentTotal)}đ).\n\n"
                  "Nếu áp dụng, bạn sẽ KHÔNG được hoàn lại phần tiền thừa.\nBạn có chắc chắn muốn dùng?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Chọn mã khác", style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Vẫn dùng", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }

      setState(() {
        _couponController.text = result.code;
        _discountAmount = result.discountAmount.toDouble();
        _isVoucherApplied = true;
      });
      _showSnackBar('Đã áp dụng mã: ${result.code}', Colors.green);
    }
  }

  Future<void> _checkCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isCheckingVoucher = true);

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/api/v1/vouchers/check',
        queryParameters: {'code': code},
      );

      if (response.statusCode == 200) {
        setState(() {
          _discountAmount = response.data['discountAmount'];
          _isVoucherApplied = true;
        });
        _showSnackBar('Áp dụng mã thành công!', Colors.green);
      }
    } catch (e) {
      String msg = "Mã không hợp lệ hoặc đã hết hạn";
      if (e is DioException && e.response != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      _showSnackBar(msg, Colors.red);
      setState(() {
        _discountAmount = 0;
        _isVoucherApplied = false;
      });
    } finally {
      setState(() => _isCheckingVoucher = false);
    }
  }

  Future<void> _handleDateSelection() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) => _buildThemePicker(context, child),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      await _checkRoomAvailability();

      for (var tour in widget.args.selectedTours ?? []) {
        final currentDate = _selectedTourDates[tour.id] ?? picked.start;
        if (!_isDateInStayRange(currentDate)) {
          _selectedTourDates[tour.id] = picked.start;
        }
      }
    }
  }

  Future<void> _selectTourDate(TourBrief tour) async {
    final firstDate = _dateRange?.start ?? DateTime.now();
    final lastDate = _dateRange?.end ?? DateTime.now().add(const Duration(days: 30));
    final currentDate = _selectedTourDates[tour.id] ?? firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => _buildThemePicker(context, child),
    );
    if (picked != null) _updateTourDate(tour.id, picked);
  }

  Widget _buildThemePicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          onSurface: AppColors.textGray,
        ),
      ),
      child: child!,
    );
  }

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToPayment(List<TourBrief> tours) {
    final profileState = context.read<ProfileBloc>().state;
    int userId = 0;
    if (profileState is ProfileLoaded) {
      userId = profileState.user.id;
    } else if (profileState is ProfileUpdateSuccess) {
      userId = profileState.user.id;
    }
    if (userId == 0) {
      _showSnackBar('Vui lòng đăng nhập lại');
      return;
    }
    final bookingInfo = BookingInfo(
      homestayId: widget.args.id,
      roomTypeId: widget.args.roomTypeId,
      userId: userId,
      pricePerNight: widget.args.price,
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      numberOfPeople: _numberOfPeople,
      numberOfRooms: _numberOfRooms,
      couponCode: _isVoucherApplied ? _couponController.text.trim() : null,
      discountAmount: _discountAmount,
      taxRate: _taxRate,
      selectedTours: tours.map((tour) => TourBookingData(
        tourId: tour.id,
        tourName: tour.name,
        pricePerPerson: tour.pricePerPerson,
        tourDate: _selectedTourDates[tour.id] ?? _dateRange!.start,
        numberOfPeople: _numberOfPeople,
      )).toList(),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(bookingInfo: bookingInfo)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Homestay', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textGray,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
      ),
      backgroundColor: AppColors.background,
      body: _buildBookingForm(),
    );
  }

  Widget _buildBookingForm() {
    final tours = widget.args.selectedTours ?? [];
    final roomCapacity = widget.args.roomCapacity;
    final maxPeople = roomCapacity * _numberOfRooms;

    final totalPrice = _calculateTotalPrice();
    final tourTotalPrice = _calculateTourTotalPrice();
    double finalPrice = totalPrice - _discountAmount;
    if (finalPrice < 0) finalPrice = 0;
    final taxAmount = finalPrice * _taxRate / 100;
    final totalWithTax = finalPrice + taxAmount;

    final isRoomAvailable = _maxAvailableRooms > 0;
    final canProceed = _dateRange != null && isRoomAvailable && _roomError == null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  widget.args.imageUrl,
                  width: double.infinity, height: 220, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220, color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.args.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pricing Header Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildInfoRow(
                icon: Icons.monetization_on_outlined,
                title: 'Đơn giá phòng',
                value: '${_currencyFormatter.format(widget.args.price)} đ / đêm',
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Chi tiết đặt chỗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray)),
          const SizedBox(height: 12),

          // Main Config Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.date_range_outlined, title: 'Thời gian lưu trú',
                    value: _dateRange == null ? "Chọn ngày" : "${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}",
                    isSelectable: true, onTap: _handleDateSelection,
                  ),
                  const Divider(height: 1),
                  if (_isCheckingRooms)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    _buildInfoRow(
                      icon: Icons.bedroom_parent_outlined, title: 'Số lượng phòng',
                      value: _dateRange == null ? "Hãy chọn ngày trước" : '$_numberOfRooms phòng (Tối đa $_maxAvailableRooms)',
                      isSelectable: _dateRange != null, onTap: _showRoomQuantityModal,
                    ),
                    if (_roomError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 32),
                        child: Align(alignment: Alignment.centerLeft, child: Text(_roomError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ),
                  ],
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.people_outline, title: 'Số lượng khách',
                    value: _dateRange == null ? "Hãy chọn ngày trước" : '$_numberOfPeople người (Tối đa $maxPeople)',
                    isSelectable: _dateRange != null, onTap: _showPeopleQuantityModal,
                  ),
                  if (_numberOfPeople > maxPeople && _dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 32),
                      child: Align(alignment: Alignment.centerLeft, child: Text('⚠️ Vượt quá sức chứa ($roomCapacity người/phòng)', style: const TextStyle(color: Colors.red, fontSize: 12))),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tour & Voucher Section
          if (tours.isNotEmpty) _buildTourSection(tours, tourTotalPrice),
          const SizedBox(height: 8),
          _buildVoucherSection(),
          const SizedBox(height: 28),

          // Order Summary Card
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPriceDetailRow('Tiền phòng', '${_currencyFormatter.format(totalPrice - tourTotalPrice)} đ'),
                  if (tours.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPriceDetailRow('Tiền tour đi kèm', '${_currencyFormatter.format(tourTotalPrice)} đ'),
                  ],
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceDetailRow('Mã giảm giá', '- ${_currencyFormatter.format(_discountAmount)} đ', color: Colors.green),
                  ],
                  if (_taxRate > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceDetailRow(
                      'Thuế (${_taxRate.toStringAsFixed(_taxRate.truncateToDouble() == _taxRate ? 0 : 2)}%)',
                      '${_currencyFormatter.format(taxAmount)} đ',
                    ),
                  ],
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textGray)),
                      Text('${_currencyFormatter.format(totalWithTax)} đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          PrimaryButton(
            text: 'Tiến hành Thanh toán',
            onPressed: (canProceed && _numberOfPeople <= maxPeople) ? () => _navigateToPayment(tours) : null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTourSection(List<TourBrief> tours, double tourTotalPrice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tour_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text("Tour dịch vụ đi kèm", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text("${_currencyFormatter.format(tourTotalPrice)} đ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          ...tours.map((tour) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.lens, size: 6, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tour.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                  Text("${_currencyFormatter.format(tour.pricePerPerson * _numberOfPeople)} đ", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14)),
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text("Ngày tham gia:", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd/MM/yyyy').format(_selectedTourDates[tour.id] ?? DateTime.now()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: _dateRange == null ? null : () => _selectTourDate(tour),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Đổi ngày", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (tours.last != tour) Divider(height: 20, color: Colors.grey.shade200),
              ],
            ),
          )),
          const Divider(height: 24),
          Text(
            "* Số khách đặt tour tự động đồng bộ theo số lượng khách đặt phòng ($_numberOfPeople người)",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _couponController,
            enabled: !_isVoucherApplied,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Nhập mã giảm giá',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.orange, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                tooltip: "Chọn từ danh sách",
                onPressed: _isVoucherApplied ? null : _openVoucherModal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isVoucherApplied
                ? () => setState(() { _isVoucherApplied = false; _discountAmount = 0; _couponController.clear(); })
                : (_isCheckingVoucher ? null : _checkCoupon),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVoucherApplied ? Colors.red.shade50 : AppColors.primary,
              foregroundColor: _isVoucherApplied ? Colors.red : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: _isCheckingVoucher
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isVoucherApplied ? "Hủy" : "Áp dụng", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value, bool isSelectable = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: isSelectable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textGray)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelectable && value.contains("Chọn") ? AppColors.primary : AppColors.textGray,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (isSelectable) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.chevron_right, color: Colors.grey, size: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetailRow(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 14, color: color ?? AppColors.textGray, fontWeight: color != null ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
