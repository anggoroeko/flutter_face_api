import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_face_api/face_api.dart' as Regula;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var image1 = new Regula.MatchFacesImage();
  var image2 = new Regula.MatchFacesImage();

  var img1 = Image.network(
      'https://absen.api.persahabatan.co.id/assets/assets/images/testabsen.jpg');

  var img2 = Image.asset('assets/images/portrait.png');
  String _similarity = "nil";
  String _liveness = "nil";
  bool isFace = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  initPlatformState() async {
    Uint8List imageFile = await getImageBytesSync(
        'https://absen.api.persahabatan.co.id/assets/assets/images/testabsen.jpg');
    setImage(true, imageFile, Regula.ImageType.LIVE);
  }

  // showAlertDialog(BuildContext context, bool first) => showDialog(
  //     context: context,
  //     builder: (BuildContext context) => first
  //         ? AlertDialog(title: const Text("Select option"), actions: [
  //             TextButton(child: const Text("Use camera"), onPressed: () {})
  //           ])
  //         : AlertDialog(title: const Text("Select option"), actions: [
  //             TextButton(
  //                 child: const Text("Use camera"),
  //                 onPressed: () {
  //                   Regula.FaceSDK.presentFaceCaptureActivity().then((result) =>
  //                       setImage(
  //                           first,
  //                           base64Decode(Regula.FaceCaptureResponse.fromJson(
  //                                   json.decode(result))!
  //                               .image!
  //                               .bitmap!
  //                               .replaceAll("\n", "")),
  //                           Regula.ImageType.LIVE));
  //                   // setImage(first, null, Regula.ImageType.LIVE));
  //                   Navigator.pop(context);
  //                 })
  //           ]));

  showCircleFace(first) async {
    await Regula.FaceSDK.presentFaceCaptureActivity().then((result) => setImage(
        first,
        base64Decode(Regula.FaceCaptureResponse.fromJson(json.decode(result))!
            .image!
            .bitmap!
            .replaceAll("\n", "")),
        Regula.ImageType.LIVE));
    matchFaces();
  }

  setImage(bool first, Uint8List? imageFile, int type) {
    print('ImageFile ---->>>>');
    // print(imageFile);
    if (imageFile == null) return;

    setState(() => _similarity = "nil");

    if (first) {
      image1.bitmap = base64Encode(imageFile);
      image1.imageType = type;
      setState(() {
        img1 = Image.memory(imageFile);
        _liveness = "nil";
      });
    } else {
      image2.bitmap = base64Encode(imageFile);
      image2.imageType = type;
      setState(() => img2 = Image.memory(imageFile));
    }

    setState(() {
      isFace = false;
    });
  }

  // getImageBase64(String imageUrl) async {
  //   try {
  //     // Fetch the image from the URL
  //     http.Response response = await http.get(Uri.parse(imageUrl));
  //     if (response.statusCode == 200) {
  //       // Convert the image bytes to Base64
  //       String base64Image = base64Encode(response.bodyBytes);
  //       print('Base64 Image: $base64Image');
  //       // Use the Base64 string as needed (e.g., upload to server, display in Flutter app)
  //     } else {
  //       print('Failed to load image. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching image: $e');
  //   }
  // }

  getImageBytesSync(String imageUrl) async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isFace = true;
    });
    try {
      // Fetch the image from the URL
      http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Read the response body as bytes
        Uint8List bytes = response.bodyBytes;
        // print('Image Bytes: $bytes');
        return bytes;
        // Use the bytes as needed (e.g., display in Flutter app)
      } else {
        print('Failed to load image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
    return Uint8List.fromList([0, 0, 0]);
  }

  clearResults() {
    setState(() {
      // img1 = Image.asset('assets/images/portrait.png');
      img2 = Image.asset('assets/images/portrait.png');
      _similarity = "nil";
      _liveness = "nil";
    });
    image2 = new Regula.MatchFacesImage();
  }

  matchFaces() async {
    if (image1.bitmap == null ||
        image1.bitmap == "" ||
        image2.bitmap == null ||
        image2.bitmap == "") return;

    setState(() => _similarity = 'Processing');
    var request = Regula.MatchFacesRequest();
    request.images = [image1, image2];

    Regula.FaceSDK.matchFaces(jsonEncode(request)).then((value) {
      var response = Regula.MatchFacesResponse.fromJson(json.decode(value));

      Regula.FaceSDK.matchFacesSimilarityThresholdSplit(
              jsonEncode(response!.results), 0.75)
          .then((str) {
        var split = Regula.MatchFacesSimilarityThresholdSplit.fromJson(
            json.decode(str));

        setState(() {
          isFace = false;
        });

        setState(() => _similarity = split!.matchedFaces.isNotEmpty
            ? ("${(split.matchedFaces[0]!.similarity! * 100).toStringAsFixed(2)}%")
            : "error");
      });
    });
  }

  // liveness() => Regula.FaceSDK.startLiveness().then((value) {
  //       var result = Regula.LivenessResponse.fromJson(json.decode(value));
  //       setImage(true, base64Decode(result!.bitmap!.replaceAll("\n", "")),
  //           Regula.ImageType.LIVE);
  //       setState(() => _liveness = result.liveness == 0 ? "passed" : "unknown");
  //     });

  Widget createButton(String text, VoidCallback onPress) => SizedBox(
        // ignore: deprecated_member_use
        width: 250,
        // ignore: deprecated_member_use
        child: TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.black12),
            ),
            onPressed: onPress,
            child: Text(text)),
      );

  Widget createImage(first, image, VoidCallback onPress) => Material(
      child: Visibility(
          visible: true,
          child: InkWell(
            onTap: onPress,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image(height: 150, width: 150, image: image),
            ),
          )));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            width: double.infinity,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  createImage(true, img1.image, () async {
                    Uint8List imageFile = await getImageBytesSync(
                        'https://absen.api.persahabatan.co.id/assets/assets/images/testabsen.jpg');
                  }),
                  createImage(false, img2.image, () => showCircleFace(false)),
                  Container(margin: const EdgeInsets.fromLTRB(0, 0, 0, 15)),
                  createButton("Clear", () => clearResults()),
                  Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isFace
                              ? const CircularProgressIndicator()
                              : Text("Similarity: $_similarity",
                                  style: const TextStyle(fontSize: 18)),
                          Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 0, 0)),
                          // Text("Liveness: $_liveness",
                          //     style: const TextStyle(fontSize: 18))
                        ],
                      ))
                ])),
      );
}
