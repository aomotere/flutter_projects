import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'task_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<TaskSearchResult>? searchResults;
  ChatMessage({required this.text, required this.isUser, this.searchResults});
}

class AiProvider extends ChangeNotifier {
  static const String _keyBoxName = 'settings';
  static const String _apiKeyField = 'gemini_api_key';
  static const int _maxTasksForAi = 30;

  final List<ChatMessage> messages = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  String get apiKey {
    final box = Hive.box(_keyBoxName);
    return box.get(_apiKeyField, defaultValue: '') as String;
  }

  bool get hasApiKey => apiKey.isNotEmpty;

  Future<void> saveApiKey(String key) async {
    final box = Hive.box(_keyBoxName);
    await box.put(_apiKeyField, key.trim());
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    final box = Hive.box(_keyBoxName);
    await box.delete(_apiKeyField);
    messages.clear();
    notifyListeners();
  }

  /// Extract likely search keywords from a user question.
  List<String> _extractSearchTerms(String message) {
    // Remove common question words to get task-relevant keywords
    const stopWords = {
      'what',
      'which',
      'where',
      'when',
      'who',
      'how',
      'why',
      'is',
      'are',
      'was',
      'were',
      'do',
      'does',
      'did',
      'can',
      'could',
      'would',
      'should',
      'will',
      'shall',
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'about',
      'into',
      'my',
      'me',
      'i',
      'you',
      'your',
      'this',
      'that',
      'it',
      'all',
      'any',
      'some',
      'no',
      'not',
      'have',
      'has',
      'had',
      'be',
      'been',
      'being',
      'get',
      'got',
      'give',
      'find',
      'show',
      'list',
      'tell',
      'search',
      'look',
      'tasks',
      'task',
      'please',
      'help',
      'much',
      'many',
      'there',
      'them',
      'their',
    };

    return message
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList();
  }

  /// Detect if the query references a specific workflow stage.
  String? _detectWorkflowFilter(String message) {
    const workflows = [
      'plan',
      'develop',
      'build',
      'test',
      'release',
      'deploy',
      'operate',
      'monitor',
    ];
    final lower = message.toLowerCase();
    for (final w in workflows) {
      if (lower.contains(w)) return w[0].toUpperCase() + w.substring(1);
    }
    return null;
  }

  /// Detect if the query references a specific status.
  String? _detectStatusFilter(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('complete') && !lower.contains('incomplete')) {
      return 'Complete';
    }
    if (lower.contains('incomplete') ||
        lower.contains('pending') ||
        lower.contains('unfinished')) {
      return 'Incomplete';
    }
    return null;
  }

  String _buildSearchContext(
    List<TaskSearchResult> results,
    Map<String, int> stats,
    int totalTaskCount,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('The user has $totalTaskCount total tasks.');
    buffer.writeln(
      'Search matched ${stats['total']} tasks '
      '(${stats['complete']} complete, ${stats['incomplete']} incomplete).',
    );

    if (results.isEmpty) {
      buffer.writeln('No tasks matched the search criteria.');
      return buffer.toString();
    }

    buffer.writeln(
      '\nTop ${results.length} most relevant tasks '
      '(out of ${stats['total']} matches):',
    );
    for (int i = 0; i < results.length; i++) {
      final t = results[i].task;
      buffer.writeln(
        '${i + 1}. "${t.title}" — workflow: ${t.workflow}, '
        'status: ${t.status}, description: ${t.description}',
      );
    }
    return buffer.toString();
  }

  String _buildSummaryContext(TaskProvider taskProvider) {
    final total = taskProvider.totalCount;
    if (total == 0) return 'The user has no tasks currently.';

    final buffer = StringBuffer();
    buffer.writeln('Task summary ($total total tasks):');
    buffer.writeln('- Complete: ${taskProvider.completeCount}');
    buffer.writeln('- Incomplete: ${taskProvider.incompleteCount}');
    buffer.writeln(
      '- Completion rate: '
      '${(taskProvider.completionRate * 100).toStringAsFixed(1)}%',
    );
    final wf = taskProvider.workflowCounts;
    if (wf.isNotEmpty) {
      buffer.writeln(
        '- By workflow: ${wf.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
      );
    }
    return buffer.toString();
  }

  /// Determines if the message is a general/summary question (no search needed)
  /// vs. a specific task search query.
  bool _isGeneralQuestion(String message) {
    final lower = message.toLowerCase();
    const generalPatterns = [
      'summarize',
      'summary',
      'overview',
      'how am i doing',
      'productivity tip',
      'advice',
      'prioritize',
      'progress',
      'how many tasks',
      'total tasks',
      'completion rate',
    ];
    return generalPatterns.any((p) => lower.contains(p));
  }

  Future<void> sendMessage(
    String userMessage,
    TaskProvider taskProvider,
  ) async {
    if (!hasApiKey) {
      _error = 'Please set your Gemini API key first.';
      notifyListeners();
      return;
    }

    messages.add(ChatMessage(text: userMessage, isUser: true));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Determine search strategy
      final isGeneral = _isGeneralQuestion(userMessage);
      List<TaskSearchResult> searchResults = [];
      String taskContext;

      if (isGeneral) {
        // General question — send aggregate stats only (scales to any size)
        taskContext = _buildSummaryContext(taskProvider);
      } else {
        // Specific search — pre-filter locally, send only top matches
        final searchTerms = _extractSearchTerms(userMessage);
        final searchQuery = searchTerms.join(' ');
        final workflowFilter = _detectWorkflowFilter(userMessage);
        final statusFilter = _detectStatusFilter(userMessage);

        searchResults = taskProvider.searchTasks(
          searchQuery,
          limit: _maxTasksForAi,
          workflowFilter: workflowFilter,
          statusFilter: statusFilter,
        );

        final stats = taskProvider.searchStats(searchQuery);
        taskContext = _buildSearchContext(
          searchResults,
          stats,
          taskProvider.totalCount,
        );
      }

      // Step 2: Send to Gemini with relevant context only
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final prompt =
          '''
You are a helpful productivity assistant inside a task-management app that may contain thousands of tasks.
The app has already searched and filtered tasks locally. Here is the relevant context:

$taskContext

The user asks: "$userMessage"

Instructions:
- If search results are provided, reference specific matching tasks by name.
- Mention how many total matches were found if relevant.
- If no tasks matched, suggest refining the search or offer general advice.
- If it's a general question, use the summary statistics.
- Keep responses under 250 words and be actionable.''';

      final response = await model.generateContent([Content.text(prompt)]);
      final reply = response.text ?? 'No response received.';

      messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
          searchResults: searchResults.isNotEmpty ? searchResults : null,
        ),
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('API key') || errorMsg.contains('API_KEY')) {
        _error = 'Invalid API key. Please check your Gemini API key.';
      } else if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        _error = 'API rate limit exceeded. Please wait a moment and try again.';
      } else if (errorMsg.contains('SocketException') ||
          errorMsg.contains('NetworkError') ||
          errorMsg.contains('Failed host lookup')) {
        _error = 'No internet connection. Please check your network.';
      } else if (errorMsg.contains('safety') || errorMsg.contains('blocked')) {
        _error =
            'Response blocked by safety filters. Try rephrasing your question.';
      } else {
        _error = 'Error: $errorMsg';
      }
      messages.add(ChatMessage(text: _error!, isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    messages.clear();
    _error = null;
    notifyListeners();
  }
}
