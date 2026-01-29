import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/drive_service.dart';
import 'services/data_service.dart';
import 'services/verification_service.dart';
import 'services/enquiry_service.dart';
import 'services/booking_service.dart';
import 'services/availability_service.dart';
import 'services/notification_service.dart';

List<SingleChildWidget> getAppProviders() {
  return [
    Provider<AuthService>(create: (_) => AuthService()),
    Provider<DataService>(create: (_) => DataService()),
    Provider<AdminService>(create: (_) => AdminService()),
    Provider<DriveService>(create: (_) => DriveService()),
    Provider<VerificationService>(create: (_) => VerificationService()),
    Provider<EnquiryService>(create: (_) => EnquiryService()),
    Provider<BookingService>(create: (_) => BookingService()),
    Provider<AvailabilityService>(create: (_) => AvailabilityService()),
    Provider<NotificationService>(create: (_) => NotificationService()),
  ];
}
