import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_theme.dart';

class QrScannerSheet extends StatefulWidget {
  final String title;
  final String prompt;
  final Function(String scannedCode) onCodeDetected;

  const QrScannerSheet({
    super.key,
    required this.title,
    required this.prompt,
    required this.onCodeDetected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String prompt,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrScannerSheet(
        title: title,
        prompt: prompt,
        onCodeDetected: (code) => Navigator.of(ctx).pop(code),
      ),
    );
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualOtpController = TextEditingController();
  bool _isManualEntry = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualOtpController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        widget.onCodeDetected(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isManualEntry = !_isManualEntry;
                    });
                  },
                  icon: Icon(
                    _isManualEntry ? Icons.qr_code_scanner : Icons.keyboard,
                    size: 16,
                  ),
                  label: Text(_isManualEntry ? 'Scan QR' : 'Manual OTP'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isManualEntry ? _buildManualView() : _buildScannerView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _handleDetect,
        ),
        // Viewfinder overlay
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.secondary, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Camera action controls
        Positioned(
          bottom: 24,
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flash_on),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => _controller.switchCamera(),
                icon: const Icon(Icons.flip_camera_ios),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pin_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter 6-Digit OTP Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask the other party for the code displayed on their screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _manualOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: AppColors.primary,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final code = _manualOtpController.text.trim();
              if (code.isNotEmpty) {
                widget.onCodeDetected(code);
              }
            },
            child: const Text('Verify Code'),
          ),
        ],
      ),
    );
  }
}
