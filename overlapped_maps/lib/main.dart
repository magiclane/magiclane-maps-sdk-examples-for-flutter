import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

Future<void> main() async {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  await GemKit.initialize(appAuthorization: projectApiToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Overlapped Maps',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Overlapped Maps',
            style: TextStyle(color: Colors.white)),
      ),
      // Stack maps
      body: Stack(children: [
        const GemMap(),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          width: MediaQuery.of(context).size.width * 0.4,
          child: const GemMap(),
        ),
      ]),
    );
  }
}
