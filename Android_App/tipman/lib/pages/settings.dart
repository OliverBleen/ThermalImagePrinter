import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tipman/preferences.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextStyle textStyle = TextStyle(fontSize: 20);

  bool _saveImagesWhenPrinting = true;
  bool _saveDitheredImagesWhenPrinting = true;

  Future<void> _loadPreferences() async {
    var saveImagesWhenPrinting = await Preferences.getBool(Settings.saveImagesWhenPrinting);
    var saveDitheredImagesWhenPrinting = await Preferences.getBool(Settings.saveDitheredImagesWhenPrinting);

    setState(() {
      _saveImagesWhenPrinting = saveImagesWhenPrinting ?? true;
      _saveDitheredImagesWhenPrinting = saveDitheredImagesWhenPrinting ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text('Save pictures?', style: textStyle),
            subtitle: Text('Save pictures you take in the app to the gallery when printing'),
            value: _saveImagesWhenPrinting,
            onChanged: (bool? value) {
              if(value != null) {
                Preferences.saveBool(Settings.saveImagesWhenPrinting, value);
              }
              setState(() {
                _saveImagesWhenPrinting = value!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Save dithered pictures?', style: textStyle),
            subtitle: Text('Save dithered pictures to the gallery when printing'),
            value: _saveDitheredImagesWhenPrinting,
            onChanged: (bool? value) {
              if(value != null) {
                Preferences.saveBool(Settings.saveDitheredImagesWhenPrinting, value);
              }
              setState(() {
                _saveDitheredImagesWhenPrinting = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}