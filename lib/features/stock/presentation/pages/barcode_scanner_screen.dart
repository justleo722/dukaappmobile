import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  /// Opens the scanner and returns the raw barcode string (or null if cancelled).
  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // The MobileScanner widget owns the camera start/stop lifecycle (autoStart).
  // We must NOT call start() manually — doing so races the widget's own start
  // and freezes/crashes the native camera.
  late final MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    _isProcessing = true;
    // Popping while a detection frame is in-flight is safe; the widget is
    // disposed right after, which stops the camera via autoStart.
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          'Scan Barcode',
          style: AppTypography.h6.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(
                  torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: torchOn ? Colors.amber : Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: _buildMessage(
                  icon: error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? Icons.no_photography_rounded
                      : Icons.error_outline_rounded,
                  title: error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission denied'
                      : 'Camera unavailable',
                  message: error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Please allow camera access in app settings to scan barcodes.'
                      : error.errorCode.message,
                  onRetry: () => _controller.start(),
                ),
              );
            },
            placeholderBuilder: (context) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              );
            },
          ),
          _buildScanOverlay(),
          _buildBottomHint(),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h6.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withAlpha(200),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -1,
              left: -1,
              right: -1,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomHint() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(180),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Position the barcode within the frame',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withAlpha(220),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
