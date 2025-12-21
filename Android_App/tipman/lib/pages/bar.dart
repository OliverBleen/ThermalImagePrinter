import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tipman/preferences.dart';
import 'package:tipman/tip_api.dart';


class BarPage extends StatefulWidget {
  const BarPage({super.key});

  @override
  State<BarPage> createState() => _BarPageState();
}

class _BarPageState extends State<BarPage> {
  TextStyle textStyle = TextStyle(fontSize: 20);
  var txtController = TextEditingController();

  List<Drink> availableDrinks = [
    Drink('Tequila Lemon Tea', 500),
    Drink('Auslaender Rum', 1000),
    Drink('Lecker Bierchen', 1000),
  ];
  Map<Drink, int> selectedDrinks = Map.identity();
  String? name;


  Future<void> _loadPreferences() async {

  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10).copyWith(bottom: 15),
      child: Column(
        spacing: 8,
        children: [
          TextField(
            style: textStyle,
            controller: txtController,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Enter name:'
            ),
            onChanged: (String? value) {
              name = value;
            },
          ),
          Expanded(
            child:ListView(
              children: [
                Table(
                  columnWidths: const <int, TableColumnWidth>{
                    0: FlexColumnWidth(),
                    1: FixedColumnWidth(74),
                    2: FixedColumnWidth(85),
                    3: FixedColumnWidth(65),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
                  children: drinkListToWidgetList(),
                ),
              ],
            )
          ),
          Row(
            children: [
              Text('Total:', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
              Spacer(),
              Text('EUR ${(getTotalPriceInCent(selectedDrinks) / 100).toStringAsFixed(2)}€', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedDrinks.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsetsGeometry.fromLTRB(20, 10, 20, 10),
                  child: Text('Reset', style: textStyle,),
                )
              ),
              Spacer(),
              ElevatedButton(
                onPressed: printFullReceipt,
                child: Padding(
                  padding: const EdgeInsetsGeometry.fromLTRB(20, 10, 20, 10),
                  child: Text('Print', style: textStyle,),
                )
              ),
            ],)
        ],
      ),
    );
  }

  List<TableRow> drinkListToWidgetList() {
    List<TableRow> rows = List.empty(growable: true);

    for(var drink in availableDrinks) {
      rows.add(
        _TableRow2(
          callback: () => addDrink(drink),
          tableCells: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                drink.name,
                style: textStyle.copyWith(fontSize: 17)
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${selectedDrinks[drink] != null ? selectedDrinks[drink]!.toString() : '0'} x ', style: textStyle.copyWith(fontSize: 17),),
                Text((drink.costInCent / 100).toStringAsFixed(2)),
              ],
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Text(
                'EUR ${selectedDrinks[drink] != null ? ((selectedDrinks[drink]! * drink.costInCent) / 100).toStringAsFixed(2) : '0.00'}', style: textStyle.copyWith(fontSize: 17),
                textAlign: TextAlign.right,
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 5),
              child: ElevatedButton(
                onPressed: () {
                  removeDrink(drink);
                },
                child: Text('-', style: textStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
                )
              ),
            ),
          ]
        )
      );
    }

    return rows;
  }

  void addDrink(Drink drink) {
    if(selectedDrinks[drink] != null) {
      setState(() {
        selectedDrinks[drink] = selectedDrinks[drink]! + 1;
      });
    }
    else {
      setState(() {
          selectedDrinks[drink] = 1;
      });
    }
  }

  void removeDrink(Drink drink) {
    if(selectedDrinks[drink] != null && selectedDrinks[drink]! > 0) {
      setState(() {
        selectedDrinks[drink] = selectedDrinks[drink]! - 1;
      });
    }
  }

  Future<void> printHeader() async {
    if(name == null) {
      showDialogInternal(SimpleDialog(
          title: const Text('Name not set'),
          children: [
            Center(child: Text('Please set the name'))
          ],
      ));
    }
    await TipApiHelper.println(name, TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.center, inverse: true));
    await TipApiHelper.feedLines(1);
    await TipApiHelper.println('Receipt ${DateTime.now().toUtc().toIso8601String().substring(0, 23)}T', TipApiPrintSettings());
    await TipApiHelper.feedLines(1);
  }
  void printFullReceipt() async {
    await printHeader();
    for(var drink in selectedDrinks.entries) {
      await TipApiHelper.println(drink.key.name, TipApiPrintSettings());
      String moneyLine = '';
      if(drink.value >= 10) {
        moneyLine += '${drink.value} x ';
      }
      else {
        moneyLine += ' ${drink.value} x ';
      }
      if(drink.key.costInCent >= 1000) {
        moneyLine += '${(drink.key.costInCent / 100).toStringAsFixed(2)} = ';
      }
      else {
        moneyLine += ' ${(drink.key.costInCent / 100).toStringAsFixed(2)} = ';
      }
      if(drink.key.costInCent * drink.value >= 1000) {
        moneyLine += ((drink.key.costInCent * drink.value) / 100).toStringAsFixed(2);
      }
      else {
        moneyLine += ' ${((drink.key.costInCent * drink.value) / 100).toStringAsFixed(2)}';
      }
      await TipApiHelper.println(moneyLine, TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.right));
    }
    await TipApiHelper.println('--------------------------------', TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.center));
    await TipApiHelper.println('SUM:   EUR ${(getTotalPriceInCent(selectedDrinks) / 100).toStringAsFixed(2)}', TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.right, underline:  TipApiPrintSettingsUnderline.twodot));
    await TipApiHelper.feedLines(1);
    await TipApiHelper.println('We hope to see', TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.center));
    await TipApiHelper.println('you again soon!', TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.center));
    await TipApiHelper.spitOut();
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



int getTotalPriceInCent(Map<Drink, int> drinks) {
  int out = 0;

  for(var drink in drinks.entries) {
    out += drink.value * drink.key.costInCent;
  }
  return out;
}

class Drink {
  String name;
  int costInCent;

  Drink(this.name, this.costInCent);

  @override
  operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }
    return other is Drink
      && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}


class _TableRow2 implements TableRow {
  final List<Widget> tableCells;
  final VoidCallback? callback;

  _TableRow2({
    required this.tableCells,
    this.callback,
  });

  @override
  List<Widget> get children => tableCells
      .map(
        (cell) => TableRowInkWell(
          onTap: callback,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          child: cell,
        ),
      )
      .toList();

  @override
  Decoration? get decoration => null;

  @override
  LocalKey? get key => null;
}
