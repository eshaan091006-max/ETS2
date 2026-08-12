import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/constants/supabase/credentials.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    publishableKey: SupabaseCredentials.anonKey,
  );
  
  final client = Supabase.instance.client;
  print('Supabase initialized. Client URL: ${SupabaseCredentials.url}');

  // 1. Try reading tables anonymously
  final tables = ['events', 'contingents', 'department', 'participations', 'form_links', 'admins', 'audit_logs'];
  print('\n--- Testing Anonymous Read ---');
  for (var table in tables) {
    try {
      final res = await client.from(table).select().limit(5);
      print('Table "$table": Success. Count: ${res.length}. Data: $res');
    } catch (e) {
      print('Table "$table": Failed. Error: $e');
    }
  }
}
