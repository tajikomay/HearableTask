import 'package:flutter/foundation.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

class NineAxisSensor extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  bool isEnabled = false;

  int? _resultCode;
  Uint8List? _data;

  static final NineAxisSensor _instance = NineAxisSensor._internal();

  factory NineAxisSensor() {
    return _instance;
  }

  NineAxisSensor._internal();

  int? get resultCode => _resultCode;
  Uint8List? get data => _data;

  double getX() {
    double accX = 0.0;
    int accXoffset = 5;

    // 9軸センサの加速度情報をX軸に取得
    if (_data != null) {
      Uint8List data = _data!;
      for (int i = 0; i < 5; i++) {
        accX += data[accXoffset + (i * 22)];
        accX += data[accXoffset + 1 + (i * 22)];
      }
      // 10で割った平均値を得る
      accX /= 10;
    }
    return accX;
  }

  double getZ() {
    double accZ = 0.0;
    int accZoffset = 5;

    // 9軸センサの加速度情報をX軸に取得
    if (_data != null) {
      Uint8List data = _data!;
      for (int i = 0; i < 5; i++) {
        accZ += data[accZoffset + (i * 22)];
        accZ += data[accZoffset + 1 + (i * 22)];
      }
      // 10で割った平均値を得る
      accZ /= 10;
    }
    return accZ;
  }
  

  Future<bool> addNineAxisSensorNotificationListener() async {
    final res = await _samplePlugin.addNineAxisSensorNotificationListener(
        onStartNotification: _onStartNotification,
        onStopNotification: _onStopNotification,
        onReceiveNotification: _onReceiveNotification);
    return res;
  }

  void _removeNineAxisSensorNotificationListener() {
    _samplePlugin.removeNineAxisSensorNotificationListener();
  }

  void _onStartNotification(int resultCode) {
    _resultCode = resultCode;
    notifyListeners();
  }

  void _onStopNotification(int resultCode) {
    _removeNineAxisSensorNotificationListener();
    _resultCode = resultCode;
    notifyListeners();
  }

  void _onReceiveNotification(Uint8List? data, int resultCode) {
    _data = data;
    _resultCode = resultCode;
    notifyListeners();
  }
}
