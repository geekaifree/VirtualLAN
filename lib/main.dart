import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const VirtualLANApp());
class VirtualLANApp extends StatelessWidget {
  const VirtualLANApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '虚拟局域网', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true, brightness: Brightness.dark),
    home: const VLANHomePage());
}

class VLANDevice {
  String id, name, ip, mac, os, status;
  VLANDevice({required this.id, required this.name, required this.ip, required this.mac, this.os = 'Unknown', this.status = 'online'});
}

class VLANNetwork {
  String id, name, networkId;
  List<VLANDevice> devices;
  VLANNetwork({required this.id, required this.name, required this.networkId, this.devices = const []});
}

class VLANHomePage extends StatefulWidget {
  const VLANHomePage({super.key});
  @override
  State<VLANHomePage> createState() => _VLANHomePageState();
}

class _VLANHomePageState extends State<VLANHomePage> {
  List<VLANNetwork> _networks = [];
  VLANNetwork? _active;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() {
      _networks = [
        VLANNetwork(id: '1', name: '家庭网络', networkId: 'a1b2c3d4e5', devices: [
          VLANDevice(id: '1', name: 'MacBook', ip: '10.0.0.1', mac: 'AA:BB:CC:DD:EE:01', os: 'macOS'),
          VLANDevice(id: '2', name: 'iPhone', ip: '10.0.0.2', mac: 'AA:BB:CC:DD:EE:02', os: 'iOS'),
          VLANDevice(id: '3', name: 'Windows PC', ip: '10.0.0.3', mac: 'AA:BB:CC:DD:EE:03', os: 'Windows', status: 'offline'),
        ]),
        VLANNetwork(id: '2', name: '办公网络', networkId: 'f6g7h8i9j0', devices: [
          VLANDevice(id: '4', name: '办公电脑', ip: '10.0.1.1', mac: 'AA:BB:CC:DD:EE:04', os: 'Windows'),
        ]),
      ];
      _active = _networks.first;
    });
  }

  void _createNetwork() {
    final nameC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('创建虚拟网络'),
      content: TextField(controller: nameC, decoration: const InputDecoration(labelText: '网络名称', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () {
        if (nameC.text.isNotEmpty) {
          final net = VLANNetwork(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, networkId: DateTime.now().toIso8601String().hashCode.toRadixString(16).substring(0, 10));
          setState(() { _networks.add(net); _active = net; });
        }
        Navigator.pop(ctx);
      }, child: const Text('创建'))],
    ));
  }

  void _joinNetwork() {
    final idC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('加入网络'),
      content: TextField(controller: idC, decoration: const InputDecoration(labelText: '网络ID', border: OutlineInputBorder(), hintText: '输入网络ID')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发送加入请求'), behavior: SnackBarBehavior.floating)); }, child: const Text('加入'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌐 虚拟局域网'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _createNetwork, tooltip: '创建网络'),
        IconButton(icon: const Icon(Icons.login), onPressed: _joinNetwork, tooltip: '加入网络'),
      ]),
      body: Column(children: [
        // 网络选择
        SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _networks.length, itemBuilder: (ctx, i) {
          final net = _networks[i];
          final isActive = _active?.id == net.id;
          return GestureDetector(onTap: () => setState(() => _active = net), child: Container(margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isActive ? Colors.purple : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: Center(child: Text(net.name, style: TextStyle(color: isActive ? Colors.white : null, fontWeight: FontWeight.bold)))));
        })),
        if (_active != null) ...[
          // 网络信息
          Card(margin: const EdgeInsets.symmetric(horizontal: 12), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            const Icon(Icons.wifi, color: Colors.purple), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_active!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('ID: ${_active!.networkId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_active!.devices.where((d) => d.status == 'online').length} 在线', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('${_active!.devices.length} 设备', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ]))),
          const SizedBox(height: 8),
          // 设备列表
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _active!.devices.length, itemBuilder: (ctx, i) {
            final d = _active!.devices[i];
            final online = d.status == 'online';
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: online ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(d.os == 'macOS' ? '💻' : d.os == 'iOS' ? '📱' : '🖥️', style: const TextStyle(fontSize: 20)))),
              title: Text(d.name, style: TextStyle(fontWeight: FontWeight.bold, color: online ? null : Colors.grey)),
              subtitle: Text('${d.ip} • ${d.mac}', style: const TextStyle(fontSize: 12)),
              trailing: Container(width: 8, height: 8, decoration: BoxDecoration(color: online ? Colors.green : Colors.grey, shape: BoxShape.circle)),
            ));
          })),
        ],
      ]),
    );
  }
}
