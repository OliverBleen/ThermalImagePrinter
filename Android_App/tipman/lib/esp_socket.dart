import 'dart:io';
import 'package:tipman/main.dart';


class EspSocket
{
  static InternetAddress? espAddress;

  static void startHandeling() async
  {
    try
    {
      ServerSocket server = await ServerSocket.bind('0.0.0.0', 3621);

      server.listen((Socket socket) {
        espAddress = socket.remoteAddress;
      });
    }
    catch(ex)
    {
      Future.delayed(Duration(milliseconds: 500), () => showDialogInternal('Error', 'Error binding socket:\n$ex'));
    }
  }
}