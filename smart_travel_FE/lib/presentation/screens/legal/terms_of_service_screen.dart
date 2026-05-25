import 'package:flutter/material.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class TermsOfServiceScreen extends StatefulWidget {
  final bool isDialog;

  const TermsOfServiceScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.isDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Điều khoản dịch vụ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Điều khoản dịch vụ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.mainGradient),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ),
      );
    }
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ĐIỀU KHOẢN DỊCH VỤ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(
          'I. Giới thiệu',
          'Smart Travel là nền tảng dịch vụ du lịch trực tuyến cung cấp các dịch vụ liên quan đến du lịch bao gồm: đặt homestay, tour du lịch, và các dịch vụ liên quan khác. Bằng cách sử dụng dịch vụ của chúng tôi, bạn đồng ý tuân thủ các điều khoản này.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'II. Điều kiện sử dụng',
          '• Bạn phải là người dùng hợp pháp có độ tuổi ≥ 18 tuổi\n• Bạn chịu trách nhiệm về mọi hoạt động trên tài khoản của mình\n• Bạn không được phép sử dụng dịch vụ cho các mục đích bất hợp pháp\n• Bạn phải cung cấp thông tin chính xác và đầy đủ',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'III. Quyền và trách nhiệm người dùng',
          'Người dùng có quyền truy cập và sử dụng dịch vụ theo quy định. Người dùng chịu trách nhiệm bảo mật thông tin đăng nhập, thanh toán và với tất cả các hoạt động được thực hiện qua tài khoản của họ.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'IV. Chính sách thanh toán',
          '• Tất cả các giao dịch phải được thanh toán đầy đủ trước khi xác nhận đặt chỗ\n• Chúng tôi chấp nhận các phương thức thanh toán: thẻ tín dụng, VNPAY, MoMo\n• Mọi giao dịch thanh toán đều được mã hóa và bảo mật',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'V. Hủy và hoàn tiền',
          '• Nếu hủy đặt chỗ trước 7 ngày, sẽ hoàn lại 100% tiền\n• Hủy trong 7-3 ngày trước: hoàn lại 50%\n• Hủy trong 3 ngày: không hoàn lại\n• Hoàn tiền sẽ được xử lý trong 5-7 ngày làm việc',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VI. Trách nhiệm của chúng tôi',
          'Smart Travel không chịu trách nhiệm cho bất kỳ thiệt hại gián tiếp, ngẫu nhiên hoặc theo sau từ việc sử dụng hoặc không thể sử dụng dịch vụ của chúng tôi.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VII. Thay đổi điều khoản',
          'Chúng tôi có quyền sửa đổi các điều khoản này bất kỳ lúc nào. Các thay đổi sẽ được công bố trên ứng dụng và có hiệu lực ngay sau khi đăng.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VIII. Liên hệ',
          'Nếu bạn có bất kỳ câu hỏi nào về các điều khoản này, vui lòng liên hệ conus tại:\nEmail: support@smarttravel.vn\nHotline: 1800-SMART-TRAVEL',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary),
          ),
          child: const Text(
            'Cập nhật lần cuối: 2024\nVersión: 1.0',
            style: TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

