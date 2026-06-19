import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_logger/services/api_service.dart';
import 'package:wifi_logger/services/db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _networkName = 'Fetching...';
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  int _ping = 0;
  String _status = 'Not Tested';
  String _lastTest = 'Never';
  bool _isTesting = false;
  String _serverStatus = 'Server: Unknown';
  Color _serverStatusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _getNetworkName();
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _serverStatus = 'Server: Checking...';
      _serverStatusColor = Colors.orange;
    });

    final connected = await ApiService.checkConnection();

    setState(() {
      _serverStatus = connected ? 'Server: Connected ' : 'Server: Unreachable ';
      _serverStatusColor = connected ? Colors.green : Colors.red;
    });
  }

  Future<void> _startSpeedTest() async {
    if (_isTesting) return;

    final connected = await ApiService.checkConnection();
    if (!connected) {
      setState(() {
        _status = 'Error: Server unreachable';
        _serverStatus = 'Server: Unreachable';
        _serverStatusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
    });

    // Ping
    setState(() => _status = 'Testing ping...');
    final List<int> pings = [];
    for (int i = 0; i < 5; i++) {
      final p = await ApiService.measurePing();
      if (p != -1) pings.add(p);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final avgPing = pings.isEmpty
        ? 0
        : (pings.reduce((a, b) => a + b) / pings.length).round();
    setState(() => _ping = avgPing);
    // Download
    setState(() => _status = 'Testing download...');
    final download = await ApiService.measureDownloadSpeed();
    setState(() => _downloadSpeed = download == -1 ? 0 : download);

    // Upload
    setState(() => _status = 'Testing upload...');
    final upload = await ApiService.measureUploadSpeed();
    setState(() => _uploadSpeed = upload == -1 ? 0 : upload);

    // Save to SQlite
    await DbService.insertResult(
      networkName: _networkName,
      downloadSpeed: _downloadSpeed,
      uploadSpeed: _uploadSpeed,
      ping: _ping,
      testedAt: _formattedTime(),
    );

    setState(() {
      _isTesting = false;
      _status = 'Done';
      _lastTest = _formattedTime();
    });
  }

  String _formattedTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _getNetworkName() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => _networkName = 'Permission denied');
      return;
    }

    final info = NetworkInfo();
    final ssid = await info.getWifiName();

    setState(() {
      // If null then phone is on hotspot or mobile data not on wifi
      _networkName = (ssid == null || ssid.isEmpty)
          ? 'Mobile Hotspot'
          : ssid.replaceAll('"', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Logger'),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: _checkServerConnection,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  _serverStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: _serverStatusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 10),

          _infoTile('Current Network', _networkName),
          _infoTile('Download Speed', '$_downloadSpeed Mbps'),
          _infoTile('Upload Speed', '$_uploadSpeed Mbps'),
          _infoTile('Ping', '$_ping ms'),
          _infoTile('Status', _status),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: _isTesting ? null : _startSpeedTest,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isTesting ? Colors.grey : Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: _isTesting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'START SPEED TEST',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),

          _infoTile('Last Test', _lastTest),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
