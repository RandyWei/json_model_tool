import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:xml/xml.dart';

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

  List<String> results = [];

  //是否启动驼峰
  bool enableSmallHump = false;

  //是否增加 coding keys
  bool enableCodingKeys = false;

  //是否增加 init 方法
  bool enableInit = false;

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

      xmlToStruct(tmpText);
    }
    setState(() {});
  }

  String xmlToStruct(String input, {String key = "请在这里输入Model名字"}) {
    try {
      var document = XmlDocument.parse(input);
      results.add(xmlElementToStruct(
          document.findElements("plist").first.findElements("dict").first));
      result = results.join("\n");

      setState(() {});
      results.clear();
    } catch (e) {}
    return "";
  }

  String xmlElementToStruct(XmlElement element,
      {String type = "请在这里输入Model名字"}) {
    var model = "struct $type:Codable,Identifiable{\n";
    List<String> codingKeysList = [];
    for (var node1 in element.childElements) {
      var keyText = node1.name.toString();

      if (node1.nodeType == XmlNodeType.ELEMENT && "key" == keyText) {
        var typeText = node1.nextElementSibling?.name.toString();

        var rawKey = node1.text;
        var keyNodeStr = checkEnableHump(rawKey);

        if (typeText == "string") {
          model += "    var $keyNodeStr : String";
        } else if (typeText == "int") {
          model += "    var $keyNodeStr : Int";
        } else if (typeText == "true" || typeText == "false") {
          model += "    var $keyNodeStr : Bool";
        } else if (typeText == "double") {
          model += "    var $keyNodeStr : Double";
        } else if (typeText == "float") {
          model += "    var $keyNodeStr : Float";
        } else if (typeText == "dict") {
          if (node1.nextElementSibling != null) {
            var type = keyNodeStr.replaceRange(
                0, 1, keyNodeStr.characters.first.toUpperCase());
            model += "    var $keyNodeStr : $type";

            results
                .add(xmlElementToStruct(node1.nextElementSibling!, type: type));
          }
        } else if (typeText == "array") {
          if (node1.nextElementSibling != null) {
            var type = keyNodeStr.replaceRange(
                0, 1, keyNodeStr.characters.first.toUpperCase());
            model += "    var $keyNodeStr : [$type]";
            results.add(xmlElementToStruct(
                node1.nextElementSibling!.childElements.first,
                type: type));
          }
        }
        model += "\n";

        codingKeysList.add("case $keyNodeStr = \"$rawKey\" \n");
      }
    }

    model += checkCodingKeys(codingKeysList);
    model += "}\n";
    return model;
  }

  String checkEnableHump(String rawKey) {
    if (enableSmallHump) {
      var keysByUnderLine = rawKey.split("_");
      var mappingKey = keysByUnderLine
          .map((e) => e.replaceRange(0, 1, e.characters.first.toUpperCase()))
          .join("")
          .toString();
      mappingKey = mappingKey.replaceRange(
          0, 1, mappingKey.characters.first.toLowerCase());
      return mappingKey;
    } else {
      return rawKey;
    }
  }

  String checkCodingKeys(List<String> list) {
    var codingKeysEnum = "";
    if (enableCodingKeys) {
      codingKeysEnum = "\n    enum CodingKeys: String CodingKey {\n\n";
      for (var element in list) {
        codingKeysEnum += "        $element \n";
      }
      codingKeysEnum += "    }\n";
    }
    return codingKeysEnum;
  }

  String convertToStruct(Map<String, dynamic> map,
      {String type = "请在这里输入Model名字"}) {
    var model = "struct $type:Codable,Identifiable{\n";
    List<String> codingKeysList = [];

    //foreach the map
    map.forEach((key, value) {
      var mappingKey = checkEnableHump(key);

      if (enableSmallHump) {
        var keysByUnderLine = key.split("_");

        mappingKey = keysByUnderLine
            .map((e) => e.replaceRange(0, 1, e.characters.first.toUpperCase()))
            .join("")
            .toString();
        mappingKey = mappingKey.replaceRange(
            0, 1, mappingKey.characters.first.toLowerCase());
      }

      if (value is String) {
        model += "    var $mappingKey : String";
      } else if (value is int) {
        model += "    var $mappingKey : Int";
      } else if (value is bool) {
        model += "    var $mappingKey : Bool";
      } else if (value is double) {
        model += "    var $mappingKey : Double";
      } else if (value is Float) {
        model += "    var $mappingKey : Float";
      } else if (value is Map) {
        var type = mappingKey.replaceRange(
            0, 1, mappingKey.characters.first.toUpperCase());
        model += "    var $mappingKey : $type";
        results.add(convertToStruct(value as Map<String, dynamic>, type: type));
      } else if (value is List && value.isNotEmpty) {
        var type = mappingKey.replaceRange(
            0, 1, mappingKey.characters.first.toUpperCase());
        model += "    var $mappingKey : [$type]";
        results.add(
            convertToStruct(value.first as Map<String, dynamic>, type: type));
      }
      model += "\n";

      codingKeysList.add("case $mappingKey = \"$key\" \n");
    });

    model += checkCodingKeys(codingKeysList);

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                            value: enableSmallHump,
                            onChanged: (value) {
                              enableSmallHump = value ?? false;
                              enableCodingKeys = value ?? false;
                              setState(() {});
                            }),
                        const Text("Enable Hump"),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: enableCodingKeys,
                            onChanged: (value) {
                              enableCodingKeys = value ?? false;
                              setState(() {});
                            }),
                        const Text("CodingKeys"),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  child: const Text("Convert"),
                  onPressed: formatAndConvert,
                )
              ],
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
