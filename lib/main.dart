import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memo_service.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  MobileAds.instance.initialize();

  // runApp(const MyApp());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BannerAd myBanner = BannerAd(
    // Test 광고 ID, 광고 승인받은 후 생성한 광고 unit ID 로 바꾸기
    adUnitId: Platform.isAndroid
        ? 'ca-app-pub-4626454853712911/8756746784' // ca-app-pub-3940256099942544/6300978111 // Android ad unit ID
        : 'ca-app-pub-4626454853712911/5939011754', // ca-app-pub-3940256099942544/2934735716 // iOS ad unit ID
    size: AdSize.fullBanner,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  );

  InterstitialAd? interstitialAd;

  @override
  void initState() {
    super.initState();
    myBanner.load();

    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
            interstitialAd?.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          },
        ));
  }

  // List<String> memoList = ['장보기 목록: 사과, 양파'];
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoService>(builder: (context, memoService, child) {
      List<Memo> memoList = memoService.memoList;

      return Scaffold(
        appBar: AppBar(
          title: Text("mymemo"),
        ),
        body: memoList.isEmpty
            ? Center(child: Text('메모를 작성해 주세요.'))
            : ListView.builder(
                itemCount: memoList.length,
                itemBuilder: (context, index) {
                  Memo memo = memoList[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: IconButton(
                          icon: Icon(memo.isPinned
                              ? CupertinoIcons.pin_fill
                              : CupertinoIcons.pin),
                          onPressed: () {
                            memoService.updatePinMemo(index: index);
                          },
                        ),
                        title: Text(
                          memo.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          memo.updatedAt == null
                              ? ''
                              : memo.updatedAt.toString().substring(0, 19),
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(Icons.access_alarms_outlined),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(
                                index: index,
                              ),
                            ),
                          );
                          if (memo.content.isEmpty) {
                            memoService.deleteMemo(index: index);
                          }
                        },
                      ),
                      Divider(),
                    ],
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            memoService.createMemo(content: '');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(
                  index: memoList.length - 1,
                ),
              ),
            );
            if (memoList.last.content.isEmpty) {
              memoService.deleteMemo(index: memoList.length - 1);
            }
          },
        ),
        bottomNavigationBar: Container(
          alignment: Alignment.center,
          width: myBanner.size.width.toDouble(),
          height: myBanner.size.height.toDouble(),
          child: AdWidget(ad: myBanner),
        ),
      );
    });
  }
}

// 메모 생성 및 수정 페이지
class DetailPage extends StatelessWidget {
  DetailPage({super.key, required this.index});

  final int index;

  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MemoService memoService = context.read<MemoService>();
    Memo memo = memoService.memoList[index];

    contentController.text = memo.content;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // 삭제 버튼 클릭시
              showDeleteDialog(context, memoService);
            },
            icon: Icon(Icons.delete),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: contentController,
          decoration: InputDecoration(
            hintText: "메모를 입력하세요",
            border: InputBorder.none,
          ),
          autofocus: true,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            // 텍스트필드 안의 값이 변할 때
            memoService.updateMemo(index: index, content: value);
          },
        ),
      ),
    );
  }

  void showDeleteDialog(BuildContext context, MemoService memoService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("정말로 삭제하시겠습니까?",
              style: TextStyle(
                fontSize: 14,
              )),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소"),
            ),
            // 확인 버튼
            TextButton(
              onPressed: () {
                memoService.deleteMemo(index: index);
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // HomePage 로 가기
              },
              child: Text(
                "확인",
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }
}
