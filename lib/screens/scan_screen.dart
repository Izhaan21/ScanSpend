import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/expense_provider.dart';
import '../services/ai_service.dart';
import '../services/ocr_service.dart';
import 'review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();
  final OCRService _ocrService = OCRService();

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _imagePath;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isProcessing = false;
  String _loadingMessage = '';

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _captureFlashController;
  late Animation<double> _captureFlashAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const Color _accentColor = Color(0xFF89F5E7);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Scanning line animation (repeating up-down)
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.1, end: 0.85).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Capture flash feedback
    _captureFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _captureFlashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _captureFlashController, curve: Curves.easeOut),
    );

    // Pulse ring around capture button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
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

  // ── Camera Init ────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        _showError('Camera permission denied. Please enable it in settings.');
      }
      return;
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      // Set initial flash mode
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) _showError('Camera init failed: $e');
    }
  }

  // ── Flash Toggle ───────────────────────────────────────────────────────────
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

  // ── Capture ────────────────────────────────────────────────────────────────
  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    // Flash feedback
    _captureFlashController.forward(from: 0).then((_) {
      _captureFlashController.reverse();
    });

    try {
      setState(() {
        _isProcessing = true;
        _loadingMessage = 'Capturing...';
      });

      // Turn off torch before capture so it doesn't blow out the image
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }

      final XFile image = await _cameraController!.takePicture();

      // Restore torch
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _imagePath = image.path;
        _loadingMessage = 'Analysing receipt with AI...';
      });

      await _analyseAndNavigate(image.path);
    } catch (e) {
      _showError('Capture failed: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Gallery Pick ───────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      setState(() {
        _imagePath = image.path;
        _isProcessing = true;
        _loadingMessage = 'Analysing receipt with AI...';
      });

      await _analyseAndNavigate(image.path);
    } catch (e) {
      _showError('Gallery pick failed: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Core analysis + navigation ─────────────────────────────────────────────
  Future<void> _analyseAndNavigate(String imagePath) async {
    Map<String, dynamic>? result;

    try {
      // ── Step 1: Gemini direct vision parse ───────────────────────────────
      if (mounted) setState(() => _loadingMessage = '🔍 Reading receipt with AI…');
      result = await _aiService.parseReceiptImage(imagePath);

    } catch (e) {
      final msg = e.toString();

      if (msg.contains('_fallback_needed')) {
        // ── Step 2: Vision returned unknown — try OCR → text parse ─────
        result = await _runOcrFallback(imagePath);
        if (result == null) return; // error already shown

      } else if (msg.contains('QUOTA_EXCEEDED')) {
        if (mounted) {
          setState(() { _isProcessing = false; _loadingMessage = ''; _imagePath = null; });
          _showError(
            'Gemini API quota exceeded.\n\n'
            'Your free-tier daily limit is reached.\n'
            'Fix: Go to console.cloud.google.com → Enable billing on your project.',
          );
        }
        return;

      } else if (msg.contains('INVALID_KEY')) {
        if (mounted) {
          setState(() { _isProcessing = false; _loadingMessage = ''; _imagePath = null; });
          _showError('Invalid Gemini API key.\nCheck the key in AIService._apiKey.');
        }
        return;

      } else {
        // Unknown error — try OCR fallback before giving up
        result = await _runOcrFallback(imagePath);
        if (result == null) return;
      }
    }

    if (!mounted) return;

    // ── Navigate to Review screen ─────────────────────────────────────────
    context.read<ExpenseProvider>().setCurrentExpenseFromJson(result);
    setState(() { _isProcessing = false; _loadingMessage = ''; });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(imagePath: imagePath),
      ),
    );
  }

  /// OCR fallback: runs ML Kit text recognition then sends text to Gemini.
  /// Returns null and shows an error if both fail.
  Future<Map<String, dynamic>?> _runOcrFallback(String imagePath) async {
    try {
      if (mounted) setState(() => _loadingMessage = '📝 Running OCR scan…');
      final rawText = await _ocrService.extractTextFromImage(imagePath);

      if (rawText.trim().isEmpty) {
        if (mounted) {
          setState(() { _isProcessing = false; _loadingMessage = ''; _imagePath = null; });
          _showError(
            'No text detected in the image.\n\n'
            'Tips:\n• Ensure good lighting\n• Hold phone steady\n• Receipt should fill the frame',
          );
        }
        return null;
      }

      if (mounted) setState(() => _loadingMessage = '🤖 Parsing OCR text with AI…');
      final result = await _aiService.parseReceiptText(rawText);
      return result;

    } catch (e) {
      if (mounted) {
        setState(() { _isProcessing = false; _loadingMessage = ''; _imagePath = null; });
        final msg = e.toString();
        if (msg.contains('QUOTA_EXCEEDED')) {
          _showError(
            'Gemini API quota exceeded.\n\n'
            'Your free-tier daily limit is reached.\n'
            'Fix: Enable billing at console.cloud.google.com',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E2D4E),
        title: const Row(children: [
          Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 22),
          SizedBox(width: 10),
          Text('Scan Failed', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text(message,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF89F5E7))),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera / Image preview
          _buildCameraLayer(),

          // 2. Dark mask + viewfinder (only when not showing captured image)
          if (_imagePath == null) _buildViewfinderLayer(context),

          // 3. Capture flash feedback overlay
          _buildCaptureFlash(),

          // 4. Top bar
          _buildTopBar(context),

          // 5. Bottom controls
          if (!_isProcessing) _buildBottomControls(context),

          // 6. Loading overlay
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Camera layer ──────────────────────────────────────────────────────────
  Widget _buildCameraLayer() {
    if (_imagePath != null) {
      return Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.25),
        colorBlendMode: BlendMode.darken,
      );
    }
    if (_isCameraInitialized && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    // Camera initializing placeholder
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accentColor),
            SizedBox(height: 16),
            Text('Initialising camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Viewfinder ─────────────────────────────────────────────────────────────
  Widget _buildViewfinderLayer(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vfWidth = size.width * 0.85;
    final vfHeight = vfWidth * (4 / 3);
    final vfLeft = (size.width - vfWidth) / 2;
    // Estimate vertical center: viewfinder is inside a Column centered in the screen.
    // Column = vfHeight + 24 + ~44 (pill) + 8 + ~24 (dot row) = vfHeight + 100
    final colHeight = vfHeight + 100;
    final vfTop = (size.height - colHeight) / 2;

    return CustomPaint(
      painter: _ScanOverlayPainter(
        vfLeft: vfLeft,
        vfTop: vfTop,
        vfWidth: vfWidth,
        vfHeight: vfHeight,
        radius: 28,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                width: vfWidth,
                height: vfHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.0),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner brackets
                    _corner(top: true, left: true),
                    _corner(top: true, left: false),
                    _corner(top: false, left: true),
                    _corner(top: false, left: false),
                    // Animated scan line
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (_, child) => Positioned(
                        top: vfHeight * _scanLineAnim.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: const BoxDecoration(
                            color: _accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor,
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Align the receipt within the frame',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AUTODETECTING...',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
        ),
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const double len = 28.0;
    const double thick = 3.5;
    const Color c = _accentColor;
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
            topLeft: (top && left) ? const Radius.circular(10) : Radius.zero,
            topRight: (top && !left) ? const Radius.circular(10) : Radius.zero,
            bottomLeft:
                (!top && left) ? const Radius.circular(10) : Radius.zero,
            bottomRight:
                (!top && !left) ? const Radius.circular(10) : Radius.zero,
          ),
          border: Border(
            top: top
                ? const BorderSide(color: c, width: thick)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: c, width: thick)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: c, width: thick)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: c, width: thick)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Capture flash ──────────────────────────────────────────────────────────
  Widget _buildCaptureFlash() {
    return AnimatedBuilder(
      animation: _captureFlashAnim,
      builder: (_, child) => IgnorePointer(
        child: Container(
          color: Colors.white
              .withValues(alpha: _captureFlashAnim.value * 0.6),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close
              _iconBtn(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
              // Mode pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
                child: const Text(
                  'DOCUMENT MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Flash toggle
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? _accentColor.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: active
                ? _accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? _accentColor : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ── Bottom controls ─────────────────────────────────────────────────────────
  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 28, bottom: 36, left: 24, right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: _secondaryBtn(Icons.photo_library_outlined, 'Gallery'),
                ),
                // Capture button
                GestureDetector(
                  onTap: _captureImage,
                  child: _captureBtn(),
                ),
                // Multi-Scan (coming soon) with SOON badge
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '📂 Multi-Scan: Scan multiple receipts in one go — coming soon!',
                      ),
                      backgroundColor: Colors.grey.shade800,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _secondaryBtn(Icons.add_photo_alternate_outlined, 'Multi-Scan'),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOON',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            color: Colors.white.withValues(alpha: 0.1),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
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
          // Pulse ring
          Container(
            width: 92 * _pulseAnim.value,
            height: 92 * _pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3 * _pulseAnim.value),
                width: 2,
              ),
            ),
          ),
          // Main button
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06), width: 3),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFE2E8F0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading overlay ────────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _accentColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: _accentColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _loadingMessage.isNotEmpty ? _loadingMessage : 'Processing...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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

// ── Overlay painter: dark mask with transparent viewfinder cutout ─────────────
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
    final paint = Paint()..color = const Color(0xB3000000); // ~70% black

    // Full screen rect
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Transparent cutout (rounded rect for viewfinder)
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vfLeft, vfTop, vfWidth, vfHeight),
          Radius.circular(radius),
        ),
      );

    // Punch the hole: full screen minus the cutout
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
