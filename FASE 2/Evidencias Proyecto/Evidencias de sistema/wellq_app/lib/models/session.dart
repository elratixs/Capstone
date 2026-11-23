class Session {
  const Session({
    required this.accessToken,
    required this.userName,
    this.roles = const [],
    this.userId,
  });
  final String accessToken;
  final String userName;
  final List<String> roles;
  final String? userId;
  bool get isPatient =>
      roles.any((role) => ['patient', 'Paciente'].contains(role));
}
