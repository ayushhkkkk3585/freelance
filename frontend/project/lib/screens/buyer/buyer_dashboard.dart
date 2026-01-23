import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wallet_provider.dart';
import '../widgets/request_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;
    
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await Future.wait([
      requestProvider.fetchPendingRequests(refresh: true),
      requestProvider.fetchMyBookings(refresh: true),
      notificationProvider.fetchNotifications(refresh: true),
      walletProvider.fetchWallet(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Header
              SliverToBoxAdapter(child: _buildHeader()),
              // Stats Card
              SliverToBoxAdapter(child: _buildStatsCard()),
              // Categories
              SliverToBoxAdapter(child: _buildCategories()),
              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryRed,
                    unselectedLabelColor: AppTheme.grey,
                    indicatorColor: AppTheme.primaryRed,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Available'),
                      Tab(text: 'My Bookings'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableRequests(),
              _buildMyBookings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  backgroundImage: auth.user?.photoUrl != null
                      ? NetworkImage(auth.user!.photoUrl!)
                      : null,
                  child: auth.user?.photoUrl == null
                      ? Text(
                          auth.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.user?.name.split(' ').first ?? 'Buyer'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${auth.user?.rating.toStringAsFixed(1) ?? '0.0'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                        Text(
                          ' • ${auth.user?.dealCount ?? 0} deals',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (context, notifProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.notifications).then((_) {
                            // Refresh requests when coming back from notifications
                            _loadData();
                          });
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      if (notifProvider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (context, auth, wallet, child) {
        return Column(
          children: [
            // Balance Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${wallet.balance}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceItem('Total Earned', '₹${wallet.totalEarnings}'),
                        Container(width: 1, height: 30, color: Colors.white30),
                        _buildBalanceItem('Total Profit', '₹${wallet.totalProfit}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  _buildStatItem(
                    Icons.shopping_bag_outlined,
                    '${auth.user?.totalBookings ?? 0}',
                    'Total Bookings',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.lightGrey,
                  ),
                  _buildStatItem(
                    Icons.credit_card_outlined,
                    '${auth.user?.cardsOwned.length ?? 0}',
                    'Cards',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.lightGrey,
                  ),
                  _buildStatItem(
                    Icons.reviews_outlined,
                    '${auth.user?.reviewCount ?? 0}',
                    'Reviews',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.selectedCategory != null)
                    TextButton(
                      onPressed: () {
                        provider.setCategory(null);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: Category.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: provider.selectedCategory == null,
                        selectedColor: AppTheme.primaryRed,
                        labelStyle: TextStyle(
                          color: provider.selectedCategory == null
                              ? AppTheme.white
                              : AppTheme.black,
                        ),
                        onSelected: (_) {
                          provider.setCategory(null);
                        },
                      ),
                    );
                  }
                  final category = Category.categories[index - 1];
                  final isSelected = provider.selectedCategory == category.name;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      avatar: Icon(
                        category.icon,
                        size: 16,
                        color: isSelected ? AppTheme.white : AppTheme.grey,
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.white : AppTheme.black,
                      ),
                      onSelected: (selected) {
                        provider.setCategory(selected ? category.name : null);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableRequests() {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.requests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (provider.requests.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No Requests Available',
            message: 'Check back later for new requests',
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryRed,
          onRefresh: () => provider.fetchPendingRequests(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.requests.length,
            itemBuilder: (context, index) {
              final request = provider.requests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: request,
                  showActions: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.requestDetail,
                      arguments: request.id,
                    ).then((_) {
                      // Refresh when coming back from detail screen
                      provider.fetchPendingRequests(refresh: true);
                      provider.fetchMyBookings(refresh: true);
                    });
                  },
                  onReject: () {
                    // Show confirmation and hide request locally
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request ignored'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Refresh the list to remove this request from view
                    provider.fetchPendingRequests(refresh: true);
                  },
                  onAccept: () async {
                    final success = await provider.acceptRequest(request.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request accepted! Complete the booking before timer ends.'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      _tabController.animateTo(1);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Failed to accept request'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyBookings() {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.acceptedRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (provider.acceptedRequests.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Bookings Yet',
            message: 'Accept requests to start earning',
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryRed,
          onRefresh: () => provider.fetchMyBookings(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.acceptedRequests.length,
            itemBuilder: (context, index) {
              final request = provider.acceptedRequests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: request,
                  showTimer: request.isAccepted,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.requestDetail,
                      arguments: request.id,
                    ).then((_) {
                      // Refresh when coming back from detail screen
                      provider.fetchMyBookings(refresh: true);
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.offWhite,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
