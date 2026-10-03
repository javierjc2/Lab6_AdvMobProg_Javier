import 'login_type.dart';

/// User model shared by both login types (DummyJSON and Firebase).
///
/// DummyJSON users have a numeric [id], [gender] and tokens. Firebase users
/// have a string [uid], plus the sign-up profile fields ([age], [contactNo]).
/// [loginType] tells the UI which fields are meaningful.
class User {
  final int id;
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final int age;
  final String contactNo;
  final LoginType loginType;

  User({
    required this.id,
    this.uid = '',
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.age = 0,
    this.contactNo = '',
    this.loginType = LoginType.dummyJson,
  });

  String get fullName => ('$firstName $lastName').trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}') ?? 0,
      contactNo: json['contactNo']?.toString() ?? '',
      loginType: LoginType.fromString(json['loginType']?.toString()),
    );
  }

  User copyWith({
    int? id,
    String? uid,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? gender,
    String? image,
    String? accessToken,
    String? refreshToken,
    int? age,
    String? contactNo,
    LoginType? loginType,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      age: age ?? this.age,
      contactNo: contactNo ?? this.contactNo,
      loginType: loginType ?? this.loginType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'age': age,
      'contactNo': contactNo,
      'loginType': loginType.name,
    };
  }
}
