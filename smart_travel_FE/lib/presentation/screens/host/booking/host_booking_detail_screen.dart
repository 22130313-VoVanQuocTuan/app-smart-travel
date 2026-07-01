import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';

class HostBookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const HostBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<HostBookingDetailScreen> createState() => _HostBookingDetailScreenState();
}

class _HostBookingDetailScreenState extends State<HostBookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HostBookingBloc>().add(LoadBookingDetailEvent(widget.bookingId));
  }

  void _showStatusUpdateDialog(String currentStatus) {
    const statusOptions = [
      'CONFIRMED',
      'CHECKED_IN',
      'CHECKED_OUT',
      'COMPLETED',
      'CANCELLED',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
              const Text(
                'Cập nhật trạng thái đơn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              ...statusOptions.map((status) {
                if (status == currentStatus) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  title: Text(_getStatusLabel(status), style: const TextStyle(fontWeight: FontWeight.w500)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDialog(status);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDialog(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thay đổi'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Bạn có chắc chắn muốn cập nhật trạng thái đơn đặt này thành "${_getStatusLabel(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<HostBookingBloc>().add(
                UpdateBookingStatusEvent(
                  bookingId: widget.bookingId,
                  status: newStatus,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'CHECKED_IN':
        return Icons.login_outlined;
      case 'CHECKED_OUT':
        return Icons.logout_outlined;
      case 'COMPLETED':
        return Icons.done_all_outlined;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusLabel(String status) {
    const map = {
      'PENDING': 'Chờ xác nhận',
      'CONFIRMED': 'Đã xác nhận',
      'CHECKED_IN': 'Đã nhận phòng',
      'CHECKED_OUT': 'Đã trả phòng',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã hủy đơn',
    };
    return map[status] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'CHECKED_IN':
        return Colors.green;
      case 'CHECKED_OUT':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodLabel(String? paymentMethod) {
    switch (paymentMethod?.trim().toUpperCase()) {
      case 'VNPAY':
        return 'VNPay';
      case 'MOMO':
        return 'MoMo';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      case 'CASH':
        return 'Tiền mặt';
      default:
        return paymentMethod?.trim().isNotEmpty == true ? paymentMethod! : 'Chưa cập nhật';
    }
  }

  String _getPaymentStatusLabel(String? paymentStatus) {
    switch (paymentStatus?.trim().toUpperCase()) {
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
        return paymentStatus?.trim().isNotEmpty == true ? paymentStatus! : 'Chưa cập nhật';
    }
  }

  String _orPlaceholder(String value) {
    return value.trim().isEmpty ? 'Chưa cập nhật' : value;
  }

  Color _getTourStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTourStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Chi tiết Booking', style: TextStyle(fontWeight: FontWeight.w600)),
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
      ),
      body: BlocConsumer<HostBookingBloc, HostBookingState>(
        listener: (context, state) {
          if (state is HostBookingStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.read<HostBookingBloc>().add(LoadBookingDetailEvent(widget.bookingId));
          } else if (state is HostBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is HostBookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HostBookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      context.read<HostBookingBloc>().add(LoadBookingDetailEvent(widget.bookingId));
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (state is HostBookingDetailLoaded) {
            final booking = state.bookingDetail;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(booking),
                        const SizedBox(height: 12),
                        _buildPriceCard(booking),
                        const SizedBox(height: 12),
                        _buildCustomerCard(booking),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (booking.status != 'COMPLETED' && booking.status != 'CANCELLED')
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStatusUpdateDialog(booking.status),
                          icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                          label: const Text('CẬP NHẬT TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[600],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoCard(BookingDetail booking) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hotelName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.roomTypeName ?? 'Chưa phân loại phòng',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Ngày nhận phòng', dateFormat.format(booking.startDate)),
            _buildInfoRow('Ngày trả phòng', dateFormat.format(booking.endDate)),
            _buildInfoRow('Số đêm lưu trú', '${booking.nights} đêm'),
            _buildInfoRow('Số lượng phòng', '${booking.numberOfRooms} phòng'),
            _buildInfoRow('Số lượng khách', '${booking.numberOfPeople} người'),

            if (booking.tours.isNotEmpty) ...[
              const Divider(height: 28),
              const Row(
                children: [
                  Icon(Icons.tour_outlined, size: 18, color: Colors.teal),
                  SizedBox(width: 6),
                  Text(
                    'Dịch vụ Tour đi kèm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...booking.tours.map(_buildTourItem),
            ],

            if (booking.status == 'CANCELLED') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Lý do hủy đơn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.cancellationReason ?? 'Không có lý do chi tiết',
                      style: TextStyle(fontSize: 12, color: Colors.red[700], height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTourItem(TourBookingInfo tour) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formatter = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tour.tourName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getTourStatusColor(tour.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTourStatusLabel(tour.status),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getTourStatusColor(tour.status)),
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: Colors.black12)),
          _buildInfoRow('Ngày khởi hành', dateFormat.format(tour.tourDate)),
          _buildInfoRow('Số người tham gia', '${tour.numberOfPeople} người'),
          _buildInfoRow('Đơn giá tour', '${formatter.format(tour.unitPrice)} đ'),
          _buildPriceRow('Thành tiền tour', tour.totalPrice),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BookingDetail booking) {
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
            if (booking.hotelPrice > 0)
              _buildPriceRow('Tiền phòng', booking.hotelPrice),
            if (booking.totalTourPrice > 0)
              _buildPriceRow('Tiền dịch vụ tour', booking.totalTourPrice),
            if (booking.discountAmount > 0)
              _buildPriceRow('Mã giảm giá', -booking.discountAmount, isDiscount: true),
            if (booking.taxAmount > 0)
              _buildPriceRow(
                'Thuế (${booking.taxRate.toStringAsFixed(0)}%)',
                booking.taxAmount,
              ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
            _buildInfoRow('Hình thức thanh toán', _getPaymentMethodLabel(booking.paymentMethod)),
            _buildInfoRow('Trạng thái giao dịch', _getPaymentStatusLabel(booking.paymentStatus)),
            const Divider(height: 24),
            if (booking.taxAmount > 0)
              _buildPriceRow('Tạm tính', booking.finalPrice),
            _buildPriceRow(
              booking.taxAmount > 0 ? 'Tổng thanh toán' : 'Thành tiền',
              booking.taxAmount > 0 ? booking.totalWithTax : booking.finalPrice,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BookingDetail booking) {
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
              'Thông tin khách hàng',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Họ và tên', _orPlaceholder(booking.customerName)),
            _buildInfoRow('Số điện thoại', _orPlaceholder(booking.customerPhone)),
            _buildInfoRow('Địa chỉ Email', _orPlaceholder(booking.customerEmail)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
            '${isDiscount ? '-' : ''}${formatter.format(amount.abs())} đ',
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
}