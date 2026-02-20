import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // TODO: Edit profile
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (user.bio != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Stats (only for buyers)
              if (user.role == 'buyer')
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.shopping_bag_outlined,
                          value: '${user.totalBookings}',
                          label: 'Bookings',
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          icon: Icons.star_outline,
                          value: user.rating.toStringAsFixed(1),
                          label: 'Rating',
                        ),
                      ],
                    ),
                  ),
                ),

              // Cards Owned (for buyers)
              if (user.role == 'buyer' && user.cardsOwned.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSection(
                    'My Cards',
                    user.cardsOwned.map((card) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: AppTheme.primaryRed,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              card,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Menu Items
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.star_outline,
                        title: 'Reviews',
                        subtitle: 'View your reviews',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.reviews,
                            arguments: {'userId': user.id, 'userRole': user.role},
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.history_outlined,
                        title: 'Transaction History',
                        subtitle: 'View all transactions',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.transactionHistory);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage notifications',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.notifications);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with your account',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.helpSupport);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'App version and info',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.about);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        isDestructive: true,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.lightGrey,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppTheme.error.withOpacity(0.1)
                : AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.error : AppTheme.primaryRed,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppTheme.error : AppTheme.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
