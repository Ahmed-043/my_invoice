import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// State definition for Supabase Backend / BLoC
abstract class SupabaseState {
  const SupabaseState();
}

class SupabaseInitialState extends SupabaseState {
  const SupabaseInitialState();
}

class SupabaseLoadingState extends SupabaseState {
  const SupabaseLoadingState();
}

class SupabaseAuthenticatedState extends SupabaseState {
  final User user;
  const SupabaseAuthenticatedState(this.user);
}

class SupabaseUnauthenticatedState extends SupabaseState {
  const SupabaseUnauthenticatedState();
}

class SupabaseDataLoadedState extends SupabaseState {
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> services;
  const SupabaseDataLoadedState({required this.projects, required this.services});
}

class SupabaseErrorState extends SupabaseState {
  final String errorMessage;
  const SupabaseErrorState(this.errorMessage);
}

/// BLoC Event definitions
abstract class SupabaseEvent {
  const SupabaseEvent();
}

class CheckAuthEvent extends SupabaseEvent {
  const CheckAuthEvent();
}

class SignInEvent extends SupabaseEvent {
  final String email;
  final String password;
  const SignInEvent({required this.email, required this.password});
}

class SignUpEvent extends SupabaseEvent {
  final String email;
  final String password;
  final String name;
  final String businessName;
  final String phone;

  const SignUpEvent({
    required this.email,
    required String password,
    required this.name,
    this.businessName = '',
    this.phone = '',
  }) : password = password;
}

class SignOutEvent extends SupabaseEvent {
  const SignOutEvent();
}

class LoadDashboardDataEvent extends SupabaseEvent {
  const LoadDashboardDataEvent();
}

/// Supabase Backend BLoC implementation
class SupabaseBloc {
  final SupabaseService _service = SupabaseService();

  final _stateController = StreamController<SupabaseState>.broadcast();
  Stream<SupabaseState> get stream => _stateController.stream;

  SupabaseState _currentState = const SupabaseInitialState();
  SupabaseState get state => _currentState;

  void emit(SupabaseState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> handleEvent(SupabaseEvent event) async {
    if (event is CheckAuthEvent) {
      final user = _service.currentUser;
      if (user != null) {
        emit(SupabaseAuthenticatedState(user));
      } else {
        emit(const SupabaseUnauthenticatedState());
      }
    } else if (event is SignInEvent) {
      emit(const SupabaseLoadingState());
      try {
        final response = await _service.signIn(
          email: event.email,
          password: event.password,
        );
        if (response.user != null) {
          emit(SupabaseAuthenticatedState(response.user!));
        } else {
          emit(const SupabaseErrorState('Sign in failed'));
        }
      } catch (e) {
        emit(SupabaseErrorState(e.toString()));
      }
    } else if (event is SignUpEvent) {
      emit(const SupabaseLoadingState());
      try {
        final response = await _service.signUp(
          email: event.email,
          password: event.password,
          name: event.name,
          businessName: event.businessName,
          phone: event.phone,
        );
        if (response.user != null) {
          emit(SupabaseAuthenticatedState(response.user!));
        } else {
          emit(const SupabaseErrorState('Registration failed'));
        }
      } catch (e) {
        emit(SupabaseErrorState(e.toString()));
      }
    } else if (event is SignOutEvent) {
      await _service.signOut();
      emit(const SupabaseUnauthenticatedState());
    } else if (event is LoadDashboardDataEvent) {
      emit(const SupabaseLoadingState());
      try {
        final projects = await _service.getProjects();
        final services = await _service.getPredefinedServices();
        emit(SupabaseDataLoadedState(projects: projects, services: services));
      } catch (e) {
        emit(SupabaseErrorState(e.toString()));
      }
    }
  }

  void dispose() {
    _stateController.close();
  }
}
