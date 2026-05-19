// lib/presentation/screens/user/user_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_travel/data/models/user/user_booking_model.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_bloc.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_event.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_state.dart';
import 'package:smart_travel/presentation/screens/user/user_booking_detail_screen.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isQRScannerOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<UserBookingBloc>().add(const LoadUserBookingsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openQRScanner() {
    setState(() {
      isQRScannerOpen = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQRScannerSheet(),
    ).then((_) {
      setState(() {
        isQRScannerOpen = false;
      });
    });
  }

  Widget _buildQRScannerSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppBar(
            title: const Text('Quét mã QR'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    Navigator.pop(context);
                    context.read<UserBookingBloc>().add(FindBookingByQREvent(barcode.rawValue!));
                    return;
                  }
                }
              },
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
        title: const Text('Booking của tôi'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hiện tại', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openQRScanner,
            tooltip: 'Tìm booking bằng QR',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UserBookingBloc>().add(const RefreshUserBookingsEvent());
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<UserBookingBloc, UserBookingState>(
        listener: (context, state) {
          if (state is UserBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is UserBookingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is UserBookingQRFound) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserBookingDetailScreen(booking: state.booking),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserBookingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserBookingLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentBookingsTab(state.currentBookings),
                _buildHistoryTab(state.bookingHistory),
              ],
            );
          } else if (state is UserBookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UserBookingBloc>().add(const LoadUserBookingsEvent());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCurrentBookingsTab(List<UserBooking> bookings) {
    final activeBookings = bookings.where((b) => b.isActive).toList();

    if (activeBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Hiện không có booking nào đang diễn ra'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserBookingBloc>().add(const RefreshUserBookingsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: activeBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(activeBookings[index]);
        },
      ),
    );
  }

  Widget _buildHistoryTab(List<UserBooking> bookings) {
    final pastBookings = bookings.where((b) => b.isPast).toList();

    if (pastBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Chưa có lịch sử booking nào'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserBookingBloc>().add(const RefreshUserBookingsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pastBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(pastBookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(UserBooking booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formatter = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserBookingDetailScreen(booking: booking),
            ),
          ).then((_) {
            context.read<UserBookingBloc>().add(const RefreshUserBookingsEvent());
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.hotel,
                      color: Colors.teal[600],
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
                          booking.roomTypeName ?? 'Không có thông tin phòng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
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
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.numberOfPeople} khách, ${booking.numberOfRooms} phòng',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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