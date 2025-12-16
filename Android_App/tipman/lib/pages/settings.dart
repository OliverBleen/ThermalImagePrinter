import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  int cacheSize = 0;

  Future<void> _loadPreferences() async {
    var saveImagesWhenPrinting = await Preferences.getBool(Settings.saveImagesWhenPrinting);
    var saveDitheredImagesWhenPrinting = await Preferences.getBool(Settings.saveDitheredImagesWhenPrinting);

    setState(() {
      _saveImagesWhenPrinting = saveImagesWhenPrinting ?? true;
      _saveDitheredImagesWhenPrinting = saveDitheredImagesWhenPrinting ?? true;
    });

    var cacheDirSize = await dirStat((await getTemporaryDirectory()).path);
    setState(() {
      cacheSize = cacheDirSize;
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
          Padding(
            padding: const EdgeInsetsGeometry.only(top: 25),
            child: ElevatedButton(
              onPressed: onClearCachePressed,
              child: Padding(
                padding: const EdgeInsetsGeometry.fromLTRB(20, 10, 20, 10),
                child: Column(
                  children: [
                    Text('Clear Cache', style: textStyle,),
                    Text('Size: ${(cacheSize/1024/1024).toStringAsFixed(2)}MiB',)
                  ],
                ),
              )
            ),
          )
        ],
      ),
    );
  }

  void onClearCachePressed() async {
    final Directory cacheDir = await getTemporaryDirectory();
    await cacheDir.delete(recursive: true);
    await cacheDir.create();

    showDialogInternal(SimpleDialog(
      title: const Text('Cleared cache'),
      children: [
        Center(child: const Text('Cache has been cleared'))
      ],
    ));

    var cacheDirSize = await dirStat((await getTemporaryDirectory()).path);
    setState(() {
      cacheSize = cacheDirSize;
    });
  }
  void showDialogInternal(Widget widget)
  {
    if(mounted) {
      showDialog(
        context: context,
        builder: (context) => widget,
      );
    }
  }

  Future<int> dirStat(String dirPath) async {
    int totalSize = 0;
    var dir = Directory(dirPath);
    try {
      if (await dir.exists()) {
        await dir.list(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) async {
            if (entity is File) {
              totalSize += await entity.length();
            }
          });
      }
    } catch (e) {
      //Do nothing
    }

    return totalSize;
  }
}