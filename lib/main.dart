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
  List _attendanceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
      _attendanceList = [
        {'title': 'プログラミング基礎', 'status': '出席'},
        {'title': '英語I', 'status': '欠席'},
      ];
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_attendanceList);
    await prefs.setString('attendance_list', jsonString);
  }

  Future<void> _deleteData(int index) async {
    setState(() {
      _attendanceList.removeAt(index);
    });
    await _saveData();
  }

  @override
  Widget build(BuildContext context) {
    // ★追加：出席と欠席の回数を自動で数える集計ロジック
    int presentCount = 0;
    int absentCount = 0;
    for (var item in _attendanceList) {
      if (item['status'] == '出席') {
        presentCount++;
      } else if (item['status'] == '欠席') {
        absentCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('出席チェッカー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ★追加：出席・欠席の集計を表示するカード
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('出席回数', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$presentCount 回', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      Column(
                        children: [
                          const Text('欠席回数', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$absentCount 回', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
                // 授業リスト部分
                Expanded(
                  child: _attendanceList.isEmpty
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
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  item['title']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(item['status']!),
                                      backgroundColor: isPresent ? Colors.green[100] : Colors.red[100],
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey),
                                      onPressed: () => _deleteData(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
            await _saveData();
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