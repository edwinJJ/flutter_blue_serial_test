import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  final List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      _bluetooth.startDiscovery().listen((r) {
        setState(() {
          final existingIndex = _devices
              .indexWhere((element) => element.address == r.device.address);
          if (existingIndex >= 0) {
            _devices[existingIndex] = r.device;
          } else {
            _devices.add(r.device);
          }
        });
      }).onDone(() {
        setState(() {
          _isScanning = false;
        });
      });
    } catch (ex) {
      print('Error starting discovery: $ex');
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');
      setState(() {
        _connectedDevice = device;
      });
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
      ),
      body: Column(
        children: [
          if (_connectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: ListTile(
                  title: const Text('Connected Device'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_connectedDevice!.name ?? "Unknown"}'),
                      Text('MAC Address: ${_connectedDevice!.address}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _disconnectFromDevice,
                  ),
                ),
              ),
            ),
          ElevatedButton(
            onPressed: _isScanning ? null : _startDiscovery,
            child: Text(_isScanning ? 'Scanning...' : 'Scan for devices'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown device"),
                  subtitle: Text(device.address),
                  onTap: () => _connectToDevice(device),
                  trailing: _connectedDevice?.address == device.address
                      ? const Icon(Icons.bluetooth_connected)
                      : const Icon(Icons.bluetooth),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _disconnectFromDevice() {
    _connection?.dispose();
    setState(() {
      _connection = null;
      _connectedDevice = null;
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
