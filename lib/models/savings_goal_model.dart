import 'savings_goal_transaction.dart';

class SavingsGoalModel {
  String savingsGoalId;
  String savingsGoalName;
  double savingsGoalTargetAmount;
  double savingsGoalCurrentAmount;
  String savingsGoalTargetDate;
  String savingsGoalImageUrl;
  Map<String, dynamic> savingsGoalUser;
  String savingsGoalCreatedOn;
  List<dynamic> savingsGoalTransactions;

  SavingsGoalModel({
    required this.savingsGoalId,
    required this.savingsGoalName,
    required this.savingsGoalTargetAmount,
    required this.savingsGoalCurrentAmount,
    required this.savingsGoalTargetDate,
    required this.savingsGoalImageUrl,
    required this.savingsGoalUser,
    required this.savingsGoalCreatedOn,
    required this.savingsGoalTransactions,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalModel(
      savingsGoalId: json['savingsGoalId'] ?? '',
      savingsGoalName: json['savingsGoalName'] ?? '',
      savingsGoalTargetAmount:
          (json['savingsGoalTargetAmount'] ?? 0).toDouble(),
      savingsGoalCurrentAmount:
          (json['savingsGoalCurrentAmount'] ?? 0).toDouble(),
      savingsGoalTargetDate: json['savingsGoalTargetDate'] ?? '',
      savingsGoalImageUrl: json['savingsGoalImageUrl'] ?? '',
      savingsGoalUser: json['savingsGoalUser'] ?? '',
      savingsGoalCreatedOn: json['savingsGoalCreatedOn'] ?? '',
      savingsGoalTransactions:
          (json['savingsGoalTransactions'] as List<dynamic>?)
              ?.map((e) => SavingsGoalTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savingsGoalId': savingsGoalId,
      'savingsGoalName': savingsGoalName,
      'savingsGoalTargetAmount': savingsGoalTargetAmount,
      'savingsGoalCurrentAmount': savingsGoalCurrentAmount,
      'savingsGoalTargetDate': savingsGoalTargetDate,
      'savingsGoalImageUrl': savingsGoalImageUrl,
      'savingsGoalUser': savingsGoalUser,
      'savingsGoalCreatedOn': savingsGoalCreatedOn,
      'savingsGoalTransactions': savingsGoalTransactions,
    };
  }
}
