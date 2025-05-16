import 'package:flutter/material.dart';

import 'extension.dart';

class SmallScreenUI extends StatefulWidget {
  final List<LivenessDetectionStep> challengeList;
  final int currentStep;
  final Widget durationUI;
  const SmallScreenUI({required this.challengeList, required this.currentStep, super.key, required this.durationUI });

  @override
  State<SmallScreenUI> createState() => _SmallScreenUIState();
}

class _SmallScreenUIState extends State<SmallScreenUI> {
  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.only(top: 52, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                    elevation: 0,
                    backgroundColor: Colors.white24, // Background color
                  ),
                  onPressed: () {
                    // Your action
                  },
                  child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24,),
                ),
                Spacer(),
                widget.durationUI
              ],
            ),
          ),
          SizedBox(height: 24,),
          Text("Place your face in frame", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
          SizedBox(height: 18,),
          Container(
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(48)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: (widget.currentStep >= widget.challengeList.length)? const Text("Hold Steady...", style: TextStyle(color: Colors.white, fontSize: 14),):Text(widget.challengeList[widget.currentStep].displayName, style: TextStyle(color: Colors.white, fontSize: 14),),
          ),
          Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Cancel", style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 18
              ),),
            ),
          ),
          SizedBox(height: 48,),

        ],
      ),
    );
  }
}