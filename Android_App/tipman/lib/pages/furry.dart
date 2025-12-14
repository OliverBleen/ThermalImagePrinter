import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as im;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tipman/tip_api.dart';
import 'package:tipman/preferences.dart';

typedef HeadingEntry = DropdownMenuEntry<Heading>;
typedef SubHeadingEntry = DropdownMenuEntry<SubHeading>;
enum Heading {
  cute('You Cute!', SubHeading.spotted),
  fine('No Awoo. Fine: Euro 200.00', SubHeading.payFine);

  const Heading(this.label, this.defaultSubHeading);
  final String label;
  final SubHeading defaultSubHeading;

  static final List<HeadingEntry> entries =
    UnmodifiableListView<HeadingEntry>(
      values.map<HeadingEntry>(
        (Heading heading) => HeadingEntry(
          value: heading,
          label: heading.label,
        ),
      ),
    );
}
enum SubHeading {
  spotted('Spotted at {location}'),
  payFine('To be paid within 3 days');
  
  const SubHeading(this.label);
  final String label;

  static final List<SubHeadingEntry> entries =
    UnmodifiableListView<SubHeadingEntry>(
      values.map<SubHeadingEntry>(
        (SubHeading subHeading) => SubHeadingEntry(
          value: subHeading,
          label: subHeading.label,
        ),
      ),
    );
}

class FurryPage extends StatefulWidget {
  const FurryPage({super.key});

  @override
  State<FurryPage> createState() => _FurryPageState();
}

class _FurryPageState extends State<FurryPage> {
  TextStyle textStyle = TextStyle(fontSize: 20);
  final ImagePicker _picker = ImagePicker();
  var txtController = TextEditingController();

  Heading? selectedHeading = Heading.cute;
  SubHeading? selectedSubHeading = SubHeading.spotted;
  String? location;
  double imageDitherThreshold = 0.5;
  XFile? imageFile;
  Image? editedImage;
  im.Image? rawEditedImage;
  bool editInProgress = false;
  bool shouldEditAgain = false;
  bool imageFileFromCamera = true;
  bool generateQRCode = false;
  double? printProgress;

