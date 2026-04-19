import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/task_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final aiProvider = context.read<AiProvider>();
    final taskProvider = context.read<TaskProvider>();
    _inputController.clear();
    aiProvider.sendMessage(text, taskProvider);
    _scrollToBottom();
  }

  void _quickSend(String text) {
    _inputController.text = text;
    _send();
  }

  Future<void> _showApiKeyDialog() async {
    final aiProvider = context.read<AiProvider>();
    final controller = TextEditingController(text: aiProvider.apiKey);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a free API key from Google AI Studio',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Paste your Gemini API key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (aiProvider.hasApiKey)
            TextButton(
              onPressed: () {
                aiProvider.removeApiKey();
                Navigator.pop(ctx);
              },
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await aiProvider.saveApiKey(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Task Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'API Key Settings',
            onPressed: _showApiKeyDialog,
          ),
          if (aiProvider.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Chat',
              onPressed: aiProvider.clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Task count banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '${taskProvider.totalCount} tasks indexed  •  '
              'AI search pre-filters locally, then uses Gemini for insights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Chat messages
          Expanded(
            child: aiProvider.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI-Powered Task Search',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aiProvider.hasApiKey
                                ? 'Search through your tasks using natural language. '
                                  'The AI filters locally first, then analyzes matches.'
                                : 'Tap the key icon above to set your free Gemini API key.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (aiProvider.hasApiKey)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _SuggestionChip(
                                  label: 'Find incomplete deploy tasks',
                                  onTap: () => _quickSend(
                                    'Find incomplete deploy tasks',
                                  ),
                                ),
                                _SuggestionChip(
                                  label: 'Summarize my progress',
                                  onTap: () => _quickSend(
                                    'Summarize my progress',
                                  ),
                                ),
                                _SuggestionChip(
                                  label: 'What should I prioritize?',
                                  onTap: () => _quickSend(
                                    'What should I prioritize?',
                                  ),
                                ),
                                _SuggestionChip(
                                  label: 'Show tasks in testing phase',
                                  onTap: () => _quickSend(
                                    'Show tasks in testing phase',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? width * 0.15 : 12,
                      vertical: 16,
                    ),
                    itemCount: aiProvider.messages.length +
                        (aiProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == aiProvider.messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Searching & analyzing...'),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = aiProvider.messages[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ChatBubble(message: msg),
                          // Show matched tasks inline after AI response
                          if (!msg.isUser &&
                              msg.searchResults != null &&
                              msg.searchResults!.isNotEmpty)
                            _MatchedTasksCard(results: msg.searchResults!),
                        ],
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? width * 0.15 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'Search tasks or ask a question...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _send(),
                        enabled: !aiProvider.isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: aiProvider.isLoading ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable card showing matched tasks inline below an AI response.
class _MatchedTasksCard extends StatefulWidget {
  final List<TaskSearchResult> results;
  const _MatchedTasksCard({required this.results});

  @override
  State<_MatchedTasksCard> createState() => _MatchedTasksCardState();
}

class _MatchedTasksCardState extends State<_MatchedTasksCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayCount = _expanded ? widget.results.length : 5;
    final visible = widget.results.take(displayCount).toList();

    return Card(
      margin: const EdgeInsets.only(left: 4, right: 40, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${widget.results.length} matching tasks found',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...visible.map((r) => _MatchedTaskTile(result: r)),
          if (widget.results.length > 5)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    _expanded
                        ? 'Show less'
                        : 'Show ${widget.results.length - 5} more...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchedTaskTile extends StatelessWidget {
  final TaskSearchResult result;
  const _MatchedTaskTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final task = result.task;
    final theme = Theme.of(context);
    final isComplete = task.status == 'Complete';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isComplete ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.isNotEmpty ? task.title : task.workflow,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.workflow,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gemini',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.search, size: 18),
      onPressed: onTap,
    );
  }
}
