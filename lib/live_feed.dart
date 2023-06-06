import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:live_feed_test/extension.dart';

class LiveFeedView extends StatefulWidget {
  const LiveFeedView({Key? key}) : super(key: key);

  @override
  State<LiveFeedView> createState() => _LiveFeedViewState();
}

class _LiveFeedViewState extends State<LiveFeedView> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool isWorking = false;
  String result = '';
  late CameraImage cameraImage;
  String dogBreed = '';
  String dogProb = '';
  List<dynamic> output = [];

  @override
  void initState() {
    super.initState();
    setupCamera();
    loadModel();
  }

  @override
  void dispose() async {
    _cameraController!.dispose();
    await Tflite.close();
    super.dispose();
  }

  Future<void> setupCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high);

    await _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
    });

    setState(() {
      _cameraController!.startImageStream((image) => {
            if (!isWorking)
              {
                isWorking = true,
                cameraImage = image,
                runModelOnStreamFrames(),
              }
          });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/ml/model_v2.tflite",
      labels: "assets/ml/labels_v2.txt",
    );
  }

  runModelOnStreamFrames() async {
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: cameraImage.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );

    result = '';

    recognitions?.forEach((outputs) {
      dogBreed = outputs['label'];
      dogProb = (outputs['confidence'] * 100).toStringAsFixed(2);
      setState(() {
        result = '$dogProb% - $dogBreed \n ';
      });
      isWorking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20.0,
                    color: Colors.grey,
                    offset: Offset(20, 20),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(6.0.wp),
                    bottomLeft: Radius.circular(6.0.wp)),
                child: CameraPreview(_cameraController!),
              ),
            ),
            SizedBox(
              height: 8.0.wp,
            ),
            Text(
              result,
              style: TextStyle(
                fontSize: 6.0.wp,
                color: Colors.green,
                letterSpacing: 0.4.wp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
