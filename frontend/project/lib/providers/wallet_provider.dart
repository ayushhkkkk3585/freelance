import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  Wallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  Wallet? get wallet => _wallet;
  List<Transaction> get transactions => _transactions;
  int get balance => _wallet?.balance ?? 0;
  int get frozenAmount => _wallet?.frozenAmount ?? 0;
  int get availableBalance => _wallet?.availableBalance ?? 0;
  // Buyer earnings
  int get totalEarnings => _wallet?.totalEarnings ?? 0;
  int get totalProfit => _wallet?.totalProfit ?? 0;
  // Client savings
  int get totalSavings => _wallet?.totalSavings ?? 0;
  int get totalRefunds => _wallet?.totalRefunds ?? 0;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch Wallet
  Future<void> fetchWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await WalletService.getWallet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Transactions
  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) _transactions = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await WalletService.getTransactions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Points to Wallet
  Future<void> addPoints(int amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await WalletService.addPoints(amount);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
