// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light theme: dark status/navigation icons on light surfaces.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarColor: Color(0xFFF5F7FB),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const HomeProtectorApp(),
    ),
  );
}

class HomeProtectorApp extends StatelessWidget {
  const HomeProtectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeProtector · 홈프로텍터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 모바일 앱으로 실험/사용하는 서비스라, 넓은 화면(웹/데스크톱)에서는
      // 콘텐츠를 휴대폰 폭(≤480)으로 가운데 정렬해 '폰 프레임'처럼 보여 준다.
      // (이 제약이 없으면 캘린더 셀이 과도하게 커져 비스크롤 그리드가 잘려 14일까지만 보였음)
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        if (width <= 520 || child == null) return child ?? const SizedBox();
        return ColoredBox(
          color: const Color(0xFFE2E8F0),
          child: Center(
            child: ClipRect(
              child: SizedBox(
                width: 440,
                child: child,
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
