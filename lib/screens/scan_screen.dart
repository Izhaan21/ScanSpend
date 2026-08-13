import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/ocr_service.dart';
import 'review_screen.dart';
import '../widgets/premium_background.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();
  final OCRService _ocrService = OCRService();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _imagePath;

  bool _isProcessing = false;
  String _loadingMessage = '';

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _captureFlashController;
  late Animation<double> _captureFlashAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Minimalist Premium Dark Palette
  static const Color _bg         = Color(0xFF090E17);
  static const Color _cardBg     = Color(0xFF141415);
  static const Color _primary    = Color(0xFF2563EB);
  static const Color _secondary  = Color(0xFF06B6D4);
  static const Color _border     = Colors.transparent;
  static const Color _textMuted  = Color(0xFF94A3B8);
  static const Color _text       = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.1, end: 0.88).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _captureFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _captureFlashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _captureFlashController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanLineController.dispose();
    _captureFlashController.dispose();
    _pulseController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final locStatus = await Permission.location.status;
    final camStatus = await Permission.camera.status;

    if (!locStatus.isGranted || !camStatus.isGranted) {
      if (!locStatus.isGranted && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(children: [
              Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 12),
              Text('Location Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
            content: const Text(
              'ScanSpend uses your location to automatically detect the correct local currency when scanning receipts abroad.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not Now', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

        if (proceed == true) {
          await [Permission.camera, Permission.location].request();
        } else {
          await Permission.camera.request();
        }
      } else {
        await [Permission.camera, Permission.location].request();
      }
    }

    final finalCamStatus = await Permission.camera.status;
    if (!finalCamStatus.isGranted) {
      if (mounted) _showError('Camera permission denied. Please enable it in system settings.');
      return;
    }

    final finalLocStatus = await Permission.location.status;
    if (finalLocStatus.isGranted && mounted) {
      context.read<SettingsProvider>().triggerGPSCurrencyDetection();
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        back,
        ResolutionPreset.veryHigh, // higher res = more pixels per character
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) _showError('Camera initialization failed: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final newState = !_isFlashOn;
      await _cameraController!.setFlashMode(
        newState ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _isFlashOn = newState);
    } catch (e) {
      _showError('Flash not supported on this device.');
    }
  }

  /// Tap-to-focus: convert a screen offset to a normalised camera point
  /// and set focus + exposure at that location.
  Future<void> _onTapToFocus(TapDownDetails details) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(details.globalPosition);
    final double x = local.dx / box.size.width;
    final double y = local.dy / box.size.height;
    final Offset point = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    try {
      await _cameraController!.setFocusPoint(point);
      await _cameraController!.setExposurePoint(point);
    } catch (_) {}
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    _captureFlashController.forward(from: 0).then((_) {
      _captureFlashController.reverse();
    });

    try {
      setState(() {
        _isProcessing = true;
        _loadingMessage = 'Capturing image...';
      });

      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }

      // Lock focus & exposure on centre before shooting
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFocusPoint(const Offset(0.5, 0.5));
        await _cameraController!.setExposurePoint(const Offset(0.5, 0.5));
        // Brief pause to let AF settle
        await Future.delayed(const Duration(milliseconds: 350));
      } catch (_) {}

      final XFile image = await _cameraController!.takePicture();

      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _imagePath = image.path;
        _loadingMessage = 'Analysing receipt...';
      });

      await _analyseAndNavigate(image.path);
    } catch (e) {
      _showError('Capture failed: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // lossless — preserve every pixel of receipt text
      );
      if (image == null) return;

      setState(() {
        _imagePath = image.path;
        _isProcessing = true;
        _loadingMessage = 'Analysing receipt...';
      });

      await _analyseAndNavigate(image.path);
    } catch (e) {
      _showError('Gallery selection failed: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyseAndNavigate(String imagePath) async {
    Map<String, dynamic>? result;

    try {
      if (mounted) setState(() => _loadingMessage = 'Reading receipt with AI...');
      result = await _aiService.parseReceiptImage(imagePath);
    } catch (e) {
      // Distinguish deliberate OCR-fallback sentinel from real errors.
      final msg = e.toString();
      if (msg.contains(AIService.kFallbackNeeded)) {
        debugPrint('Vision pass: fallback needed — starting OCR pipeline...');
      } else {
        debugPrint('Vision parsing failed ($msg) — trying OCR fallback...');
      }
      result = await _runOcrFallback(imagePath);
      if (result == null) return;
    }

    if (!mounted) return;

    bool navigated = false;
    try {
      context.read<ExpenseProvider>().setCurrentExpenseFromJson(result);
      navigated = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      debugPrint('Navigation to review failed: $e');
      if (mounted) _showError('Could not process the receipt. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _loadingMessage = '';
          if (!navigated) _imagePath = null;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _runOcrFallback(String imagePath) async {
    try {
      if (mounted) setState(() => _loadingMessage = 'Running OCR scan...');
      final rawText = await _ocrService.extractTextFromImage(imagePath);

      if (rawText.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _loadingMessage = '';
            _imagePath = null;
          });
          _showError(
            'No receipt text detected.\n\n'
            'Tips:\n• Ensure good lighting\n• Hold your device steady\n• Receipt should fill the frame',
          );
        }
        return null;
      }

      if (mounted) setState(() => _loadingMessage = 'Parsing text with AI...');
      final result = await _aiService.parseReceiptText(rawText);
      return result;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _loadingMessage = '';
          _imagePath = null;
        });
        final msg = e.toString();
        if (msg.contains('QUOTA_EXCEEDED')) {
          _showError(
            'Gemini AI limit reached.\n\n'
            'Please check your Google Cloud Console billing.',
          );
        } else {
          _showError('Could not extract receipt data.\n\n${msg.replaceAll('Exception: ', '')}');
        }
      }
      return null;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF111A2E),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
          SizedBox(width: 12),
          Text('Error', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
        content: Text(message,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraLayer(),
            if (_imagePath == null) _buildViewfinderLayer(context),
            _buildCaptureFlash(),
            _buildTopBar(context),
            if (!_isProcessing) _buildBottomControls(context),
            if (_isProcessing) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_imagePath != null) {
      return Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.2),
        colorBlendMode: BlendMode.darken,
      );
    }
    if (_isCameraInitialized && _cameraController != null) {
      return GestureDetector(
        onTapDown: _onTapToFocus,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }
    return Container(
      color: Colors.transparent,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 16),
            Text('Starting camera...',
                style: TextStyle(color: _textMuted, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderLayer(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vfWidth = size.width * 0.85;
    final vfHeight = vfWidth * (4 / 3);
    final vfLeft = (size.width - vfWidth) / 2;
    // Shift the viewfinder slightly up from the exact vertical center
    final vfTop = (size.height - vfHeight) / 2 - 40;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _ScanOverlayPainter(
            vfLeft: vfLeft,
            vfTop: vfTop,
            vfWidth: vfWidth,
            vfHeight: vfHeight,
            radius: 24,
          ),
        ),
        Positioned(
          left: vfLeft,
          top: vfTop,
          child: Container(
            width: vfWidth,
            height: vfHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Stack(
              children: [
                _corner(top: true, left: true),
                _corner(top: true, left: false),
                _corner(top: false, left: true),
                _corner(top: false, left: false),
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, child) => Positioned(
                    top: vfHeight * _scanLineAnim.value,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: vfTop + vfHeight + 24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111A2E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: const Text(
                'Align receipt within frame',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const double len = 24.0;
    const double thick = 3.0;
    const Color c = Colors.white;
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: len,
        height: len,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: (top && left) ? const Radius.circular(8) : Radius.zero,
            topRight: (top && !left) ? const Radius.circular(8) : Radius.zero,
            bottomLeft: (!top && left) ? const Radius.circular(8) : Radius.zero,
            bottomRight: (!top && !left) ? const Radius.circular(8) : Radius.zero,
          ),
          border: Border(
            top: top ? const BorderSide(color: c, width: thick) : BorderSide.none,
            bottom: !top ? const BorderSide(color: c, width: thick) : BorderSide.none,
            left: left ? const BorderSide(color: c, width: thick) : BorderSide.none,
            right: !left ? const BorderSide(color: c, width: thick) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureFlash() {
    return AnimatedBuilder(
      animation: _captureFlashAnim,
      builder: (_, child) => IgnorePointer(
        child: Container(
          color: Colors.white.withValues(alpha: _captureFlashAnim.value * 0.7),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBtn(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A2E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.document_scanner_rounded, size: 16, color: _primary),
                    SizedBox(width: 8),
                    Text(
                      'Scan receipt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                onTap: _toggleFlash,
                active: _isFlashOn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? _primary.withValues(alpha: 0.2)
              : const Color(0xFF111A2E).withValues(alpha: 0.9),
          border: Border.all(
            color: active ? _primary : _border,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? _primary : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 32, bottom: 48, left: 24, right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickFromGallery,
              child: _secondaryBtn(Icons.photo_library_outlined, 'Gallery'),
            ),
            GestureDetector(
              onTap: _captureImage,
              child: _captureBtn(),
            ),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Batch scanning coming soon',
                  ),
                  backgroundColor: _cardBg,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _secondaryBtn(Icons.auto_awesome_motion_rounded, 'Batch'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF111A2E).withValues(alpha: 0.9),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _captureBtn() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88 * _pulseAnim.value,
            height: 88 * _pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 1), width: 3),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: _primary,
              ),
              const SizedBox(height: 24),
              Text(
                _loadingMessage.isNotEmpty ? _loadingMessage : 'Processing...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double vfLeft;
  final double vfTop;
  final double vfWidth;
  final double vfHeight;
  final double radius;

  const _ScanOverlayPainter({
    required this.vfLeft,
    required this.vfTop,
    required this.vfWidth,
    required this.vfHeight,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xB3000000); // 70% opacity black

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vfLeft, vfTop, vfWidth, vfHeight),
          Radius.circular(radius),
        ),
      );

    final overlayPath =
        Path.combine(PathOperation.difference, fullPath, cutoutPath);

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.vfLeft != vfLeft ||
      old.vfTop != vfTop ||
      old.vfWidth != vfWidth ||
      old.vfHeight != vfHeight;
}
