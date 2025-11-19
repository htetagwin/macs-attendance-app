import 'package:flutter/material.dart';
import 'package:simple_attendance_app/constants.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlack,
      body: Center(child: CircularProgressIndicator(color: accentGold)),
    );
  }
}