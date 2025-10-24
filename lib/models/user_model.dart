class UserModel {
  String userId;
  String userName;
  String userEmail;
  String userImageUrl;
  String userCreatedOn;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userImageUrl,
    required this.userCreatedOn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userImageUrl: json['userImageUrl'] ?? '',
      userCreatedOn: json['userCreatedOn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userImageUrl': userImageUrl,
      'userCreatedOn': userCreatedOn,
    };
  }

  factory UserModel.empty() {
    return UserModel(
      userId: '',
      userName: '',
      userEmail: '',
      userImageUrl: '',
      userCreatedOn: '',
    );
  }
}
