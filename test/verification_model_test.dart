import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourism_app/core/models/verification_model.dart'; // Adjust path if needed

// Mock Timestamp for testing without Firebase
class MockTimestamp extends Timestamp {
  MockTimestamp(super.seconds, super.nanoseconds);
}

void main() {
  group('ProviderVerification Model Test', () {
    test('should correctly convert to Map', () {
      final now = DateTime.now();
      final verification = ProviderVerification(
        id: '123',
        providerId: 'user_001',
        documentType: 'ID Card',
        documentUrl: 'http://example.com/doc.jpg',
        status: VerificationStatus.pending,
        submittedAt: now,
      );

      final map = verification.toMap();

      expect(map['id'], '123');
      expect(map['providerId'], 'user_001');
      expect(map['status'], 'pending');
      expect(map['submittedAt'], isA<Timestamp>());
    });

    test('should correctly parse from Map', () {
      final now = DateTime.now();
      final map = {
        'id': '123',
        'providerId': 'user_001',
        'documentType': 'ID Card',
        'documentUrl': 'http://example.com/doc.jpg',
        'status': 'approved',
        'submittedAt': Timestamp.fromDate(now),
        'verifiedBy': 'admin_001',
      };

      final verification = ProviderVerification.fromMap(map);

      expect(verification.id, '123');
      expect(verification.status, VerificationStatus.approved);
      expect(verification.verifiedBy, 'admin_001');
    });

    test('should handle invalid status gracefully', () {
      final now = DateTime.now();
      final map = {
        'id': '123',
        'providerId': 'user_001',
        'documentType': 'ID Card',
        'documentUrl': 'http://example.com/doc.jpg',
        'status': 'unknown_status', // Invalid
        'submittedAt': Timestamp.fromDate(now),
      };

      final verification = ProviderVerification.fromMap(map);

      // Should default to pending or throw? My code defaults to pending
      expect(verification.status, VerificationStatus.pending);
    });
  });
}
