class SavingsGoalTransaction {
  String savingsGoalTrxId;
  String savingsGoalTrxName;
  double savingsGoalTrxAmount;
  String savingsGoalTrxCreatedOn;

  SavingsGoalTransaction({
    required this.savingsGoalTrxId,
    required this.savingsGoalTrxName,
    required this.savingsGoalTrxAmount,
    required this.savingsGoalTrxCreatedOn,
  });

  factory SavingsGoalTransaction.fromJson(Map<String, dynamic> json) {
    return SavingsGoalTransaction(
      savingsGoalTrxId: json['savingsGoalTrxId'] ?? '',
      savingsGoalTrxName: json['savingsGoalTrxName'] ?? '',
      savingsGoalTrxAmount: (json['savingsGoalTrxAmount'] ?? 0).toDouble(),
      savingsGoalTrxCreatedOn: json['savingsGoalTrxCreatedOn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savingsGoalTrxId': savingsGoalTrxId,
      'savingsGoalTrxName': savingsGoalTrxName,
      'savingsGoalTrxAmount': savingsGoalTrxAmount,
      'savingsGoalTrxCreatedOn': savingsGoalTrxCreatedOn,
    };
  }
}