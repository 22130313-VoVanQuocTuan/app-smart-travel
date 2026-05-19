// lib/presentation/screens/host/host_booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';

class HostBookingDetailScreen extends StatefulWidget {
  const HostBookingDetailScreen({Key? key}) : super(key: key);

  @override
  State<HostBookingDetailScreen> createState() => _HostBookingDetailScreenState();
}

class _HostBookingDetailScreenState extends State<HostBookingDetailScreen> {
  late int bookingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null) {
      bookingId = arguments as int;
      context.read<HostBookingBloc>().add(LoadBookingDetailEvent(bookingId));
    }
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
                  bookingId: bookingId,
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
            context.read<HostBookingBloc>().add(LoadBookingDetailEvent(bookingId));
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
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HostBookingBloc>().add(LoadBookingDetailEvent(bookingId));
                    },
                    child: const Text('Thử lại'),
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

  Widget _buildInfoCard(BookingDetail booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = booking.endDate.difference(booking.startDate).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.hotelName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Loại phòng', booking.roomTypeName ?? 'Không xác định'),
            _buildInfoRow('Ngày nhận', dateFormat.format(booking.startDate)),
            _buildInfoRow('Ngày trả', dateFormat.format(booking.endDate)),
            _buildInfoRow('Số đêm', '$nights đêm'),
            _buildInfoRow('Số phòng', '${booking.numberOfRooms}'),
            _buildInfoRow('Số khách', '${booking.numberOfPeople}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(BookingDetail booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildPriceRow('Tổng tiền', booking.totalPrice),
            if (booking.discountAmount > 0)
              _buildPriceRow('Giảm giá', -booking.discountAmount, isDiscount: true),
            const Divider(),
            _buildPriceRow('Thành tiền', booking.finalPrice, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BookingDetail booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin khách hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Họ tên', booking.customerName),
            _buildInfoRow('Số điện thoại', booking.customerPhone),
            _buildInfoRow('Email', booking.customerEmail),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
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
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(0)}₫',
            style: TextStyle(
              color: isDiscount ? Colors.red : (isTotal ? Colors.teal : Colors.black),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

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

}