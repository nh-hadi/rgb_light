import 'dart:async';
import 'package:flutter/material.dart';

import '../esp_udp_service.dart';
import '../models/preset_model.dart';
import '../widgets/color_wheel_picker.dart';
import '../widgets/json_animations_panel.dart';
import '../ws2812fx_modes.dart';

class SingleStripControlScreen extends StatefulWidget {
  final int targetId; // 0 = Both, 1 = D4, 2 = D5
  final String title;
  final Color accentColor;
  final EspUdpService udpService;

  const SingleStripControlScreen({
    super.key,
    required this.targetId,
    required this.title,
    required this.accentColor,
    required this.udpService,
  });

  @override
  State<SingleStripControlScreen> createState() =>
      _SingleStripControlScreenState();
}

class _SingleStripControlScreenState extends State<SingleStripControlScreen> {
  Color _selectedColor = const Color(0xFFFF3B30);
  double _brightness = 255.0;
  double _speedPercent = 70.0;
  WS2812FXMode _selectedMode = kWS2812FXModes[12];
  String _activePlayingAnimationId = '';
  bool _isWheelDragging = false;
  bool _isPreviewMode = true;
  Timer? _inactivityTimer;

  // NAMA FILE JSON TERPISAH BERDASARKAN TARGET STRIP (D4 vs D5)
  String get _presetFileName =>
      widget.targetId == 1 ? 'presets_d4.json' : 'presets_d5.json';

  // STATE SAVED PRESET UNTUK REVERT OTOMATIS
  Color _savedColor = const Color(0xFFFF3B30);
  double _savedBrightness = 255.0;
  double _savedSpeedPercent = 70.0;
  WS2812FXMode _savedMode = kWS2812FXModes[12];

