import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 225, 80, 1),
          secondary: Color(0xFF3A3A3A),
          tertiary: Color(0xFFD0D0D0),
          background: Color(0xFFFFFFFF),
        ),
        textTheme: const TextTheme(
          titleSmall: TextStyle(
            color: Color.fromARGB(255, 225, 80, 1),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF3A3A3A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          displayMedium: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        )
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devicesList = [];
  BluetoothConnection? connection;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;
  int _deviceState = 0;
  bool _connected = false;
  BluetoothDevice? _device;
  bool _isButtonUnavailable = false;
  String? serialText;

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    _deviceState = 0;
    enableBluetooth();
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: const Text('Elevador Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ativar bluetooth do smartphone',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        activeColor: Theme.of(context).colorScheme.primary,
                        value: _bluetoothState.isEnabled,
                        onChanged: (bool value) {
                          future() async {
                            if (value) {
                              await FlutterBluetoothSerial.instance.requestEnable();
                            } else {
                              await FlutterBluetoothSerial.instance.requestDisable();
                            }
                            _isButtonUnavailable = true;
                            await getPairedDevices();
                            _isButtonUnavailable = false;
                            if (_connected) {
                              _disconnect();
                            }
                          }
                          future().then((_) {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                    'Selecione o dispositivo emparelhado para conectar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButton(
                    items: _getDeviceItems(),
                    onChanged: (value) => setState(() => _device = value!),
                    value: _devicesList.isNotEmpty ? _device : null,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: _isButtonUnavailable ? null : _connected ? _disconnect : _connect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _isButtonUnavailable ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isButtonUnavailable ? 'Conectando...' : _connected ? 'Desconectar' : 'Conectar',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                          Icon(
                            _isButtonUnavailable ? Icons.history_outlined : _connected ? Icons.bluetooth_disabled_rounded : Icons.bluetooth_rounded,
                            color: Theme.of(context).colorScheme.background,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                    'Selecione o andar do elevador',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: _connected ? _sendTwoMessageToBluetooth : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '2 Andar',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                          Icon(
                            Icons.arrow_upward_rounded,
                            color: Theme.of(context).colorScheme.background,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: _connected ? _sendOneMessageToBluetooth : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '1 Andar',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                          Icon(
                            Icons.arrow_downward_rounded,
                            color: Theme.of(context).colorScheme.background,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                    'Último retorno do serial',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          serialText ?? 'Nenhum',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Column(
              children: [
                Text(
                  'UFPR - TADS',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Embarcados & IoT',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'David - Eduardo - Laerte',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
    } else {
      await getPairedDevices();
    }
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _devicesList = devices;
    });
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('Nenhum dispositivo encontrado'),
      ));
    } else {
      for (var device in _devicesList) {
        items.add(DropdownMenuItem(
          value: device,
          child: Text(device.name ?? ''),
        ));
      }
    }
    return items;
  }

  void _connect() async {
    if (_device == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Center(child: Text('Nenhum dispositivo selecionado')),
      ));
    } else {
      if (!isConnected) {
        setState(() {
          _isButtonUnavailable = true;
        });
        await BluetoothConnection.toAddress(_device!.address).then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });
          connection!.input!.listen((Uint8List data) {
            setState(() {
              serialText = data.toString();
            });
          }).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (mounted) {
              setState(() {});
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Center(child: Text('Dispositivo conectado')),
          ));
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        setState(() {
          _isButtonUnavailable = false;
        });
      }
    }
  }

  void _disconnect() async {
    await connection!.close();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Center(child: Text('Dispositivo desconectado')),
    ));
    if (!connection!.isConnected) {
      setState(() {
        _connected = false;
        serialText = 'Nenhum';
      });
    }
  }

  void _sendOneMessageToBluetooth() async {
    connection!.output.add(Uint8List.fromList('1'.codeUnits));
    await connection!.output.allSent;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Center(child: Text('1 Andar')),
    ));
    setState(() {
      _deviceState = 1;
    });
  }

  void _sendTwoMessageToBluetooth() async {
    connection!.output.add(Uint8List.fromList('2'.codeUnits));
    await connection!.output.allSent;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Center(child: Text('2 Andar')),
    ));
    setState(() {
      _deviceState = -1;
    });
  }
}