  Future<void> _loadPreferences() async {
    int? index = await Preferences.getInt(Settings.selectedHeading);
    if(index != null && index > 0 && index < Heading.entries.length) {
      setState(() {
        selectedHeading = Heading.entries[index!].value;
      });
    }
    index = await Preferences.getInt(Settings.selectedSubHeading);
    if(index != null && index > 0 && index < SubHeading.entries.length) {
      setState(() {
        selectedSubHeading = SubHeading.entries[index!].value;
      });
    }
    var loc = await Preferences.getString(Settings.location);
    var imgDither = (await Preferences.getDouble(Settings.imageDitherThreshold)) ?? 0.5;
    var genQRCode = (await Preferences.getBool(Settings.generateQRCode)) ?? true;
    setState(() {
      if(loc != null) {
        location = loc;
        txtController.text = loc;
      }
      imageDitherThreshold = imgDither;
      generateQRCode = genQRCode;
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
            children: <Widget>[
              DropdownMenuFormField(
                textStyle: textStyle,
                expandedInsets: EdgeInsets.zero,
                initialSelection: selectedHeading,
                label: Text('Heading', style: textStyle,),
                onSelected: (Heading? heading) {
                  setState(() {
                    selectedHeading = heading;
                    selectedSubHeading = heading?.defaultSubHeading;
                  });
                  if(selectedHeading != null) {
                    Preferences.saveInt(Settings.selectedHeading, selectedHeading!.index);
                  }
                  if(selectedSubHeading != null) {
                    Preferences.saveInt(Settings.selectedSubHeading, selectedSubHeading!.index);
                  }
                },
                dropdownMenuEntries: Heading.entries,
              ),
              DropdownMenuFormField(
                textStyle: textStyle,
                expandedInsets: EdgeInsets.zero,
                initialSelection: selectedSubHeading,
                label: const Text('Sub Heading'),
                onSelected: (SubHeading? subHeading) {
                  if(subHeading != null) {
                    Preferences.saveInt(Settings.selectedSubHeading, subHeading.index);
                  }
                  setState(() {
                    selectedSubHeading = subHeading;
                  });
                },
                dropdownMenuEntries: SubHeading.entries,
              ),
              TextField(
                style: textStyle,
                controller: txtController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter location'
                ),
                onChanged: (String? value) {
                  location = value;
                },
              ),
              Padding(
                padding: const EdgeInsetsGeometry.only(top: 20),
                child: Text('Picture selection:'),
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
                    child: Text('Please select an image', style: textStyle,),
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
              CheckboxListTile(
                title: Text('Add QR Code to project website?', style: textStyle,),
                value: generateQRCode,
                onChanged: (bool? value) {
                  if(value != null) {
                    Preferences.saveBool(Settings.generateQRCode, value);
                  }
                  setState(() {
                    generateQRCode = value!;
                  });
                },
              ),
              printProgress != null ? Container(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const Text('Printing Progress:'),
                    Container(
                      padding: EdgeInsets.only(top: 10),
                    ),
                    LinearProgressIndicator(
                      value: printProgress,
                    )
                  ],
                )
              ) : Container(),
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
        ]
      )
    );
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
      if(location == null || location!.isEmpty) {
        showDialogInternal(SimpleDialog(
          title: const Text('Location not set'),
          children: [
            Center(child: const Text('You need to set the location in order to print'))
          ],
        ));
        return;
      }
      Preferences.saveString(Settings.location, location!);

      if(imageFile != null && imageFileFromCamera && (await Preferences.getBool(Settings.saveImagesWhenPrinting) ?? true)) {
        Gal.putImage(imageFile!.path, album: '${DateFormat('yyyyMMdd').format(DateTime.now())}_$location');
      }
      if(rawEditedImage != null && (await Preferences.getBool(Settings.saveDitheredImagesWhenPrinting) ?? true)) {
        var filename = '${p.join(p.dirname(imageFile!.path), p.basenameWithoutExtension(imageFile!.path))}_dithered.png';
        if(await im.encodePngFile(filename, rawEditedImage!)) {
          Gal.putImage(filename, album: '${DateFormat('yyyyMMdd').format(DateTime.now())}_$location');
        }
      }
      if(!await TipApiHelper.isApiAvailable()) {
        showDialogInternal(SimpleDialog(
          title: const Text('API could not be reached'),
          children: [
            Center(child: const Text('Call to endpoint /api/tip/version failed'))
          ],
        ));
        setState(() {
          printProgress = null;
        });
        return;
      }
      setState(() {
        printProgress = 0;
      });
      await TipApiHelper.println(selectedHeading?.label, TipApiPrintSettings());
      setState(() {
        printProgress = 0.2;
      });
      await TipApiHelper.println(selectedSubHeading?.label.replaceAll('{location}', location!), TipApiPrintSettings());
      if(rawEditedImage == null) {
        showDialogInternal(SimpleDialog(
          title: const Text('Image was null'),
          children: [
            Center(child: const Text('Could not print image as the variable was null'))
          ],
        ));
      }
      else {
        setState(() {
          printProgress = 0.45;
        });
        print('Converting to bmp...');
        var bmp = to1BitBitmap(rawEditedImage!);
        print('Starting BitMap print...');

        setState(() {
          printProgress = 0.6;
        });

        await TipApiHelper.printBitmap(bmp, rawEditedImage!.width, rawEditedImage!.height);
        print('Starting BitMap print finished!');
      }
      setState(() {
          printProgress = 0.7;
        });
      if(generateQRCode) {
        await TipApiHelper.printQRCode('https://oliverbleen.net/projects/tip', TipApiPrintSettings(alignment: TipApiPrintSettingsAlignment.center));
      }
      setState(() {
          printProgress = 0.99;
        });
      await TipApiHelper.spitOut();

      setState(() {
        printProgress = null;
      });
    }
    catch (ex) {
      showDialogInternal(SimpleDialog(
          title: const Text('Error occured during printing'),
          children: [
            Center(child: Text(ex.toString()))
          ],
      ));
      setState(() {
        printProgress = null;
      });
    }
    
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