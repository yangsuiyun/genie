import 'package:flutter/material.dart';

class ColorPickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color value;
  final ValueChanged<Color> onChanged;

  const ColorPickerTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: () => _showColorPicker(context),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildColorOption(context, Colors.red),
              _buildColorOption(context, Colors.blue),
              _buildColorOption(context, Colors.green),
              _buildColorOption(context, Colors.orange),
              _buildColorOption(context, Colors.purple),
              _buildColorOption(context, Colors.teal),
            ],
          ),
        ),
      ),
    );

    if (color != null) {
      onChanged(color);
    }
  }

  Widget _buildColorOption(BuildContext context, Color color) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      title: Text(color.toString()),
      onTap: () => Navigator.of(context).pop(color),
    );
  }
}
