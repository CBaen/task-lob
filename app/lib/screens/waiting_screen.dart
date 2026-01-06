import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';

/// Waiting Screen - Shows tasks that are waiting on OTHERS
/// "Ball is in their court" - nothing for you to do here yet
class WaitingScreen extends ConsumerWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingTasks = ref.watch(waitingTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting On Others'),
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
      body: waitingTasks.isEmpty
          ? _buildEmptyState(context)
          : _buildTaskList(context, waitingTasks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing waiting',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'All balls are in your court or done.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    // Group by who has the ball
    final grouped = <String?, List<Task>>{};
    for (final task in tasks) {
      final owner = task.courtUserId ?? 'Unknown';
      grouped.putIfAbsent(owner, () => []).add(task);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_top,
                size: 32,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'} waiting',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Ball is in their court',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tasks grouped by owner
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonHeader(context, entry.key ?? 'Unknown', entry.value.length),
              ...entry.value.map((t) => TaskCard(
                    task: t,
                    key: Key(t.id),
                    showCourtOwner: true,
                  )),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPersonHeader(BuildContext context, String personId, int count) {
    // In a real app, you'd look up the person's name
    final displayName = personId.startsWith('user_') ? 'Team Member' : personId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
