import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/account_model.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  bool _showScanner = false;

  @override
  void dispose() {
    _labelController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _showScannerPage() {
    setState(() => _showScanner = true);
  }

  void _closeScannerPage() {
    setState(() => _showScanner = false);
  }

  void _handleQrCode(String code) {
    try {
      final uri = Uri.parse(code);
      if (uri.scheme == 'otpauth' && uri.host == 'totp') {
        final pathSegments = uri.path.split('/');
        String label = pathSegments.isNotEmpty ? pathSegments.last : '';

        final secret = uri.queryParameters['secret'] ?? '';
        final issuer = uri.queryParameters['issuer'] ?? '';

        if (secret.isNotEmpty) {
          setState(() {
            _secretController.text = secret;
            _labelController.text = label;
            _issuerController.text = issuer;
            _showScanner = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无效的二维码：$e')));
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final account = TotpAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text.trim(),
        issuer: _issuerController.text.trim(),
        secret: _secretController.text.trim(),
      );
      Navigator.pop(context, account);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return _buildScannerPage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('添加账户')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ElevatedButton.icon(
                onPressed: _showScannerPage,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('扫描二维码'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '或手动输入',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: '标签',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.0,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => v?.trim().isEmpty == true ? '请输入标签' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuerController,
                decoration: InputDecoration(
                  labelText: '发行者（非必填）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.0,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secretController,
                decoration: InputDecoration(
                  labelText: '密钥',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.0,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),

                validator: (v) {
                  if (v?.trim().isEmpty == true) return '请输入密钥';
                  if (!RegExp(
                    r'^[A-Z2-7]+=*$',
                    multiLine: true,
                  ).hasMatch(v?.trim() ?? '')) {
                    return '目前仅支持base32密钥';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeScannerPage,
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _handleQrCode(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '将二维码放在框内',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
