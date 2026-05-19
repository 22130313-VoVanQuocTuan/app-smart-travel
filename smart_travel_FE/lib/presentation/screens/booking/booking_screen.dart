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
  Map<int, DateTime> _selectedTourDates = {};

  @override
  void initState() {
    super.initState();
    _initDefaultValues();
    _checkRoomAvailability();
  }

  void _initDefaultValues() {
    _numberOfPeople = widget.args.roomCapacity;
    _numberOfRooms = 1;

    final today = DateTime.now();
    for (var tour in widget.args.selectedTours ?? []) {
      _selectedTourDates[tour.id] = today.add(const Duration(days: 1));
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        int tempRooms = _numberOfRooms;
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Số lượng phòng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => tempRooms--),
                        icon: const Icon(Icons.remove_circle, size: 32),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 20),
                      Container(width: 60, alignment: Alignment.center,
                          child: Text('$tempRooms', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setModalState(() => tempRooms++),
                        icon: const Icon(Icons.add_circle, size: 32),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Tối đa $_maxAvailableRooms phòng', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Xác nhận',
                    onPressed: () {
                      setState(() => _numberOfRooms = tempRooms);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPeopleQuantityModal() {
    if (_dateRange == null) {
      _showSnackBar('Vui lòng chọn thời gian lưu trú trước');
      return;
    }

    final roomCapacity = widget.args.roomCapacity;
    final maxPeople = roomCapacity * _numberOfRooms;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        int tempPeople = _numberOfPeople;
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Số lượng người", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => tempPeople--),
                        icon: const Icon(Icons.remove_circle, size: 32),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 20),
                      Container(width: 60, alignment: Alignment.center,
                          child: Text('$tempPeople', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setModalState(() => tempPeople++),
                        icon: const Icon(Icons.add_circle, size: 32),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Tối đa $maxPeople người ($roomCapacity người/phòng)', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Xác nhận',
                    onPressed: () {
                      setState(() => _numberOfPeople = tempPeople);
                      Navigator.pop(ctx);
                    },
                  ),
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
            title: const Text("Lưu ý", style: TextStyle(color: Colors.orange)),
            content: Text(
              "Voucher giảm ${NumberFormat('#,###').format(result.discountAmount)}đ lớn hơn giá trị đơn hàng (${NumberFormat('#,###').format(currentTotal)}đ).\n\n"
                  "Nếu áp dụng, bạn sẽ KHÔNG được hoàn lại phần tiền thừa.\nBạn có chắc chắn muốn dùng?",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Chọn mã khác")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Vẫn dùng"),
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
        colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.textGray),
      ),
      child: child!,
    );
  }

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Homestay'),
        elevation: 0,
        foregroundColor: AppColors.textGray,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
      ),
      backgroundColor: AppColors.background,
      body: _buildBookingForm(),
    );
  }

  Widget _buildBookingForm() {
    final formatter = NumberFormat('#,###');
    final tours = widget.args.selectedTours ?? [];
    final roomCapacity = widget.args.roomCapacity;
    final maxPeople = roomCapacity * _numberOfRooms;

    final totalPrice = _calculateTotalPrice();
    final tourTotalPrice = _calculateTourTotalPrice();
    double finalPrice = totalPrice - _discountAmount;
    if (finalPrice < 0) finalPrice = 0;

    final isRoomAvailable = _maxAvailableRooms > 0;
    final canProceed = _dateRange != null && isRoomAvailable && _roomError == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.args.imageUrl,
              width: double.infinity, height: 200, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.args.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textGray)),
          const SizedBox(height: 8),
          _buildInfoRow(icon: Icons.monetization_on_outlined, title: 'Đơn giá', value: '${formatter.format(widget.args.price)} VND / đêm'),
          const SizedBox(height: 24),
          const Text('Chi tiết đặt chỗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray)),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.date_range, title: 'Thời gian lưu trú',
            value: _dateRange == null ? "Chọn ngày" : "${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}",
            isSelectable: true, onTap: _handleDateSelection,
          ),
          const SizedBox(height: 16),

          if (_isCheckingRooms)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildInfoRow(
              icon: Icons.bedroom_parent_outlined, title: 'Số lượng phòng',
              value: '$_numberOfRooms phòng (tối đa $_maxAvailableRooms)',
              isSelectable: true, onTap: _showRoomQuantityModal,
            ),
            if (_roomError != null) Padding(padding: const EdgeInsets.only(top: 4, left: 32),
                child: Text(_roomError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          ],
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.people_outline, title: 'Số lượng người/phòng',
            value: '$_numberOfPeople người (tối đa $maxPeople)',
            isSelectable: true, onTap: _showPeopleQuantityModal,
          ),
          if (_numberOfPeople > maxPeople) Padding(padding: const EdgeInsets.only(top: 4, left: 32),
              child: Text('⚠️ Số người vượt quá sức chứa ($roomCapacity người/phòng)', style: const TextStyle(color: Colors.red, fontSize: 12))),
          const SizedBox(height: 16),

          if (tours.isNotEmpty) _buildTourSection(tours, formatter, tourTotalPrice),
          _buildVoucherSection(),
          const SizedBox(height: 32),

          _buildPriceDetailRow('Tiền phòng', '${formatter.format(totalPrice - tourTotalPrice)} VND'),
          if (tours.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildPriceDetailRow('Tiền tour', '${formatter.format(tourTotalPrice)} VND'),
          ],
          const SizedBox(height: 8),
          if (_discountAmount > 0) _buildPriceDetailRow('Giảm giá', '- ${formatter.format(_discountAmount)} VND', color: Colors.green),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray)),
              Text('${formatter.format(finalPrice)} VND', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: 'Tiến hành Thanh toán',
            onPressed: (canProceed && _numberOfPeople <= maxPeople) ? () {
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
                selectedTours: tours.map((tour) => TourBookingData(
                  tourId: tour.id,
                  tourName: tour.name,
                  pricePerPerson: tour.pricePerPerson,
                  tourDate: _selectedTourDates[tour.id] ?? _dateRange!.start,
                  numberOfPeople: _numberOfPeople,
                )).toList(),
              );
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(bookingInfo: bookingInfo)));
            } : null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTourSection(List<TourBrief> tours, NumberFormat formatter, double tourTotalPrice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tour, color: AppColors.primary, size: 20), const SizedBox(width: 8),
            const Text("Tour đi kèm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text("${formatter.format(tourTotalPrice)} VND", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          ...tours.map((tour) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.circle, size: 6, color: Colors.grey), const SizedBox(width: 8),
                  Expanded(child: Text(tour.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text("${formatter.format(tour.pricePerPerson * _numberOfPeople)} VND", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ]),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(left: 14),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 8),
                    const Text("Ngày tham gia:", style: TextStyle(fontSize: 13, color: Colors.grey)), const SizedBox(width: 8),
                    Text(DateFormat('dd/MM/yyyy').format(_selectedTourDates[tour.id] ?? DateTime.now()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _dateRange == null ? null : () => _selectTourDate(tour),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: const Size(40, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text("Chọn ngày", style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),
                const Divider(height: 24),
              ],
            ),
          )),
          const SizedBox(height: 4),
          Text("* Số lượng người tham gia tour bằng với số người đặt phòng ($_numberOfPeople người)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _couponController, enabled: !_isVoucherApplied,
            decoration: InputDecoration(
              labelText: 'Mã giảm giá', filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.confirmation_number_outlined, color: Colors.orange),
                tooltip: "Chọn Voucher của bạn",
                onPressed: _isVoucherApplied ? null : _openVoucherModal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isVoucherApplied
                ? () => setState(() { _isVoucherApplied = false; _discountAmount = 0; _couponController.clear(); })
                : (_isCheckingVoucher ? null : _checkCoupon),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVoucherApplied ? Colors.red.shade100 : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isCheckingVoucher
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isVoucherApplied ? "Hủy" : "Áp dụng"),
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value, bool isSelectable = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: isSelectable ? onTap : null, borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 12),
          Text('$title:', style: TextStyle(fontSize: 16, color: AppColors.textGray)), const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textGray), textAlign: TextAlign.right)),
          if (isSelectable) const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildPriceDetailRow(String title, String value, {double fontSize = 16, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700)),
        Text(value, style: TextStyle(fontSize: fontSize, color: color ?? AppColors.textGray, fontWeight: color != null ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}