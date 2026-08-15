import 'package:flutter/material.dart';

class JsonAnimationsPanel extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Map<String, dynamic>> savedAnimations;
  final String activePlayingId;
  final Function(Map<String, dynamic>) onPlay;
  final VoidCallback onStop;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  const JsonAnimationsPanel({
    super.key,
    required this.title,
    required this.accentColor,
    required this.savedAnimations,
    required this.activePlayingId,
    required this.onPlay,
    required this.onStop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
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
        children: [
          // HEADER PANEL COMPACT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.video_library_rounded, color: accentColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Daftar Animasi ($title)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${savedAnimations.length} Item',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (savedAnimations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada animasi tersimpan di $title',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            )
          else
            Column(
              children: savedAnimations.map((anim) {
                final bool isActive = activePlayingId == anim['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor.withValues(alpha: 0.08)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? accentColor : Colors.grey[200]!,
                      width: isActive ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // BADGE WARNA ITEM
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            (anim['color'] as Color).withValues(alpha: 0.2),
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: anim['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // INFORMASI ANIMASI RINGKAS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anim['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${anim['modeName']} • ${anim['duration']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TOMBOL ACTION: PLAY / EDIT / DELETE
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PLAY / STOP
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (isActive) {
                                onStop();
                              } else {
                                onPlay(anim);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isActive
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isActive ? Colors.redAccent : Colors.green[600],
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // EDIT BUTTON
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onEdit(anim),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // DELETE BUTTON
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onDelete(anim['id']),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 18,
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
