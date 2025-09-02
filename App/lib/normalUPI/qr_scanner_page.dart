import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../payToUpiId/payToUpiId.dart';
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
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2B5A),
          title: const Text(
            'Camera Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Please grant camera permission to scan QR codes.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      body: Column(
        children: [
          // Custom App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // Camera View
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: _onQRDetected,
                    ),
                    // Overlay
                    _buildScannerOverlay(),
                    // Corner decorations
                    ..._buildCornerDecorations(),
                    // Scanning animation
                    if (_isScanning) _buildScanningAnimation(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_scannedData != null) ...[
                    _buildScannedDataDisplay(),
                  ] else ...[
                    _buildInstructions(),
                  ],
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFF10B981),
          borderRadius: 20,
          borderLength: 30,
          borderWidth: 8,
          cutOutSize: 250,
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      // Top-left
      Positioned(
        top: 60,
        left: 60,
        child: _buildCornerDecoration(true, true),
      ),
      // Top-right
      Positioned(
        top: 60,
        right: 60,
        child: _buildCornerDecoration(true, false),
      ),
      // Bottom-left
      Positioned(
        bottom: 60,
        left: 60,
        child: _buildCornerDecoration(false, true),
      ),
      // Bottom-right
      Positioned(
        bottom: 60,
        right: 60,
        child: _buildCornerDecoration(false, false),
      ),
    ];
  }

  Widget _buildCornerDecoration(bool isTop, bool isLeft) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF10B981), width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF10B981), width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF10B981), width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF10B981), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF10B981),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannedDataDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'QR Code Scanned Successfully',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_upiData != null) ...[
            _buildUpiInfo(),
          ] else ...[
            Text(
              _scannedData!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 15),
          if (_upiData != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedWithPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpiInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_upiData!['pa'] != null) ...[
          const Text(
            'UPI ID:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            _upiData!['pa']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_upiData!['pn'] != null) ...[
          const Text(
            'Merchant Name:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            _upiData!['pn']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_upiData!['am'] != null) ...[
          const Text(
            'Amount:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            '₹${_upiData!['am']}',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          'Point your camera at a QR code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The QR code will be scanned automatically',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          Icons.photo_library,
          'Gallery',
          _pickFromGallery,
        ),
        _buildActionButton(
          Icons.qr_code,
          'My QR',
          _showMyQR,
        ),
        _buildActionButton(
          Icons.refresh,
          'Rescan',
          _rescan,
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2B5A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        
        // Vibrate on successful scan
        _vibrate();
      }
    }
  }

  Map<String, String>? _parseUpiData(String qrData) {
    try {
      // Parse UPI QR code format
      if (qrData.startsWith('upi://pay?') || qrData.contains('pa=')) {
        final uri = Uri.parse(qrData);
        final Map<String, String> upiData = {};
        
        uri.queryParameters.forEach((key, value) {
          upiData[key] = value;
        });
        
        return upiData.isNotEmpty ? upiData : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _vibrate() {
    // Add haptic feedback here if needed
    // HapticFeedback.mediumImpact();
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Here you would typically use a library to decode QR from image
      // For now, show a placeholder message
      _showSnackBar('Gallery QR scanning feature coming soon!');
    }
  }

  void _showMyQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyQRPage(),
      ),
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
          builder: (context) => PayToUpiIdPage(
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2B5A),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderRadius;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - 2 * borderWidth,
      cutOutHeight - 2 * borderWidth,
    );

    // Background
    canvas
      ..drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()
              ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
              ..close(),
          ),
          backgroundPaint);

    // Top left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.left, cutOutRect.top)
          ..lineTo(cutOutRect.left, cutOutRect.top - borderLength),
        boxPaint);

    // Top right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.right, cutOutRect.top)
          ..lineTo(cutOutRect.right, cutOutRect.top - borderLength),
        boxPaint);

    // Bottom left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.left, cutOutRect.bottom)
          ..lineTo(cutOutRect.left, cutOutRect.bottom + borderLength),
        boxPaint);

    // Bottom right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.right, cutOutRect.bottom)
          ..lineTo(cutOutRect.right, cutOutRect.bottom + borderLength),
        boxPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
