import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../payToUpiId/payToUpiId.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'my_qr_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _isScanning = true;
  String? _scannedData;
  Map<String, String>? _upiData;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera permission needed',
                  style: AppTypography.heading(size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grant camera access so EchoPay can scan QR codes.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          openAppSettings();
                        },
                        child: const Text('Settings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Custom top bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Colors.black,
            child: Row(
              children: [
                _topIcon(Icons.arrow_back_rounded,
                    () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Text(
                  'scan & pay',
                  style: AppTypography.heading(
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _topIcon(
                  _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  _toggleFlash,
                ),
              ],
            ),
          ),

          // Camera view
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onQRDetected,
                ),
                _scannerOverlay(),
                if (_isScanning) _scanLine(),
              ],
            ),
          ),

          // Bottom panel
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scannedData != null)
                    _scannedPanel()
                  else
                    _instructions(),
                  const SizedBox(height: 22),
                  _actionRow(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _scannerOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.pop, width: 3),
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _scanLine() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 2,
          color: AppColors.pop,
        ),
      ),
    );
  }

  Widget _scannedPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mint.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.mint, size: 20),
              const SizedBox(width: 10),
              Text(
                'qr scanned',
                style: AppTypography.eyebrow(color: AppColors.mint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upiData != null)
            _upiInfo()
          else
            Text(
              _scannedData!,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (_upiData != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedWithPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to pay'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _upiInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_upiData!['pa'] != null) _kv('UPI ID', _upiData!['pa']!),
        if (_upiData!['pn'] != null) _kv('Name', _upiData!['pn']!),
        if (_upiData!['am'] != null) _kv('Amount', '₹${_upiData!['am']}'),
      ],
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              key,
              style: AppTypography.eyebrow(size: 10),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructions() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.qr_code_2_rounded,
              color: AppColors.ink, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          'Point camera at a QR',
          style: AppTypography.heading(size: 17),
        ),
        const SizedBox(height: 4),
        Text(
          'Any UPI QR code works.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
            child: _action(Icons.photo_library_outlined, 'Gallery',
                _pickFromGallery)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.qr_code_rounded, 'My QR', _showMyQR)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.refresh_rounded, 'Rescan', _rescan)),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _scannedData = code;
          _upiData = _parseUpiData(code);
        });
      }
    }
  }

  Map<String, String>? _parseUpiData(String qrData) {
    try {
      if (qrData.startsWith('upi://pay?') || qrData.contains('pa=')) {
        final uri = Uri.parse(qrData);
        final Map<String, String> upiData = {};
        uri.queryParameters.forEach((key, value) {
          upiData[key] = value;
        });
        return upiData.isNotEmpty ? upiData : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  void _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showSnackBar('Gallery QR scanning is coming soon');
    }
  }

  void _showMyQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyQRPage()),
    );
  }

  void _rescan() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _upiData = null;
    });
  }

  void _proceedWithPayment() {
    if (_upiData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayToUpiIdPage(
            prefilledUpiId: _upiData!['pa'],
            prefilledAmount: _upiData!['am'],
            prefilledName: _upiData!['pn'],
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
