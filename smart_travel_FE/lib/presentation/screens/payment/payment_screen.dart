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
    return bookingInfo.totalWithTax;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    final amountBeforeTax = bookingInfo.amountBeforeTax;
    final taxAmount = bookingInfo.taxAmount;
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
                      if (bookingInfo.taxRate > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Tam tinh: ${currencyFormatter.format(amountBeforeTax)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thue (${bookingInfo.taxRate.toStringAsFixed(bookingInfo.taxRate.truncateToDouble() == bookingInfo.taxRate ? 0 : 2)}%): ${currencyFormatter.format(taxAmount)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
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
                    color: Colors.black.withValues(alpha: 0.5),
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
            BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)),
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
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              useHybridComposition: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
              // ✅ Auto-handle payment result if page loaded
              if (url.toString().contains("/api/v1/payment/payment-result") ||
                  url.toString().contains("/payment-result")) {
                print(">>> Payment result page loaded, preparing to close...");
                // Auto-close WebView after 2 seconds to show result page
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    _handlePaymentResult(url.toString());
                  }
                });
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              print(">>> WebView URL: $url");
              if (url.contains("momo") || url.contains("://momo")) {
                print(">>> Phát hiện URL liên quan đến MoMo: $url");
              }

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

               // XỰ LÝ URL TRẢ VỀ THÀNH CÔNG - NEW Endpoint
               if (url.contains("/api/v1/payment/payment-result") || 
                   url.contains("/payment-result") ||
                   url.contains("/payment/momo-return") ||
                   url.contains("/payment/vnpay-return")) {

                 print(">>> PHÁT HIỆN URL TRẢ VỀ: $url");
                 _handlePaymentResult(url);
                 return NavigationActionPolicy.ALLOW;  // Allow page to load, then auto-handle
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
     try {
       final uri = Uri.parse(url);
       
       // ✅ NEW: Parse from new /payment-result endpoint params
       final status = uri.queryParameters['status'];  // "success" or "failed"
       final paymentId = uri.queryParameters['paymentId'];
       final method = uri.queryParameters['method'];  // "vnpay" or "momo"
       final backendMessage = uri.queryParameters['message'];
       
       // ✅ FALLBACK: Parse old endpoint params if new ones don't exist
       final momoResultCode = uri.queryParameters['resultCode'];
       final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];
       
       bool isSuccess = false;
       String displayMessage = "Giao dịch thất bại hoặc bị hủy";
       
       // ✅ Check new status first
       if (status != null) {
         isSuccess = status == 'success';
         if (isSuccess) {
           displayMessage = "Thanh toán ${method?.toUpperCase() ?? 'online'} thành công!";
           if (backendMessage != null) {
             try {
               displayMessage = Uri.decodeComponent(backendMessage);
             } catch (e) {
               // Keep default message if decode fails
             }
           }
         } else {
           displayMessage = "Thanh toán ${method?.toUpperCase() ?? 'online'} thất bại!";
         }
       } 
       // ✅ Fallback to old params
       else if (momoResultCode != null || vnpResponseCode != null) {
         isSuccess = momoResultCode == '0' || vnpResponseCode == '00';
         if (isSuccess) {
           displayMessage = "Thanh toán thành công!";
         }
       }
       
       // ✅ Log detailed info
       print(">>> Payment Result - Status: $status, PaymentId: $paymentId, Method: $method, Success: $isSuccess");
       
       if (isSuccess) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(displayMessage),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 3),
           ),
         );
         // ✅ Back to home screen
         Navigator.of(context).popUntil((route) => route.isFirst);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(displayMessage),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 3),
           ),
         );
         // Back to payment screen to retry
         Navigator.of(context).pop();
       }
     } catch (e) {
       print(">>> Error handling payment result: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Lỗi xử lý kết quả thanh toán: $e"),
           backgroundColor: Colors.red,
         ),
       );
       Navigator.of(context).pop();
     }
   }
}
