class ApiEndPoints {
  ApiEndPoints._();

  static const String baseUrl = 'https://rrsc.kamranhossaintopu.me';

  static String imagePath(String imageUrl) => '$baseUrl/uploads/$imageUrl';

  static const Set<String> _localHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '10.0.2.2',
  };

  static String? resolveImageUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (!uri.hasScheme) {
      final path = value.startsWith('/') ? value.substring(1) : value;
      return path.startsWith('uploads/') ? '$baseUrl/$path' : imagePath(path);
    }

    if (_localHosts.contains(uri.host.toLowerCase())) {
      return Uri.parse(baseUrl)
          .replace(path: uri.path, query: uri.hasQuery ? uri.query : null)
          .toString();
    }
    return value;
  }

  // auth
  static const String register1 = '$baseUrl/api/users/register-step1';
  static const String verifyOtp = '$baseUrl/api/users/verify-otp';
  static const String register3 = '$baseUrl/api/users/register-step3';
  static const String login = '$baseUrl/api/users/login';
  static const String refreshToken = '$baseUrl/api/users/refresh-token';
  static const String getMe = '$baseUrl/api/users/get-me';

  // forget password
  static const String forgetPassword = '$baseUrl/api/users/forget_pass';
  static const String resetPasswordOtp =
      '$baseUrl/api/users/checkForgetPassOtp';
  static const String resetPassword = '$baseUrl/api/users/resetPass';

  // add item
  static const String addItem = '$baseUrl/api/items/add-item';
  static const String getAllItem = '$baseUrl/api/items/get-all-items';
  static String getModelFromTheBrand(String brandName) {
    return 'https://vpic.nhtsa.dot.gov/api/vehicles/getmodelsformake/$brandName?format=json';
  }

  static const String getAllPlane = '$baseUrl/api/admin/get-all-services';
  static String getOneItem(String itemId) =>
      '$baseUrl/api/items/get-item/$itemId';
  static String getQuestion(String itemId) =>
      '$baseUrl/api/items/$itemId/questions';
  static String generateTasks(String itemId) =>
      '$baseUrl/api/items/$itemId/generate-tasks';
  static String answerQuestion(String itemId) =>
      '$baseUrl/api/items/$itemId/submit-answers';

  // payment
  static const String payment = '$baseUrl/api/payments/pay';

  // profile
  static const String updateUserImage = '$baseUrl/api/users/update-image';
  static const String updateUserDetails =
      '$baseUrl/api/users/update-user-details';
  static const String sendMailToAdmin = '$baseUrl/api/users/sende-mail';
  static const String updatePassword = '$baseUrl/api/users/change-password';
  static const String deleteAccount = '$baseUrl/api/users/delete-account';
  static const String reportIssue = '$baseUrl/api/reports';

  // tracking
  static String getAllTaskList({
    String filter = 'all',
    int page = 1,
    int limit = 20,
  }) => '$baseUrl/api/items/all-tasks?filter=$filter&page=$page&limit=$limit';
  static String getAllTaskListByItemId(
    String itemId, {
    String filter = 'all',
    int page = 1,
    int limit = 20,
  }) =>
      '$baseUrl/api/items/$itemId/tasks?filter=$filter&page=$page&limit=$limit';
  static String addReceiptByTaskId(String taskId) =>
      '$baseUrl/api/items/upload-maintenance-history/$taskId';
  static String toggleTaskStatus(String taskId) =>
      '$baseUrl/api/items/toggle-task-status/$taskId';

  // notifications
  static String notifications({
    int page = 1,
    int limit = 20,
  }) => '$baseUrl/api/notifications?page=$page&limit=$limit';

  static const String readAllNotifications =
      '$baseUrl/api/notifications/read-all';

  static String readNotification(String id) =>
      '$baseUrl/api/notifications/$id/read';

  static String deleteNotification(String id) =>
      '$baseUrl/api/notifications/$id';
}
