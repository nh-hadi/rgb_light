import 'package:flutter/material.dart';

class JsonAnimationsPanel extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Map<String, dynamic>> savedAnimations;
  final double globalBrightness;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  const JsonAnimationsPanel({
    super.key,
    required this.title,
    required this.accentColor,
    required this.savedAnimations,
    required this.globalBrightness,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String brightPercent = '${((globalBrightness / 255.0) * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER PANEL COMPACT WITH GLOBAL BRIGHTNESS BADGE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.video_library_rounded, color: accentColor, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    'Daftar Animasi ($title)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // BADGE KECERAHAN GLOBAL MASTER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 11, color: Color(0xFFD97706)),
                        const SizedBox(width: 3),
                        Text(
                          brightPercent,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // BADGE JUMLAH ITEM
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${savedAnimations.length} Item',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (savedAnimations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Belum ada animasi tersimpan di $title',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ),
            )
          else
            Column(
              children: savedAnimations.map((anim) {
                final color = anim['color'] is Color
                    ? anim['color'] as Color
                    : Colors.purpleAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // BADGE WARNA ITEM RINGKAS
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // INFORMASI ANIMASI RINGKAS & MEWAH
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              anim['name'] ?? 'Animasi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${anim['modeName'] ?? ''} • ${anim['speed'] ?? '70%'} • ${anim['duration'] ?? '10s'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TOMBOL ACTION: EDIT & DELETE RINGKAS
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onEdit(anim),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.blueAccent,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onDelete(anim['id']),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
