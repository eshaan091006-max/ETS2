// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:malhar_ets/utils/cache_manager.dart';
import 'package:malhar_ets/utils/sync_manager.dart';

class EventController {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton instance
  static final EventController _instance = EventController._internal();

  RealtimeChannel? _eventChannel;

  factory EventController() => _instance;

  EventController._internal();

  // Reactive list
  final ValueNotifier<List<Event>> _events = ValueNotifier<List<Event>>([]);
  ValueNotifier<List<Event>> get eventsNotifier => _events;
  List<Event> get events => _events.value;

  /// Load from Supabase (with dummy fallback)
  Future<void> loadEvents() async {
    // 1. Try loading from cache
    try {
      final cachedStr = await CacheManager.getCachedData(CacheManager.keyEvents);
      if (cachedStr != null) {
        _events.value = eventFromJson(cachedStr);
      }
    } catch (_) {}

    // 2. Fetch from Supabase
    try {
      final response = await _client
          .from('events')
          .select("*")
          .order('event_id', ascending: true);
      final List<Event> loadedEvents =
          response.map<Event>((json) => Event.fromJson(json)).toList();
      _events.value = loadedEvents;
      
      // 3. Save to Cache
      await CacheManager.cacheData(CacheManager.keyEvents, eventToJson(loadedEvents));
    } catch (e) {
      print("Error loading events: $e");
    }
  }

  /// Initialize (used at startup)
  Future<EventController> initializeEvents() async {
    await loadEvents();
    return this;
  }

  /// Get by ID
  Event? getEventById(int id) {
    try {
      return _events.value.firstWhere((e) => e.eventId == id);
    } catch (_) {
      return null;
    }
  }

  /// Print for debugging
  void printAll() {
    for (Event event in _events.value) {
      print("${event.eventId} ${event.eventName}");
    }
  }

  /// Listen to changes using Realtime
  void subscribeToEvents(GlobalKey<NavigatorState> key) {
    Timer? debounceTimer;

    _eventChannel = _client.channel('public:events');

    _eventChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(seconds: 2), () async {
              print('Event Table Updated!');
              await loadEvents();
              PageRefreshController.triggerRefresh();
              // AppFeedback.notifyUpdate(
              //   key.currentContext!,
              //   'Events Data has been Updated!',
              // );
            });
          },
        )
        .subscribe();
  }

  /// 🔹 CREATE
  Future<int?> createEvent(BuildContext context, Event event) async {
    try {
      await loadEvents();
      int nextId = 1;
      if (_events.value.isNotEmpty) {
        nextId = _events.value.map((e) => e.eventId).reduce((a, b) => a > b ? a : b) + 1;
      }
      event.eventId = nextId;

      final response =
          await _client.from('events').insert(event.toInsertJson()).select();

      print(response);

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Event created successfully.");
        await loadEvents();
        PageRefreshController.triggerRefresh();
        return response.first['event_id'] as int?;
      } else {
        AppFeedback.showError(context, "Failed to create event.");
        return null;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error creating event: $e");
      return null;
    }
  }

  /// 🔹 UPDATE
  Future<bool> updateEvent(BuildContext context, Event event) async {
    try {
      final response =
          await _client
              .from('events')
              .update(event.toJson())
              .eq('event_id', event.eventId)
              .select();

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Event updated successfully.");
        await loadEvents();
        PageRefreshController.triggerRefresh();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to update event.");
        return false;
      }
    } catch (e) {
      await SyncManager.addToQueue('events', 'update', event.toJson());
      
      final index = _events.value.indexWhere((e) => e.eventId == event.eventId);
      if (index != -1) {
        _events.value[index] = event;
      } else {
        _events.value.add(event);
      }
      _events.notifyListeners();
      PageRefreshController.triggerRefresh();

      AppFeedback.showSuccess(context, "Saved offline. Will sync when connected.");
      return true;
    }
  }

  Future<bool> updateHighestMarks(BuildContext context, int eventId) async {
    Event event =
        EventController().getEventById(eventId) ??
        Event(dateTime: DateTime.now());
    List<Participation> participations =
        ParticipationController().participations
            .where((p) => p.eventId == eventId)
            .toList();
    try {
      int maxMarks = participations.first.marksScored;
      for (Participation p in participations) {
        maxMarks = (p.marksScored > maxMarks) ? p.marksScored : maxMarks;
      }
      event.highestMarks = maxMarks;
      EventController().updateEvent(context, event);
      AppFeedback.showSuccess(context, "Event updated successfully.");
      return true;
    } catch (e) {
      AppFeedback.showError(context, "Error updating Event: $e");
      return false;
    }
  }

  /// 🔹 DELETE
  Future<bool> deleteEvent(BuildContext context, int eventId) async {
    try {
      // 1. Delete associated form links first
      await _client.from('form_links').delete().eq('event_id', eventId);

      // 2. Delete associated participations
      await _client.from('participations').delete().eq('event_id', eventId);

      // 3. Delete the event itself
      final response =
          await _client
              .from('events')
              .delete()
              .eq('event_id', eventId)
              .select();

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Event deleted successfully.");
        await loadEvents();
        PageRefreshController.triggerRefresh();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to delete event.");
        return false;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error deleting event: $e");
      return false;
    }
  }
}
