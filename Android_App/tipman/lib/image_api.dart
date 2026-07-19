import 'dart:developer';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ImageApiHelper
{
  static final String _baseAddress = "https://home.oliverbleen.net:8001";
  static final String _token = "";

  static Future<http.Response> upload(String albumTitle, String uuid, String filePath) async
  {
    try {
      var file = XFile(filePath);
      print('Upload. Type "${file.mimeType}"');
      var uri = Uri.parse('$_baseAddress/api/Images/Upload/$albumTitle/$uuid');
      Map<String, String> headers = { "X-Api-Key": _token};
      print(uri);
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      final httpImage = http.MultipartFile.fromBytes('imageData', await file.readAsBytes(),
          contentType: MediaType.parse(file.mimeType ?? 'image/png'), filename: 'image.png');
      request.files.add(httpImage);
      var response = await request.send();

      log('HTTP POST: ${uri.toString()}', level: 800);

      return http.Response(await response.stream.bytesToString(), response.statusCode);
    }
    catch (ex) {
      return http.Response(ex.toString(), 404);
    }
  }

  static Future<http.Response> deleteImage(String uuid) async
  {
    try {
      var uri = Uri.parse('$_baseAddress/api/Images/Delete/$uuid');
      Map<String, String> headers = { "X-Api-Key": _token};
      var request = http.MultipartRequest('DELETE', uri);
      request.headers.addAll(headers);
      var response = await request.send();

      log('HTTP DELETE: ${uri.toString()}', level: 800);

      return http.Response(await response.stream.bytesToString(), response.statusCode);
    }
    catch (ex) {
      return http.Response(ex.toString(), 404);
    }
  }

  static Future<http.Response> deleteAlbum(String albumTitle) async
  {
    try {
      var uri = Uri.parse('$_baseAddress/api/Albums/Delete/$albumTitle');
      Map<String, String> headers = { "X-Api-Key": _token};
      var request = http.MultipartRequest('DELETE', uri);
      request.headers.addAll(headers);
      var response = await request.send();

      log('HTTP DELETE: ${uri.toString()}', level: 800);

      return http.Response(await response.stream.bytesToString(), response.statusCode);
    }
    catch (ex) {
      return http.Response(ex.toString(), 404);
    }
  }
}
