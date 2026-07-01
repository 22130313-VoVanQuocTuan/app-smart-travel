import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/user/user_booking_model.dart';
import 'package:smart_travel/domain/repositories/review_repository.dart';
import 'package:smart_travel/injection_container.dart' as di;
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_event.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_state.dart';
import 'package:smart_travel/presentation/screens/invoice/cancel_booking_screen.dart';
import 'package:smart_travel/presentation/screens/user/qr_display_screen.dart';
import 'package:smart_travel/presentation/screens/user/review_dialog.dart';

class UserBookingDetailScreen extends StatefulWidget {
  final UserBooking booking;

  const UserBookingDetailScreen({
    super.key,
    required this.booking,
  });

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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserReviewedHotel() async {
    if (widget.booking.status != 'COMPLETED') {
      return;
    }

    try {
      final reviewRepository = di.sl<ReviewRepository>();
      final hasReviewed = await reviewRepository.checkIfUserReviewedHotel(
        hotelId: widget.booking.hotelId,
      );
      if (mounted) {
        setState(() => _hasReviewed = hasReviewed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasReviewed = false);
      }
    }
  }

  bool get _canCancel {
    return widget.booking.status == 'PENDING' || widget.booking.status == 'CONFIRMED';
  }

  String? get _paymentMethod {
    final value = widget.booking.paymentMethod;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim().toUpperCase();
  }

  String? get _paymentStatus {
    final value = widget.booking.paymentStatus;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim().toUpperCase();
  }

  bool get _usesRefundFlow {
    const refundableStatuses = {'PAID', 'COMPLETED', 'PAID_AT_HOMESTAY'};
    return widget.booking.status == 'CONFIRMED' &&
        _paymentStatus != null &&
        refundableStatuses.contains(_paymentStatus);
  }

  String get _paymentMethodLabel {
    switch (_paymentMethod) {
      case 'VNPAY':
        return 'VNPay';
      case 'MOMO':
        return 'MoMo';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      case 'CASH':
        return 'Tiền mặt';
      default:
        return widget.booking.paymentMethod ?? 'Chưa cập nhật';
    }
  }

  String get _paymentStatusLabel {
    switch (_paymentStatus) {
      case 'PAID':
      case 'COMPLETED':
      case 'PAID_AT_HOMESTAY':
        return 'Đã thanh toán';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thanh toán thất bại';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return widget.booking.paymentStatus ?? 'Chưa cập nhật';
    }
  }

