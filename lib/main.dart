import 'package:flutter/material.dart';
import 'package:map_practice/getlocation.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'getlocation',
      routes: {"getlocation": (context) => GetLocation()},
    ),
  );
}
