import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

//import 'package:hearable_device_sdk_sample/size_config.dart';
//import 'package:hearable_device_sdk_sample/widget_config.dart';
import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/nine_axis_sensor.dart';
import 'package:hearable_device_sdk_sample/eaa.dart';
import 'package:hearable_device_sdk_sample/config.dart';

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';
import 'dart:math' as math;
import 'dart:async';

class slalom extends StatelessWidget {
  const slalom({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: NineAxisSensor()),
      ],
      child: _slalom(),
    );
  }
}

class _slalom extends StatefulWidget {
  @override
  State<_slalom> createState() => _slalomState();
}

class _slalomState extends State<_slalom> {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  String userUuid = (Eaa().featureGetCount == 0)
      ? const Uuid().v4()
      : Eaa().registeringUserUuid;
  var selectedIndex = -1;
  var selectedUser = '';
  bool isSetEaaCallback = false;

  var config = Config();
  Eaa eaa = Eaa();

  TextEditingController featureRequiredNumController = TextEditingController();
  TextEditingController featureCountController = TextEditingController();
  TextEditingController eaaResultController = TextEditingController();
  TextEditingController nineAxisSensorResultController =TextEditingController();

  void _switch9AxisSensor(bool enabled) async {
    NineAxisSensor().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await NineAxisSensor().addNineAxisSensorNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        NineAxisSensor().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    _switch9AxisSensor(true);
    super.initState();
    startFalling();
    player_x();
  }

  @override
  void dispose() {
    fallingTimer?.cancel(); // ウィジェットが破棄される際にTimerをキャンセル
    playerXTimer?.cancel();
    super.dispose();
  }

  List<String> imagePaths = ['assets/SLRed.png', 'assets/SLBlue.png'];  //ポール画像の配列
  List<String> imagePlayer = ['assets/leftturn.png', 'assets/rightturn.png'];  //プレイヤー画像の配列
  double positionY = 0.0;  //ポール画像のY座標
  double initialX = 150.0;  //ポール画像のX座標
  double screenWidth = 0.0;  //画面の横幅
  int currentIndex = 0;  //ポール画像配列のインデックス
  int playerIndex = 0;  //プレイヤー画像配列のインデックス
  bool isImageVisible = true;
  double playx = 100.0;
  var random = math.Random();
  bool isGameOver = false;
  Timer? fallingTimer;
  Timer? playerXTimer;
  int score = 0;

  int randomintrange(int max, int min){
    int value = math.Random().nextInt(max - min);
    return value + min;
  }

  void startFalling() {
    fallingTimer?.cancel(); // 新しいゲームが始まる前に既存のタイマーをキャンセル
    playerXTimer?.cancel();

    fallingTimer = Timer.periodic(Duration(milliseconds: 2), (timer) {
      setState(() {
        isImageVisible = true;
        positionY += 1.0;
        if (positionY >= MediaQuery.of(context).size.height - 100.0) {
          positionY = 0.0;
          score ++;
          currentIndex = (currentIndex + 1) % 2;
          if (currentIndex == 0) {
            initialX = randomintrange(4, 1).toDouble() * 40;
          } else {
            initialX = randomintrange(8, 4).toDouble() * 40;
          }
        }
        checkCollision(context);
        if (isGameOver) {
          fallingTimer?.cancel();
          playerXTimer?.cancel();
        }
      });
    });
  }

  List<double> pzlist = [0.0, 0.0, 0.0, 0.0];
  List<double> sublist = [0.0, 0.0, 0.0];
  double velocity = 0.0;  // プレイヤーの速度
  double damping = 0.98;  // 減衰係数
  double accelerationScale = 0.1;  // 加速度のスケール

  void player_x() {
    playerXTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isGameOver) {
        double xNum = Provider.of<NineAxisSensor>(context, listen: false).getZ();
        pzlist[3] = xNum;

        for (int i = 0; i < 3; i++) {
          sublist[i] = pzlist[i + 1] - pzlist[i];
          if (sublist[i].abs() < 40){
            sublist[i] = 0;
          }
        }
        double acc = sublist[0];
        for (int i = 1; i < 2; i++) {
          if (sublist[i].abs() > sublist[i - 1].abs()) {
            acc = sublist[i];
          }
        }
        if (acc > 100){
          acc = 100;
        }
        if (acc < -100){
          acc = -100;
        }
        // 速度と位置の更新
        velocity += acc * accelerationScale;
        velocity *= damping;  // 減衰
        playx += velocity;

        // 画面外に出ないように調整
        if (playx > 300) {
          playx = 300;
          velocity = 0.0;  // 画面右端で速度をリセット
        }
        if (playx < 0) {
          playx = 0;
          velocity = 0.0;  // 画面左端で速度をリセット
        }

        setState(() {
          playerIndex = (velocity >= 0) ? 0 : 1;
        });

        // リストの更新
        pzlist[0] = pzlist[1];
        pzlist[1] = pzlist[2];
        pzlist[2] = pzlist[3];
      } else {
        playerXTimer?.cancel();
      }
    });
  }

  void checkCollision(BuildContext context) {
    if (positionY == 700.0) {
      double playerCenterX = playx;
      double poleCenterX = initialX;

      if (currentIndex==0 && playerCenterX>poleCenterX || currentIndex==1 && playerCenterX<poleCenterX ) {
        endGame(context);
      }
    }
  }

  void endGame(BuildContext context) {
    _switch9AxisSensor(false);
    score--;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('DQ', textAlign: TextAlign.center),
                Text('Score: $score', textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                isGameOver = false;
                restartGame(); // 新しいメソッドを呼び出す
              },
              child: Text('OK'),
            ),
          ],
        );
      });

    fallingTimer?.cancel();
    playerXTimer?.cancel();
    isGameOver = true;
    playx = 100.0;
  }

  void restartGame() {
    startFalling();
    player_x();
    _switch9AxisSensor(true);
    score = 0;
    pzlist = [0.0, 0.0, 0.0, 0.0, 0.0];
    sublist = [0.0, 0.0, 0.0, 0.0];
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('スラローム'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 148, 237, 239),
      ),
      body: Stack(
        children: [
          // Image Widget (Falling Image)
          Positioned(
            top: positionY,
            left: initialX,
            child: isImageVisible
                ? Image.asset(
                    imagePaths[currentIndex],
                    height: 100.0,
                    width: 100.0,
                  )
                : Container(),
          ),
          Positioned(
            bottom: 0.0,
            left: playx,
            child: Image.asset(
              imagePlayer[playerIndex],
              height: 100.0,
              width: 100.0,
            ),
          ),
        ],
      ),
    );
  }
}
