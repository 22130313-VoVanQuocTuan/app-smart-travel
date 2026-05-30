// lib/presentation/screens/user/user_booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/user/user_booking_model.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_event.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_state.dart';
import 'package:smart_travel/presentation/screens/user/qr_display_screen.dart';
import 'package:smart_travel/presentation/screens/user/review_dialog.dart';
import 'package:smart_travel/domain/repositories/review_repository.dart';
import 'package:smart_travel/injection_container.dart' as di;

class UserBookingDetailScreen extends StatefulWidget {
  final UserBooking booking;

  const UserBookingDetailScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<UserBookingDetailScreen> createState() => _UserBookingDetailScreenState();
}

class _UserBookingDetailScreenState extends State<UserBookingDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserReviewedHotel();
  }

  Future<void> _checkIfUserReviewedHotel() async {
    if (widget.booking.status != 'COMPLETED') {
      return; // Only check for completed bookings
    }

    try {
      // Get review repository from service locator
      final reviewRepository = di.sl<ReviewRepository>();
      final hasReviewed = await reviewRepository.checkIfUserReviewedHotel(
        hotelId: widget.booking.hotelId,
      );
      
      if (mounted) {
        setState(() => _hasReviewed = hasReviewed);
      }
    } catch (e) {
      // If error checking, allow review (safer approach)
      if (mounted) {
        setState(() => _hasReviewed = false);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canCancel {
    return widget.booking.status == 'PENDING' || widget.booking.status == 'CONFIRMED';
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Gọi API lấy policy khi dialog mở
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserBookingBloc>().add(GetCancellationPolicyEvent(widget.booking.id));
          });

          return AlertDialog(
            title: const Text('Xác nhận hủy booking'),
            content: BlocConsumer<UserBookingBloc, UserBookingState>(
              listener: (context, state) {
                if (state is BookingCancelled) {
                  Navigator.pop(context); // Đóng dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Quay lại màn hình danh sách
                } else if (state is UserBookingError) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CancellationPolicyLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is CancellationPolicyLoaded) {
                  final policy = state.policy;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông báo chính sách
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: policy.canCancel ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: policy.canCancel ? Colors.green[200]! : Colors.red[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              policy.canCancel ? Icons.info_outline : Icons.warning_amber,
                              color: policy.canCancel ? Colors.green[700] : Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                policy.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: policy.canCancel ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Thông tin chi tiết
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Thông tin chính sách hủy:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            _buildPolicyRow(
                              'Thời hạn hủy',
                              'Trước ${policy.cancelBeforeHours} giờ so với giờ nhận phòng',
                            ),
                            _buildPolicyRow(
                              'Hạn cuối hủy',
                              policy.cancelDeadline,
                            ),
                            if (policy.cancellationFeePercent > 0) ...[
                              _buildPolicyRow(
                                'Phí hủy',
                                '${policy.cancellationFeePercent.toStringAsFixed(0)}% giá trị booking',
                              ),
                              _buildPolicyRow(
                                'Phí ước tính',
                                '${NumberFormat('#,###').format(policy.estimatedCancellationFee)}₫',
                                isHighlight: true,
                              ),
                            ] else ...[
                              _buildPolicyRow(
                                'Phí hủy',
                                'Miễn phí',
                                isHighlight: true,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (policy.canCancel) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Lý do hủy (không bắt buộc):',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập lý do hủy...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  );
                } else if (state is UserBookingError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<UserBookingBloc>().add(GetCancellationPolicyEvent(widget.booking.id));
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }

                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
              BlocBuilder<UserBookingBloc, UserBookingState>(
                builder: (context, state) {
                  if (state is CancellationPolicyLoaded && state.policy.canCancel) {
                    return ElevatedButton(
                      onPressed: () {
                        final reason = _reasonController.text.trim();
                        context.read<UserBookingBloc>().add(
                          CancelUserBookingWithReasonEvent(
                            bookingId: widget.booking.id,
                            reason: reason.isEmpty ? 'Khách hàng yêu cầu hủy' : reason,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Xác nhận hủy'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPolicyRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.teal[700] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Booking'),
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.teal[400]!],
            ),
          ),
        ),
        actions: [
          if (widget.booking.status == 'COMPLETED')
            IconButton(
              icon: Icon(
                _hasReviewed ? Icons.star : Icons.star_outline,
                color: _hasReviewed ? Colors.amber : null,
              ),
              onPressed: _hasReviewed
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn đã đánh giá homestay này rồi 👍'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  : () {
                      showDialog(
                        context: context,
                        builder: (_) => ReviewDialog(
                          bookingId: widget.booking.id,
                          hotelName: widget.booking.hotelName,
                          onSubmit: () {
                            // After successful review, update state
                            setState(() => _hasReviewed = true);
                          },
                        ),
                      );
                    },
              tooltip: _hasReviewed ? 'Đã đánh giá' : 'Đánh giá homestay',
            ),
          if (_canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _showCancelDialog,
              tooltip: 'Hủy booking',
            ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QRDisplayScreen(
                    invoiceNumber: 'INV-${widget.booking.id}',
                    bookingId: widget.booking.id,
                    itemName: widget.booking.hotelName,
                  ),
                ),
              );
            },
            tooltip: 'Xem QR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHotelCard(),
            const SizedBox(height: 16),
            _buildBookingInfoCard(),
            const SizedBox(height: 16),
            _buildPriceCard(),
            const SizedBox(height: 16),
            _buildContactCard(),
            if (widget.booking.cancellationReason != null) ...[
              const SizedBox(height: 16),
              _buildCancelReasonCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.hotel, size: 40, color: Colors.teal[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.hotelName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.roomTypeName ?? 'Phòng',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(widget.booking.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = widget.booking.endDate.difference(widget.booking.startDate).inDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đặt phòng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow('Mã đơn', 'BK${widget.booking.id}'),
            _buildInfoRow('Ngày nhận', dateFormat.format(widget.booking.startDate)),
            _buildInfoRow('Ngày trả', dateFormat.format(widget.booking.endDate)),
            _buildInfoRow('Số đêm', '$nights đêm'),
            _buildInfoRow('Số phòng', '${widget.booking.numberOfRooms}'),
            _buildInfoRow('Số khách', '${widget.booking.numberOfPeople}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildPriceRow('Tổng tiền', widget.booking.totalPrice),
            if (widget.booking.discountAmount > 0)
              _buildPriceRow('Giảm giá', -widget.booking.discountAmount, isDiscount: true),
            const Divider(height: 20),
            _buildPriceRow('Thành tiền', widget.booking.finalPrice, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin liên hệ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow('Địa chỉ', widget.booking.hotelAddress),
            _buildInfoRow('Số điện thoại', widget.booking.hotelPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, size: 20, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  'Lý do hủy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.booking.cancellationReason ?? 'Không có lý do',
              style: TextStyle(fontSize: 13, color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${formatter.format(amount.abs())}₫',
            style: TextStyle(
              color: isDiscount ? Colors.red : (isTotal ? Colors.teal[700] : Colors.black87),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'CONFIRMED':
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case 'CHECKED_IN':
        color = Colors.green;
        label = 'Đã nhận phòng';
        break;
      case 'COMPLETED':
        color = Colors.teal;
        label = 'Hoàn thành';
        break;
      case 'CANCELLED':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}