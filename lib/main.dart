import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🔥 Đốt Nỗi Buồn 🔥',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(backgroundColor: Colors.deepOrange),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(backgroundColor: Colors.deepOrange),
      ),
      home: DotNoiBuonApp(),
    );
  }
}

class DotNoiBuonApp extends StatefulWidget {
  @override
  State<DotNoiBuonApp> createState() => _DotNoiBuonAppState();
}

class _DotNoiBuonAppState extends State<DotNoiBuonApp> {
  final _controller = TextEditingController();
  final _audioPlayer = AudioPlayer();
  List<String> _noiBuonDaDot = [];
  bool _hienLua = false;
  bool _hienKetQua = false;
  String _ketQua = '';

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _taiNoiBuon() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _noiBuonDaDot = prefs.getStringList('noi_buon') ?? [];
    });
  }

  Future<void> _luuNoiBuon(String noiBuon) async {
    final prefs = await SharedPreferences.getInstance();
    final danhSach = prefs.getStringList('noi_buon') ?? [];
    danhSach.add(noiBuon);
    await prefs.setStringList('noi_buon', danhSach);
  }

  Future<void> _xoaTatCa() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('noi_buon');
    setState(() => _noiBuonDaDot = []);
  }

  Future<void> _xoaMot(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final danhSach = prefs.getStringList('noi_buon') ?? [];
    danhSach.removeAt(index);
    await prefs.setStringList('noi_buon', danhSach);
    setState(() => _noiBuonDaDot = danhSach);
  }

  Future<void> _xuatNoiBuonRaFile() async {
    final prefs = await SharedPreferences.getInstance();
    final danhSach = prefs.getStringList('noi_buon') ?? [];
    if (danhSach.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chưa có nỗi buồn nào để xuất')));
      return;
    }
    final noiDung = danhSach.reversed.map((e) => '• $e').join('\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/noi_buon_da_dot.html');
    await file.writeAsString(noiDung, encoding: utf8);
    Share.shareXFiles([
      XFile(file.path),
    ], text: '📝 Danh sách nỗi buồn của tôi');
  }

  void _dotNoiBuon() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _ketQua = '🔥 Đang đốt: "$text" 🔥';
      _hienLua = true;
      _hienKetQua = true;
      _controller.clear();
    });
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource('sounds/fire.mp3'));
    await _luuNoiBuon(text);
    await _taiNoiBuon();
    Future.delayed(Duration(seconds: 8), () {
      setState(() {
        _hienLua = false;
        _hienKetQua = false;
      });
    });
  }

  String _chuyenThanhIcon(String noiBuon) {
    noiBuon = noiBuon.toLowerCase();
    if (noiBuon.contains('tiền') || noiBuon.contains('mất')) return '💸';
    if (noiBuon.contains('tình') || noiBuon.contains('chia tay')) return '💔';
    if (noiBuon.contains('giận') || noiBuon.contains('bực')) return '😡';
    if (noiBuon.contains('buồn') || noiBuon.contains('chán')) return '😢';
    return '📝';
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('🎤 [STATUS]: $status'),
      onError: (error) => print('❌ [ERROR]: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      // Nếu không khởi tạo được, hiển thị báo lỗi cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể sử dụng tính năng giọng nói. Kiểm tra quyền microphone hoặc thử lại sau.',
          ),
        ),
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🔥 Đốt Nỗi Buồn 🔥"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập nỗi buồn của bạn...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepOrange),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: Colors.deepOrange,
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _dotNoiBuon,
              child: Text('🔥 Đốt!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _hienKetQua ? 1.0 : 0.0,
              duration: Duration(seconds: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _ketQua,
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            AnimatedOpacity(
              opacity: _hienLua ? 1.0 : 0.0,
              duration: Duration(seconds: 6),
              child: Lottie.asset(
                'assets/animations/fire.json',
                width: 200,
                height: 200,
                repeat: true,
                animate: true,
              ),
            ),

            if (_noiBuonDaDot.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Những nỗi buồn đã đốt:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _noiBuonDaDot.length,
                    itemBuilder: (context, i) {
                      final reversed = _noiBuonDaDot.length - 1 - i;
                      final noiBuon = _noiBuonDaDot[reversed];
                      return ListTile(
                        title: Text(
                          '${_chuyenThanhIcon(noiBuon)} $noiBuon',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _xoaMot(reversed),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _xoaTatCa,
                    icon: Icon(Icons.delete_forever),
                    label: Text('Xoá tất cả'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _xuatNoiBuonRaFile,
                    icon: Icon(Icons.share),
                    label: Text('Xuất & chia sẻ nỗi buồn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
