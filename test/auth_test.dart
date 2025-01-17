import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initilaized to begin with', () {
      expect(provider._isInitalized, false);
    });
    test('Cannot Log out if not initialized', () async {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });
    test('Should be able to be initialized', () async {
      await provider.initilaize();
      expect(provider._isInitalized, true);
    });
    test('User should be null after initilaization', () {
      expect(provider.currentUser, null);
    });
    test(
      'Shoud be able to initialize in less than 2 seconds',
      () async {
        await provider.initilaize();
        expect(provider._isInitalized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );
    test('Create User should delegate to logIn', () async {
      final badEmailUser = provider.createUser(
        email: 'foo@bar.com',
        password: 'anypassword',
      );
      expect(badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));

      final badPasswordUser = provider.createUser(
        email: 'someone@bar.com',
        password: 'foobar',
      );
      expect(badPasswordUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));

      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });
    test('Logged in user  should be able to get verified', () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });
    test('Should be able to log out and log in again', () async {
      await provider.logOut();
      await provider.logIn(
        email: 'email',
        password: 'passsword',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {
  final String message;
  NotInitializedException(this.message);
}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitalized = false;
  bool get isInitialized => _isInitalized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitalized) {
      throw NotInitializedException('Auth provider is not initialized');
    }
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initilaize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitalized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!_isInitalized) {
      throw NotInitializedException('Auth provider is not initialized');
    }
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw UserNotFoundAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!_isInitalized) {
      throw NotInitializedException('Auth provider is not initialized');
    }
    if (_user == null) {
      throw UserNotFoundAuthException();
    }
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitalized) {
      throw NotInitializedException('Auth provider is not initialized');
    }
    final user = _user;
    if (user == null) {
      throw UserNotFoundAuthException();
    }
    const newUser = AuthUser(isEmailVerified: true);
    _user = newUser;
  }
}
