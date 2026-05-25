import 'package:flutter/material.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final bool isDialog;
  
  const PrivacyPolicyScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
                      'Chính sách bảo mật',
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
            'Chính sách bảo mật',
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
          'CHÍNH SÁCH BẢO MẬT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(
          'I. Thông tin chúng tôi thu thập',
          'Smart Travel thu thập các loại thông tin sau:\n• Thông tin cá nhân: tên, email, số điện thoại, địa chỉ\n• Thông tin thanh toán: số thẻ (được mã hóa), lịch sử giao dịch\n• Thông tin sử dụng: lịch sử duyệt, tìm kiếm, đặt phòng\n• Thông tin thiết bị: loại thiết bị, hệ điều hành, địa chỉ IP\n• Cookie và dữ liệu theo dõi khác',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'II. Cách chúng tôi sử dụng thông tin',
          '• Cung cấp và cải thiện dịch vụ\n• Xử lý thanh toán và đơn hàng\n• Gửi email xác nhận và thông báo\n• Phân tích và cải thiện trải nghiệm người dùng\n• Phát hiện và ngăn chặn gian lận\n• Tuân thủ các yêu cầu pháp lý',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'III. Bảo mật dữ liệu',
          'Chúng tôi sử dụng các biện pháp bảo mật tiên tiến để bảo vệ thông tin của bạn:\n• Mã hóa SSL/TLS cho tất cả các giao dịch\n• Lưu trữ dữ liệu trên máy chủ bảo mật\n• Kiểm tra bảo mật định kỳ\n• Kiểm soát truy cập dữ liệu\n• Tập huấn nhân viên về bảo mật dữ liệu',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'IV. Chia sẻ thông tin',
          'Chúng tôi chỉ chia sẻ thông tin của bạn khi:\n• Cần thiết để cung cấp dịch vụ (với chủ homestay, công ty du lịch)\n• Được yêu cầu bởi luật pháp hoặc cơ quan chính phủ\n• Bạn đã cho phép\n• Cần thiết để bảo vệ quyền hoặc an toàn của người khác',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'V. Quyền của bạn',
          '• Quyền truy cập: bạn có thể yêu cầu sao chép dữ liệu của mình\n• Quyền sửa đổi: bạn có thể cập nhật hoặc sửa lỗi dữ liệu\n• Quyền xóa: bạn có thể yêu cầu xóa dữ liệu\n• Quyền từ chối: bạn có thể từ chối xử lý dữ liệu',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VI. Cookie và công nghệ theo dõi',
          'Chúng tôi sử dụng cookie để:\n• Nhớ các tùy chọn của bạn\n• Cải thiện hiệu suất trang web\n• Phân tích hành vi người dùng\n• Hiển thị quảng cáo có liên quan\n\nBạn có thể tắt cookie trong cài đặt trình duyệt của mình.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VII. Lưu giữ dữ liệu',
          'Chúng tôi giữ lại thông tin của bạn miễn là cần thiết để cung cấp dịch vụ hoặc theo yêu cầu pháp lý. Bạn có thể yêu cầu xóa dữ liệu bất kỳ lúc nào.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'VIII. Trẻ em',
          'Dịch vụ của chúng tôi không dành cho người dưới 18 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu chúng tôi nhận thức được rằng đã thu thập dữ liệu từ trẻ em, chúng tôi sẽ xóa ngay lập tức.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'IX. Liên kết bên thứ ba',
          'Ứng dụng của chúng tôi có thể chứa các liên kết đến các trang web bên thứ ba. Chúng tôi không chịu trách nhiệm về chính sách bảo mật của các trang web đó.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'X. Thay đổi chính sách',
          'Chúng tôi có thể cập nhật chính sách bảo mật này từ lúc đến lúc. Chúng tôi sẽ thông báo cho bạn về bất kỳ thay đổi nào bằng cách đăng chính sách mới trên trang web.',
        ),
        const SizedBox(height: 12),
        _buildSection(
          'XI. Liên hệ',
          'Nếu bạn có câu hỏi về chính sách bảo mật này, vui lòng liên hệ:\nEmail: privacy@smarttravel.vn\nHotline: 1800-SMART-TRAVEL',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'Cập nhật lần cuối: 2024\nVersion: 1.0',
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

