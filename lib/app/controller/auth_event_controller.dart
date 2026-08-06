
import 'dart:async';

enum AuthEvent { sessionExpired }

class AuthEventController {
  AuthEventController._internal();
  static final AuthEventController instance = AuthEventController._internal();

  final _controller = StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void fireSessionExpired() => _controller.add(AuthEvent.sessionExpired);

  void dispose() => _controller.close();
}