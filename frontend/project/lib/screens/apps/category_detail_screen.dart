import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class AppItem {
  final String name;
  final String logo;
  final String url;

  const AppItem({required this.name, required this.logo, required this.url});
}

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String imagePath;
  final Color accentColor;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.imagePath,
    required this.accentColor,
  });

  // App data for each category
  static const Map<String, List<AppItem>> categoryApps = {
    'Movies': [
      AppItem(name: 'BookMyShow', logo: 'images/movies/bms.png', url: 'https://www.bookmyshow.com/'),
      AppItem(name: 'PVR Cinemas', logo: 'images/movies/pvr.svg', url: 'https://www.pvrcinemas.com/'),
      AppItem(name: 'INOX', logo: 'images/movies/inox.svg', url: 'https://in.bookmyshow.com/cinemas-list/inox/all-regions/inox'),
    ],
    'Events': [
      AppItem(name: 'BookMyShow', logo: 'images/events/bms.png', url: 'https://www.bookmyshow.com/'),
      AppItem(name: 'District', logo: 'images/events/district.svg', url: 'https://www.district.in/'),
    ],
    'Sports': [
      AppItem(name: 'BookMyShow', logo: 'images/sports/bms.png', url: 'https://www.bookmyshow.com/'),
      AppItem(name: 'District', logo: 'images/sports/district.svg', url: 'https://www.district.in/'),
      AppItem(name: 'Paytm Insider', logo: 'images/sports/paytminsider.svg', url: 'https://insider.in/'),
    ],
    'Live Events': [
      AppItem(name: 'BookMyShow', logo: 'images/live-events/bms.png', url: 'https://www.bookmyshow.com/'),
      AppItem(name: 'District', logo: 'images/live-events/district.svg', url: 'https://www.district.in/'),
      AppItem(name: 'Paytm Insider', logo: 'images/live-events/paytminsider.svg', url: 'https://insider.in/'),
    ],
    'Music': [
      AppItem(name: 'BookMyShow', logo: 'images/music/bms.png', url: 'https://www.bookmyshow.com/'),
      AppItem(name: 'District', logo: 'images/music/district.svg', url: 'https://www.district.in/'),
      AppItem(name: 'Spotify', logo: 'images/music/spotify.svg', url: 'https://www.spotify.com/'),
      AppItem(name: 'Ticketgenie', logo: 'images/music/ticketgenie.svg', url: 'https://ticketgenie.in/'),
    ],
    'Shopping': [
      AppItem(name: 'Amazon', logo: 'images/shopping/amazon.svg', url: 'https://www.amazon.in/'),
      AppItem(name: 'Flipkart', logo: 'images/shopping/flipkart.svg', url: 'https://www.flipkart.com/'),
      AppItem(name: 'Myntra', logo: 'images/shopping/myntra.jpg', url: 'https://www.myntra.com/'),
      AppItem(name: 'Nykaa', logo: 'images/shopping/nykaa.svg', url: 'https://www.nykaa.com/'),
      AppItem(name: 'Meesho', logo: 'images/shopping/meesho.svg', url: 'https://www.meesho.com/'),
      AppItem(name: 'Ajio', logo: 'images/shopping/ajioo.svg', url: 'https://www.ajio.com/'),
    ],
    'Food & Beverages': [
      AppItem(name: 'Zomato', logo: 'images/food/zomato.svg', url: 'https://www.zomato.com/'),
      AppItem(name: 'Swiggy', logo: 'images/food/swiggy.svg', url: 'https://www.swiggy.com/'),
      AppItem(name: 'Instamart', logo: 'images/food/swiggyinstamart.svg', url: 'https://www.swiggy.com/instamart'),
      AppItem(name: 'Blinkit', logo: 'images/food/blinkit.jpeg', url: 'https://www.blinkit.com/'),
      AppItem(name: 'JioMart', logo: 'images/food/jiomart.svg', url: 'https://www.jiomart.com/'),
    ],
    'Booking': [
      AppItem(name: 'MakeMyTrip', logo: 'images/booking/Makemytrip_logo.svg', url: 'https://www.makemytrip.com/'),
      AppItem(name: 'Goibibo', logo: 'images/booking/Goibibo_Logo.svg', url: 'https://www.goibibo.com/'),
      AppItem(name: 'OYO', logo: 'images/booking/Oyo_Rooms-Logo.wine.svg', url: 'https://www.oyorooms.com/'),
    ],
  };

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.categoryName.toLowerCase()}...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category image card
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: widget.accentColor.withOpacity(0.2),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: widget.accentColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Apps list
            _buildAppsList(),
          ],
        ),
      ),
    );
  }

  List<AppItem> get _apps => CategoryDetailScreen.categoryApps[widget.categoryName] ?? [];

  Widget _buildAppsList() {
    final apps = _apps;
    if (apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No apps available for this category yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return _buildAppCard(apps[index]);
      },
    );
  }

  Widget _buildAppCard(AppItem app) {
    final isSvg = app.logo.endsWith('.svg');
    
    return GestureDetector(
      onTap: () => _launchUrl(app.url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: isSvg
                  ? _buildSvgWithFallback(app)
                  : Image.asset(
                      app.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildLogoFallback(app.name);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSvgWithFallback(AppItem app) {
    return FutureBuilder(
      future: _checkAssetExists(app.logo),
      builder: (context, snapshot) {
        // While loading, show a placeholder
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLogoFallback(app.name);
        }
        
        // Try to load the SVG, with error handling
        return SvgPicture.asset(
          app.logo,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildLogoFallback(app.name),
        );
      },
    );
  }

  Future<bool> _checkAssetExists(String path) async {
    try {
      await DefaultAssetBundle.of(context).loadString(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildLogoFallback(String name) {
    // Get first letter of the app name
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    // Generate a color based on the name
    final colorIndex = name.hashCode % Colors.primaries.length;
    final bgColor = Colors.primaries[colorIndex].withOpacity(0.15);
    final textColor = Colors.primaries[colorIndex];
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
