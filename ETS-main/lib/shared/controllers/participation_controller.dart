// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/widgets.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/session_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:malhar_ets/utils/cache_manager.dart';
import 'package:malhar_ets/utils/sync_manager.dart';
import 'dart:async';

class ParticipationController {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton instance
  static final ParticipationController _instance =
      ParticipationController._internal();

  RealtimeChannel? _participationChannel;

  factory ParticipationController() {
    return _instance;
  }

  ParticipationController._internal();

  final List<Participation> _participations = [];

  List<Participation> get participations => _participations;

  Future<void> loadParticipations() async {
    // 1. Try loading from cache
    try {
      final cachedStr = await CacheManager.getCachedData(CacheManager.keyParticipations);
      if (cachedStr != null) {
        _participations.clear();
        _participations.addAll(participationFromJson(cachedStr));
        PageRefreshController.triggerRefresh();
      }
    } catch (_) {}

    try {
      final session = await SessionManager.getSession();
      List<dynamic> response = [];

      if (session != null) {
        if (session['type'] == 'contingent') {
          final contingent = session['contingent'] as Contingent;
          response = await _client.rpc(
            'get_my_participations_rpc',
            params: {'input_contingent_id': contingent.contingentId},
          );
        } else if (session['type'] == 'admin') {
          response = await _client.rpc('get_all_participations_rpc');
        }
      }

      _participations.clear();
      _participations.addAll(
        response.map((json) => Participation.fromJson(Map<String, dynamic>.from(json))).toList(),
      );
      // Save to cache
      await CacheManager.cacheData(CacheManager.keyParticipations, participationToJson(_participations));
    } catch (e) {
      print("Error loading participations: $e");
    } finally {
      PageRefreshController.triggerRefresh();
    }
  }

