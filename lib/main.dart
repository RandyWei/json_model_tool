import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Json Model Tool',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const MyHomePage(title: 'Json Model Tool'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  String result = "";
  bool isFormat = false;

  List<String> results = [];

  void formatAndConvert() {
    var tmpText = controller.value.text;
    try {
      const encoder = JsonEncoder.withIndent('    ');
      Map<String, dynamic> jsonObject = jsonDecode(tmpText);

      //pretty format
      var json = encoder.convert(jsonObject);
      controller.text = json;

      var model = convertToStruct(jsonObject);

      results.add(model);

      result = results.join("\n");

      results.clear();
    } catch (e) {
      debugPrint("解析异常");
    }
    setState(() {});
  }

  String convertToStruct(Map<String, dynamic> map,
      {String key = "请在这里输入Model名字"}) {
    var model = "struct $key:Codable,Identifiable{\n";

    //foreach the map
    map.forEach((key, value) {
      if (value is String) {
        model += "    var $key : String";
      } else if (value is int) {
        model += "    var $key : Int";
      } else if (value is bool) {
        model += "    var $key : Bool";
      } else if (value is double) {
        model += "    var $key : Double";
      } else if (value is Float) {
        model += "    var $key : Float";
      } else if (value is Map) {
        var type = key.replaceRange(0, 1, key.characters.first.toUpperCase());
        model += "    var $key : $type";
        results.add(convertToStruct(value as Map<String, dynamic>, key: type));
      } else if (value is List && value.isNotEmpty) {
        var type = key.replaceRange(0, 1, key.characters.first.toUpperCase());
        model += "    var $key : $type";
        results.add(
            convertToStruct(value.first as Map<String, dynamic>, key: type));
      }
      model += "\n";
    });
    model += "}\n";

    return model;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: controller,
                expands: true,
                minLines: null,
                maxLines: null,
              ),
            ),
          ),
          Container(
            height: double.infinity,
            color: Colors.purple[50],
            padding: const EdgeInsets.all(8.0),
            child: UnconstrainedBox(
              child: ElevatedButton(
                child: const Text("Convert"),
                onPressed: formatAndConvert,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(result),
            ),
          )
        ],
      ),
    );
  }
}
