import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
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
  MobileScannerController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    Navigator.of(context).pop(barcode.rawValue);
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
      ),
      body: _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        if (_controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: _onBarcodeDetected,
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        _buildScanOverlay(),
        _buildBottomHint(),
      ],
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
