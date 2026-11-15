abstract class SupportMailRepository {
  Future<String?> sendSupportMail({
    required String subject,
    required String message,
  });
  Future<bool> deleteAccount({
    required String password,
    required String reason,
  });

  Future<bool> reportIssue({
    required String type,
    required String subject,
    required String description,
  });
}