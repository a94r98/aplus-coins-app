import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_controller.dart';
import 'features/ads/ads_controller.dart';
import 'features/wallet/wallet_controller.dart';
import 'shared/theme/app_theme.dart';
import 'core/constants/config.dart';
import 'core/services/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ad networks asynchronously in the background to prevent app launch delays
  AdManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => AdsController()),
        ChangeNotifierProvider(create: (_) => WalletController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: auth.checkAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
