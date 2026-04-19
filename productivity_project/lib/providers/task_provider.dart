import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskSearchResult {
  final int index;
  final Task task;
  final double score;
  TaskSearchResult({required this.index, required this.task, required this.score});
}

class TaskProvider extends ChangeNotifier {
  static const String _boxName = 'tasks';

  Box<Task> get _box => Hive.box<Task>(_boxName);

  List<Task> get tasks => _box.values.toList();

  int get totalCount => tasks.length;
  int get completeCount => tasks.where((t) => t.status == 'Complete').length;
  int get incompleteCount => tasks.where((t) => t.status == 'Incomplete').length;

  double get completionRate =>
      totalCount == 0 ? 0.0 : completeCount / totalCount;

  /// Search tasks using keyword matching with relevance scoring.
  /// Handles thousands of tasks efficiently by doing local text search
  /// and returning only the top [limit] most relevant results.
  List<TaskSearchResult> searchTasks(
    String query, {
    int limit = 50,
    String? workflowFilter,
    String? statusFilter,
  }) {
    if (query.trim().isEmpty &&
        workflowFilter == null &&
        statusFilter == null) {
      return [];
    }

    final keywords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
    final allTasks = tasks;
    final results = <TaskSearchResult>[];

    for (int i = 0; i < allTasks.length; i++) {
      final task = allTasks[i];

      // Apply filters first (fast rejection)
      if (workflowFilter != null &&
          task.workflow.toLowerCase() != workflowFilter.toLowerCase()) {
        continue;
      }
      if (statusFilter != null &&
          task.status.toLowerCase() != statusFilter.toLowerCase()) {
        continue;
      }

      // If only filters were provided (no keywords), include with base score
      if (keywords.isEmpty) {
        results.add(TaskSearchResult(index: i, task: task, score: 1.0));
        continue;
      }

      // Score based on keyword matches across all fields
      double score = 0;
      final titleLower = task.title.toLowerCase();
      final descLower = task.description.toLowerCase();
      final workflowLower = task.workflow.toLowerCase();

      for (final keyword in keywords) {
        // Title matches weighted highest
        if (titleLower == keyword) {
          score += 10;
        } else if (titleLower.contains(keyword)) {
          score += 5;
        }
        // Description matches
        if (descLower.contains(keyword)) {
          score += 2;
        }
        // Workflow matches
        if (workflowLower.contains(keyword)) {
          score += 3;
        }
      }

      if (score > 0) {
        results.add(TaskSearchResult(index: i, task: task, score: score));
      }
    }

    // Sort by relevance score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    // Return top results only
    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// Quick stats about tasks matching a filter — runs in O(n) without
  /// allocating a filtered list, suitable for large datasets.
  Map<String, int> searchStats(String query) {
    final keywords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
    if (keywords.isEmpty) {
      return {
        'total': totalCount,
        'complete': completeCount,
        'incomplete': incompleteCount,
      };
    }

    int matched = 0, complete = 0, incomplete = 0;
    for (final task in tasks) {
      final text =
          '${task.title} ${task.description} ${task.workflow}'.toLowerCase();
      final hit = keywords.any((k) => text.contains(k));
      if (hit) {
        matched++;
        if (task.status == 'Complete') {
          complete++;
        } else {
          incomplete++;
        }
      }
    }
    return {'total': matched, 'complete': complete, 'incomplete': incomplete};
  }

  void addTask(Task task) {
    _box.add(task);
    notifyListeners();
  }

  void updateTask(int index, Task updated) {
    final task = _box.getAt(index);
    if (task != null) {
      task.title = updated.title;
      task.description = updated.description;
      task.workflow = updated.workflow;
      task.status = updated.status;
      task.save();
      notifyListeners();
    }
  }

  void toggleStatus(int index) {
    final task = _box.getAt(index);
    if (task != null) {
      task.status = task.status == 'Complete' ? 'Incomplete' : 'Complete';
      task.save();
      notifyListeners();
    }
  }

  void deleteTask(int index) {
    _box.deleteAt(index);
    notifyListeners();
  }

  Map<String, int> get workflowCounts {
    final counts = <String, int>{};
    for (final task in tasks) {
      counts[task.workflow] = (counts[task.workflow] ?? 0) + 1;
    }
    return counts;
  }
}
