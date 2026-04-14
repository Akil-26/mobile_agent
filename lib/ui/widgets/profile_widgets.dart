import 'package:flutter/material.dart';

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: onEdit,
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
