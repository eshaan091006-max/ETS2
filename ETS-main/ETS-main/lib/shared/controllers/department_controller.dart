import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:malhar_ets/utils/cache_manager.dart';

class DepartmentController {
  // Singleton instance
  static final DepartmentController _instance =
      DepartmentController._internal();

  factory DepartmentController() {
    return _instance;
  }

  DepartmentController._internal();

  final List<Department> _departments = [];

  List<Department> get departments => _departments;

  Future<void> loadDepartments() async {
    // 1. Try loading from cache
    try {
      final cachedStr = await CacheManager.getCachedData(CacheManager.keyDepartments);
      if (cachedStr != null) {
        _departments.clear();
        _departments.addAll(departmentFromJson(cachedStr));
        PageRefreshController.triggerRefresh();
      }
    } catch (_) {}

    try {
      final response = await Supabase.instance.client
          .from('department')
          .select("*");

      if (response.isNotEmpty) {
        _departments.clear();
        _departments.addAll(
          response.map((json) => Department.fromJson(json)).toList(),
        );
        // Save to cache
        await CacheManager.cacheData(CacheManager.keyDepartments, departmentToJson(_departments));
      }
    } catch (e) {
      print("Error loading departments: $e");
    } finally {
      PageRefreshController.triggerRefresh();
    }
  }

  void printAll() {
    for (Department department in _departments) {
      print("${department.id} ${department.name}");
    }
  }

  Future<DepartmentController> initializeDepartments() async {
    loadDepartments();
    return this;
  }

  Department? getDepartmentById(int id) {
    try {
      return _departments.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}
