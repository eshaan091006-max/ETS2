import 'package:flutter/material.dart';
import 'package:malhar_ets/connector.dart';
import 'package:malhar_ets/constants/app_theme.dart';
import 'package:malhar_ets/constants/supabase/credentials.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:malhar_ets/utils/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    publishableKey: SupabaseCredentials.anonKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
    ),
  );
  SyncManager.initialize();
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malhar 26',
      theme: themeData,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      home: Connector(),
      debugShowCheckedModeBanner: false,
    );
  }
}
