import 'package:bloc/bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mynotes/services/auth/auth_exceptions.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    // Handling Should Register First
    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(
        exception: null,
        isLoading: false,
      ));
    });
    // Forgot Password
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
        exception: null,
        hasSentEmail: false,
        isLoading: false,
      ));
      final email = event.email;
      if (email == null) {
        return; // User just wants to go to forgot password screen
      }
      // User wants to send a forgot password email
      emit(const AuthStateForgotPassword(
        exception: null,
        hasSentEmail: false,
        isLoading: true,
      ));
      bool didSendEmail;
      Exception? exception;
      try {
        await provider.sendPasswordReset(toEmail: email);
        didSendEmail = true;
        exception = null;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }
      emit(AuthStateForgotPassword(
        exception: exception,
        hasSentEmail: didSendEmail,
        isLoading: false,
      ));
    });
    // Send Email Verification
    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });
    // Registering
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(
          email: email,
          password: password,
        );
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(
          exception: e,
          isLoading: false,
        ));
      }
    });
    // Initialize
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user == null) {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(
          user: user,
          isLoading: false,
        ));
      }
    });

    // Log In
    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while I log you in',
        ),
      );
      final email = event.email;
      final password = event.password;

      try {
        final user = await provider.login(
          email: email,
          password: password,
        );

        if (!user.isEmailVerified) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(
            const AuthStateNeedsVerification(isLoading: false),
          );
        } else {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(AuthStateLoggedIn(
            user: user,
            isLoading: false,
          ));
        }
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });

    on<AuthEventGoogleSignIn>((event, emit) async {
      emit(const AuthStateLoggedOut(
        exception: null,
        isLoading: true,
        loadingText: 'Signing in with Google...',
      ));

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        // ✅ Force Sign-Out Before Sign-In (Ensures Account Selection)
        await googleSignIn.signOut();

        // Start the Google Sign-In process
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          return;
        }

        // Get authentication details from Google
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final firebase_auth.AuthCredential credential =
            firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        // Sign in the user with Firebase Authentication
        final firebase_auth.UserCredential userCredential = await firebase_auth
            .FirebaseAuth.instance
            .signInWithCredential(credential);

        final firebase_auth.User? user = userCredential.user;

        if (user != null) {
          // Convert Firebase User to AuthUser (your custom class)
        
          final authUser = AuthUser.fromFirebase(user);

          // Emit the logged-in state
          emit(AuthStateLoggedIn(user: authUser, isLoading: false));
        } else {
          
          emit(AuthStateLoggedOut(
            exception: GenericAuthException(),
            isLoading: false,
          ));
        }
      } catch (e) {
        
        emit(AuthStateLoggedOut(
          exception: GenericAuthException(),
          isLoading: false,
        ));
      }
    });

    // Log Out
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.logout();
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
  }
}
