import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';

/// My Court - Shows tasks that are waiting on ME to act
/// This is the "whose turn is it?" answer: IT'S YOUR TURN
class CourtScreen extends ConsumerWidget {
  const CourtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTasks = ref.watch(myCourtTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Court'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh tasks from API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refresh coming soon')),
              );
            },
          ),
        ],
      ),
      body: myTasks.isEmpty
          ? _buildEmptyState(context)
          : _buildTaskList(context, myTasks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Your court is clear!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks waiting on you right now.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // Navigate to catcher - handled by parent
            },
            icon: const Icon(Icons.mic),
            label: const Text('Catch Some Chaos'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    // Group by urgency
    final urgent = tasks.where((t) => t.urgency == TaskUrgency.urgent).toList();
    final deadline =
        tasks.where((t) => t.urgency == TaskUrgency.deadline).toList();
    final normal = tasks.where((t) => t.urgency == TaskUrgency.normal).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Court summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_tennis,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'} in your court',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (urgent.isNotEmpty)
                      Text(
                        '${urgent.length} urgent!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Urgent tasks first
        if (urgent.isNotEmpty) ...[
          _buildSectionHeader(context, 'Urgent', Icons.warning, Colors.red),
          ...urgent.map((t) => TaskCard(task: t, key: Key(t.id))),
          const SizedBox(height: 16),
        ],

        // Deadline tasks
        if (deadline.isNotEmpty) ...[
          _buildSectionHeader(
              context, 'Has Deadline', Icons.event, Colors.orange),
          ...deadline.map((t) => TaskCard(task: t, key: Key(t.id))),
          const SizedBox(height: 16),
        ],

        // Normal tasks
        if (normal.isNotEmpty) ...[
          _buildSectionHeader(context, 'Normal', Icons.inbox, Colors.blue),
          ...normal.map((t) => TaskCard(task: t, key: Key(t.id))),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
