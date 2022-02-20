import 'package:deliverzler/authentication/models/user_model.dart';
import 'package:deliverzler/authentication/repos/auth_repo.dart';
import 'package:deliverzler/authentication/viewmodels/auth_state.dart';
import 'package:deliverzler/core/routing/navigation_service.dart';
import 'package:deliverzler/core/routing/route_paths.dart';
import 'package:deliverzler/core/services/init_services/firebase_messaging_service.dart';
import 'package:deliverzler/core/utils/dialogs.dart';
import 'package:deliverzler/core/viewmodels/main_core_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider =
    StateNotifierProvider.autoDispose<AuthProvider, AuthState>((ref) {
  return AuthProvider(ref);
});

class AuthProvider extends StateNotifier<AuthState> {
  AuthProvider(this.ref) : super(const AuthState.noError()) {
    _mainCoreProvider = ref.read(mainCoreProvider);
    _authRepo = ref.read(authRepoProvider);
  }

  final Ref ref;
  late MainCoreProvider _mainCoreProvider;
  late AuthRepo _authRepo;

  signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    NavigationService.removeAllFocus();
    final _result = await _authRepo.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _result.fold(
      (l) {
        state = AuthState.error(errorText: l.message);
        AppDialogs.showServerErrorDialog(message: l.message);
      },
      (r) async {
        UserModel userModel = r;
        await submitLogin(userModel: userModel);
      },
    );
  }

  Future submitLogin({required UserModel? userModel}) async {
    debugPrint(userModel!.toMap().toString());
    final _result = await _mainCoreProvider.setUserInFirebase(userModel);
    _result.fold(
      (l) {
        state = AuthState.error(errorText: l.message);
        AppDialogs.showServerErrorDialog(message: l.message);
      },
      (r) async {
        UserModel userModel = r;
        _mainCoreProvider.setCurrentUser(userModel: userModel);
        subscribeUserToTopic();
        navigationToHomeScreen();
        state = const AuthState.noError();
      },
    );
  }

  subscribeUserToTopic() {
    FirebaseMessagingService.instance.subscribeToTopic(
      topic: 'general',
    );
  }

  navigationToHomeScreen() {
    NavigationService.pushReplacementAll(
      isNamed: true,
      page: RoutePaths.home,
    );
  }
}