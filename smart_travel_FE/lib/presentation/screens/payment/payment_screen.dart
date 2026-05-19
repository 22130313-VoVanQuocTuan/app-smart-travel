// lib/presentation/screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';
import 'package:smart_travel/presentation/blocs/payment/payment_bloc.dart';
import 'package:smart_travel/presentation/blocs/payment/payment_event.dart';
import 'package:smart_travel/presentation/blocs/payment/payment_state.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_travel/injection_container.dart' as di;

class PaymentScreen extends StatelessWidget {
  final BookingInfo bookingInfo;

  const PaymentScreen({
    Key? key,
    required this.bookingInfo,
  }) : super(key: key);

  double _calculateTotalAmount() {
    double total = 0;
    int nights = bookingInfo.endDate.difference(bookingInfo.startDate).inDays;
    if (nights < 1) nights = 1;
    total += bookingInfo.pricePerNight * bookingInfo.numberOfRooms * nights;
    for (var tour in bookingInfo.selectedTours) {
      total += tour.pricePerPerson * tour.numberOfPeople;
    }
    if (bookingInfo.discountAmount > 0) {
      total -= bookingInfo.discountAmount;
    }
    return total > 0 ? total : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    final totalAmount = _calculateTotalAmount();
    final formattedAmount = currencyFormatter.format(totalAmount);

    return BlocProvider(
      create: (context) => di.sl<PaymentBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textGray,
          elevation: 0,
        ),
        backgroundColor: AppColors.background,
        body: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSuccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentWebView(url: state.paymentUrl),
                ),
              );
            } else if (state is PaymentCashSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đặt chỗ thành công! Bạn sẽ thanh toán sau.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (state is PaymentFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng số tiền cần thanh toán:', style: TextStyle(fontSize: 18, color: AppColors.textGray)),
                      const SizedBox(height: 8),
                      Text(formattedAmount, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 32),
                      Text('Chọn phương thức thanh toán:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray)),
                      const SizedBox(height: 16),
                      _buildPaymentMethodTile(
                        context: context,
                        logoAsset: 'assets/images/vnpay_logo.png',
                        title: 'Thanh toán qua VNPay',
                        onTap: () {
                          context.read<PaymentBloc>().add(
                            ProcessPaymentSubmitted(
                              bookingInfo: bookingInfo,
                              paymentMethod: 'VNPAY',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodTile(
                        context: context,
                        logoAsset: 'assets/images/momo_logo.png',
                        title: 'Thanh toán qua MoMo',
                        onTap: () {
                          context.read<PaymentBloc>().add(
                            ProcessPaymentSubmitted(
                              bookingInfo: bookingInfo,
                              paymentMethod: 'MOMO',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodTile(
                        context: context,
                        logoAsset: 'assets/images/cash_logo.png',
                        title: 'Thanh toán trực tiếp',
                        onTap: () {
                          context.read<PaymentBloc>().add(
                            ConfirmCashPayment(bookingInfo: bookingInfo),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (state is PaymentLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required BuildContext context,
    required String logoAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              logoAsset,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.payment, size: 40, color: AppColors.primary);
              },
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textGray))),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// InAppWebView với xử lý momo:// scheme
class PaymentWebView extends StatefulWidget {
  final String url;
  const PaymentWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  final GlobalKey webViewKey = GlobalKey();
  late InAppWebViewController webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cổng thanh toán'), elevation: 0),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                domStorageEnabled: true,
                useHybridComposition: true,
              ),
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
              ),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              print(">>> WebView URL: $url");

              // XỬ LÝ URL MOMO SCHEME
              if (url.startsWith("momo://")) {
                print(">>> Phát hiện momo:// scheme, mở app MoMo...");
                try {
                  // Cách 1: Dùng url_launcher
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } else {
                    _showInstallMoMoDialog();
                  }
                } catch (e) {
                  print("Lỗi mở MoMo: $e");
                  _showInstallMoMoDialog();
                }
                return NavigationActionPolicy.CANCEL;
              }

              // XỬ LÝ URL TRẢ VỀ THÀNH CÔNG
              if (url.contains("127.0.0.1") ||
                  url.contains("localhost") ||
                  url.contains("10.0.2.2") ||
                  url.contains("/payment/momo-return") ||
                  url.contains("/payment/vnpay-return")) {

                print(">>> PHÁT HIỆN URL TRẢ VỀ: $url");
                _handlePaymentResult(url);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _showInstallMoMoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chưa cài đặt MoMo'),
        content: const Text('Để thanh toán bằng MoMo, vui lòng cài đặt ứng dụng MoMo Test.\n\nHoặc chọn phương thức thanh toán khác như VNPay hoặc Tiền mặt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final momoResultCode = uri.queryParameters['resultCode'];
    final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];

    bool isSuccess = false;
    if (momoResultCode == '0' || vnpResponseCode == '00') {
      isSuccess = true;
    }

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanh toán thành công!"), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giao dịch thất bại hoặc bị hủy"), backgroundColor: Colors.red, duration: Duration(seconds: 3)),
      );
      Navigator.of(context).pop();
    }
  }
}