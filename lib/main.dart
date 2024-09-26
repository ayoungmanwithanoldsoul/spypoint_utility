import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spypoint_utility/ffi/disc_api.dart';
import 'package:spypoint_utility/utils/DiscManager.dart';

// import 'package:spypoint_utility/ffi/disk_api_process_run.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'models/disc.dart';

void main() {
  // print("calling the getInfo()");
  DiscManager discManager = DiscManager.instance;
  // discManager.scanDiscs();
  // List<Disc> discs = discManager.discs;
  //
  // for (var disc in discs) {
  //   print(disc.toString());
  // }

  runApp(const MyApp());
}

Future<void> getInfo(DiscApi discApi) async {
  // get information about drive:
  final discInfo = await discApi.getDiscInfo();
  for (var disc in discInfo) {
    print(disc.toString());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpyPoint Utility',
      theme: appTheme(),
      // Custom theme
      routes: appRoutes(),
      // App routes
      initialRoute: '/',
      // Default to Home
      onGenerateRoute: onGenerateRoute,
    );
  }
}
