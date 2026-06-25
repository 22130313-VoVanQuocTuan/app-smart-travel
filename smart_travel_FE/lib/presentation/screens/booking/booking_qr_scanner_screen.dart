import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class BookingQrScannerScreen extends StatefulWidget {
  const BookingQrScannerScreen({super.key});

  @override
  State<BookingQrScannerScreen> createState() => _BookingQrScannerScreenState();
}

class _BookingQrScannerScreenState extends State<BookingQrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.paused:
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan booking QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (barcodeCapture) {
              if (isScanned) return;

              final List<Barcode> barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code == null) {
                  Navigator.pop(context);
                  return;
                }

                final RegExp regExp = RegExp(r'\d+');
                final RegExpMatch? match = regExp.firstMatch(code);
                final String? bookingIdStr = match?.group(0);
                final int? bookingId =
                    bookingIdStr == null ? null : int.tryParse(bookingIdStr);

                isScanned = true;
                controller.stop();
                Navigator.pop(context, bookingId);
                return;
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Place the booking QR inside the frame to scan',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.stop();
    controller.dispose();
    super.dispose();
  }
}
