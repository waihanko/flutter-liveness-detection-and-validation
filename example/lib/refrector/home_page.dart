import 'dart:io';

import 'package:flutter/material.dart';

import 'face_liveness_scan_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String imagePath = "Click button bellow to open camera";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        if(imagePath != "Click button bellow to open camera")    Align(
              child: SizedBox(
                height: 100,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
             Text(imagePath),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  FaceLivenessScanScreen(),
                    // builder: (context) => const FaceDetectionPage2(),
                  ),
                ).then((value) => {
                  setState(() {
                 imagePath = value;
                  })
                },);
              },
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Camera'),
            )
          ],
        ),
      ),
    );
  }
}