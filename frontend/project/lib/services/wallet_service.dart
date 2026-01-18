import '../models/wallet.dart';
import 'api_service.dart';

class WalletService {
  // Get Wallet Balance
  static Future<Wallet> getWallet() async {
    final response = await ApiService.get('/wallet/balance');
    final data = response['data'] as Map<String, dynamic>;
    return Wallet.fromJson(data);
  }

  // Get Transactions
  static Future<List<Transaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.get('/wallet/transactions?page=$page&limit=$limit');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> transactions = data?['transactions'] ?? [];
    return transactions.map((json) => Transaction.fromJson(json)).toList();
  }

  // Add Points (for testing/admin)
  static Future<Wallet> addPoints(int amount) async {
    final response = await ApiService.post('/wallet/add-points', {'amount': amount});
    final data = response['data'] as Map<String, dynamic>;
    return Wallet.fromJson(data);
  }
}
