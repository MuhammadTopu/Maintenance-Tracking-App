abstract class SupportMailRepository {
  Future<String?> sendSupportMail({
    required String subject,
    required String message,
  });
}