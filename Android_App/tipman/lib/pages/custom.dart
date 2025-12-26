import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as im;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
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
  var txtController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  TipApiPrintSettingsAlignment? printSettingsAlignment = TipApiPrintSettingsAlignment.left;
  TipApiPrintSettingsUnderline? printSettingsUnderline = TipApiPrintSettingsUnderline.off;
  bool printSettingsInverse = false;
  bool printSettingsUpsideDown = false;
  String? text = '';

  double imageDitherThreshold = 0.5;
  XFile? imageFile;
  Image? editedImage;
  im.Image? rawEditedImage;
  bool editInProgress = false;
  bool shouldEditAgain = false;
  bool imageFileFromCamera = true;

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
    return DefaultTextStyle(
      style: textStyle,
      child: ListView(
        padding: EdgeInsets.all(10),
        children: [
          Column(
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
              TextField(
                style: textStyle,
                controller: txtController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter data:'
                ),
                onChanged: (String? value) {
                  text = value;
                },
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.printQRCode(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('QR Code', style: textStyle,),
                      )
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.printTIP(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('Print', style: textStyle,),
                      )
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.println(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('Print Line', style: textStyle,),
                      )
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.printBarcodeCODE128(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('CODE128', style: textStyle,),
                      )
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.printBarcodeUPCA(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('UPCA', style: textStyle,),
                      )
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(text != null) {
                          try {
                            await TipApiHelper.printBarcodeEAN13(text!, getPrintSettings());
                          }
                          catch (ex) {
                            showError(ex.toString(), 'Error printing');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('EAN13', style: textStyle,),
                      )
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Spacer(),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await TipApiHelper.spitOut();
                        }
                        catch (ex) {
                          showError(ex.toString(), 'Error printing');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                        child: Text('Spit out', style: textStyle,),
                      )
                    ),
                  ),
                  Spacer(),
                ],
              ),
              Padding(
                padding: const EdgeInsetsGeometry.only(top: 20),
                child: Text('Print picture:', style: textStyle.copyWith(fontWeight: FontWeight.bold),),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _picker.pickImage(source: ImageSource.gallery).then((file) {
                        setState(() {
                          imageFile = file;
                          imageFileFromCamera = false;
                        });
                        _editImage();
                      });
                    },
                    child: Text('From Gallery', style: textStyle,),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _picker.pickImage(source: ImageSource.camera).then((file) {
                        setState(() {
                          imageFile = file;
                          imageFileFromCamera = true;
                        });
                        _editImage();
                      });
                    },
                    child: Text('From Camera', style: textStyle,),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  imageFile != null ?
                  Image.file(
                    File(imageFile!.path),
                    width: (MediaQuery.sizeOf(context).width / 2) - 20,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Center(
                        child: Text('Error displaying image', style: textStyle,),
                      );
                    }
                  ) :
                  Center(
                    child: Text('Please select\nan image', style: textStyle,),
                  ),
                  editedImage ?? Container(),
                ],
              ),
              Text('Dither Threshold:'),
              Slider(
                value: imageDitherThreshold,
                max: 255.0,
                min: 0.01,
                onChanged: (double value) {
                  Preferences.saveDouble(Settings.imageDitherThreshold, imageDitherThreshold);
                  setState(() {
                    imageDitherThreshold = value;
                  });
                  _editImage();
                },
              ),
              Padding(
                padding: const EdgeInsetsGeometry.only(top: 25),
                child: ElevatedButton(
                  onPressed: onPrintPressed,
                  child: Padding(
                    padding: const EdgeInsetsGeometry.fromLTRB(20, 10, 20, 10),
                    child: Text('Print', style: textStyle,),
                  )
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  TipApiPrintSettings getPrintSettings() {
    var settings = TipApiPrintSettings(
      inverse: printSettingsInverse,
      upsideDown: printSettingsUpsideDown,
    );
    if(printSettingsAlignment != null) {
      settings.alignment = printSettingsAlignment!;
    }
    if(printSettingsUnderline != null) {
      settings.underline = printSettingsUnderline!;
    }
    return settings;
  }

  void _editImage() {
    if(editInProgress) {
      shouldEditAgain = true;
      return;
    }
    editInProgress = true;

    _editImageInternal();
  }

  Future<void> _editImageInternal() async {
    try {
      do {
        setState(() {
          shouldEditAgain = false;
        });

        if(imageFile == null) {
          return;
        }
        im.Image? img = im.decodeImage(await File(imageFile!.path).readAsBytes());
        if(img == null) {
          return;
        }
        img = im.copyResize(img, width: 384, maintainAspect: true, interpolation: im.Interpolation.nearest);
        img = im.grayscale(img);
        img = im.ditherImage(img, quantizer: im.BinaryQuantizer(threshold: imageDitherThreshold), kernel: im.DitherKernel.atkinson);
        //img = im.luminanceThreshold(img);
        //img = im.invert(img);

        setState(() {
          if(img == null) {
            return;
          }
          editedImage = Image.memory(im.encodePng(img), width: (MediaQuery.sizeOf(context).width / 2) - 20);
          rawEditedImage = img;
        });
        /*td.Uint8List rawIn = td.Uint8List(img.width * img.height);
        for(final pixel in img) {
          rawIn[0] = ((255) * (im.ColorUint8.rgb(pixel.r, pixel.g, pixel.b).round() / 4095)).round();
        }
        Uint8List rawOut = Uint8List(48 * img.height);*/
      }
      while(shouldEditAgain);
    }
    catch (ex) {
      // Do nothing
    }
    finally {
      setState(() {
        editInProgress = false;
      });
    }
    
  }
  List<int> to1BitBitmap(im.Image image) {
    if(image.width % 8 != 0) {
      throw Exception('Image width was not divisible by 8');
    }
    List<int> out = List.empty(growable: true);

    int counter = 7;

    for(int y = 0; y < image.height; y++) {
      for(int x = 0; x < image.width; x += 8) {
        counter = 7;
        out.add(
          pixelTo1BitColor(image.getPixel(x+0, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+1, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+2, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+3, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+4, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+5, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+6, y)) << counter-- |
          pixelTo1BitColor(image.getPixel(x+7, y)) << counter
        );
      }
    }

    return out;
  }

  int pixelTo1BitColor(im.Pixel pixel) {
    return pixel.clone().rNormalized > 0.5 ? 0 : 1; // For thermal printer it is backwards
  }

  void onPrintPressed() async {
    try {
      if(imageFile != null && imageFileFromCamera && (await Preferences.getBool(Settings.saveImagesWhenPrinting) ?? true)) {
        Gal.putImage(imageFile!.path, album: 'TIP_Custom');
      }
      if(rawEditedImage != null && (await Preferences.getBool(Settings.saveDitheredImagesWhenPrinting) ?? true)) {
        var filename = '${p.join(p.dirname(imageFile!.path), p.basenameWithoutExtension(imageFile!.path))}_dithered.png';
        if(await im.encodePngFile(filename, rawEditedImage!)) {
          Gal.putImage(filename, album: 'TIP_Custom');
        }
      }
      if(!await TipApiHelper.isApiAvailable()) {
        showDialogInternal(SimpleDialog(
          title: const Text('API could not be reached'),
          children: [
            Center(child: const Text('Call to endpoint /api/tip/version failed'))
          ],
        ));
        return;
      }
      if(rawEditedImage == null) {
        showDialogInternal(SimpleDialog(
          title: const Text('Image was null'),
          children: [
            Center(child: const Text('Could not print image as the variable was null'))
          ],
        ));
        return;
      }

      var bmp = to1BitBitmap(rawEditedImage!);
      await TipApiHelper.printBitmap(bmp, rawEditedImage!.width, rawEditedImage!.height);
    }
    catch (ex) {
      showError(ex.toString(), 'Print Error');
    }
  }

  void showError(String text, String title) {
    showDialogInternal(SimpleDialog(
      title: Text(title),
      children: [
        Center(child: Text(text))
      ],
    ));
  }

  void showDialogInternal(Widget widget) {
    if(mounted) {
      showDialog(
        context: context,
        builder: (context) => widget,
      );
    }
  }
}