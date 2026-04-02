// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class TestApiScreen extends StatefulWidget {
//   const TestApiScreen({super.key});

//   @override
//   State<TestApiScreen> createState() => _TestApiScreenState();
// }

// class _TestApiScreenState extends State<TestApiScreen> {
//   String _result = 'Click a button to test API';
//   bool _loading = false;

//   Future<void> testLogin() async {
//     setState(() {
//       _loading = true;
//       _result = 'Testing login...';
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://localhost:5000/api/auth/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'email': 'test@test.com',
//           'password': 'password123'
//         }),
//       );

//       setState(() {
//         _loading = false;
//         _result = '''
// 🔵 STATUS: ${response.statusCode}
// 🔵 HEADERS: ${response.headers}
// 🔵 BODY: ${response.body}
// ''';
//       });
//     } catch (e) {
//       setState(() {
//         _loading = false;
//         _result = '❌ ERROR: $e';
//       });
//     }
//   }

//   Future<void> testRegister() async {
//     setState(() {
//       _loading = true;
//       _result = 'Testing registration...';
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://localhost:5000/api/auth/register'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'email': 'newuser@test.com',
//           'password': 'password123',
//           'fullName': 'Test User',
//           'role': 'PLAYER'
//         }),
//       );

//       setState(() {
//         _loading = false;
//         _result = '''
// 🔵 STATUS: ${response.statusCode}
// 🔵 HEADERS: ${response.headers}
// 🔵 BODY: ${response.body}
// ''';
//       });
//     } catch (e) {
//       setState(() {
//         _loading = false;
//         _result = '❌ ERROR: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('API Test Screen'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: testLogin,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(16),
//               ),
//               child: const Text('Test Login API'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: testRegister,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(16),
//               ),
//               child: const Text('Test Register API'),
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               'API Response:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: _loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : SingleChildScrollView(
//                         child: Text(
//                           _result,
//                           style: const TextStyle(fontFamily: 'monospace'),
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }