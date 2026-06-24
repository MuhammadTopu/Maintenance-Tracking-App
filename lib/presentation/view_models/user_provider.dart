import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_response_model.dart';
import '../../domain/base_repository/auth_repository.dart';

class UserProvider extends ChangeNotifier {
  final AuthRepository _repository;
  UserProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool _avatarLoadFailed = false;
  bool get avatarLoadFailed => _avatarLoadFailed;
  void setAvatarError() {
    _avatarLoadFailed = true;
    notifyListeners();
  }

  UserResponse? _userResponse;
  UserResponse? get userResponse => _userResponse;

  Future<void> getUserDetails() async {
    setLoading(true);

    final response = await _repository.getUserDetails();

    if (response != null) {
      _userResponse = response;
      notifyListeners();
    }

    setLoading(false);
  }

  Future<String?> getUserName() async {
    return _userResponse?.data.name;
  }

  Future<String?> getUserEmail() async {
    return _userResponse?.data.email;
  }

  /// -------------------------------------------------------------------------
  /// Edit Profile
  /// -------------------------------------------------------------------------

  // ================= STATE =================
  File? image;
  final ImagePicker _picker = ImagePicker();

  bool isUpdating = false;
  bool isUploaded = false;

  String message = '';

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      image = File(picked.path);
    }

    notifyListeners();
  }

  // ================= UPDATE IMAGE =================
  Future<bool> updateUserImage() async {
    if (image == null) return false;

    setLoading(true);

    final result = await _repository.updateProfileImage(image!);

    isUploaded = result;
    setLoading(false);

    return result;
  }

  // ================= UPDATE DETAILS =================
  Future<bool> updateProfileDetails(String name, String address) async {
    setLoading(true);

    final result = await _repository.updateProfileDetails(
      name: name,
      address: address,
    );

    setLoading(false);
    notifyListeners();

    return result;
  }

  // ================= CLEAR IMAGE =================
  void clearImage() {
    image = null;
    notifyListeners();
  }

  /// -------------------------------------------------------------------------
  /// Security
  /// -------------------------------------------------------------------------

  bool _current = true;
  bool _new = true;
  bool _confirm = true;

  bool get current => _current;
  bool get newPassword => _new;
  bool get confirm => _confirm;

  void toggle(String field) {
    switch (field) {
      case 'current':
        _current = !_current;
        break;
      case 'new':
        _new = !_new;
        break;
      case 'confirm':
        _confirm = !_confirm;
        break;
    }
    notifyListeners();
  }

  bool _hasMinLength = false;
  bool _hasUpperAndLower = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  bool get hasMinLength => _hasMinLength;
  bool get hasUpperAndLower => _hasUpperAndLower;
  bool get hasNumber => _hasNumber;
  bool get hasSymbol => _hasSymbol;

  bool get isPasswordValid =>
      _hasMinLength && _hasUpperAndLower && _hasNumber && _hasSymbol;

  void validatePassword(String password) {
    _hasMinLength = password.length >= 8;

    _hasUpperAndLower = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password);

    _hasNumber = RegExp(r'(?=.*[0-9])').hasMatch(password);

    _hasSymbol = RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(password);

    notifyListeners();
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    setLoading(true);

    final result = await _repository.updatePassword(
      oldPassword: currentPassword,
      newPassword: newPassword,
    );

    setLoading(false);
    notifyListeners();

    return result;
  }
}
