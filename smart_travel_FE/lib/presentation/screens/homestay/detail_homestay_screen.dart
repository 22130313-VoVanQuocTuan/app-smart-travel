// lib/presentation/screens/homestay/detail_homestay_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_state.dart';
import 'package:smart_travel/presentation/screens/booking/booking_args.dart';
import 'package:smart_travel/presentation/screens/booking/booking_screen.dart';
import 'package:smart_travel/presentation/widgets/homestay/homestay_image_carousel_sliver.dart';
import 'package:smart_travel/presentation/widgets/homestay/homestay_info_section.dart';
import 'package:smart_travel/presentation/widgets/homestay/homestay_map.dart';
import 'package:smart_travel/presentation/widgets/homestay/homestay_room_type.dart';
import 'package:smart_travel/presentation/widgets/homestay/homestay_tour_section.dart';
import 'package:smart_travel/presentation/widgets/review/review_list_widget.dart';
import '../../../injection_container.dart';
import '../../blocs/review/reviewhtd_bloc.dart';

class DetailHomestayScreen extends StatefulWidget {
  const DetailHomestayScreen({Key? key}) : super(key: key);

  @override
  State<DetailHomestayScreen> createState() => _DetailHomestayScreenState();
}

class _DetailHomestayScreenState extends State<DetailHomestayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  final Set<int> _selectedTourIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homestayId = ModalRoute.of(context)!.settings.arguments as int;
      context.read<HomestayDetailBloc>().add(
        GetHomestayDetailEvent(
          homestayId: homestayId,
          checkIn: DateTime.now(),
          checkOut: DateTime.now().add(const Duration(days: 1)),
        ),
      );
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleTourSelection(TourBrief tour, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTourIds.add(tour.id);
      } else {
        _selectedTourIds.remove(tour.id);
      }
    });
  }

  void _bookSpecificRoom(BuildContext context, Homestay homestay, RoomType room) {
    // Lấy danh sách tour đã chọn (chỉ lấy thông tin cơ bản)
    final selectedTours = _selectedTourIds.map((id) {
      return homestay.availableTours?.firstWhere((t) => t.id == id);
    }).whereType<TourBrief>().toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          args: BookingArgs(
            bookingType: 'HOMESTAY',
            id: homestay.id,
            name: "${homestay.name} - ${room.name}",
            price: room.price,
            imageUrl: homestay.thumbnail ?? '',
            roomTypeId: room.id,
            roomCapacity: room.capacity,
            maxAvailableRooms: room.availableRooms,
            selectedTours: selectedTours,
          ),
        ),
      ),
    );
  }

  double _getDisplayPrice(Homestay homestay) {
    double displayPrice = homestay.pricePerNight ?? 0.0;
    if (displayPrice <= 0 && homestay.rooms != null && homestay.rooms!.isNotEmpty) {
      final validRoomPrices = homestay.rooms!
          .map((r) => r.price)
          .where((price) => price > 0)
          .toList();
      if (validRoomPrices.isNotEmpty) {
        displayPrice = validRoomPrices.reduce((a, b) => a < b ? a : b);
      }
    }
    return displayPrice;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomestayDetailBloc, HomestayDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Builder(builder: (context) {
            if (state is HomestayDetailLoading) {
              return Center(
                child: Lottie.asset('assets/lottie/travel_is_fun.json', width: 200),
              );
            }
            if (state is HomestayDetailError) {
              return Center(child: Text(state.message));
            }

            if (state is HomestayDetailLoaded) {
              final homestay = state.homestay;
              final displayPrice = _getDisplayPrice(homestay);
              final images = homestay.images ?? [];
              final tours = homestay.availableTours ?? [];

              return CustomScrollView(
                slivers: [
                  HomestayImageCarouselSliver(
                    images: images,
                    onBack: () => Navigator.pop(context),
                  ),
                  SliverToBoxAdapter(
                    child: HomestayInfoSection(
                      homestay: homestay,
                      displayPrice: displayPrice,
                      fadeAnimation: _fadeController,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomestayRoomTypeWidget(
                      rooms: homestay.rooms ?? [],
                      onBook: (room) => _bookSpecificRoom(context, homestay, room),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomestayTourSection(
                      tours: tours,
                      selectedTourIds: _selectedTourIds,
                      onToggleSelect: _toggleTourSelection,
                    ),
                  ),
                  SliverToBoxAdapter(child: HomestayMapSection(homestay: homestay)),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Đánh giá từ khách hàng",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 500,
                      child: BlocProvider(
                        create: (_) => ReviewHtdBloc(sl()),
                        child: ReviewListWidget(
                          type: "HOTEL",
                          serviceId: homestay.id,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        );
      },
    );
  }
}