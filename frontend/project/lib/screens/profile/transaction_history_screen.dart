import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/wallet.dart';
import '../../services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final transactions = await WalletService.getTransactions(
        page: 1,
        limit: 20,
      );

      setState(() {
        _transactions = transactions;
        _currentPage = 1;
        _hasMore = transactions.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final transactions = await WalletService.getTransactions(
        page: _currentPage + 1,
        limit: 20,
      );

      setState(() {
        _transactions.addAll(transactions);
        _currentPage++;
        _hasMore = transactions.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : _error != null && _transactions.isEmpty
              ? _buildErrorState()
              : _transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load transactions',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadTransactions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: AppTheme.primaryRed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryRed),
              ),
            );
          }
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isCredit = transaction.type == 'credit' ||
        transaction.type == 'refund' ||
        transaction.type == 'buyer_earning' ||
        transaction.type == 'client_refund' ||
        transaction.type == 'unfreeze';
    final isDebit = transaction.type == 'debit' || transaction.type == 'freeze';

    Color amountColor;
    String amountPrefix;
    IconData typeIcon;
    Color iconBgColor;

    if (isCredit) {
      amountColor = AppTheme.success;
      amountPrefix = '+';
    } else if (isDebit) {
      amountColor = AppTheme.error;
      amountPrefix = '-';
    } else {
      amountColor = AppTheme.grey;
      amountPrefix = '';
    }

    // Set icon based on transaction type
    switch (transaction.type) {
      case 'credit':
        typeIcon = Icons.add_circle_outline;
        iconBgColor = AppTheme.success.withOpacity(0.1);
        break;
      case 'debit':
        typeIcon = Icons.remove_circle_outline;
        iconBgColor = AppTheme.error.withOpacity(0.1);
        break;
      case 'refund':
      case 'client_refund':
        typeIcon = Icons.replay;
        iconBgColor = AppTheme.info.withOpacity(0.1);
        break;
      case 'buyer_earning':
        typeIcon = Icons.monetization_on_outlined;
        iconBgColor = AppTheme.success.withOpacity(0.1);
        break;
      case 'freeze':
        typeIcon = Icons.ac_unit;
        iconBgColor = Colors.blue.withOpacity(0.1);
        break;
      case 'unfreeze':
        typeIcon = Icons.wb_sunny_outlined;
        iconBgColor = Colors.orange.withOpacity(0.1);
        break;
      default:
        typeIcon = Icons.swap_horiz;
        iconBgColor = AppTheme.grey.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              typeIcon,
              color: amountColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeLabel(transaction.type),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.requestEventName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.requestEventName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix₹${transaction.amount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ₹${transaction.balanceAfter}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'refund':
        return 'Refund';
      case 'buyer_earning':
        return 'Earning';
      case 'client_refund':
        return 'Client Refund';
      case 'freeze':
        return 'Amount Frozen';
      case 'unfreeze':
        return 'Amount Unfrozen';
      case 'app_profit':
        return 'Platform Fee';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      // Today - show time
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today at ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
