import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/env.dart';
import 'data/services/ad_service.dart';
import 'routing/router.dart';
import 'routing/routes.dart';
import 'ui/core/themes/theme.dart';
import 'ui/core/ui/toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 광고 단위 ID가 있을 때만 광고 SDK를 켠다.
  if (Env.admobRewardedId.isNotEmpty) await AdMobAdService.initialize();
  runApp(
    MultiProvider(
      providers: [...providersLocal(), ...appViewModels],
      child: const CassetteApp(),
    ),
  );
}

class CassetteApp extends StatefulWidget {
  const CassetteApp({super.key, this.initialLocation = Routes.record});

  final String initialLocation;

  @override
  State<CassetteApp> createState() => _CassetteAppState();
}

class _CassetteAppState extends State<CassetteApp> {
  late final GoRouter _router = router(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'cassette',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      builder: (context, child) => Stack(
        children: [
          ?child,
          ToastHost(controller: context.read<ToastController>()),
        ],
      ),
    );
  }
}
