import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/local_storage.dart';

class User {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        avatar: json['avatar'],
        preferences: json['preferences'] ?? {},
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar': avatar,
        'preferences': preferences,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

enum AuthState { loading, authenticated, unauthenticated, error }

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    try {
      await _localStorage.initialize();

      // Check for stored auth token
      final token = _localStorage.getAuthToken();
      if (token != null) {
        // Verify token with server
        final response = await _apiClient.get('/auth/verify');
        if (response.isSuccess) {
          final userData = _localStorage.getUser();
          if (userData != null) {
            state = AsyncValue.data(User.fromJson(userData));
            return;
          }
        } else {
          // Token is invalid, clear it
          await _localStorage.clearAuthTokens();
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
      });

      if (response.isSuccess) {
        final data = response.data;

        // Save tokens
        await _localStorage.saveAuthToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _localStorage.saveRefreshToken(data['refresh_token']);
        }

        // Save user data
        final user = User.fromJson(data['user']);
        await _localStorage.saveUser(user.toJson());

        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(response.error ?? 'Login failed', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
    bool acceptTerms = false,
    bool subscribeNewsletter = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'accept_terms': acceptTerms,
        'subscribe_newsletter': subscribeNewsletter,
      });

      if (response.isSuccess) {
        final data = response.data;

        // Save tokens
        await _localStorage.saveAuthToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _localStorage.saveRefreshToken(data['refresh_token']);
        }

        // Save user data
        final user = User.fromJson(data['user']);
        await _localStorage.saveUser(user.toJson());

        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(response.error ?? 'Registration failed', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      // Implementation would integrate with Google Sign-In
      final response = await _apiClient.post('/auth/google', data: {
        'provider': 'google',
        // 'id_token': googleIdToken,
      });

      if (response.isSuccess) {
        final data = response.data;

        await _localStorage.saveAuthToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _localStorage.saveRefreshToken(data['refresh_token']);
        }

        final user = User.fromJson(data['user']);
        await _localStorage.saveUser(user.toJson());

        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(response.error ?? 'Google login failed', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    state = const AsyncValue.loading();

    try {
      // Implementation would integrate with Sign in with Apple
      final response = await _apiClient.post('/auth/apple', data: {
        'provider': 'apple',
        // 'authorization_code': appleAuthCode,
      });

      if (response.isSuccess) {
        final data = response.data;

        await _localStorage.saveAuthToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _localStorage.saveRefreshToken(data['refresh_token']);
        }

        final user = User.fromJson(data['user']);
        await _localStorage.saveUser(user.toJson());

        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(response.error ?? 'Apple login failed', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Notify server of logout
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if server call fails
    }

    // Clear local data
    await _localStorage.clearAuthTokens();
    await _localStorage.clearUser();

    state = const AsyncValue.data(null);
  }

  Future<bool> resetPassword(String email) async {
    try {
      final response = await _apiClient.post('/auth/reset-password', data: {
        'email': email,
      });

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return false;

    try {
      final response = await _apiClient.put('/auth/profile', data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (avatar != null) 'avatar': avatar,
      });

      if (response.isSuccess) {
        final updatedUser = User.fromJson(response.data);
        await _localStorage.saveUser(updatedUser.toJson());
        state = AsyncValue.data(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    final currentUser = state.value;
    if (currentUser == null) return false;

    try {
      final response = await _apiClient.put('/auth/preferences', data: preferences);

      if (response.isSuccess) {
        final updatedUser = currentUser.copyWith(
          preferences: {...currentUser.preferences, ...preferences},
          updatedAt: DateTime.now(),
        );
        await _localStorage.saveUser(updatedUser.toJson());
        state = AsyncValue.data(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.put('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _apiClient.delete('/auth/account');

      if (response.isSuccess) {
        await _localStorage.clearAllData();
        state = const AsyncValue.data(null);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Provider definitions
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

final userProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(userProvider) != null;
});

final authStateProvider = Provider<AuthState>((ref) {
  final authAsync = ref.watch(authProvider);

  return authAsync.when(
    data: (user) => user != null ? AuthState.authenticated : AuthState.unauthenticated,
    loading: () => AuthState.loading,
    error: (_, __) => AuthState.error,
  );
});

final userPreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final user = ref.watch(userProvider);
  return user?.preferences ?? {};
});