  void _saveCurrentStateAsPreset() {
    setState(() {
      _savedColor = _selectedColor;
      _savedBrightness = _brightness;
      _savedSpeedPercent = _speedPercent;
      _savedMode = _selectedMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    if (_isPreviewMode) {
      _revertToSavedPreset();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    if (_isPreviewMode) {
      _revertToSavedPreset();
    }
    super.deactivate();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isPreviewMode) {
      _inactivityTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isPreviewMode) {
          setState(() {
            _isPreviewMode = false;
          });
          _revertToSavedPreset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 2),
              content: Text('⏱️ Live Preview Timeout (30d). Kembali ke Preset tersimpan.'),
            ),
          );
        }
      });
    }
  }

  void _revertToSavedPreset() {
    setState(() {
      _selectedColor = _savedColor;
      _brightness = _savedBrightness;
      _speedPercent = _savedSpeedPercent;
      _selectedMode = _savedMode;
    });

    final delayMs = _calculateDelayMs(_savedSpeedPercent);
    widget.udpService.sendColorDirect(_savedColor);
    widget.udpService.sendBrightnessDirect(_savedBrightness.round());
    widget.udpService.sendMode(_savedMode.id);
    widget.udpService.sendSpeedDirect(delayMs);
  }

  void _activatePreviewAndSend(VoidCallback sendAction) {
    if (!_isPreviewMode) {
      setState(() {
        _isPreviewMode = true;
      });
    }
    _resetInactivityTimer();
    sendAction();
  }

  final List<Map<String, dynamic>> _savedJsonAnimations = [
    {
      'id': '1',
      'name': 'Rainbow Flow',
      'modeName': 'Rainbow Cycle',
      'duration': '10 Detik',
      'color': Colors.purpleAccent,
      'speed': '80%',
      'brightness': '100%',
    },
    {
      'id': '2',
      'name': 'Strobe Night',
      'modeName': 'Police Strobe',
      'duration': '15 Detik',
      'color': Colors.redAccent,
      'speed': '95%',
      'brightness': '100%',
    },
  ];

  int _calculateDelayMs(double percent) {
    final delay = 3000 - ((percent / 100.0) * 2900);
    return delay.round().clamp(100, 3000);
  }

  void _showSaveAnimationDialog() {
    final nameController = TextEditingController(text: _selectedMode.name);
    final durationController = TextEditingController(text: '10');

    final int r = (_selectedColor.r * 255).round();
    final int g = (_selectedColor.g * 255).round();
    final int b = (_selectedColor.b * 255).round();
    final String hexCode =
        '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    final String brightPercent = '${((_brightness / 255.0) * 100).round()}%';
    final String speedPercent = '${_speedPercent.round()}%';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER BERWARNA GRADIENT
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Simpan Animasi JSON',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                widget.title,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.accentColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // COMPACT VIBRANT PARAMETER BADGES (CARD WARNA-WARNI RINGKAS)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // COLOR BADGE WITH GLOW
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedColor,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedMode.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hexCode,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // SPEED BADGE (PER ANIMATION)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.speed_rounded, size: 13, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text('Kecepatan: $speedPercent', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // GLOBAL BRIGHTNESS NOTICE
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wb_sunny_rounded, size: 13, color: Color(0xFFD97706)),
                                    SizedBox(width: 4),
                                    Text('Kecerahan: Global', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // INPUT FORMS COMPACT
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Nama Animasi',
                        isDense: true,
                        prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Durasi Berjalan',
                        suffixText: 'Detik',
                        isDense: true,
                        prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ACTION BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.save_alt_rounded, size: 16),
                          onPressed: () {
                            final name = nameController.text.trim();
                            final durSec = durationController.text.trim();
                            if (name.isNotEmpty) {
                              setState(() {
                                _savedJsonAnimations.add({
                                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                  'name': name,
                                  'modeName': _selectedMode.name,
                                  'duration': '$durSec Detik',
                                  'color': _selectedColor,
                                  'speed': speedPercent,
                                  'brightness': brightPercent,
                                });
                              });
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green[700],
                                content: Text('💾 Animasi "$name" Disimpan ke List JSON!'),
                              ),
                            );
                          },
                          label: const Text('Simpan Ke List', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditAnimationDialog(Map<String, dynamic> anim) {
    final nameController = TextEditingController(text: anim['name']);
    final rawDur = (anim['duration'] as String).replaceAll(' Detik', '');
    final durationController = TextEditingController(text: rawDur);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Edit Detail Animasi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Animasi',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Durasi Berjalan (Detik)',
                  suffixText: 'Detik',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final newName = nameController.text.trim();
                final newDur = durationController.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    anim['name'] = newName;
                    anim['duration'] = '$newDur Detik';
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.blue[700],
                    content: Text('✏️ Animasi "$newName" Berhasil Diperbarui!'),
                  ),
                );
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  void _playJsonAnimation(Map<String, dynamic> anim) {
    setState(() {
      _activePlayingAnimationId = anim['id'];
    });
    widget.udpService.sendMode(_selectedMode.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[700],
        content: Text(
            '▶️ Memutar Animasi JSON: ${anim['name']} (${widget.title})'),
      ),
    );
  }

  void _stopJsonAnimation() {
    setState(() {
      _activePlayingAnimationId = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.grey,
        content: Text('⏹️ Animasi Dihentikan'),
      ),
    );
  }

  void _deleteJsonAnimation(String id) {
    setState(() {
      _savedJsonAnimations.removeWhere((item) => item['id'] == id);
      if (_activePlayingAnimationId == id) {
        _activePlayingAnimationId = '';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Animasi Dihapus dari List')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int r = (_selectedColor.r * 255).round();
    final int g = (_selectedColor.g * 255).round();
    final int b = (_selectedColor.b * 255).round();

    final String hexCode =
        '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 360.0).clamp(0.72, 1.0);

    final double dynamicTopPadding = statusBarHeight + (64.0 * scale) + 12.0;
    final double dynamicBottomPadding = (76.0 * scale) + bottomInset + 16.0;

    return SingleChildScrollView(
      physics: _isWheelDragging
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.0, dynamicTopPadding, 20.0, dynamicBottomPadding),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // PANEL RODA WARNA (WRAPPER CARD MODERN & SLEEK)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // HEADER PANEL RODA WARNA WITH PREVIEW MODE SWITCH
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              size: 18,
                              color: _selectedColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Warna LED',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),

                      // TOMBOL SWITCH MODE PREVIEW DI KANAN HEADER PANEL
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _isPreviewMode = !_isPreviewMode;
                          });
                          if (_isPreviewMode) {
                            _resetInactivityTimer();
                          } else {
                            _inactivityTimer?.cancel();
                            _revertToSavedPreset();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text(
                                _isPreviewMode
                                    ? '👁️ Live Preview ON (Auto-Revert 30d)'
                                    : '▶️ Live Preview OFF. Revert ke Preset tersimpan.',
                              ),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isPreviewMode
                                ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isPreviewMode
                                  ? const Color(0xFF0284C7)
                                  : Colors.grey[300]!,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPreviewMode
                                    ? Icons.remove_red_eye_rounded
                                    : Icons.play_circle_outline_rounded,
                                size: 15,
                                color: _isPreviewMode
                                    ? const Color(0xFF0284C7)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isPreviewMode ? 'Preview ON' : 'Preview OFF',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isPreviewMode
                                      ? const Color(0xFF0284C7)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // RODA WARNA DENGAN PENGUNCI DRAG
                  Center(
                    child: ColorWheelPicker(
                      initialColor: _selectedColor,
                      size: 240.0,
                      onDragStart: () {
                        setState(() {
                          _isWheelDragging = true;
                        });
                      },
                      onDragEnd: () {
                        setState(() {
                          _isWheelDragging = false;
                        });
                      },
                      onColorChanged: (color) {
                        setState(() {
                          _selectedColor = color;
                        });
                        _activatePreviewAndSend(() => widget.udpService.sendColor(color));
                      },
                      onColorEnd: (color) {
                        _activatePreviewAndSend(() => widget.udpService.sendColorDirect(color));
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // KOTAK PREVIEW WARNA AKTIF (MENGAPIT KODE HEX & RGB)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hexCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'RGB: $r, $g, $b',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // PRESET WARNA CEPAT (PALET WARNA FAVORIT)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: const [
                        Color(0xFFFF3B30), // Red
                        Color(0xFFFF9500), // Orange
                        Color(0xFFFFCC00), // Yellow
                        Color(0xFF34C759), // Green
                        Color(0xFF5AC8FA), // Cyan
                        Color(0xFF007AFF), // Blue
                        Color(0xFFAF52DE), // Purple
                        Color(0xFFFF2D55), // Pink
                        Color(0xFFFFFFFF), // White
                      ].map((color) {
                        final bool isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                            _activatePreviewAndSend(() {
                              widget.udpService.sendColor(color);
                              widget.udpService.sendColorDirect(color);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSelected ? 32 : 28,
                            height: isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected ? widget.accentColor : Colors.grey[300]!,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: color.computeLuminance() > 0.6
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PANEL KECERAHAN & KECEPATAN (COMPACT HIGH DENSITY)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. KECERAHAN LED ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.wb_sunny_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Kecerahan LED',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${((_brightness / 255.0) * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // TOMBOL EKSPLISIT SIMPAN KECERAHAN KE MEMORI ESP8266
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              widget.udpService.sendBrightnessDirect(_brightness.round());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.amber[800],
                                  content: Text(
                                    '💾 Kecerahan Global (${((_brightness / 255.0) * 100).round()}%) Disimpan di ESP8266!',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: const Color(0xFFD97706),
                      overlayColor: const Color(0xFFFDE68A).withValues(alpha: 0.5),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _brightness,
                      min: 0,
                      max: 255,
                      onChanged: (val) {
                        setState(() {
                          _brightness = val;
                        });
                        _activatePreviewAndSend(() => widget.udpService.sendBrightness(val.round()));
                      },
                      onChangeEnd: (val) {
                        _activatePreviewAndSend(() => widget.udpService.sendBrightnessDirect(val.round()));
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                  ),

                  // 2. KECEPATAN ANIMASI ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Kecepatan Animasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_speedPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF3B82F6),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: const Color(0xFF2563EB),
                      overlayColor: const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _speedPercent,
                      min: 0,
                      max: 100,
                      onChanged: (val) {
                        setState(() {
                          _speedPercent = val;
                        });
                        final delayMs = _calculateDelayMs(val);
                        _activatePreviewAndSend(() => widget.udpService.sendSpeed(delayMs));
                      },
                      onChangeEnd: (val) {
                        final delayMs = _calculateDelayMs(val);
                        _activatePreviewAndSend(() => widget.udpService.sendSpeedDirect(delayMs));
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // EFEK ANIMASI DROPDOWN
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 18,
                      color: Colors.purple[600],
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Efek Animasi LED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WS2812FXMode>(
                      value: _selectedMode,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down_rounded,
                          color: Colors.purple[700], size: 24),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                      items: kWS2812FXModes.map((mode) {
                        return DropdownMenuItem<WS2812FXMode>(
                          value: mode,
                          child: Text(mode.name),
                        );
                      }).toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          setState(() {
                            _selectedMode = mode;
                          });
                          _activatePreviewAndSend(() => widget.udpService.sendMode(mode.id));
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TOMBOL SIMPAN PRESET (ULTRA-MODERN IOT STYLING)
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _saveCurrentStateAsPreset();
                        _showSaveAnimationDialog();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Simpan Preset Animasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // PANEL DAFTAR ANIMASI JSON COMPACT (KHUSUS EDIT & DELETE)
            JsonAnimationsPanel(
              title: widget.title,
              accentColor: widget.accentColor,
              savedAnimations: _savedJsonAnimations,
              globalBrightness: _brightness,
              onEdit: _showEditAnimationDialog,
              onDelete: _deleteJsonAnimation,
            ),

            const SizedBox(height: 90),
          ],
        ),
      );
  }
}
