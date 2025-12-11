import 'package:flutter/material.dart';
import 'package:tipman/pages/furry.dart';

void main() {
  runApp(const TipMan());
}

class TipMan extends StatelessWidget {
  const TipMan({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TIP Manager',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String _title = 'TIP Manager: ${_bottomNavBarWidgets.entries.elementAt(0).key}';

  static const Map<String, Widget> _bottomNavBarWidgets = <String, Widget>{
    'Furry': FurryPage(),
    'Bar': Text('Bar'),
    'Custom': Text('Custom'),
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _title = 'TIP Manager: ${_bottomNavBarWidgets.entries.elementAt(index).key}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_title),
      ),
      body: Center(
        child: _bottomNavBarWidgets.entries.elementAt(_selectedIndex).value,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Furry'),
          BottomNavigationBarItem(icon: Icon(Icons.local_bar), label: 'Bar'),
          BottomNavigationBarItem(icon: Icon(Icons.draw), label: 'Custom'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
