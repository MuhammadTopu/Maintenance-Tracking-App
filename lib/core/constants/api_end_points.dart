class ApiEndPoints {
  ApiEndPoints._();

  static const String baseUrl = 'http://206.162.244.151:8787';

  static String imagePath(String imageUrl) => '$baseUrl/uploads/$imageUrl';

  // auth
  static const String register1 = '$baseUrl/api/users/register-step1';
  static const String verifyOtp = '$baseUrl/api/users/verify-otp';
  static const String register3 = '$baseUrl/api/users/register-step3';
  static const String login = '$baseUrl/api/users/login';
  static const String getMe = '$baseUrl/api/users/get-me';

  // forget password
  static const String forgetPassword = '$baseUrl/api/users/forget_pass';
  static const String resetPasswordOtp = '$baseUrl/api/users/checkForgetPassOtp';
  static const String resetPassword = '$baseUrl/api/users/resetPass';

  // add item
  static const String addItem = '$baseUrl/api/items/add-item';
  static const String getAllItem = '$baseUrl/api/items/get-all-items';
  static String getModelFromTheBrand(String brandName) {
    return 'https://vpic.nhtsa.dot.gov/api/vehicles/getmodelsformake/$brandName?format=json';
  }
  static const String getAllPlane = '$baseUrl/api/admin/get-all-services';
  static String getOneItem(String itemId) => '$baseUrl/api/items/get-item/$itemId';
  static String getQuestion(String itemId) => '$baseUrl/api/items/$itemId/questions';
  static String answerQuestion(String itemId) => '$baseUrl/api/items/$itemId/generate-tasks';

  // payment
  static const String payment = '$baseUrl/api/payments/pay';

  // profile
  static const String updateUserImage = '$baseUrl/api/users/update-image';
  static const String updateUserDetails = '$baseUrl/api/users/update-user-details';
  static const String sendMailToAdmin = '$baseUrl/api/users/sende-mail';

  // tracking
  static const String getAllTaskList = '$baseUrl/api/items/all-tasks';
  static String getAllTaskListByItemId(String itemId) => '$baseUrl/api/items/$itemId/tasks';
  static String addReceiptByTaskId(String taskId) => '$baseUrl/api/items/upload-maintenance-history/$taskId';

  static String toggleTaskStatus(String taskId) => '$baseUrl/api/items/toggle-item-status/$taskId';
}
