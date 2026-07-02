import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/config/env_config.dart';
import 'package:soccer_sys/core/config/env_loader.dart';
import 'package:soccer_sys/core/localization/app_translations.dart';
import 'package:soccer_sys/core/localization/date_formatting.dart';
import 'package:soccer_sys/core/localization/locale_controller.dart';
import 'package:soccer_sys/core/routes/app_pages.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/services/fcm_service.dart';
import 'package:soccer_sys/core/theme/app_theme.dart';
import 'package:soccer_sys/core/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeAppDateFormatting();
  await FcmService.bootstrap();

  try {
    await loadAppEnv();
  } catch (_) {
    // EnvConfig still has safe fallbacks for missing assets.
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  final localeController = Get.put(LocaleController(), permanent: true);
  final themeController = Get.put(ThemeController(), permanent: true);
  await localeController.loadSavedLocale();
  await themeController.loadSavedTheme();

  runApp(const SoccerSysApp(initialRoute: AppRoutes.splash));
}

class SoccerSysApp extends StatelessWidget {
  const SoccerSysApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'app_name'.tr,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode.value,
        translations: AppTranslations(),
        locale: localeController.locale.value,
        fallbackLocale: const Locale('en'),
        initialRoute: initialRoute,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Directionality(
            textDirection:
                localeController.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