  void _openCancelFlow() {
    if (_usesRefundFlow) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CancelBookingScreen(
            bookingData: {
              'bookingId': widget.booking.id,
              'invoiceNumber': 'BK${widget.booking.id}',
              'itemName': widget.booking.hotelName,
              'startDate': DateFormat('yyyy-MM-dd').format(widget.booking.startDate),
              'endDate': DateFormat('yyyy-MM-dd').format(widget.booking.endDate),
              'nights': widget.booking.nights,
              'paymentMethod': widget.booking.paymentMethod,
              'paymentStatus': widget.booking.paymentStatus,
            },
          ),
        ),
      );
      return;
    }

    _showCancelDialog();
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserBookingBloc>().add(GetCancellationPolicyEvent(widget.booking.id));
          });

          return AlertDialog(
            title: const Text('Xác nhận hủy đặt phòng'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: BlocConsumer<UserBookingBloc, UserBookingState>(
              listener: (context, state) {
                if (state is BookingCancelled) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                } else if (state is UserBookingError) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state is CancellationPolicyLoading) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is UserBookingError) {
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

                if (state is CancellationPolicyLoaded) {
                  final policy = state.policy;
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: policy.canCancel ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: policy.canCancel ? Colors.green[200]! : Colors.red[200]!,
                            ),
                          ),
                          child: Text(
                            policy.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: policy.canCancel ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPolicyRow(
                          'Thời hạn hủy',
                          'Trước ${policy.cancelBeforeHours} giờ',
                        ),
                        _buildPolicyRow('Hạn cuối', policy.cancelDeadline),
                        _buildPolicyRow(
                          'Phí hủy phòng',
                          policy.cancellationFeePercent > 0
                              ? '${policy.cancellationFeePercent.toStringAsFixed(0)}%'
                              : 'Miễn phí',
                          isHighlight: true,
                        ),
                        if (policy.cancellationFeePercent > 0)
                          _buildPolicyRow(
                            'Phí ước tính',
                            '${NumberFormat('#,###').format(policy.estimatedCancellationFee)}₫',
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
                              hintText: 'Nhập lý do hủy của bạn...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại', style: TextStyle(color: Colors.grey[600])),
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
                            reason: reason.isEmpty ? 'Khách hàng yêu cầu hủy đơn' : reason,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
                      child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
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
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
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
        title: const Text('Chi tiết Đặt Phòng', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
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
                    content: Text('Bạn đã đánh giá homestay này rồi'),
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
              onPressed: _openCancelFlow,
              tooltip: 'Hủy đơn đặt',
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
            tooltip: 'Xem mã QR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHotelCard(),
            const SizedBox(height: 12),
            _buildBookingInfoCard(),
            const SizedBox(height: 12),
            _buildPriceCard(),
            const SizedBox(height: 12),
            _buildContactCard(),
            if (widget.booking.cancellationReason != null) ...[
              const SizedBox(height: 12),
              _buildCancelReasonCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.holiday_village_outlined, size: 36, color: Colors.teal[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.hotelName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.roomTypeName ?? 'Phòng trống',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đặt phòng',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Mã đơn hàng', 'BK${widget.booking.id}'),
            _buildInfoRow('Ngày nhận phòng', dateFormat.format(widget.booking.startDate)),
            _buildInfoRow('Ngày trả phòng', dateFormat.format(widget.booking.endDate)),
            _buildInfoRow('Số đêm lưu trú', '${widget.booking.nights} đêm'),
            _buildInfoRow('Số lượng phòng', '${widget.booking.numberOfRooms} phòng'),
            _buildInfoRow('Số lượng khách', '${widget.booking.numberOfPeople} người'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildPriceRow('Tổng tiền dịch vụ', widget.booking.totalPrice),
            if (widget.booking.discountAmount > 0)
              _buildPriceRow('Mã giảm giá', -widget.booking.discountAmount, isDiscount: true),
            if (widget.booking.taxAmount > 0)
              _buildPriceRow(
                'Thuế (${widget.booking.taxRate.toStringAsFixed(0)}%)',
                widget.booking.taxAmount,
              ),
            const Divider(height: 24),
            if (widget.booking.taxAmount > 0)
              _buildPriceRow('Tạm tính', widget.booking.finalPrice),
            _buildPriceRow(
              widget.booking.taxAmount > 0 ? 'Tổng thanh toán' : 'Thành tiền',
              widget.booking.taxAmount > 0
                  ? widget.booking.totalWithTax
                  : widget.booking.finalPrice,
              isTotal: true,
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            _buildInfoRow('Hình thức', _paymentMethodLabel),
            _buildInfoRow('Trạng thái', _paymentStatusLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin liên hệ homestay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Địa chỉ', widget.booking.hotelAddress),
            _buildInfoRow('Số điện thoại', widget.booking.hotelPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  'Lý do hủy đơn',
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
              widget.booking.cancellationReason ?? 'Không có lý do chi tiết',
              style: TextStyle(fontSize: 13, color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      double amount, {
        bool isDiscount = false,
        bool isTotal = false,
      }) {
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 13,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${formatter.format(amount.abs())} ₫',
            style: TextStyle(
              color: isDiscount ? Colors.red : (isTotal ? Colors.teal[700] : Colors.black87),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 13,
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
      case 'PENDING_REFUND':
        color = Colors.orange;
        label = 'Chờ hoàn tiền';
        break;
      case 'REFUNDED':
        color = Colors.purple;
        label = 'Đã hoàn tiền';
        break;
      case 'CANCELED':
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}