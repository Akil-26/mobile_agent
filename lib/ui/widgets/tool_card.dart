import 'package:flutter/material.dart';
import '../../models/tool_definitions.dart';

class ToolCard extends StatelessWidget {
  final ToolDefinition tool;
  final VoidCallback onTap;

  const ToolCard({
    required this.tool,
    required this.onTap,
    super.key,
  });

  Color _getCategoryColor() {
    switch (tool.category) {
      case 'communication':
        return Colors.blue;
      case 'productivity':
        return Colors.green;
      case 'media':
        return Colors.purple;
      case 'settings':
        return Colors.orange;
      case 'info':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (tool.category) {
      case 'communication':
        return Icons.call;
      case 'productivity':
        return Icons.checklist;
      case 'media':
        return Icons.camera;
      case 'settings':
        return Icons.settings;
      case 'info':
        return Icons.info;
      default:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor();

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tool.category.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tool.requiresConfirmation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Requires approval',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tool.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
