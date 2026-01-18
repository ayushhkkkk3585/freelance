class Wallet {
  final String id;
  final String userId;
  final int balance;
  final int frozenAmount;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.frozenAmount = 0,
    required this.updatedAt,
  });

  /// Available balance = Total balance - Frozen amount
  int get availableBalance => balance - frozenAmount;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      balance: json['balance'] ?? 0,
      frozenAmount: json['frozenAmount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'frozenAmount': frozenAmount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Transaction {
  final String id;
  final String userId;
  final String type; // debit, credit, refund, freeze, unfreeze
  final int amount;
  final String description;
  final String? requestId;
  final String? requestEventName;
  final int balanceAfter;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.requestId,
    this.requestEventName,
    this.balanceAfter = 0,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle populated requestId
    String? requestId;
    String? requestEventName;
    if (json['requestId'] is Map) {
      requestId = json['requestId']['_id']?.toString();
      requestEventName = json['requestId']['eventName'];
    } else {
      requestId = json['requestId']?.toString();
    }

    return Transaction(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      requestId: requestId,
      requestEventName: requestEventName,
      balanceAfter: json['balanceAfter'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'requestId': requestId,
      'balanceAfter': balanceAfter,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get display icon based on transaction type
  String get displayType {
    switch (type) {
      case 'credit':
        return 'Credited';
      case 'debit':
        return 'Debited';
      case 'freeze':
        return 'Frozen';
      case 'unfreeze':
        return 'Unfrozen';
      case 'refund':
        return 'Refunded';
      default:
        return type;
    }
  }

  bool get isPositive => type == 'credit' || type == 'refund' || type == 'unfreeze';
}
