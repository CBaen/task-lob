import 'package:flutter/material.dart';
import '../models/task.dart';

/// Card displaying a task in the court/waiting lists
class TaskCard extends StatelessWidget {
  final Task task;
  final bool showCourtOwner;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.showCourtOwner = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap ?? () => _showTaskDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _buildStatusBadge(context),
                  const SizedBox(width: 8),
                  if (task.urgency != TaskUrgency.normal)
                    _buildUrgencyBadge(context),
                  const Spacer(),
                  if (task.systemName != null)
                    Chip(
                      label: Text(
                        task.systemName!,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Summary
              Text(
                task.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),

              // Current state preview if exists
              if (task.currentState != null && task.currentState!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.currentState!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Court owner (for waiting screen)
              if (showCourtOwner && task.courtUserId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'With: ${task.courtUserId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    if (task.courtReason != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${task.courtReason})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ],

              // Missing info indicator
              if (task.needsMoreInfo) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline,
                          size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${task.missingInfo.length} question${task.missingInfo.length == 1 ? '' : 's'} needed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Deadline if exists
              if (task.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: _isOverdue(task.deadline!)
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDeadline(task.deadline!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOverdue(task.deadline!)
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (color, label) = switch (task.status) {
      TaskStatus.draft => (Colors.grey, 'Draft'),
      TaskStatus.sent => (Colors.blue, 'Sent'),
      TaskStatus.active => (Colors.green, 'Active'),
      TaskStatus.blocked => (Colors.orange, 'Blocked'),
      TaskStatus.done => (Colors.teal, 'Done'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(BuildContext context) {
    final (color, icon, label) = switch (task.urgency) {
      TaskUrgency.urgent => (Colors.red, Icons.priority_high, 'Urgent'),
      TaskUrgency.deadline => (Colors.orange, Icons.event, 'Deadline'),
      TaskUrgency.normal => (Colors.grey, Icons.remove, 'Normal'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) {
      return 'Overdue!';
    } else if (diff.inDays == 0) {
      return 'Due today';
    } else if (diff.inDays == 1) {
      return 'Due tomorrow';
    } else if (diff.inDays < 7) {
      return 'Due in ${diff.inDays} days';
    } else {
      return 'Due ${deadline.month}/${deadline.day}';
    }
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Summary
              Text(
                task.summary,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 16),

              // Status and urgency
              Wrap(
                spacing: 8,
                children: [
                  _buildStatusBadge(context),
                  if (task.urgency != TaskUrgency.normal) _buildUrgencyBadge(context),
                ],
              ),

              if (task.currentState != null) ...[
                const SizedBox(height: 24),
                _buildSection(context, 'Current State', task.currentState!),
              ],

              if (task.desiredOutcome != null) ...[
                const SizedBox(height: 16),
                _buildSection(context, 'Desired Outcome', task.desiredOutcome!),
              ],

              if (task.missingInfo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Questions to Answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...task.missingInfo.map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.help_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q)),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 24),

              // Raw input
              ExpansionTile(
                title: const Text('Original Input'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task.rawInput),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Flip court
                      },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Pass Ball'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Mark done
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }
}
