import 'package:flutter/material.dart';
import 'package:kashida_example/demo_state.dart';
import 'package:kashida_example/insert_page.dart';
import 'package:kashida_example/justify_page.dart';
import 'package:kashida_example/rules_page.dart';

void main() {
  runApp(const KashidaExampleApp());
}

class KashidaExampleApp extends StatelessWidget {
  const KashidaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashida example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E4B)),
        useMaterial3: true,
      ),
      home: const KashidaDemoPage(),
    );
  }
}

class KashidaDemoPage extends StatefulWidget {
  const KashidaDemoPage({super.key});

  @override
  State<KashidaDemoPage> createState() => _KashidaDemoPageState();
}

class _KashidaDemoPageState extends State<KashidaDemoPage> {
  final _demo = DemoController();
  int _index = 0;

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _demo,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(switch (_index) {
              1 => 'Find and insert',
              2 => 'Pattern rules',
              _ => 'Justify',
            }),
          ),
          body: IndexedStack(
            index: _index,
            children: [
              JustifyPage(controller: _demo),
              InsertPage(controller: _demo),
              RulesPage(controller: _demo),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.format_align_justify_outlined),
                selectedIcon: Icon(Icons.format_align_justify),
                label: 'Justify',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Find & insert',
              ),
              NavigationDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule),
                label: 'Rules',
              ),
            ],
          ),
        );
      },
    );
  }
}
