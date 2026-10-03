/// Which backend authenticated the current session.
///
/// Stored in SharedPreferences (as [name]) so the app knows, after a restart,
/// whether to restore the session from DummyJSON data or from Firebase.
enum LoginType {
  dummyJson,
  firebase;

  static LoginType fromString(String? value) => LoginType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => LoginType.dummyJson,
      );

  String get label => this == LoginType.firebase ? 'Firebase' : 'DummyJSON';
}
