class InputValidators {
  static bool emailValidator(String? value) {
    String email = value?.trim() ?? '';
    RegExp regEx = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (regEx.hasMatch(email) == false) {
      return false;
    }
    return true;
  }

  static String? passwordValidator(String? value) {
    if ((value?.isEmpty ?? true) || (value!.length < 6)) {
      return 'Please enter password with at least 6 letters';
    }
    return null;
  }

  static String? nameValidator(String name, String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Please enter $name';
    }
    return null;
  }

  static String? phoneValidator(String? value) {
    String phone = value?.trim() ?? '';
    RegExp regExp = RegExp(r'^(?:\+8801|01)[3-9]\d{8}$');
    if (regExp.hasMatch(phone) == false) {
      return 'Please enter valid phone number';
    }
    return null;
  }
}