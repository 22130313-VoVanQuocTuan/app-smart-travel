import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/injection_container.dart' as di;
import 'package:smart_travel/presentation/blocs/admin_invoice/admin_invoice_detail_bloc.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

import '../../../../domain/entities/admin_invoice_detail.dart';
import '../../../../domain/usecases/invoice/admin_approve_refund_usecase.dart';
import '../../../../domain/usecases/invoice/admin_cancel_order_usecase.dart';
import '../../../../domain/usecases/invoice/admin_check_in_usecase.dart';
import '../../../../domain/usecases/invoice/admin_check_out_usecase.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';

class AdminInvoiceDetailScreen extends StatelessWidget {
  final int bookingId;

  const AdminInvoiceDetailScreen({super.key, required this.bookingId});

  String _formatDateTime(String value) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _paymentMethodLabel(String value) {
    switch (value.trim().toUpperCase()) {
      case 'VNPAY':
        return 'VNPay';
      case 'MOMO':
        return 'MoMo';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      case 'CASH':
        return 'Tiền mặt';
      default:
        return value.trim().isEmpty ? 'Chưa cập nhật' : value;
    }
  }

  String _paymentStatusLabel(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'PAID_AT_HOMESTAY':
        return 'Đã thanh toán';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thất bại';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return value.trim().isEmpty ? 'Chưa cập nhật' : value;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'CHECKED':
        return 'Đã check-in';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'PENDING_REFUND':
        return 'Chờ hoàn tiền';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Đã hủy đơn';
      default:
        return status;
    }
  }

  String _safeText(String value) {
    return value.trim().isEmpty ? 'Chưa cập nhật' : value;
  }

  bool _isOverdue(String endDate) {
    try {
      return DateTime.now().isAfter(DateTime.parse(endDate));
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: BlocProvider(
        create: (_) => di.sl<AdminInvoiceDetailBloc>()..add(LoadAdminInvoiceDetail(bookingId)),
        child: BlocBuilder<AdminInvoiceDetailBloc, AdminInvoiceDetailState>(
          builder: (context, state) {
            if (state is AdminInvoiceDetailLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is AdminInvoiceDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 72, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text('Quay lại', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is AdminInvoiceDetailLoaded) {
              final detail = state.detail;
              final isHotel = detail.hotelId != null;
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 180,
                          pinned: true,
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          leading: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.15),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    Color.lerp(AppColors.primary, Colors.black, 0.25)!,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Text(
                                    detail.taxAmount > 0
                                        ? _formatPrice(detail.totalWithTax)
                                        : _formatPrice(detail.finalPrice),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _statusLabel(detail.status).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInvoiceCard(detail),
                                const SizedBox(height: 12),
                                if (detail.cancellationReason?.isNotEmpty == true)
                                  _buildWarningCard(detail),
                                _buildSectionTitle('DỊCH VỤ ĐẶT'),
                                _buildServiceCard(detail, isHotel),
                                const SizedBox(height: 16),
                                _buildSectionTitle('THÔNG TIN KHÁCH HÀNG'),
                                _buildCustomerCard(detail),
                                const SizedBox(height: 16),
                                _buildSectionTitle('CHI TIẾT THANH TOÁN'),
                                _buildPaymentCard(detail),
                                const SizedBox(height: 20),
                                Text(
                                  'Ngày tạo đơn: ${_formatDateTime(detail.createdAt)}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cập nhật cuối: ${_formatDateTime(detail.updatedAt)}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBottomBar(context, detail),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(AdminInvoiceDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mã đơn đặt phòng', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          SelectableText(
            detail.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(AdminInvoiceDetail detail, bool isHotel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHotel ? Colors.blue[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHotel ? Icons.holiday_village_outlined : Icons.tour_outlined,
                  color: isHotel ? Colors.blue : Colors.orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.serviceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if (detail.roomTypeName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail.roomTypeName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(Icons.calendar_today_rounded, 'Nhận phòng', _formatDate(detail.startDate)),
              ),
              Container(width: 1, height: 28, color: Colors.grey[200]),
              Expanded(
                child: _buildInfoColumn(Icons.event_available_rounded, 'Trả phòng', _formatDate(detail.endDate)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconText(Icons.people_alt_rounded, '${detail.numberOfPeople} Khách'),
                if ((detail.numberOfRooms ?? 0) > 0)
                  _buildIconText(Icons.door_front_door_rounded, 'Số phòng: ${detail.numberOfRooms}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(AdminInvoiceDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  detail.customerName.isNotEmpty ? detail.customerName[0].toUpperCase() : 'K',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeText(detail.customerName),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _safeText(detail.customerEmail),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.phone_iphone_rounded, 'Số điện thoại liên hệ', _safeText(detail.customerPhone)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 16)),
          _buildDetailRow(
            Icons.sticky_note_2_outlined,
            'Yêu cầu đặc biệt từ khách hàng',
            detail.specialRequests?.trim().isNotEmpty == true
                ? detail.specialRequests!
                : 'Không có yêu cầu đặc biệt',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(AdminInvoiceDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildPriceRow('Tổng tiền dịch vụ gốc', _formatPrice(detail.totalPrice)),
          if (detail.discountAmount > 0)
            _buildPriceRow('Giảm giá / Voucher áp dụng', '- ${_formatPrice(detail.discountAmount)}', color: Colors.green),
          if (detail.taxAmount > 0)
            _buildPriceRow(
              'Thuế phí (${detail.taxRate.toStringAsFixed(0)}%)',
              '+ ${_formatPrice(detail.taxAmount)}',
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 16, thickness: 1)),
          if (detail.taxAmount > 0)
            _buildPriceRow('Tạm tính doanh thu', _formatPrice(detail.finalPrice)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng số tiền thu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text(
                _formatPrice(detail.taxAmount > 0 ? detail.totalWithTax : detail.finalPrice),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Trạng thái: ${_paymentStatusLabel(detail.paymentStatus)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Hình thức: ${_paymentMethodLabel(detail.paymentMethod)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(AdminInvoiceDetail detail) {
    final refundLines = <String>[
      if (detail.refundBankName?.isNotEmpty == true) 'Ngân hàng: ${detail.refundBankName}',
      if (detail.refundBankBranch?.isNotEmpty == true) 'Chi nhánh: ${detail.refundBankBranch}',
      if (detail.refundAccountNumber?.isNotEmpty == true) 'Số tài khoản: ${detail.refundAccountNumber}',
      if (detail.refundAccountHolder?.isNotEmpty == true) 'Chủ tài khoản: ${detail.refundAccountHolder}',
    ];

    final content = [
      detail.cancellationReason ?? '',
      if (refundLines.isNotEmpty) refundLines.join('\n'),
    ].where((e) => e.trim().isNotEmpty).join('\n\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.red[700], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghi chú bổ sung / Lý do hủy đơn',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(content, style: TextStyle(color: Colors.red[900], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AdminInvoiceDetail detail) {
    final authState = context.read<AuthBloc>().state;
    String? currentRole;

    if (authState is LoginSuccess) {
      currentRole = authState.response.role;
    } else if (authState is AdminAuthenticated) {
      currentRole = authState.role;
    } else if (authState is HostAuthenticated) {
      currentRole = authState.role;
    }

    if (currentRole == null) {
      return const SizedBox.shrink();
    }

    final bool isRootAdmin = currentRole == 'ADMIN';
    final bool isHotelAdmin = currentRole == 'ADMINHOTEL' || currentRole == 'HOST';
    final bool isTourAdmin = currentRole == 'ADMINTOUR';
    final bool canManage = isHotelAdmin || isTourAdmin;
    final status = detail.status.toUpperCase();
    final isOverdue = _isOverdue(detail.endDate);

    final showCheckIn = status == 'ACTIVE' && canManage;
    final showCheckOut = status == 'CHECKED' && canManage;
    final showRefund = status == 'PENDING_REFUND' && (isRootAdmin || canManage);
    final showCancel = status == 'ACTIVE' && isOverdue && (isRootAdmin || canManage);

    if (!showCheckIn && !showCheckOut && !showRefund && !showCancel) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showRefund)
              Expanded(
                child: _buildActionButton(
                  label: 'Duyệt hoàn tiền',
                  icon: Icons.price_check_outlined,
                  color: Colors.orange.shade700,
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      'Duyệt hoàn tiền',
                      'Bạn có chắc chắn muốn duyệt hoàn trả tiền cho đơn hàng này?',
                    );
                    if (!ok) return;
                    if (!context.mounted) return;

                    try {
                      await di.sl<AdminApproveRefundUseCase>()(bookingId: detail.bookingId);
                      if (!context.mounted) return;
                      _reloadWithMessage(context, detail.bookingId, 'Duyệt hoàn tiền thành công');
                    } catch (e) {
                      if (!context.mounted) return;
                      _showError(context, e);
                    }
                  },
                ),
              ),
            if (showRefund && (showCheckOut || showCheckIn || showCancel)) const SizedBox(width: 12),
            if (showCheckOut)
              Expanded(
                child: _buildActionButton(
                  label: 'Check-out',
                  icon: Icons.logout_outlined,
                  color: Colors.teal,
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      'Xác nhận trả phòng',
                      'Xác nhận khách hàng đã trả phòng và tiến hành hoàn tất hóa đơn này?',
                    );
                    if (!ok) return;
                    if (!context.mounted) return;

                    try {
                      await di.sl<AdminCheckOutUseCase>()(bookingId: detail.bookingId);
                      if (!context.mounted) return;
                      _reloadWithMessage(context, detail.bookingId, 'Check-out hoàn tất thành công');
                    } catch (e) {
                      if (!context.mounted) return;
                      _showError(context, e);
                    }
                  },
                ),
              ),
            if (showCheckOut && (showCheckIn || showCancel)) const SizedBox(width: 12),
            if (showCheckIn)
              Expanded(
                child: _buildActionButton(
                  label: 'Check-in',
                  icon: Icons.login_outlined,
                  color: Colors.blue.shade700,
                  onPressed: () async {
                    int? rooms;
                    if (detail.hotelId != null) {
                      rooms = await _askRoomCount(context);
                      if (rooms == null) return;
                      if (!context.mounted) return;
                    }

                    final ok = await _confirm(
                      context,
                      'Xác nhận nhận phòng',
                      detail.hotelId != null
                          ? 'Xác nhận thực hiện Check-in với $rooms phòng đã bàn giao?'
                          : 'Xác nhận khách đã có mặt đầy đủ để bắt đầu lịch trình tour?',
                    );
                    if (!ok) return;
                    if (!context.mounted) return;

                    try {
                      await di.sl<AdminCheckInUseCase>()(
                        bookingId: detail.bookingId,
                        numberOfRooms: rooms,
                      );
                      if (!context.mounted) return;
                      _reloadWithMessage(context, detail.bookingId, 'Check-in phòng thành công');
                    } catch (e) {
                      if (!context.mounted) return;
                      _showError(context, e);
                    }
                  },
                ),
              ),
            if (showCheckIn && showCancel) const SizedBox(width: 12),
            if (showCancel)
              Expanded(
                child: _buildActionButton(
                  label: 'Hủy đơn',
                  icon: Icons.cancel_presentation_outlined,
                  color: Colors.red.shade700,
                  onPressed: () async {
                    final reason = await _askCancelReason(context);
                    if (reason == null || reason.isEmpty) return;
                    if (!context.mounted) return;

                    final ok = await _confirm(
                      context,
                      'Hủy đơn hàng hệ thống',
                      'Bạn chắc chắn muốn thực hiện hủy đơn đặt phòng này?\nLý do: $reason',
                    );
                    if (!ok) return;
                    if (!context.mounted) return;

                    try {
                      await di.sl<AdminCancelOrderUseCase>()(
                        bookingId: detail.bookingId,
                        cancelMessage: reason,
                      );
                      if (!context.mounted) return;
                      _reloadWithMessage(context, detail.bookingId, 'Hủy đơn hàng thành công');
                    } catch (e) {
                      if (!context.mounted) return;
                      _showError(context, e);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<int?> _askRoomCount(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập số lượng phòng'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ví dụ: 2',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy', style: TextStyle(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Số phòng nhập vào không hợp lệ')),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result;
  }

  Future<String?> _askCancelReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lý do hủy đơn hàng'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do chi tiết hủy đơn...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy', style: TextStyle(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do cụ thể')),
                );
                return;
              }
              Navigator.pop(ctx, text);
            },
            child: const Text('Gửi duyệt', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _reloadWithMessage(BuildContext context, int bookingId, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    context.read<AdminInvoiceDetailBloc>().add(LoadAdminInvoiceDetail(bookingId));
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Có lỗi xảy ra: $error'), backgroundColor: Colors.red),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 10, top: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade600),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}