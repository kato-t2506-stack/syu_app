import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '出席チェッカー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AttendanceHomeScreen(),
    );
  }
}

// 1. 一覧画面
class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  // 型を省略して自動推論させます
  List _attendanceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // アプリ起動時にデータを読み込む
  }

  // データをローカルから読み込む処理
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('attendance_list');
    
    if (jsonString != null) {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      setState(() {
        _attendanceList = decodedList.map((item) {
          return Map<String, String>.from(item);
        }).toList();
      });
    } else {
      // 初回起動時のデフォルトデータ
      _attendanceList = [
        {'title': 'プログラミング基礎', 'status': '出席'},
        {'title': '英語I', 'status': '欠席'},
      ];
    }
    setState(() {
      _isLoading = false;
    });
  }

  // データをローカルに保存する処理
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_attendanceList);
    await prefs.setString('attendance_list', jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出席チェッカー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceList.isEmpty
              ? const Center(
                  child: Text(
                    'まだ出席データはありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _attendanceList.length,
                  itemBuilder: (context, index) {
                    final item = _attendanceList[index];
                    final isPresent = item['status'] == '出席';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          item['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Chip(
                          label: Text(item['status']!),
                          backgroundColor: isPresent ? Colors.green[100] : Colors.red[100],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newRecord = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceAddScreen(),
            ),
          );

          if (newRecord != null) {
            setState(() {
              _attendanceList.add(newRecord);
            });
            await _saveData(); // 追加したときに保存する
          }
        },
        tooltip: '授業を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 2. 登録画面
class AttendanceAddScreen extends StatefulWidget {
  const AttendanceAddScreen({super.key});

  @override
  State<AttendanceAddScreen> createState() => _AttendanceAddScreenState();
}

class _AttendanceAddScreenState extends State<AttendanceAddScreen> {
  final _controller = TextEditingController();
  String _status = '出席';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('授業の追加'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '授業名',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例：Webプログラミング',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '出席状態',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('出席'),
                    value: '出席',
                    groupValue: _status,
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('欠席'),
                    value: '欠席',
                    groupValue: _status,
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('授業名を入力してください')),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'title': text,
                    'status': _status,
                  });
                },
                child: const Text('保存して追加', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}