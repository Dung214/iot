import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String rfidUid = '';
  String status = '';
  FlutterLocalNotificationsPlugin _notificationPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // Đăng ký lắng nghe sự kiện NFC
    NfcManager.instance.startSession(
      onSessionStarted: () {
        print('NFC Session started');
      },
      onDiscovered: (NfcTag tag) async {
        NfcData data = await NfcManager.instance.read(tag);
        rfidUid = data.id;

        // Gửi dữ liệu lên cloud server
        _sendDataToCloud();
      },
    );

    // Khởi tạo plugin thông báo
    _initializeNotifications();
  }

  // Gửi dữ liệu lên cloud server
  void _sendDataToCloud() async {
    // URL của cloud server
    var uri = Uri.parse('https://example.com/api/v1/data');

    // Tạo đối tượng JSON
    Map<String, dynamic> data = {
      'rfidUid': rfidUid,
      'timeIn': DateTime.now().millisecondsSinceEpoch,
    };

    // Gửi dữ liệu lên cloud server
    await http.post(uri, body: json.encode(data)).then((response) {
      // Xử lý phản hồi từ cloud server
      if (response.statusCode == 200) {
        // Lấy dữ liệu từ cloud server
        String dataFromCloud = response.body;

        // Chuyển dữ liệu từ cloud server sang đối tượng JSON
        Map<String, dynamic> dataFromCloudJson = json.decode(dataFromCloud);

        // Cập nhật trạng thái
        setState(() {
          status = dataFromCloudJson['status'];
        });

        // Hiển thị thông báo
        _showNotification(status);
      }
    });
  }

  void _showNotification(String status) {
    // Tạo đối tượng thông báo
    var notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        //'channel_description',
        importance: Importance.high,
      ),
    );

    // Hiển thị thông báo
    _notificationPlugin.show(
      0,
      'Bãi đỗ xe thông minh',
      status == 'in' ? 'Đã vào' : 'Đã ra',
      notificationDetails,
    );
  }

  // Khởi tạo plugin thông báo
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationPlugin.initialize(
      initializationSettings,
    );
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bãi đỗ xe thông minh',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bãi đỗ xe thông minh'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Notification:',
              ),
              Text(
                status,
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
