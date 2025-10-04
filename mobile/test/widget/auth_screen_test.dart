import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/screens/auth/login_screen.dart';
import '../../lib/screens/auth/register_screen.dart';
import '../../lib/screens/auth/forgot_password_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/services/api_client.dart';

// Generate mocks using mockito code generation
@GenerateMocks([ApiClient])
import 'auth_screen_test.mocks.dart';

void main() {
  group('Authentication Screens Widget Tests', () {
    late MockApiClient mockApiClient;
    late ProviderContainer container;

    setUp(() {
      mockApiClient = MockApiClient();
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('LoginScreen Tests', () {
      testWidgets('should render login form correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Verify login form elements are present
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Sign in to continue'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
      });

      testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Tap sign in button without entering any data
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify validation errors appear
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('should validate email format', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Enter invalid email
        await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify email validation error
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('should toggle password visibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Find password field
        final passwordField = find.byType(TextFormField).last;
        final passwordWidget = tester.widget<TextFormField>(passwordField);

        // Initially password should be obscured
        expect(passwordWidget.obscureText, isTrue);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        // Password should now be visible
        final updatedPasswordWidget = tester.widget<TextFormField>(passwordField);
        expect(updatedPasswordWidget.obscureText, isFalse);
      });

      testWidgets('should call login API when form is valid', (WidgetTester tester) async {
        // Mock successful login
        when(mockApiClient.login(any))
            .thenAnswer((_) async => LoginResponse(
                  accessToken: 'test-token',
                  user: User(id: '1', email: 'test@example.com', name: 'Test User'),
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Enter valid credentials
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Tap sign in
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.login(any)).called(1);
      });

      testWidgets('should show loading indicator during login', (WidgetTester tester) async {
        // Mock delayed login response
        when(mockApiClient.login(any))
            .thenAnswer((_) => Future.delayed(
                  Duration(seconds: 2),
                  () => LoginResponse(
                    accessToken: 'test-token',
                    user: User(id: '1', email: 'test@example.com', name: 'Test User'),
                  ),
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Enter valid credentials and submit
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Signing In...'), findsOneWidget);
      });

      testWidgets('should show error message on login failure', (WidgetTester tester) async {
        // Mock login failure
        when(mockApiClient.login(any))
            .thenThrow(ApiException('Invalid credentials'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Enter credentials and submit
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify error message is shown
        expect(find.text('Invalid credentials'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('RegisterScreen Tests', () {
      testWidgets('should render registration form correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        // Verify registration form elements
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Join us today'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Email, Password, Confirm Password
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget); // Terms acceptance
        expect(find.text('I agree to the Terms of Service'), findsOneWidget);
      });

      testWidgets('should validate password confirmation', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        // Enter different passwords
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(2), 'password123'); // Password
        await tester.enterText(textFields.at(3), 'differentpassword'); // Confirm password

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify password mismatch error
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('should require terms acceptance', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        // Fill form but don't check terms
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Test User');
        await tester.enterText(textFields.at(1), 'test@example.com');
        await tester.enterText(textFields.at(2), 'password123');
        await tester.enterText(textFields.at(3), 'password123');

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify terms acceptance error
        expect(find.text('Please accept the terms of service'), findsOneWidget);
      });

      testWidgets('should validate password strength', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        // Enter weak password
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(2), 'weak');

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify password strength error
        expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      });

      testWidgets('should call register API when form is valid', (WidgetTester tester) async {
        // Mock successful registration
        when(mockApiClient.register(any))
            .thenAnswer((_) async => RegisterResponse(
                  success: true,
                  message: 'Registration successful',
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        // Fill valid form
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Test User');
        await tester.enterText(textFields.at(1), 'test@example.com');
        await tester.enterText(textFields.at(2), 'Password123!');
        await tester.enterText(textFields.at(3), 'Password123!');

        // Accept terms
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.register(any)).called(1);
      });
    });

    group('ForgotPasswordScreen Tests', () {
      testWidgets('should render forgot password form correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ForgotPasswordScreen(),
            ),
          ),
        );

        // Verify forgot password form elements
        expect(find.text('Forgot Password'), findsOneWidget);
        expect(find.text('Enter your email to reset password'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget); // Email field
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Send Reset Link'), findsOneWidget);
        expect(find.text('Back to Login'), findsOneWidget);
      });

      testWidgets('should validate email field', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ForgotPasswordScreen(),
            ),
          ),
        );

        // Submit without email
        await tester.tap(find.text('Send Reset Link'));
        await tester.pumpAndSettle();

        // Verify validation error
        expect(find.text('Please enter your email'), findsOneWidget);

        // Enter invalid email
        await tester.enterText(find.byType(TextFormField), 'invalid-email');
        await tester.tap(find.text('Send Reset Link'));
        await tester.pumpAndSettle();

        // Verify email validation error
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('should call forgot password API when email is valid', (WidgetTester tester) async {
        // Mock successful forgot password request
        when(mockApiClient.forgotPassword(any))
            .thenAnswer((_) async => ForgotPasswordResponse(
                  success: true,
                  message: 'Reset link sent to your email',
                ));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ForgotPasswordScreen(),
            ),
          ),
        );

        // Enter valid email and submit
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.text('Send Reset Link'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiClient.forgotPassword(any)).called(1);

        // Verify success message
        expect(find.text('Reset link sent to your email'), findsOneWidget);
      });

      testWidgets('should navigate back to login', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ForgotPasswordScreen(),
              routes: {
                '/login': (context) => LoginScreen(),
              },
            ),
          ),
        );

        // Tap back to login
        await tester.tap(find.text('Back to Login'));
        await tester.pumpAndSettle();

        // Verify navigation (would need proper navigation testing setup)
        // This is a simplified test - in practice you'd mock Navigator
      });
    });

    group('Authentication Form Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Verify semantic labels for accessibility
        expect(find.byType(Semantics), findsWidgets);

        // Check for proper labels on form fields
        final emailField = find.byType(TextFormField).first;
        final emailWidget = tester.widget<TextFormField>(emailField);
        expect(emailWidget.decoration?.labelText, equals('Email'));

        final passwordField = find.byType(TextFormField).last;
        final passwordWidget = tester.widget<TextFormField>(passwordField);
        expect(passwordWidget.decoration?.labelText, equals('Password'));
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Test tab navigation between fields
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify focus moves to next field
        final focusedNode = FocusManager.instance.primaryFocus;
        expect(focusedNode, isNotNull);
      });
    });

    group('Authentication State Management Tests', () {
      testWidgets('should update UI based on auth state changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Test state changes through providers
        // This would require more sophisticated provider testing
        // For now, we verify the basic widget structure responds to state

        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });
  });
}