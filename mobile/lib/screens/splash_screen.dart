import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import 'welcome_screen.dart';
import 'shop_setup_screen.dart';
import 'subscription_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Crisp 350ms splash display for snappy, professional launch
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuth = await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (!isAuth) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    if (authProvider.shop == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShopSetupScreen()),
      );
      return;
    }

    // Trigger shop and subscription sync in the background
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    shopProvider.loadShopData();

    // Check cached subscription status without waiting on slow/sleeping network
    final cachedSub = await ApiClient.getCachedSubscription();
    if (!mounted) return;

    if (cachedSub != null && cachedSub['is_active'] == false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.textWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Retailza",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Smart Kirana Billing & Khata Management",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
