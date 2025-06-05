import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Creamos un ThemeData personalizado basado en el actual, pero con texto adaptado
    final ThemeData customTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: isDarkMode ? Colors.white : Colors.black87,
            displayColor: isDarkMode ? Colors.white : Colors.black87,
          ),
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      scaffoldBackgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 1,
      ),
      colorScheme: Theme.of(context).colorScheme.copyWith(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
          ),
    );

    return Theme(
      data: customTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ],
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}
