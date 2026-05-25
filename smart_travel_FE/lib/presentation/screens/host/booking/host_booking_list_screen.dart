// lib/presentation/screens/host/booking/host_booking_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';
import 'package:smart_travel/router/route_names.dart';

class HostBookingListScreen extends StatefulWidget {
  const HostBookingListScreen({Key? key}) : super(key: key);

  @override
  State<HostBookingListScreen> createState() => _HostBookingListScreenState();
}

class _HostBookingListScreenState extends State<HostBookingListScreen> {
  String? selectedStatus;
  DateTime? startDate;
  DateTime? endDate;

  final List<String> statusOptions = [
    'TẤT CẢ',
    'PENDING',
    'CONFIRMED',
    'CHECKED_IN',
    'CHECKED_OUT',
    'COMPLETED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    context.read<HostBookingBloc>().add(const LoadHostBookingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Booking'),
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.teal[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDateRangePicker(),
            tooltip: 'Lọc theo ngày',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadBookings,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips with count
          BlocBuilder<HostBookingBloc, HostBookingState>(
            builder: (context, state) {
              Map<String, int> statusCounts = {};

              if (state is HostBookingLoaded) {
                statusCounts = _countBookingsByStatus(state.bookings);
              }

              return _buildStatusFilter(statusCounts);
            },
          ),

          // Date range filter indicator
          if (startDate != null && endDate != null)
            _buildDateRangeFilter(),

          // Dùng Expanded để tránh overflow
          Expanded(
            child: BlocConsumer<HostBookingBloc, HostBookingState>(
              listener: (context, state) {
                if (state is HostBookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                if (state is HostBookingStatusUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is HostBookingLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải dữ liệu...'),
                      ],
                    ),
                  );
                } else if (state is HostBookingLoaded) {
                  if (state.filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có booking nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedStatus != null || startDate != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectedStatus = null;
                                  startDate = null;
                                  endDate = null;
                                });
                                if (mounted) {
                                  context.read<HostBookingBloc>().add(const LoadHostBookingsEvent());
                                }
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Xóa bộ lọc'),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _pullToRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = state.filteredBookings[index];
                        return BookingListItem(
                          booking: booking,
                          onTap: () => _navigateToDetail(context, booking.id),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to detail and reload on return
  Future<void> _navigateToDetail(BuildContext context, int bookingId) async {
    await Navigator.pushNamed(
      context,
      RouteNames.hostBookingDetail,
      arguments: bookingId,
    );
    
    // Reload dữ liệu khi quay lại
    if (mounted) {
      // Delay 300ms để ensure navigation pop animation hoàn thành
      await Future.delayed(const Duration(milliseconds: 300));
      _reloadBookings();
    }
  }

  // Reload bookings
  void _reloadBookings() {
    if (mounted) {
      if (selectedStatus != null) {
        context.read<HostBookingBloc>().add(
          FilterBookingsByStatusEvent(selectedStatus!),
        );
      } else if (startDate != null && endDate != null) {
        context.read<HostBookingBloc>().add(
          FilterBookingsByDateRangeEvent(
            startDate: startDate!,
            endDate: endDate!,
          ),
        );
      } else {
        context.read<HostBookingBloc>().add(const LoadHostBookingsEvent());
      }
    }
  }

  // Pull to refresh
  Future<void> _pullToRefresh() async {
    return Future.delayed(const Duration(milliseconds: 300), _reloadBookings);
  }

  // Hàm đếm số lượng booking theo từng trạng thái
  Map<String, int> _countBookingsByStatus(List<HostBooking> bookings) {
    final Map<String, int> counts = {
      'PENDING': 0,
      'CONFIRMED': 0,
      'CHECKED_IN': 0,
      'CHECKED_OUT': 0,
      'COMPLETED': 0,
      'CANCELLED': 0,
    };

    for (var booking in bookings) {
      final status = booking.status;
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }

  Widget _buildStatusFilter(Map<String, int> statusCounts) {
    int totalCount = 0;
    for (var count in statusCounts.values) {
      totalCount += count;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: statusOptions.length,
          itemBuilder: (context, index) {
            final status = statusOptions[index];
            final isSelected = (selectedStatus == status) ||
                (status == 'TẤT CẢ' && selectedStatus == null);

            // Lấy số lượng an toàn
            final count = status == 'TẤT CẢ'
                ? totalCount
                : (statusCounts[status] ?? 0);

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildStatusChip(
                status: status,
                count: count,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (status == 'TẤT CẢ') {
                      selectedStatus = null;
                    } else {
                      selectedStatus = isSelected ? null : status;
                    }
                  });

                  if (selectedStatus != null) {
                    context.read<HostBookingBloc>().add(
                      FilterBookingsByStatusEvent(selectedStatus!),
                    );
                  } else {
                    context.read<HostBookingBloc>().add(const LoadHostBookingsEvent());
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  //Widget chip hiển thị trạng thái + số lượng
  Widget _buildStatusChip({
    required String status,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isAll = status == 'TẤT CẢ';
    final statusLabel = _getStatusLabel(status);
    final color = isAll ? Colors.teal : _getStatusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 20, color: Colors.teal[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                startDate = null;
                endDate = null;
              });
              if (mounted) {
                context.read<HostBookingBloc>().add(const LoadHostBookingsEvent());
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal[600]!,
              onPrimary: Colors.white,
              surface: Colors.teal[50]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });

      context.read<HostBookingBloc>().add(
        FilterBookingsByDateRangeEvent(
          startDate: picked.start,
          endDate: picked.end,
        ),
      );
    }
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'TẤT CẢ': return 'Tất cả';
      case 'PENDING': return 'Chờ xác nhận';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'CHECKED_IN': return 'Đã nhận phòng';
      case 'CHECKED_OUT': return 'Đã trả phòng';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED': return 'Đã hủy';
      default: return status;
    }
  }
}

// ==================== BOOKING LIST ITEM WIDGET ====================

class BookingListItem extends StatelessWidget {
  final HostBooking booking;
  final VoidCallback onTap;

  const BookingListItem({
    required this.booking,
    required this.onTap,
    Key? key,
  }) : super(key: key);

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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ xác nhận';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'CHECKED_IN': return 'Đã nhận phòng';
      case 'CHECKED_OUT': return 'Đã trả phòng';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED': return 'Đã hủy';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = booking.endDate.difference(booking.startDate).inDays;
    final formatter = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.hotel,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.hotelName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Khách: ${booking.guestName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(booking.status).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.hotel, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '$nights đêm • ${booking.numberOfRooms} phòng • ${booking.numberOfPeople} khách',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatter.format(booking.finalPrice)}₫',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}