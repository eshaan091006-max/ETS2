import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormLinkController {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton instance
  static final FormLinkController _instance = FormLinkController._internal();

  RealtimeChannel? _formLinkChannel;

  factory FormLinkController() {
    return _instance;
  }

  FormLinkController._internal();

  final List<FormLink> _formLinks = [];

  List<FormLink> get formLinks => _formLinks;

  Future<void> loadFormLinks() async {
    final response = await _client
        .from('form_links')
        .select('*')
        .order('id', ascending: true);

    _formLinks.clear();
    _formLinks.addAll(response.map((json) => FormLink.fromJson(json)).toList());
    PageRefreshController.triggerRefresh();
  }

  void subscribeToFormLinks(GlobalKey<NavigatorState> key) {
    Timer? debounceTimer;
    _formLinkChannel = _client.channel('public:form_links');

    _formLinkChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'form_links',
          callback: (payload) {
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(seconds: 2), () async {
              print('FormLinks table updated!');
              await loadFormLinks();
              PageRefreshController.triggerRefresh();
              // Optionally:
              // AppFeedback.notifyUpdate(
              //   key.currentContext!,
              //   'Form links updated.',
              // );
            });
          },
        )
        .subscribe();
  }

  void printAll() {
    for (FormLink f in _formLinks) {
      print("${f.id} ${f.eventId} ${f.link} ${f.label} ${f.visibleTo}");
    }
  }

  Future<FormLinkController> initializeFormLinks() async {
    await loadFormLinks();
    return this;
  }

  FormLink? getFormLinkById(int id) {
    try {
      return _formLinks.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  List<FormLink> getFormLinksByEventId(int id) {
    return _formLinks.where((f) => f.eventId == id).toList();
  }

  // 🔹 CREATE
  Future<bool> createFormLink(BuildContext context, FormLink formLink) async {
    try {
      final response =
          await _client
              .from('form_links')
              .insert(formLink.toInsertJson())
              .select();

      print(response);

      if (response.isNotEmpty) {
        if (context.mounted) {
          AppFeedback.showSuccess(context, "Form link created successfully.");
        }
        loadFormLinks();
        return true;
      } else {
        if (context.mounted) {
          AppFeedback.showError(context, "Failed to create form link.");
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, "Error creating form link: $e");
      }
      return false;
    }
  }

  Future<bool> createMultipleFormLinks(
    BuildContext context,
    List<FormLink> formLinks,
  ) async {
    try {
      final response =
          await _client
              .from('form_links')
              .insert(formLinks.map((f) => f.toInsertJson()).toList())
              .select();

      print(response);

      if (response.isNotEmpty) {
        if (context.mounted) {
          AppFeedback.showSuccess(context, "Form links created successfully.");
        }
        loadFormLinks();
        return true;
      } else {
        if (context.mounted) {
          AppFeedback.showError(context, "Failed to create form links.");
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, "Error creating form links: $e");
      }
      return false;
    }
  }

  // 🔹 UPDATE
  Future<bool> updateFormLink(
    BuildContext context,
    FormLink formLink, {
    bool displayMsg = true,
  }) async {
    try {
      final response =
          await _client
              .from('form_links')
              .update(formLink.toJson())
              .eq('id', formLink.id)
              .select();

      if (response.isNotEmpty) {
        if (displayMsg && context.mounted) {
          AppFeedback.showSuccess(context, "Form link updated successfully.");
        }
        if (displayMsg) loadFormLinks();
        return true;
      } else {
        if (displayMsg && context.mounted) {
          AppFeedback.showError(context, "Failed to update form link.");
        }
        return false;
      }
    } catch (e) {
      if (displayMsg && context.mounted) {
        AppFeedback.showError(context, "Error updating form link: $e");
      }
      return false;
    }
  }

  // 🔹 SYNC (Replace all for an event)
  Future<bool> syncFormLinks(BuildContext context, int eventId, List<FormLink> newLinks) async {
    try {
      // Delete existing
      await _client.from('form_links').delete().eq('event_id', eventId);

      // Insert new
      if (newLinks.isNotEmpty) {
        for (var link in newLinks) {
          link.eventId = eventId;
        }
        await _client
            .from('form_links')
            .insert(newLinks.map((f) => f.toInsertJson()).toList());
      }

      if (context.mounted) {
        AppFeedback.showSuccess(context, "Form links updated successfully.");
      }
      loadFormLinks();
      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, "Error syncing form links: $e");
      }
      return false;
    }
  }

  // 🔹 DELETE
  Future<bool> deleteFormLink(BuildContext context, int formLinkId) async {
    try {
      final response =
          await _client
              .from('form_links')
              .delete()
              .eq('id', formLinkId)
              .select();

      if (response.isNotEmpty) {
        if (context.mounted) {
          AppFeedback.showSuccess(context, "Form link deleted successfully.");
        }
        loadFormLinks();
        return true;
      } else {
        if (context.mounted) {
          AppFeedback.showError(context, "Failed to delete form link.");
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, "Error deleting form link: $e");
      }
      return false;
    }
  }
}
