enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthUser {
  final String email;
  final String displayName;
  final String? profileImagePath;
  final String fullName;
  final DateTime joinDate;
  final bool isVerified;

  const AuthUser({
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.joinDate,
    this.isVerified = false,
    this.profileImagePath,
  });

  AuthUser copyWith({
    String? email,
    String? displayName,
    String? profileImagePath,
    String? fullName,
    DateTime? joinDate,
    bool? isVerified,
    bool clearProfileImage = false,
  }) {
    return AuthUser(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      joinDate: joinDate ?? this.joinDate,
      isVerified: isVerified ?? this.isVerified,
      profileImagePath: clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          displayName == other.displayName &&
          fullName == other.fullName &&
          joinDate == other.joinDate &&
          isVerified == other.isVerified &&
          profileImagePath == other.profileImagePath;

  @override
  int get hashCode =>
      email.hashCode ^
      displayName.hashCode ^
      fullName.hashCode ^
      joinDate.hashCode ^
      isVerified.hashCode ^
      profileImagePath.hashCode;
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(AuthUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? errorMessage}) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ user.hashCode ^ errorMessage.hashCode;
}
