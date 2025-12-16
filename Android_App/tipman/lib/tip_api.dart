import 'dart:developer';
import 'dart:core';
import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;

class TipApiHelper
{
  static final String _baseAddress = "4.3.2.1";

  static Future<http.Response> printTIP(String data, TipApiPrintSettings settings)
  {
    return post("/api/tip/print", data, settings);
  }
  static Future<http.Response> println(String? data, TipApiPrintSettings settings)
  {
    return post("/api/tip/println", data, settings);
  }
  static Future<http.Response> printQRCode(String data, TipApiPrintSettings settings)
  {
    return post("/api/tip/printQRCode", data, settings);
  }
  static Future<http.Response> printBarcodeCODE128(String data, TipApiPrintSettings settings)
  {
    return post("/api/tip/printBarcode_CODE128", data, settings);
  }
  static Future<http.Response> printBarcodeUPCA(String data, TipApiPrintSettings settings)
  {
    return post("/api/tip/printBarcode_UPCA", data, settings);
  }
  static Future<http.Response> printBarcodeEAN13(String data, TipApiPrintSettings settings)
  {
    return post("/api/tip/printBarcode_EAN13", data, settings);
  }
  static Future<http.Response> feedLines(int lines)
  {
    return post("/api/tip/feedLines", lines.toString(), TipApiPrintSettings());
  }
  static Future<http.Response> spitOut()
  {
    return post("/api/tip/spitOut", null, TipApiPrintSettings());
  }

  static Future<http.Response> post(String endpoint, String? data, TipApiPrintSettings settings) async
  {
    try {
      var uri = Uri.http(_baseAddress, endpoint, settings.toMap(data));
      log('HTTP POST: ${uri.toString()}', level: 800);
      return http.post(uri).timeout(const Duration(seconds: 5));
    }
    catch (ex) {
      return http.Response('', 404);
    }
  }

  static Future<bool> isApiAvailable() async
  {
    try {
     return (await version()).statusCode == 200; 
    }
    catch (ex) {
      return false;
    }
  }

  static Future<http.Response> version()
  {
    return get("/api/tip/version");
  }

  static Future<http.Response> get(String endpoint) async
  {
    try {
      var uri = Uri.http(_baseAddress, endpoint);
      log('HTTP GET: ${uri.toString()}', level: 800);
      return http.get(uri).timeout(const Duration(seconds: 2));
    }
    catch (ex) {
      return http.Response('', 404);
    }
  }

  static Future<String?> printBitmap(List<int> data, int width, int height) async
  {
    if(width > 384) {
      return 'Invalid image width > 384';
    }
    if(width % 8 != 0) {
      return 'Invalid image width not divisible by 8';
    }
    if(data.length < (width / 8) * height) {
      return 'Data length too short. Expected ${(width / 8) * height}, was ${data.length}';
    }

    List<List<int>> bitmapLines = List.empty(growable: true);
    for(int i = 0; i < height; i++)
    {
      bitmapLines.add(data.getRange((i*(width/8)).round(), ((i+1)*(width/8)).round()).toList());
    }

    for(int i = 0; i * 10 < height; i++) {
      var range = bitmapLines.getRange(i*10, (i+1)*10 <= bitmapLines.length ? (i+1)*10 : bitmapLines.length);
      await postBitmapData(toFlatList(range.toList(growable: false)));
      await postBitmap(width, range.length);
    }

    return null;
  }

  static List<int> toFlatList(List<List<int>> list)
  {
    List<int> out = List.empty(growable: true);
    for (var l in list) {
      out.addAll(l);
    }
    return out;
  }

  static Future<http.Response> postBitmapData(List<int> data) async
  {
    try {
      var uri = Uri.http(_baseAddress, '/api/tip/uploadBitmapData');
      log('HTTP POST: ${uri.toString()}', level: 800);
      return http.post(uri, body: data).timeout(const Duration(seconds: 3));
    }
    catch (ex) {
      print('postBitmapData ERROR: $ex');
      return http.Response('', 404);
    }
  }
  static Future<http.Response> postBitmap(int width, int height) async
  {
    try {
      var uri = Uri.http(_baseAddress, '/api/tip/printBitmap', <String, String>{'width': width.toString(), 'height': height.toString()});
      log('HTTP POST: ${uri.toString()}', level: 800);
      return http.post(uri).timeout(const Duration(seconds: 5));
    }
    catch (ex) {
      print('postBitmap ERROR: $ex');
      return http.Response('', 404);
    }
  }
}


typedef TipApiPrintSettingsAlignmentEntry = DropdownMenuEntry<TipApiPrintSettingsAlignment>;
typedef TipApiPrintSettingsUnderlineEntry = DropdownMenuEntry<TipApiPrintSettingsUnderline>;

enum TipApiPrintSettingsAlignment {
  left, center, right;

  static final List<TipApiPrintSettingsAlignmentEntry> entries =
    UnmodifiableListView<TipApiPrintSettingsAlignmentEntry>(
      values.map<TipApiPrintSettingsAlignmentEntry>(
        (TipApiPrintSettingsAlignment heading) => TipApiPrintSettingsAlignmentEntry(
          value: heading,
          label: heading.name,
        ),
      ),
    );
}
enum TipApiPrintSettingsUnderline {
  off, onedot, twodot;

  static final List<TipApiPrintSettingsUnderlineEntry> entries =
    UnmodifiableListView<TipApiPrintSettingsUnderlineEntry>(
      values.map<TipApiPrintSettingsUnderlineEntry>(
        (TipApiPrintSettingsUnderline heading) => TipApiPrintSettingsUnderlineEntry(
          value: heading,
          label: heading.name,
        ),
      ),
    );
}

class TipApiPrintSettings
{
  TipApiPrintSettingsAlignment alignment;
  TipApiPrintSettingsUnderline underline;
  bool inverse;
  bool upsideDown;

  TipApiPrintSettings({this.alignment = TipApiPrintSettingsAlignment.left, this.underline = TipApiPrintSettingsUnderline.off, this.inverse = false, this.upsideDown = false});

  Map<String, String> toMap(String? data)
  {
    return <String, String>{
      if(data != null && data.isNotEmpty)
        'data': data,
      'align': alignment.name,
      'underline': underline.name,
      'inverse': inverse.toString(),
      'upside_down': upsideDown.toString(),
    };
  }
}