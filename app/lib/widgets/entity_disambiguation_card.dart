import 'package:flutter/material.dart';
import '../models/parsed_lob.dart';

/// Card for disambiguating an entity with multiple possible matches
/// Shows: "Which Sarah?" → [Sarah Thompson] [Sarah Miller] [+ Add New]
class EntityDisambiguationCard extends StatelessWidget {
  final ExtractedEntity entity;
  final Function(EntityMatch) onSelect;
  final VoidCallback onAddNew;

  const EntityDisambiguationCard({
    super.key,
    required this.entity,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMatches = entity.possibleMatches?.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with entity type badge
            Row(
              children: [
                _buildTypeBadge(context),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entity.clarificationQuestion ?? 'Who is "${entity.mention}"?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Context clues
            if (entity.contextClues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: entity.contextClues.map((clue) => Chip(
                  label: Text(clue, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Possible matches
            if (hasMatches) ...[
              Text(
                'Select one:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...entity.possibleMatches!.map((match) => _buildMatchOption(context, match)),
            ],

            // No matches found
            if (!hasMatches) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No matches found for "${entity.mention}"',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Add new button
            OutlinedButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add "${entity.mention}" as new ${entity.type}'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    final (color, icon, label) = switch (entity.type) {
      'person' => (Colors.blue, Icons.person, 'Person'),
      'company' => (Colors.purple, Icons.business, 'Company'),
      'system' => (Colors.green, Icons.computer, 'System'),
      'account' => (Colors.orange, Icons.key, 'Account'),
      _ => (Colors.grey, Icons.help, entity.type),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
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

  Widget _buildMatchOption(BuildContext context, EntityMatch match) {
    final theme = Theme.of(context);
    final confidencePercent = (match.confidence * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelect(match),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // Match info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (match.role != null || match.email != null)
                      Text(
                        [match.role, match.email].whereType<String>().join(' - '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Confidence indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _confidenceColor(match.confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$confidencePercent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _confidenceColor(match.confidence),
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Compact list of all ambiguous entities for the header
class AmbiguousEntitiesBanner extends StatelessWidget {
  final List<ExtractedEntity> entities;
  final VoidCallback onResolve;

  const AmbiguousEntitiesBanner({
    super.key,
    required this.entities,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entities.length} ${entities.length == 1 ? 'entity needs' : 'entities need'} clarification',
              style: TextStyle(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onResolve,
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
