class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String cnic;
  final String address;
  final String? profileImageUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.cnic,
    required this.address,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'cnic': cnic,
      'address': address,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      cnic: map['cnic'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }
}
