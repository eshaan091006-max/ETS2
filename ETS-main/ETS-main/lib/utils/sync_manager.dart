import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncManager {
  static const String _queueKey = 'offline_sync_queue';
  static bool _isSyncing = false;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static void initialize() {
    // 1. Flush any pending items on startup
    flushQueue();

    // 2. Listen for connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        print('Connection restored! Flushing sync queue...');
        flushQueue();
      }
    });
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  static Future<void> addToQueue(String table, String action, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueStr);
    
    queue.add({
      'table': table,
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_queueKey, jsonEncode(queue));
    print('Added to offline sync queue: $action on $table');
  }
  
  static Future<void> flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _isSyncing = false;
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString(_queueKey);
      if (queueStr == null) {
        _isSyncing = false;
        return;
      }
      
      final List<dynamic> queue = jsonDecode(queueStr);
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      final supabase = Supabase.instance.client;
      final List<dynamic> failedItems = [];
      
      for (var item in queue) {
        try {
          final table = item['table'];
          final action = item['action'];
          final data = item['data'];
          
          if (action == 'insert') {
            await supabase.from(table).insert(data);
          } else if (action == 'update') {
            if (table == 'participations') {
              await supabase.from(table).update(data)
                .eq('participation_id', data['participation_id']);
            } else if (data.containsKey('id')) {
              await supabase.from(table).update(data).eq('id', data['id']);
            } else if (data.containsKey('event_id')) { // For event
              await supabase.from(table).update(data).eq('event_id', data['event_id']);
            } else if (data.containsKey('contingent_id')) { // For contingent
              await supabase.from(table).update(data).eq('contingent_id', data['contingent_id']);
            }
          }
          print('Successfully synced $action on $table');
        } catch (e) {
          print('Failed to sync item: $e');
          // If it fails due to network, keep it in queue. 
          // If it fails due to validation (e.g. duplicate key), we might want to drop it, 
          // but for simplicity we keep it or rely on Supabase resolving it.
          // To be safe, we'll keep it.
          failedItems.add(item);
        }
      }
      
      await prefs.setString(_queueKey, jsonEncode(failedItems));
    } finally {
      _isSyncing = false;
    }
  }
}
