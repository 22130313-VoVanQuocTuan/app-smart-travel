// lib/presentation/screens/host/host_booking_detail_screen.dart
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
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<HostBookingDetailScreen> createState() => _HostBookingDetailScreenState();
}

class _HostBookingDetailScreenState extends State<HostBookingDetailScreen> {

  @override
  void initState() {
    super.initState();
    // ⭐ Dùng widget.bookingId thay vì arguments
    context.read<HostBookingBloc>().add(LoadBookingDetailEvent(widget.bookingId));
  }

  void _showStatusUpdateDialog(String currentStatus) {
    final statusOptions = [
      'CONFIRMED',
      'CHECKED_IN',
      'CHECKED_OUT',
      'COMPLETED',
      'CANCELLED',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cập nhật trạng thái',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...statusOptions.map((status) {
                if (status == currentStatus) return const SizedBox.shrink();
                return ListTile(
                  leading: Icon(_getStatusIcon(status)),
                  title: Text(_getStatusLabel(status)),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDialog(status);
                  },
                );
              }).toList(),
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
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn cập nhật trạng thái thành "${_getStatusLabel(newStatus)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
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
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CONFIRMED': return Icons.check_circle;
      case 'CHECKED_IN': return Icons.login;
      case 'CHECKED_OUT': return Icons.logout;
      case 'COMPLETED': return Icons.done_all;
      case 'CANCELLED': return Icons.cancel;
      default: return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    const map = {
      'PENDING': 'Chờ xác nhận',
      'CONFIRMED': 'Đã xác nhận',
      'CHECKED_IN': 'Đã nhận phòng',
      'CHECKED_OUT': 'Đã trả phòng',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã hủy',
    };
    return map[status] ?? status;
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
      ),
      body: BlocConsumer<HostBookingBloc, HostBookingState>(
        listener: (context, state) {
          if (state is HostBookingStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            // Refresh lại chi tiết sau khi cập nhật
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
          } else if (state is HostBookingDetailLoaded) {
            final booking = state.bookingDetail;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(booking),
                  const SizedBox(height: 16),
                  _buildPriceCard(booking),
                  const SizedBox(height: 16),
                  _buildCustomerCard(booking),
                  const SizedBox(height: 24),
                  if (booking.status != 'COMPLETED' && booking.status != 'CANCELLED')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showStatusUpdateDialog(booking.status),
                        icon: const Icon(Icons.edit),
                        label: const Text('Cập nhật trạng thái'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else if (state is HostBookingError) {
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
                    onPressed: () {
                      context.read<HostBookingBloc>().add(LoadBookingDetailEvent(widget.bookingId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Thêm method để lấy màu theo status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'CHECKED_IN': return Colors.green;
      case 'CHECKED_OUT': return Colors.purple;
      case 'COMPLETED': return Colors.teal;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildInfoCard(BookingDetail booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = booking.endDate.difference(booking.startDate).inDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.hotelName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Loại phòng', booking.roomTypeName ?? 'Không xác định'),
            const SizedBox(height: 8),
            _buildInfoRow('Ngày nhận', dateFormat.format(booking.startDate)),
            const SizedBox(height: 8),
            _buildInfoRow('Ngày trả', dateFormat.format(booking.endDate)),
            const SizedBox(height: 8),
            _buildInfoRow('Số đêm', '$nights đêm'),
            const SizedBox(height: 8),
            _buildInfoRow('Số phòng', '${booking.numberOfRooms}'),
            const SizedBox(height: 8),
            _buildInfoRow('Số khách', '${booking.numberOfPeople}'),

            if (booking.tours.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Thông tin Tour',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...booking.tours.map((tour) => _buildTourItem(tour)),
            ],

            if (booking.status == 'CANCELLED') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: Colors.red[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Lý do hủy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.cancellationReason ?? 'Không có lý do',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tour, size: 16, color: Colors.teal[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tour.tourName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTourStatusColor(tour.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTourStatusLabel(tour.status),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Ngày tour', dateFormat.format(tour.tourDate)),
          _buildInfoRow('Số khách', '${tour.numberOfPeople}'),
          _buildInfoRow('Đơn giá', '${formatter.format(tour.unitPrice)}₫'),
          _buildInfoRow('Thành tiền', '${formatter.format(tour.totalPrice)}₫'),
        ],
      ),
    );
  }
  Color _getTourStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }
  String _getTourStatusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED': return 'Đã hủy';
      default: return status;
    }
  }

  Widget _buildPriceCard(BookingDetail booking) {
    final formatter = NumberFormat('#,###');

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
            if (booking.hotelPrice > 0)
              _buildPriceRow('Tiền phòng', booking.hotelPrice),
            if (booking.totalTourPrice > 0)
              _buildPriceRow('Tiền tour', booking.totalTourPrice),
            if (booking.discountAmount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Giảm giá', -booking.discountAmount, isDiscount: true),
            ],
            const Divider(height: 24),
            _buildPriceRow('Thành tiền', booking.finalPrice, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BookingDetail booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin khách hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow('Họ tên', booking.customerName),
            const SizedBox(height: 8),
            _buildInfoRow('Số điện thoại', booking.customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow('Email', booking.customerEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    final formatter = NumberFormat('#,###');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.teal[800] : null,
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
    );
  }
}