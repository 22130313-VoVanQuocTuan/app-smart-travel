import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/injection_container.dart' as di;
import 'package:smart_travel/presentation/blocs/invoice/cancel_bloc.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

import '../../../router/route_names.dart';
import '../../blocs/invoice/cancel_event.dart';
import '../../blocs/invoice/cancel_state.dart';

class CancelFormScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const CancelFormScreen({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<CancelFormScreen> createState() => _CancelFormScreenState();
}

class _CancelFormScreenState extends State<CancelFormScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankBranchController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  bool _agreeTerms = false;

  String _formatDate(String date) {
    List<String> parts = date.split('-');
    return "${parts[2]}/${parts[1]}/${parts[0]}";
  }

  String? get _paymentMethod {
    final value = widget.bookingData['paymentMethod'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toUpperCase();
    }
    return null;
  }

  bool get _requiresRefundBankInfo {
    final paymentMethod = _paymentMethod;
    if (paymentMethod == null) {
      return false;
    }
    return paymentMethod != 'CASH' && paymentMethod != 'UNKNOWN';
  }

  bool get _hasRequiredRefundInfo {
    if (!_requiresRefundBankInfo) {
      return true;
    }
    return _bankNameController.text.trim().isNotEmpty &&
        _accountNumberController.text.trim().isNotEmpty &&
        _accountHolderController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _submitCancel(BuildContext context) {
    if (_requiresRefundBankInfo && !_hasRequiredRefundInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin tài khoản ngân hàng để hoàn tiền."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<CancelBloc>().add(
      SubmitCancelRequest(
        bookingId: widget.bookingData['bookingId'],
        reason: _reasonController.text.trim().isEmpty
            ? "Không có lý do"
            : _reasonController.text.trim(),
        refundBankName: _bankNameController.text.trim(),
        refundBankBranch: _bankBranchController.text.trim(),
        refundAccountNumber: _accountNumberController.text.trim(),
        refundAccountHolder: _accountHolderController.text.trim(),
      ),
    );
  }

  Widget _buildBankInfoSection() {
    if (!_requiresRefundBankInfo) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thông tin tài khoản nhận hoàn tiền",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Đơn này đã thanh toán qua ${_paymentMethod ?? 'ngân hàng'}. Vui lòng cung cấp tài khoản để hệ thống và quản lý hoàn tiền lại cho khách.",
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _bankNameController,
          label: "Tên ngân hàng",
          hintText: "Ví dụ: Vietcombank",
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _accountNumberController,
          label: "Số tài khoản",
          hintText: "Nhập số tài khoản nhận hoàn tiền",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _accountHolderController,
          label: "Tên chủ tài khoản",
          hintText: "Ví dụ: NGUYEN VAN A",
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _bankBranchController,
          label: "Chi nhánh ngân hàng (tuỳ chọn)",
          hintText: "Ví dụ: CN Quận 1",
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      body: BlocProvider(
        create: (_) => di.sl<CancelBloc>(),
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Biểu mẫu huỷ đặt chỗ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<CancelBloc, CancelState>(
                listener: (context, state) {
                  if (state is CancelSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Yêu cầu huỷ/hoàn tiền đã được gửi thành công!"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.myInvoices,
                      (route) => false,
                    );
                  }
                  if (state is CancelError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bookingData['itemName'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${_formatDate(widget.bookingData['startDate'])} · ${widget.bookingData['nights']} đêm",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.receipt, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Mã đặt chỗ: ${widget.bookingData['invoiceNumber']}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            if (_paymentMethod != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Thanh toán: $_paymentMethod",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Vui lòng cho chúng tôi biết lý do huỷ đặt chỗ",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: Thay đổi lịch trình, lý do cá nhân...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBankInfoSection(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Tuyên bố người dùng",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        "Khi nhấn vào \"Xác nhận huỷ đặt chỗ\", tôi xác nhận rằng tôi đã đọc và đồng ý với các ",
                                  ),
                                  TextSpan(
                                    text:
                                        "Điều khoản & Điều kiện của Chính sách Huỷ phòng",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ". Tôi hiểu rằng phiếu xác nhận đã xuất trước đó cho đặt phòng này sẽ mất hiệu lực.",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeTerms = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Có, tôi đồng ý",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _agreeTerms && state is! CancelLoading
                              ? () => _submitCancel(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red[200],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state is CancelLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Xác nhận huỷ đặt chỗ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
