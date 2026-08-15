import 'package:flutter/material.dart';

import '../esp_udp_service.dart';
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.save_alt_rounded, color: widget.accentColor),
              const SizedBox(width: 8),
              Text(
                'Simpan Ke List (${widget.title})',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: _selectedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode: ${_selectedMode.name}\nTarget: ${widget.title}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
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
                      'speed': '${_speedPercent.round()}%',
                      'brightness': '${((_brightness / 255) * 100).round()}%',
                    });
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green[700],
                    content: Text(
                        '💾 Animasi "$name" Disimpan di ${widget.title}!'),
                  ),
                );
              },
              child: const Text('Simpan Ke List'),
            ),
          ],
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

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // RODA WARNA
            Center(
              child: ColorWheelPicker(
                initialColor: _selectedColor,
                size: 250.0,
                onColorChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                  widget.udpService.sendColor(color);
                },
                onColorEnd: (color) {
                  widget.udpService.sendColorDirect(color);
                },
              ),
            ),

            const SizedBox(height: 18),

            // KOTAK PREVIEW WARNA
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedColor,
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hexCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      'RGB: $r, $g, $b',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PANEL KECERAHAN & KECEPATAN (SESUAI GAMBAR DENGAN BADGE PIL & CARD)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.wb_sunny_rounded,
                              size: 18,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Kecerahan LED',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${((_brightness / 255.0) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: const Color(0xFFD97706),
                      overlayColor: const Color(0xFFFDE68A).withValues(alpha: 0.5),
                      trackHeight: 10,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
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
                        widget.udpService.sendBrightness(val.round());
                      },
                      onChangeEnd: (val) {
                        widget.udpService.sendBrightnessDirect(val.round());
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.2),
                  ),

                  // 2. KECEPATAN ANIMASI ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Kecepatan Animasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_speedPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF3B82F6),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: const Color(0xFF2563EB),
                      overlayColor: const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                      trackHeight: 10,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
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
                        widget.udpService.sendSpeed(delayMs);
                      },
                      onChangeEnd: (val) {
                        final delayMs = _calculateDelayMs(val);
                        widget.udpService.sendSpeedDirect(delayMs);
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
                          widget.udpService.sendMode(mode.id);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TOMBOL SIMPAN KE DAFTAR ANIMASI JSON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _showSaveAnimationDialog,
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: Text(
                      '💾 Simpan State Ini Ke List (${widget.title})',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PANEL DAFTAR ANIMASI JSON COMPACT + EDIT
            JsonAnimationsPanel(
              title: widget.title,
              accentColor: widget.accentColor,
              savedAnimations: _savedJsonAnimations,
              activePlayingId: _activePlayingAnimationId,
              onPlay: _playJsonAnimation,
              onStop: _stopJsonAnimation,
              onEdit: _showEditAnimationDialog,
              onDelete: _deleteJsonAnimation,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
