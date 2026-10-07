import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();
  runApp(SoThuChiApp(store: store));
}

class SoThuChiApp extends StatelessWidget {
  const SoThuChiApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: S.current.appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(AppColors.light),
          darkTheme: buildTheme(AppColors.dark),
          themeMode: store.themeMode,
          locale: Locale(store.lang.name),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Shell(),
        ),
      ),
    );
  }
}
