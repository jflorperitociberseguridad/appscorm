import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course_model.dart';
import '../services/api/api_client.dart';
import '../services/api/api_exceptions.dart';
import '../services/api/auth_service.dart';
import '../services/api/course_api_service.dart';
import '../services/api/course_repository.dart';

class AuthState {
  final String? token;
  final DateTime? expiresAt;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.expiresAt, this.isLoading = false, this.error});

  AuthState copyWith({
    String? token,
    DateTime? expiresAt,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authToken = await _authService.login(email: email, password: password);
      state = state.copyWith(
        token: authToken.token,
        expiresAt: authToken.expiresAt,
        isLoading: false,
        error: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authNotifierProvider.select((value) => value.token));
  return ApiClient(tokenResolver: () => token);
});

final courseApiServiceProvider = Provider<CourseApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CourseApiService(client);
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final service = ref.watch(courseApiServiceProvider);
  return CourseRepository(service);
});

class CoursesListNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final CourseApiService _service;

  CoursesListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    state = const AsyncValue.loading();
    try {
      final courses = await _service.fetchCourses();
      state = AsyncValue.data(courses);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refresh() => loadCourses();
}

final coursesListProvider =
    StateNotifierProvider<CoursesListNotifier, AsyncValue<List<CourseModel>>>((ref) {
  final service = ref.watch(courseApiServiceProvider);
  return CoursesListNotifier(service);
});
