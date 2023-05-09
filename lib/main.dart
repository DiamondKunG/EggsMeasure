import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Egg Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Egg Analyzer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  double? _diameter;
  String? _grade;
  String? _errorMessage;
  String? _returnImage;

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _errorMessage = pickedFile.path;
      } else {
        _errorMessage = "No image selected";
      }
    });
  }

  Future<void> analyzeImage() async {
    try {
      if (_image == null) {
        throw Exception('No image selected');
      }

      final bytes = await _image!.readAsBytes();
      String base64Image = base64Encode(bytes);

      var data = {'image': base64Image};

      var response = await http.post(
        Uri.parse('http://203.145.117.248:5000/'), //ip endpoint ของ เซิร์ฟ API
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data), // รับค่าที่ ทาง server ส่งกลับมา
      );

      if (response.statusCode == 200) { // เมื่อค่า response เป็น 200 = ติดต่อกับเซิร์ฟเวอร์ได้ปกติ
        var result = jsonDecode(response.body); // ทำการนำค่าที่ server ส่งกลับมา มา decode
        double diameter = result['diameter']; // แยกขนาดของไข่
        String grade = result['grade']; // แขกเกรดของไข่

        setState(() {
          _diameter = diameter / 100; // นำมา หาร 100
          _grade = grade; // กำหนด _grade = เกรดที่ server ส่งมา เพื่อไปแสดงในหน้าหลัก
          _errorMessage = null;

          print(_grade.toString() + " " + _diameter.toString());
          
        });
      } else {
        throw Exception('An error occurred: ${response.statusCode}');
      }
    } catch (e, s) {
      //print('Error occurred: $e');
      //print(s); // print stack trace
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 200,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: getImage,
                    icon: Icon(Icons.upload),
                    label: Text("Upload an Image"),
                  ),
                  SizedBox(height: 20),
                  _image == null
                      ? Text('No image selected.')
                      : Column(
                    children: [
                      Image.file(
                        _image!,
                        height: 200,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: analyzeImage,
                        icon: Icon(Icons.search),
                        label: Text("Analyze Image"),
                      ),
                      SizedBox(height: 20),
                      Text("Grade: " + _grade.toString() == "null" ? "" : "Grade: " + _grade.toString(),style: TextStyle(fontSize: 30),), // โชว์เกรดของไข่ ถ้า _grade มีการอัพเดตและไม่ใช่ nullZ
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
