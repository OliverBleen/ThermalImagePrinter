import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tipman/preferences.dart';
import 'package:tipman/tip_api.dart';


class CustomPage extends StatefulWidget {
  const CustomPage({super.key});

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  TextStyle textStyle = TextStyle(fontSize: 20);

  TipApiPrintSettingsAlignment? printSettingsAlignment = TipApiPrintSettingsAlignment.left;
  TipApiPrintSettingsUnderline? printSettingsUnderline = TipApiPrintSettingsUnderline.off;
  bool printSettingsInverse = false;
  bool printSettingsUpsideDown = false;

  Future<void> _loadPreferences() async {
    int? index = await Preferences.getInt(Settings.customAlignment);
    if(index != null && index >= 0 && index < TipApiPrintSettingsAlignment.entries.length) {
      setState(() {
        printSettingsAlignment = TipApiPrintSettingsAlignment.entries[index!].value;
      });
    }
    index = await Preferences.getInt(Settings.customUnderline);
    if(index != null && index >= 0 && index < TipApiPrintSettingsUnderline.entries.length) {
      setState(() {
        printSettingsUnderline = TipApiPrintSettingsUnderline.entries[index!].value;
      });
    }
    var inverse = await Preferences.getBool(Settings.customInverse) ?? false;
    var upsideDown = await Preferences.getBool(Settings.customUpsideDown) ?? false;
    setState(() {
      printSettingsInverse = inverse;
      printSettingsUpsideDown = upsideDown;
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
        spacing: 8,
        children: [
          DropdownMenuFormField(
            textStyle: textStyle,
            expandedInsets: EdgeInsets.zero,
            initialSelection: printSettingsAlignment,
            label: Text('Alignment', style: textStyle,),
            onSelected: (TipApiPrintSettingsAlignment? alignment) {
              setState(() {
                printSettingsAlignment = alignment;
              });
              if(printSettingsAlignment != null) {
                Preferences.saveInt(Settings.customAlignment, printSettingsAlignment!.index);
              }
            },
            dropdownMenuEntries: TipApiPrintSettingsAlignment.entries,
          ),
          DropdownMenuFormField(
            textStyle: textStyle,
            expandedInsets: EdgeInsets.zero,
            initialSelection: printSettingsUnderline,
            label: Text('Underline', style: textStyle,),
            onSelected: (TipApiPrintSettingsUnderline? underline) {
              setState(() {
                printSettingsUnderline = underline;
              });
              if(printSettingsUnderline != null) {
                Preferences.saveInt(Settings.customAlignment, printSettingsUnderline!.index);
              }
            },
            dropdownMenuEntries: TipApiPrintSettingsUnderline.entries,
          ),
          CheckboxListTile(
            title: Text('Inverse?', style: textStyle),
            subtitle: Text('Print white-on-black'),
            value: printSettingsInverse,
            onChanged: (bool? value) {
              if(value != null) {
                Preferences.saveBool(Settings.customInverse, value);
              }
              setState(() {
                printSettingsInverse = value!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Upside Down?', style: textStyle),
            subtitle: Text('Print upside-down'),
            value: printSettingsUpsideDown,
            onChanged: (bool? value) {
              if(value != null) {
                Preferences.saveBool(Settings.customUpsideDown, value);
              }
              setState(() {
                printSettingsUpsideDown = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}