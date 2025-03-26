import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? Colors.yellow : Colors.grey[800],
          );
        },
      ),
      onPressed: () {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
      tooltip: 'Theme wechseln',
    );
  }
}
