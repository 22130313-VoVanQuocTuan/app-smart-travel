import 'package:flutter/material.dart';

/// Screen to handle payment result after successful payment
/// Used for deeplink: smarttravel://payment-result?status=success&paymentId=123&method=vnpay
class PaymentResultScreen extends StatefulWidget {
  final String? status;
  final String? paymentId;
  final String? method;
  final String? message;

  const PaymentResultScreen({
    Key? key,
    this.status,
    this.paymentId,
    this.method,
    this.message,
  }) : super(key: key);

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.status == 'success';
    final bgColor = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.cancel;
    final title = isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại';
    final message = widget.message ?? (isSuccess ? 'Giao dịch của bạn đã được xử lý' : 'Giao dịch không thành công');

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: bgColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: bgColor,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            if (widget.paymentId != null) ...[
              const SizedBox(height: 20),
              Text(
                'Mã giao dịch: ${widget.paymentId}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (widget.method != null) ...[
              const SizedBox(height: 5),
              Text(
                'Phương thức: ${widget.method?.toUpperCase()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('Quay lại trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