  void subscribeToParticipations(GlobalKey<NavigatorState> key) {
    Timer? debounceTimer;
    _participationChannel = _client.channel('public:participations');

    _participationChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'participations',
          callback: (payload) {
            //Cancelling the previous Timer if any such that code block actually dismisses
            // the previous update instead of js stacking it inside a timer.

            debounceTimer?.cancel();

            // Setting timer for multiple calls in few seconds and then updating all at once.
            debounceTimer = Timer(const Duration(seconds: 2), () async {
              await loadParticipations();
              print('Participation table updated!');
              PageRefreshController.triggerRefresh();
              // AppFeedback.notifyUpdate(
              //   key.currentContext!,
              //   'Participation data has been updated!',
              // );
            });
          },
        )
        .subscribe();
  }

  void printAll() {
    for (Participation p in _participations) {
      print(
        "${p.participationId} ${p.contingentId} ${p.eventId} ${p.marksScored}",
      );
    }
  }

  Future<ParticipationController> initializeParticipations() async {
    await loadParticipations();
    return this;
  }

  Participation? getParticipationById(int id) {
    try {
      return _participations.firstWhere((p) => p.participationId == id);
    } catch (e) {
      return null;
    }
  }

  // 🔹 ENTRY NUMBERING
  // A contingent may be entered into the same event more than once (two teams,
  // two performances). Those rows are told apart by an entry number derived
  // from their order, not stored in the database.

  /// All participations for a contingent+event pair, oldest first.
  List<Participation> entriesFor(int contingentId, int eventId) {
    final entries =
        _participations
            .where((p) => p.contingentId == contingentId && p.eventId == eventId)
            .toList();
    entries.sort((a, b) => a.participationId.compareTo(b.participationId));
    return entries;
  }

  int entryCountFor(int contingentId, int eventId) =>
      entriesFor(contingentId, eventId).length;

  /// 1-based position of [p] among its contingent's entries in the same event.
  ///
  /// Returns 0 when it is the only entry, which is the signal to display the
  /// name plain, with no number attached.
  int entryNumberOf(Participation p) {
    final entries = entriesFor(p.contingentId, p.eventId);
    if (entries.length < 2) return 0;
    final index = entries.indexWhere(
      (e) => e.participationId == p.participationId,
    );
    return index == -1 ? 0 : index + 1;
  }

  /// " 2" for the second entry, "" when it is the only one.
  ///
  /// The single place the display convention lives — change it here and every
  /// label follows.
  String suffixFor(Participation p) {
    final number = entryNumberOf(p);
    return number == 0 ? '' : ' $number';
  }

  // 🔹 CREATE
  Future<bool> createParticipation(
    BuildContext context,
    Participation participation,
  ) async {
    try {
      await loadParticipations();
      int nextId = 1;
      if (_participations.isNotEmpty) {
        nextId = _participations.map((p) => p.participationId).reduce((a, b) => a > b ? a : b) + 1;
      }
      participation.participationId = nextId;

      final response =
          await _client
              .from('participations')
              .insert(participation.toInsertJson())
              .select();

      print(response);

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Participation created successfully.");
        await loadParticipations();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to create participation.");
        return false;
      }
    } on PostgrestException catch (e) {
      AppFeedback.showError(context, _createErrorMessage(e));
      return false;
    } catch (e) {
      AppFeedback.showError(context, "Error creating participation: $e");
      return false;
    }
  }

  /// A duplicate-key rejection here means the database still enforces one row
  /// per contingent+event, so repeat entries cannot be stored until that
  /// constraint is dropped. Say so plainly instead of dumping the exception.
  String _createErrorMessage(PostgrestException e) {
    if (e.code == '23505') {
      // participation_id is generated client-side as max+1, so two admins
      // saving at the same moment collide on the primary key. That is a
      // retry, not a schema problem — don't confuse the two.
      if (e.message.contains('pkey')) {
        return "Another admin saved at the same moment. Please try again.";
      }
      return "The database is blocking a second entry for this contingent in "
          "this event. The unique constraint on participations must be dropped "
          "before repeat entries can be saved.";
    }
    return "Error creating participation: ${e.message}";
  }

  Future<bool> createMultipleParticipation(
    BuildContext context,
    List<Participation> participations,
  ) async {
    try {
      await loadParticipations();
      int nextId = 1;
      if (_participations.isNotEmpty) {
        nextId = _participations.map((p) => p.participationId).reduce((a, b) => a > b ? a : b) + 1;
      }

      for (int i = 0; i < participations.length; i++) {
        participations[i].participationId = nextId + i;
      }

      final response =
          await _client
              .from('participations')
              .insert(participations.map((p) => p.toInsertJson()).toList())
              .select();

      print(response);

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(
          context,
          "Participations created successfully.",
        );
        await loadParticipations();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to create participations.");
        return false;
      }
    } on PostgrestException catch (e) {
      AppFeedback.showError(context, _createErrorMessage(e));
      return false;
    } catch (e) {
      AppFeedback.showError(context, "Error creating participations: $e");
      return false;
    }
  }

  // 🔹 UPDATE
  Future<bool> updateParticipation(
    BuildContext context,
    Participation participation, {
    bool displayMsg = true,
  }) async {
    try {
      final response =
          await _client
              .from('participations')
              .update(participation.toJson())
              .eq('participation_id', participation.participationId)
              .select();

      if (response.isNotEmpty) {
        if (displayMsg) {
          AppFeedback.showSuccess(
            context,
            "Participation updated successfully.",
          );
        }
        await loadParticipations();
        return true;
      } else {
        if (displayMsg) {
          AppFeedback.showError(context, "Failed to update participation.");
        }
        return false;
      }
    } catch (e) {
      await SyncManager.addToQueue('participations', 'update', participation.toJson());
      
      final index = _participations.indexWhere((p) => p.participationId == participation.participationId);
      if (index != -1) {
        _participations[index] = participation;
      } else {
        _participations.add(participation);
      }
      PageRefreshController.triggerRefresh();

      if (displayMsg) {
        AppFeedback.showSuccess(context, "Saved offline. Will sync when connected.");
      }
      return true;
    }
  }

  Future<bool> updateMultipleParticipationSameEvent(
    BuildContext context,
    List<Participation> participations,
    Event event,
  ) async {
    try {
      int maxMarks = participations.first.marksScored;
      for (Participation p in participations) {
        maxMarks = (p.marksScored > maxMarks) ? p.marksScored : maxMarks;
        final bool updated = await updateParticipation(context, p, displayMsg: false);
        if (!updated) {
          throw Exception("Failed to update participation score for contingent ID ${p.contingentId}");
        }
      }
      event.highestMarks = maxMarks;
      final bool eventUpdated = await EventController().updateEvent(context, event);
      if (!eventUpdated) {
        throw Exception("Failed to update event highest marks");
      }
      AppFeedback.showSuccess(context, "Participation updated successfully.");
      return true;
    } catch (e) {
      AppFeedback.showError(context, "Error updating participations: $e");
      return false;
    }
  }

  // Future<bool> updateMultipleParticipationSameContingent(
  //   BuildContext context,
  //   List<Participation> participations,
  //   Event event,
  //   Contingent contingent,
  // ) async {
  //   try {
  //     int maxMarks = participations.first.marksScored;
  //     for (Participation p in participations) {
  //       if (p.marksScored > event.highestMarks && p.marksScored > maxMarks) {
  //         maxMarks = p.marksScored;
  //       }
  //       updateParticipation(context, p, displayMsg: false);
  //     }
  //     AppFeedback.showSuccess(context, "Participation updated successfully.");

  //     if (event.highestMarks < maxMarks) {
  //       event.highestMarks = maxMarks;
  //       EventController().updateEvent(context, event);
  //     }
  //     return true;
  //   } catch (e) {
  //     AppFeedback.showError(context, "Error updating participations: $e");
  //     return false;
  //   }
  // }

  // 🔹 DELETE
  Future<bool> deleteParticipation(
    BuildContext context,
    Participation participation,
  ) async {
    try {
      final response =
          await _client
              .from('participations')
              .delete()
              .eq('participation_id', participation.participationId)
              .select();

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Participation deleted successfully.");
        await loadParticipations();
        await EventController().updateHighestMarks(
          context,
          participation.eventId,
        );
        return true;
      } else {
        AppFeedback.showError(context, "Failed to delete participation.");
        return false;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error deleting participation: $e");
      return false;
    }
  }
}
