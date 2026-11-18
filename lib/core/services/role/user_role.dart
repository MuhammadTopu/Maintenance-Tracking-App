enum UserRole {
  normal('normal'),
  premium('premium');

  const UserRole(this.apiValue);

  final String apiValue;

  bool get isPremium => this == UserRole.premium;

  /// Anything that is not exactly "premium" is a normal user.
  static UserRole fromApi(String? value) {
    return value?.trim().toLowerCase() == 'premium'
        ? UserRole.premium
        : UserRole.normal;
  }
}

/// Everything in the app that depends on the role. Add new features here and
/// ask `RoleService.can(...)`, instead of scattering `isPremium` checks.
enum AppFeature {
  // Free
  upcomingService(UserRole.normal),
  serviceIntervals(UserRole.normal),

  // Premium (the same list the subscription screen advertises, plus the
  // premium-only endpoints: questions -> answers -> generate tasks).
  taskGeneration(UserRole.premium),
  receiptAttachments(UserRole.premium),
  forumSuggestions(UserRole.premium),
  shopSuggestions(UserRole.premium),
  seasonalSuggestions(UserRole.premium);

  const AppFeature(this.minimumRole);

  final UserRole minimumRole;
}