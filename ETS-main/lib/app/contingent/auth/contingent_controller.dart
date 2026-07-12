import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/hash_util.dart';
import 'package:malhar_ets/utils/session_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContingentController {
  static Future<Map<String, dynamic>> loginAsContingent(
    String username,
    String password,
  ) async {
    try {
      final hashedPassword = HashUtil.hashPassword(password);
      final response = await Supabase.instance.client.rpc(
        'login_contingent_rpc',
        params: {
          'input_code': username,
          'input_password': hashedPassword,
        },
      ) as List<dynamic>;

      if (response.isNotEmpty) {
        final contingentData = Map<String, dynamic>.from(response.first);
        
        // Set the custom JWT session for Supabase
        if (contingentData.containsKey('token') && contingentData['token'] != null) {
          await SessionManager.restoreCustomJWTSession(contingentData['token']);
          // Wait for the restored session to propagate to the Supabase client headers
          await Future.delayed(const Duration(milliseconds: 300));
        }

        return {
          "success": true,
          "message": 'Contingent Login Successful for $username!',
          "contingent": Contingent.fromJson(contingentData),
          "token": contingentData['token'],
        };
      } else {
        return {"success": false, "message": "Invalid Contingent Credentials!"};
      }
    } catch (e) {
      return {"success": false, "message": "Login failed: $e"};
    }
  }
}
