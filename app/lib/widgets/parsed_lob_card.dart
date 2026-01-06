import 'package:flutter/material.dart';
import '../models/parsed_lob.dart';

/// Card displaying a single parsed task from a lob
/// Shows classification, summary, and allows selection/editing
class ParsedLobCard extends StatelessWidget {
  final ParsedTask task;
  final Function(bool)? onToggle;

  const ParsedLobCard({
    super.key,
    required this.task,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          onToggle?.call(!task.isSelected);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with classification badge and checkbox
              Row(
                children: [
                  _buildClassificationBadge(context),
                  const SizedBox(width: 8),
                  if (task.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.urgency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Checkbox(
                    value: task.isSelected,
                    onChanged: (value) => onToggle?.call(value ?? false),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Summary
              Text(
                task.displaySummary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),

              // System name if detected
              if (task.system != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.computer,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.system!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ],

              // Self-service steps
              if (task.isSelfService && task.selfServiceSteps != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'You can do this yourself:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...task.selfServiceSteps!.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${e.key + 1}. '),
                                  Expanded(child: Text(e.value)),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],

              // Venting response
              if (task.isVenting && task.ventingResponse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite,
                          size: 16, color: Colors.purple.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.ventingResponse!,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Missing info questions
              if (task.needsInfo) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Need more info:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...task.missingInfo.map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(q)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Raw chunk (collapsible)
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Original text',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.rawChunk,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildClassificationBadge(BuildContext context) {
    final (color, icon, label) = switch (task.classification) {
      'task' => (Colors.blue, Icons.task_alt, 'Task'),
      'self_service' => (Colors.green, Icons.self_improvement, 'Self-Service'),
      'reminder' => (Colors.orange, Icons.alarm, 'Reminder'),
      'venting' => (Colors.purple, Icons.favorite, 'Venting'),
      _ => (Colors.grey, Icons.help, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
