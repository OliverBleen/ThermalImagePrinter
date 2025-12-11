import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart' as im;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef HeadingEntry = DropdownMenuEntry<Heading>;
typedef SubHeadingEntry = DropdownMenuEntry<SubHeading>;
enum Heading {
  cute('You Cute!', SubHeading.spotted),
  fine('No Awoo. Fine: 200€', SubHeading.payFine);

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextStyle textStyle = TextStyle(fontSize: 20);
  final ImagePicker _picker = ImagePicker();

  Heading? selectedHeading = Heading.cute;
  SubHeading? selectedSubHeading = SubHeading.spotted;
  String? location;
  double imageDitherThreshold = 0.5;
  XFile? imageFile;
  Image? editedImage;
  bool editInProgress = false;
  bool shouldEditAgain = false;
  bool imageFileFromCamera = true;
  bool generateQRCode = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: textStyle,
      child: ListView(
        padding: EdgeInsets.all(10),
        children: [
          Form(
            key: _formKey,
            child: Column(
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
                  },
                  dropdownMenuEntries: Heading.entries,
                ),
                DropdownMenuFormField(
                  textStyle: textStyle,
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: selectedSubHeading,
                  label: const Text('Sub Heading'),
                  onSelected: (SubHeading? subHeading) {
                    setState(() {
                      selectedSubHeading = subHeading;
                    });
                  },
                  dropdownMenuEntries: SubHeading.entries,
                ),
                TextFormField(
                  style: textStyle,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter location'
                  ),
                  validator: (String? value) {
                    if(value == null || value.isEmpty) {
                      return 'Please enter the location';
                    }
                    location = value;
                    return null;
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
                    setState(() {
                      generateQRCode = value!;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsetsGeometry.only(top: 25),
                  child: ElevatedButton(
                    onPressed: () {
                      if(_formKey.currentState!.validate()) {
                        if(imageFile != null && imageFileFromCamera) {
                          Gal.putImage(imageFile!.path, album: '${DateFormat('yyyyMMdd').format(DateTime.now())}_$location');
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsetsGeometry.fromLTRB(20, 10, 20, 10),
                      child: Text('Print', style: textStyle,),
                    )
                  ),
                )
              ],
            )
          ),
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
}