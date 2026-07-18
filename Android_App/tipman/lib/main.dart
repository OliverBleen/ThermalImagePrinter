import 'package:flutter/material.dart';
import 'package:tipman/pages/furry.dart';
import 'package:tipman/pages/custom.dart';
import 'package:tipman/pages/bar.dart';
import 'package:tipman/pages/settings.dart';
import 'package:tipman/esp_socket.dart';
import 'package:flutter/services.dart';
import 'dart:io';


final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  EspSocket.startHandeling();

  WidgetsFlutterBinding.ensureInitialized();

  ByteData data = await PlatformAssetBundle().load('assets/ca/isrg-root-x2.pem');
  SecurityContext.defaultContext.setTrustedCertificatesBytes(data.buffer.asUint8List());


  runApp(MaterialApp(
    home: TipMan(),
    navigatorKey: navigatorKey,
  ));
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
    'Bar': BarPage(),
    'Custom': CustomPage(),
    'Settings': SettingsPage(),
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.secondary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Furry'),
          BottomNavigationBarItem(icon: Icon(Icons.local_bar), label: 'Bar'),
          BottomNavigationBarItem(icon: Icon(Icons.draw), label: 'Custom'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

void showDialogInternal(String title, String message)
  {
    if(navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: [
            Center(child: Text(message))
          ],
      ),
      );
    }
  }
