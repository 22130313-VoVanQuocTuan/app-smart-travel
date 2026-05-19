import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';
import 'package:intl/intl.dart';

class HostBookingListScreen extends StatefulWidget {
  const HostBookingListScreen({Key? key}) : super(key: key);

  @override
  State<HostBookingListScreen> createState() => _HostBookingListScreenState();
}

class _HostBookingListScreenState extends State<HostBookingListScreen> {
  String? selectedStatus;
  final List<String> statusOptions = [
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
        title: const Text('Quản Lý Lịch Booking'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HostBookingBloc>().add(const RefreshHostBookingsEvent());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                    label: const Text('Tất cả'),
                    selected: selectedStatus == null,
                    onPressed: () {
                      setState(() => selectedStatus = null);
                      context
                          .read<HostBookingBloc>()
                          .add(const LoadHostBookingsEvent());
                    },
                  ),
                  const SizedBox(width: 8),
                  ...statusOptions.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(status),
                        selected: selectedStatus == status,
                        onPressed: () {
                          setState(() => selectedStatus = status);
                          context.read<HostBookingBloc>().add(
                                FilterBookingsByStatusEvent(status),
                              );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Booking list
          Expanded(
            child: BlocBuilder<HostBookingBloc, HostBookingState>(
              builder: (context, state) {
                if (state is HostBookingLoading) {
                  return const Center(child: CircularProgressIndicator());
              } else if (state is HostBookingError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<HostBookingBloc>()
                                .add(const LoadHostBookingsEvent());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (state is HostBookingLoaded) {
                  if (state.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Không có booking nào',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.bookings.length,
                    itemBuilder: (context, index) {
                      final booking = state.bookings[index];
                      return BookingListItem(
                        booking: booking,
                        onTap: () {
                          // Navigate to detail screen
                          Navigator.pushNamed(
                            context,
                            '/host-booking-detail',
                            arguments: booking.id,
                          );
                        },
                      );
                    },
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
}

class BookingListItem extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onTap;

  const BookingListItem({
    required this.booking,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange[300]!;
      case 'CONFIRMED':
        return Colors.blue[300]!;
      case 'CHECKED_IN':
        return Colors.green[300]!;
      case 'CHECKED_OUT':
        return Colors.purple[300]!;
      case 'COMPLETED':
        return Colors.green[600]!;
      case 'CANCELLED':
        return Colors.red[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  String _getStatusLabel(String status) {
    const statusMap = {
      'PENDING': 'Chờ xác nhận',
      'CONFIRMED': 'Đã xác nhận',
      'CHECKED_IN': 'Đã nhận phòng',
      'CHECKED_OUT': 'Đã trả phòng',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = booking.endDate.difference(booking.startDate).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date and room info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày: ${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$nights đêm | ${booking.numberOfRooms} phòng | ${booking.numberOfPeople} khách',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${booking.finalPrice.toStringAsFixed(0)}₫',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
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



