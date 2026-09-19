import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/impact_service.dart';
import '../../services/rescue_service.dart';
import '../../widgets/qr_display_card.dart';
import '../../widgets/qr_scanner_sheet.dart';

class PickupVerificationScreen extends ConsumerStatefulWidget {
  final RescueMission mission;

  const PickupVerificationScreen({
    super.key,
    required this.mission,
  });

  @override
  ConsumerState<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState
    extends ConsumerState<PickupVerificationScreen> {
  bool _isVerifying = false;

  Future<void> _verifyPickup(String code) async {
    setState(() => _isVerifying = true);
    try {
      final clean = code.trim();
      if (clean.length == 6 && int.tryParse(clean) != null) {
        // Fallback numeric OTP verification
        await ref.read(rescueServiceProvider).verifyPickup(
              widget.mission.id,
              otp: clean,
            );
      } else {
        // Safe QR rescue identifier verification
        await ref.read(rescueServiceProvider).verifyQr(
              qrData: clean,
              action: 'pickup',
              rescueId: int.tryParse(widget.mission.id),
            );
      }

      // Authoritative backend verification succeeded - refresh both apps
      ref.invalidate(activeRescuesProvider);
      ref.invalidate(impactSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup verified! Rescue mission is now IN TRANSIT.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openCameraScanner() async {
    final scanned = await QrScannerSheet.show(
      context,
      title: 'Scan Driver Pickup Pass',
      prompt: 'Point camera at the recipient driver\'s phone screen',
    );
    if (scanned != null && scanned.isNotEmpty) {
      _verifyPickup(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate safe QR payload containing ONLY the short public rescue identifier
    // No sensitive information or OTP in QR
    final qrPayload = jsonEncode({
      'rescue_code': widget.mission.rescueCode,
      'action': 'pickup',
    });
    final pickupOtp = widget.mission.pickupOtp ?? '123456';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Vehicle Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent QR Card displaying safe rescue identifier to driver
            QrDisplayCard(
              title: 'Driver Pickup Pass',
              subtitle:
                  'Recipient driver scans this QR to verify cargo handover.',
              qrData: qrPayload,
              rescueCode: widget.mission.rescueCode,
              otpCode: pickupOtp,
            ),
            const SizedBox(height: 24),

            // Secondary option: Scan Driver QR
            OutlinedButton.icon(
              onPressed: _isVerifying ? null : _openCameraScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Recipient Pass via Camera'),
            ),
            const SizedBox(height: 12),

            // Fast Demo Self-Verify Button for Hackathon Testing
            ElevatedButton.icon(
              onPressed: _isVerifying ? null : () => _verifyPickup(pickupOtp),
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isVerifying
                  ? 'Verifying Pickup...'
                  : 'Confirm Cargo Loaded & Dispatched (Fallback OTP)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
