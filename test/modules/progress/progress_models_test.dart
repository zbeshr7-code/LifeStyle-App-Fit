import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/progress/models/progress_entry_model.dart';
import 'package:soccer_sys/modules/progress/models/progress_photo_model.dart';

void main() {
  group('ProgressEntryModel', () {
    test('fromJson maps entry with nested photos', () {
      final entry = ProgressEntryModel.fromJson({
        'id': 'entry-1',
        'user_id': 'user-1',
        'recorded_at': '2026-06-01',
        'weight_kg': 75.5,
        'note': 'Week 4',
        'created_at': '2026-06-01T10:00:00Z',
        'updated_at': '2026-06-01T10:00:00Z',
        'trainee_progress_photos': [
          {
            'id': 'photo-1',
            'entry_id': 'entry-1',
            'storage_path': 'user-1/entry-1/photo-1.jpg',
            'sort_order': 1,
            'created_at': '2026-06-01T10:00:00Z',
          },
          {
            'id': 'photo-0',
            'entry_id': 'entry-1',
            'storage_path': 'user-1/entry-1/photo-0.jpg',
            'sort_order': 0,
            'created_at': '2026-06-01T10:00:00Z',
          },
        ],
      });

      expect(entry.id, 'entry-1');
      expect(entry.weightKg, 75.5);
      expect(entry.photos.length, 2);
      expect(entry.photos.first.id, 'photo-0');
      expect(entry.photos.first.sortOrder, 0);
    });
  });

  group('ProgressPhotoModel', () {
    test('copyWith preserves fields and updates url', () {
      final photo = ProgressPhotoModel.fromJson({
        'id': 'p1',
        'entry_id': 'e1',
        'storage_path': 'path.jpg',
        'sort_order': 0,
        'created_at': '2026-06-01T10:00:00Z',
      });

      final updated = photo.copyWith(resolvedUrl: 'https://example.com/x.jpg');
      expect(updated.resolvedUrl, 'https://example.com/x.jpg');
      expect(updated.storagePath, 'path.jpg');
    });
  });
}
