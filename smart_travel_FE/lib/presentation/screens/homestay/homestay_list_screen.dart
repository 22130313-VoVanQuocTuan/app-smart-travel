import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_state.dart';
import 'package:smart_travel/presentation/screens/chat/ai_chat_screen.dart';
import 'package:smart_travel/presentation/widgets/common/bottom_navigation.dart';
import 'package:smart_travel/router/route_names.dart';
import '../../theme/app_colors.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({Key? key}) : super(key: key);

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 2;
  String _selectedFilter = "popular";

  static const Color textDark = Color(0xFF1F2937);
  static const Color primary = Color(0xFF51CCD1);

  @override
  void initState() {
    super.initState();
    _applyFilter();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        setState(() => _selectedIndex = index);
        Navigator.pushReplacementNamed(context, RouteNames.home);
        break;
      case 1:
        setState(() => _selectedIndex = index);
        Navigator.pushReplacementNamed(context, RouteNames.explore);
        break;
      case 2:
        Navigator.pushNamed(context, RouteNames.homestayList);
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen()));
        break;
      case 4:
        setState(() => _selectedIndex = index);
        Navigator.pushReplacementNamed(context, RouteNames.profile);
        break;
    }
  }

  String _getSortBy() {
    switch (_selectedFilter) {
      case 'price_asc': return 'pricePerNight';
      case 'price_desc': return 'pricePerNight';
      case 'name_asc': return 'name';
      case 'name_desc': return 'name';
      default: return 'reviewCount';
    }
  }

  String _getSortDir() {
    switch (_selectedFilter) {
      case 'price_desc':
      case 'name_desc':
        return 'desc';
      case 'popular':
        return 'desc';
      default:
        return 'asc';
    }
  }

  void _applyFilter({int page = 0}) {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    context.read<HomestayBloc>().add(
      LoadHomestaysEvent(
        keyword: _searchController.text.trim(),
        sortBy: _getSortBy(),
        sortDir: _getSortDir(),
        page: page,
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () => _applyFilter(page: currentPage - 1) : null,
            icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: currentPage > 0 ? primary : Colors.grey[300]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalPages, (index) {
                final isSelected = index == currentPage;
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) _applyFilter(page: index);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? primary : Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => _applyFilter(page: currentPage + 1) : null,
            icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: currentPage < totalPages - 1 ? primary : Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filterValue) {
    switch (filterValue) {
      case "popular": return "Phổ biến nhất";
      case "price_asc": return "Giá tăng dần";
      case "price_desc": return "Giá giảm dần";
      case "name_asc": return "Tên A-Z";
      case "name_desc": return "Tên Z-A";
      default: return "Sắp xếp";
    }
  }

  String _getFilterEmoji(String filterValue) {
    switch (filterValue) {
      case "popular": return "🔥";
      case "price_asc": return "💰";
      case "price_desc": return "⬇️";
      case "name_asc": case "name_desc": return "🔠";
      default: return "";
    }
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        final List<Map<String, String>> sortOptions = [
          {"value": "popular", "label": "🔥 Phổ biến nhất"},
          {"value": "price_asc", "label": "💰 Giá tăng dần"},
          {"value": "price_desc", "label": "⬇️ Giá giảm dần"},
          {"value": "name_asc", "label": "🔠 Tên A-Z"},
          {"value": "name_desc", "label": "🔠 Tên Z-A"},
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sắp xếp theo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 10),
              ...sortOptions.map((option) {
                final isSelected = _selectedFilter == option["value"];
                return ListTile(
                  title: Text(option["label"]!, style: TextStyle(color: isSelected ? primary : textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedFilter = option["value"]!;
                      _applyFilter();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
        foregroundColor: Colors.white,
        title: const Text("Danh sách Homestay", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: BlocBuilder<HomestayBloc, HomestayState>(
              builder: (context, state) {
                if (state is HomestayLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is HomestayLoaded) {
                  final homestays = state.homestays;

                  if (homestays.isEmpty) {
                    return const Center(child: Text("Không tìm thấy homestay nào", style: TextStyle(color: Color(0xFF6B7280))));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: homestays.length + 1,
                    itemBuilder: (context, index) {
                      if (index == homestays.length) {
                        return _buildPaginationControls(state.currentPage, state.totalPages);
                      }
                      return _buildHomestayCard(homestays[index]);
                    },
                  );
                }

                if (state is HomestayError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Lỗi tải dữ liệu: ${state.message}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                return const Center(child: Text("Bắt đầu tìm kiếm homestay"));
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationWithIndicator(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Tìm kiếm theo tên, địa chỉ...",
              hintStyle: TextStyle(color: AppColors.textGray, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: primary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: AppColors.textGray, size: 20), onPressed: () { _searchController.clear(); _applyFilter(); })
                  : null,
              border: InputBorder.none,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.5)),
            ),
            onSubmitted: (value) => _applyFilter(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showSortModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getFilterEmoji(_selectedFilter), style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(_getFilterLabel(_selectedFilter), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomestayCard(Homestay homestay) {
    final hasPrice = homestay.pricePerNight != null && homestay.pricePerNight! > 0;
    final priceString = hasPrice ? "${NumberFormat('#,###').format(homestay.pricePerNight)} đ" : "Liên hệ";

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.hotelDetail, arguments: homestay.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Image.network(
                homestay.thumbnail ?? "",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(height: 180, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.cottage_outlined, size: 40, color: Color(0xFF6B7280))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homestay.name ?? "Tên Homestay Không Xác Định",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: List.generate(homestay.stars ?? 0, (i) => const Icon(Icons.star_border_rounded, color: Colors.orange, size: 18)),
                                ),
                                const SizedBox(width: 8),
                                if (homestay.rating != null && homestay.rating! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(homestay.rating!.toStringAsFixed(1), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${homestay.numOfReviews ?? 0} đánh giá)',
                                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.place_outlined, size: 16, color: AppColors.textGray),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    homestay.destinationName ?? homestay.address ?? "Không có địa chỉ",
                                    style: TextStyle(fontSize: 14, color: AppColors.textGray),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Giá từ", style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                          Text(priceString, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          Text("/ đêm", style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}