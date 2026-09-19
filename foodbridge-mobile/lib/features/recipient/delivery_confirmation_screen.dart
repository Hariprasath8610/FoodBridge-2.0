import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/impact_service.dart';
import '../../services/rescue_service.dart';
import '../../widgets/qr_display_card.dart';
import '../../widgets/qr_scanner_sheet.dart';

class DeliveryConfirmationScreen extends ConsumerStatefulWidget {
  final RescueMission mission;

  const DeliveryConfirmationScreen({
    super.key,
    required this.mission,
  });

  @override
  ConsumerState<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends ConsumerState<DeliveryConfirmationScreen> {
  bool _isConfirming = false;

  Future<void> _verifyDelivery(String code) async {
    setState(() => _isConfirming = true);
    try {
      final clean = code.trim();
      if (clean.length == 6 && int.tryParse(clean) != null) {
        // Fallback numeric OTP verification
        await ref.read(rescueServiceProvider).verifyDelivery(
              widget.mission.id,
              otp: clean,
            );
      } else {
        // Safe QR rescue identifier verification
        await ref.read(rescueServiceProvider).verifyQr(
              qrData: clean,
              action: 'delivery',
              rescueId: int.tryParse(widget.mission.id),
            );
      }

      // Invalidate rescues & impact so dashboards update automatically
      ref.invalidate(activeRescuesProvider);
      ref.invalidate(impactSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Delivery confirmed! Meals received and Impact Record generated.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openCameraScanner() async {
    final scanned = await QrScannerSheet.show(
      context,
      title: 'Scan Delivery Handover Pass',
      prompt: 'Point camera at the delivery driver\'s phone screen',
    );
    if (scanned != null && scanned.isNotEmpty) {
      _verifyDelivery(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate safe QR payload containing ONLY the short public rescue identifier
    // No sensitive information or OTP in QR
    final qrPayload = jsonEncode({
      'rescue_code': widget.mission.rescueCode,
      'action': 'delivery',
    });
    final deliveryOtp = widget.mission.deliveryOtp ?? '654321';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirm Delivery Handover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Display Card for Recipient
            QrDisplayCard(
              title: 'Recipient Delivery Pass',
              subtitle:
                  'Transporter or driver scans this QR at the receiving dock.',
              qrData: qrPayload,
              rescueCode: widget.mission.rescueCode,
              otpCode: deliveryOtp,
            ),
            const SizedBox(height: 24),

            // Secondary option: Scan Driver QR
            OutlinedButton.icon(
              onPressed: _isConfirming ? null : _openCameraScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Transporter Pass via Camera'),
            ),
            const SizedBox(height: 12),

            // Fast Demo Self-Confirm Button for Hackathon Testing
            ElevatedButton.icon(
              onPressed:
                  _isConfirming ? null : () => _verifyDelivery(deliveryOtp),
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.task_alt),
              label: Text(_isConfirming
                  ? 'Confirming Delivery...'
                  : 'Confirm Delivery & Accept Food Cargo (Fallback OTP)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
