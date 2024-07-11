import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothScanPage(),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothDiscoveryResult>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  void _getBondedDevices() async {
    List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
    setState(() {
      _devicesList = bondedDevices;
    });
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _devicesList.clear();
    });

    try {
      _scanSubscription = _bluetooth.startDiscovery().listen((r) {
        setState(() {
          final existingIndex = _devicesList
              .indexWhere((element) => element.address == r.device.address);
          if (existingIndex >= 0) {
            _devicesList[existingIndex] = r.device;
          } else {
            _devicesList.add(r.device);
          }
        });
      });

      await Future.delayed(const Duration(seconds: 10));
      _stopScan();
    } catch (ex) {
      print('Error starting scan: $ex');
      _stopScan();
    }
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
    _scanSubscription?.cancel();
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      // 페어링 상태 확인
      bool isPaired = await FlutterBluetoothSerial.instance
              .getBondStateForAddress(device.address) ==
          BluetoothBondState.bonded;
      if (!isPaired) {
        print('Device is not paired. Attempting to pair...');
        bool? bondResult = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(device.address);
        if (bondResult != true) {
          print('Pairing failed or was cancelled');
          return;
        }
        print('Pairing successful');
      } else {
        print('Device is already paired');
      }

      // 연결시도
      await connectWithTimeout(device);
      // await BluetoothConnection.toAddress(device.address);
    } catch (e) {
      print('Error connecting to device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
    }
  }

  Future<void> connectWithTimeout(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      await Future.any([
        BluetoothConnection.toAddress(device.address),
        Future.delayed(timeout)
            .then((_) => throw TimeoutException('Connection timed out')),
      ]);

      setState(() {
        _connectedDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );

      print('Connected successfully');
      // 여기에 연결 성공 후의 로직을 추가하세요
    } on TimeoutException {
      print('Connection timed out');
      // 타임아웃 처리 로직
    } catch (e) {
      print('Connection error: $e');
      // 기타 오류 처리 로직
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown device"),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    child: const Text('Connect'),
                    onPressed: () => _connectToDevice(device),
                  ),
                );
              },
            ),
          ),
          if (_connectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Connected to: ${_connectedDevice!.name}'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
