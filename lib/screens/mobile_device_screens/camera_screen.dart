import 'package:absolute_app/core/utils/constants.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key, required this.cameras, required this.accType})
      : super(key: key);

  final List<CameraDescription> cameras;
  final String accType;

  @override
  State<CameraScreen> createState() {
    return _CameraScreenState();
  }
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Picture'),
        backgroundColor: appColor,
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
      ),
      body: _controller.value.isInitialized
          ? Stack(
              children: <Widget>[
                CameraPreview(_controller),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: appColor),
                      icon: const Icon(Icons.camera),
                      label: const Text("Click"),
                      onPressed: () async {
                        await _controller.takePicture().then((value) async {
                          if (value.path != '') {
                            await navigateToResultsAndSetLocation(
                                context, value.path);
                          }
                        });
                      },
                    ),
                  ),
                )
              ],
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }

  Future<void> navigateToResultsAndSetLocation(
      BuildContext context, String path) async {
    // final String result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => LocationResultsScreen(
    //       imagePath: path,
    //       isFromCamera: true,
    //       accType: widget.accType,
    //     ),
    //   ),
    // );
    // log('results at camera screen - $result');
    // if (!mounted) return;
    // Future.delayed(const Duration(milliseconds: 100), () {
    //   Navigator.pop(context, result);
    // }).whenComplete(() => Navigator.pop(context, result));
  }
}
