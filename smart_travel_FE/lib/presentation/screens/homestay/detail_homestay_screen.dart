// lib/presentation/screens/homestay/detail_homestay_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:smart_travel/core/network/dio_client.dart';
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
import 'package:smart_travel/presentation/widgets/homestay/homestay_rating_section.dart';
import 'package:smart_travel/presentation/widgets/review/review_list_widget.dart';
import 'package:smart_travel/router/route_names.dart';
import '../../../injection_container.dart' as di;
import '../../blocs/review/reviewhtd_bloc.dart';

class DetailHomestayScreen extends StatefulWidget {
  final DioClient? dioClient;

  const DetailHomestayScreen({Key? key, this.dioClient}) : super(key: key);

  @override
  State<DetailHomestayScreen> createState() => _DetailHomestayScreenState();
}

class _DetailHomestayScreenState extends State<DetailHomestayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  final Set<int> _selectedTourIds = {};
  double _averageRating = 0.0;
  int _reviewCount = 0;
  late int _homestayId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homestayId = ModalRoute.of(context)!.settings.arguments as int;
      context.read<HomestayDetailBloc>().add(
        GetHomestayDetailEvent(
          homestayId: _homestayId,
          checkIn: DateTime.now(),
          checkOut: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      _fetchRatings();
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  Future<void> _fetchRatings() async {
    final DioClient dioClient = widget.dioClient ?? di.sl<DioClient>();
    try {
      final response = await dioClient.get(
        '/reviews/hotel/$_homestayId/average',
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _averageRating =
              (response.data['averageRating'] as num?)?.toDouble() ?? 0.0;
          _reviewCount = response.data['reviewCount'] as int? ?? 0;
        });
      }
    } catch (e) {
      // Handle error silently - show default values
      if (mounted) {
        setState(() {
          _averageRating = 0.0;
          _reviewCount = 0;
        });
      }
    }
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

  void _bookSpecificRoom(
    BuildContext context,
    Homestay homestay,
    RoomType room,
  ) {
    // Lấy danh sách tour đã chọn (chỉ lấy thông tin cơ bản)
    final selectedTours =
        _selectedTourIds
            .map((id) {
              return homestay.availableTours?.firstWhere((t) => t.id == id);
            })
            .whereType<TourBrief>()
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BookingScreen(
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
    if (displayPrice <= 0 &&
        homestay.rooms != null &&
        homestay.rooms!.isNotEmpty) {
      final validRoomPrices =
          homestay.rooms!
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
          floatingActionButton: state is HomestayDetailLoaded
              ? Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF059669)], // Gradient Xanh Mint tone-sur-tone với nút "Chọn phòng"
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent, // Để lộ lớp gradient cực đẹp ở dưới
              elevation: 0,
              highlightElevation: 0,
              splashColor: Colors.white.withOpacity(0.3),
              tooltip: 'Chat với Chủ nhà',
              child: const Icon(Icons.maps_ugc_rounded, color: Colors.white, size: 26),
              onPressed: () {
                final homestay = state.homestay;
                if (homestay.ownerId != null) {
                  Navigator.pushNamed(
                    context,
                    RouteNames.userChat,
                    arguments: {
                      'ownerId': homestay.ownerId,
                      'ownerName': homestay.ownerName ?? homestay.name,
                      'homestayId': homestay.id,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không tìm thấy thông tin chủ nhà'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          )
              : null,
          body: Builder(
            builder: (context) {
              if (state is HomestayDetailLoading) {
                return Center(
                  child: Lottie.asset(
                    'assets/lottie/travel_is_fun.json',
                    width: 200,
                  ),
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
                        onBook:
                            (room) =>
                                _bookSpecificRoom(context, homestay, room),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: HomestayTourSection(
                        tours: tours,
                        selectedTourIds: _selectedTourIds,
                        onToggleSelect: _toggleTourSelection,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: HomestayMapSection(homestay: homestay),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // Rating Section
                    SliverToBoxAdapter(
                      child: HomestayRatingSection(
                        averageRating: _averageRating,
                        reviewCount: _reviewCount,
                        onViewAllReviews: () {
                          // Scroll to reviews section or navigate if needed
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Nhận xét chi tiết từ khách",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 500,
                        child: BlocProvider(
                          create: (_) => ReviewHtdBloc(di.sl()),
                          child: ReviewListWidget(
                            type: "HOTEL",
                            serviceId: _homestayId,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
