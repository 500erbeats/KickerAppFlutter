import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/adaptive.dart';
import 'draw_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Tab-Struktur: iOS = Cupertino-Tab-Leiste (wie SwiftUI TabView), Android = Material NavigationBar.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = <Widget>[DrawScreen(), StatsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.shuffle), label: 'Auslosung'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar), label: 'Tabellen'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Einstellungen'),
        ]),
        tabBuilder: (context, i) => CupertinoTabView(builder: (_) => _pages[i]),
      );
    }
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shuffle), label: 'Auslosung'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Tabellen'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
    );
  }
}
