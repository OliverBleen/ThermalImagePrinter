import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tipman/preferences.dart';
import 'package:tipman/pages/bar.dart';


class EditDrinksPage extends StatefulWidget {
  const EditDrinksPage({super.key});

  @override
  State<EditDrinksPage> createState() => _EditDrinksPageState();
}

class _EditDrinksPageState extends State<EditDrinksPage> {
  TextStyle textStyle = TextStyle(fontSize: 20);
  List<Drink> availableDrinks = List.empty();
  var txtController = TextEditingController();

  Future<void> _loadPreferences() async {
    var drinks = await Preferences.getStringList(Settings.barDrinks);
    if(drinks != null) {
      var drinksString = drinks.first;
      for(var drink in drinks.skip(1)) {
        drinksString += '\n$drink';
      }
      setState(() {
        txtController.text = drinksString;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TIP Manager: Bar: Edit Drinks'),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: TextField(
          style: textStyle,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.multiline,
          controller: txtController,
          maxLines: null,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Edit drink data'
          ),
        ),
      ),
      persistentFooterButtons: [
        Column(
          spacing: 8,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsetsGeometry.fromLTRB(5, 10, 5, 10),
                    child: Text('Cancel', style: textStyle,),
                  )
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    Preferences.saveStringList(Settings.barDrinks, txtController.text.split('\n'));
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsetsGeometry.fromLTRB(5, 10, 5, 10),
                    child: Text('Save', style: textStyle,),
                  )
                ),
              ],
            ),
          ],
        )
      ]
    );
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
}