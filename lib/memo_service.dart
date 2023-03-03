import 'dart:convert';
import 'package:flutter/material.dart';
import 'main.dart';

class Memo {
  Memo({
    required this.content,
    this.isPinned = false,
    this.updatedAt,
  });

  String content;
  bool isPinned;
  DateTime? updatedAt;

  Map toJson() {
    return {
      'content': content,
      'isPinned': isPinned,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Memo.fromJson(json) {
    return Memo(
      content: json['content'],
      isPinned: json['isPinned'] ?? false,
      updatedAt:
          json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt']),
    );
  }
}

class MemoService extends ChangeNotifier {
  MemoService() {
    loadMemoList();
  }

  List<Memo> memoList = [];
  // [
  //   Memo(content: '장보기 목록: 사과, 양파'),
  //   Memo(content: '새 메모 2'),
  // ];

  createMemo({required String content}) {
    Memo memo = Memo(content: content, updatedAt: DateTime.now());
    memoList.add(memo);
    notifyListeners(); // Consumer<MemoService>의 builder 부분을 호출해서 화면 새로고침
    saveMemoList();
  }

  updateMemo({required int index, required String content}) {
    Memo memo = memoList[index];
    memo.content = content;
    memo.updatedAt = DateTime.now();
    notifyListeners();
    saveMemoList();
  }

  updatePinMemo({required int index}) {
    Memo memo = memoList[index];
    memo.isPinned = !memo.isPinned;
    memoList = [
      ...memoList.where((element) => element.isPinned),
      ...memoList.where((element) => !element.isPinned),
    ];
    notifyListeners();
    saveMemoList();
  }

  deleteMemo({required int index}) {
    memoList.removeAt(index);
    notifyListeners();
    saveMemoList();
  }

  saveMemoList() {
    List memoJsonList = memoList.map((memo) => memo.toJson()).toList();
    // [{"content": "1"}, {"content": "2"}]
    String jsonString = jsonEncode(memoJsonList);
    // '[{"content": "1"}, {"content": "2"}]'
    prefs.setString('memoList', jsonString);
  }

  loadMemoList() {
    String? jsonString = prefs.getString('memoList');
    // '[{"content": "1"}, {"content": "2"}]'
    if (jsonString == null) return; // null 이면 로드하지 않음
    List memoJsonList = jsonDecode(jsonString);
    // [{"content": "1"}, {"content": "2"}]
    memoList = memoJsonList.map((json) => Memo.fromJson(json)).toList();
  }
}
