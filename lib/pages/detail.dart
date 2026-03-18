import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/account_model.dart';

class AccountDetailPage extends StatefulWidget {
  final TotpAccount account;
  final VoidCallback onDelete;
  final Function(
    String newLabel,
    String newIssuer,
    String newAvatarType, [
    String? avatarImagePath,
  ])?
  onUpdate;

  const AccountDetailPage({
    super.key,
    required this.account,
    required this.onDelete,
    this.onUpdate,
  });

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage>
    with TickerProviderStateMixin {
  late TotpAccount _account;
  Timer? _timer;
  String _currentCode = '';
  int _remainingSeconds = 0;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _account = widget.account;

    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _updateCode();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCode();
      }
    });
  }

  void _updateCode() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = _account.interval - (now % _account.interval);
    final code = _account.generateCode();

    setState(() {
      _currentCode = code;
      _remainingSeconds = remaining;
    });

    final progress = remaining / _account.interval;
    _progressController.animateTo(
      progress,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _currentCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('验证码已复制到剪贴板')));
  }

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final labelController = TextEditingController(text: _account.label);
    final issuerController = TextEditingController(text: _account.issuer);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改账户信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: '标签',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: issuerController,
              decoration: InputDecoration(
                labelText: '发行者（非必填）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newLabel = labelController.text.trim();
              final newIssuer = issuerController.text.trim();
              if (newLabel.isNotEmpty && widget.onUpdate != null) {
                setState(() {
                  _account = TotpAccount(
                    id: _account.id,
                    label: newLabel,
                    issuer: newIssuer,
                    secret: _account.secret,
                    interval: _account.interval,
                    digits: _account.digits,
                    avatarType: _account.avatarType,
                  );
                });
                widget.onUpdate!(
                  _account.label,
                  _account.issuer,
                  _account.avatarType,
                  _account.avatarImagePath,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择头像',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildAvatarOption('default', Icons.account_circle, '默认'),
                    _buildAvatarOption('code', Icons.code, 'Code'),
                    _buildAvatarOption('shop', Icons.shopping_cart, 'Shop'),
                    _buildAvatarOption('google', Icons.g_mobiledata, 'Google'),
                    _buildAvatarOption('microsoft', Icons.window, 'Microsoft'),
                    _buildAvatarOption('apple', Icons.apple, 'Apple'),
                    _buildGalleryOption(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption(String type, IconData icon, String label) {
    final isSelected = _account.avatarType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _account = TotpAccount(
            id: _account.id,
            label: _account.label,
            issuer: _account.issuer,
            secret: _account.secret,
            interval: _account.interval,
            digits: _account.digits,
            avatarType: type,
          );
        });

        if (widget.onUpdate != null) {
          widget.onUpdate!(_account.label, _account.issuer, type, null);
        }
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.grey.shade200,
            child: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryOption() {
    return GestureDetector(
      onTap: _pickImageFromGallery,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.photo_library, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text('从相册', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // 根据平台和Android版本选择合适的权限
      Permission permissionToRequest;

      if (Theme.of(context).platform == TargetPlatform.android) {
        // 获取Android设备信息
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Android 13+ (API 33+) 使用 Permission.photos
        // Android 12及以下使用 Permission.storage
        if (androidInfo.version.sdkInt >= 33) {
          permissionToRequest = Permission.photos;
        } else {
          permissionToRequest = Permission.storage;
        }
      } else {
        // iOS使用photos权限
        permissionToRequest = Permission.photos;
      }

      // 检查当前权限状态
      var status = await permissionToRequest.status;

      if (status.isDenied || status.isLimited) {
        // 显示权限请求对话框
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要权限'),
            content: const Text('应用需要访问您的相册才能选择头像'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('允许'),
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          if (mounted) Navigator.pop(context);
          return;
        }

        status = await permissionToRequest.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (status.isPermanentlyDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('需要相册权限才能选择图片。请在设置中启用权限。'),
                  action: SnackBarAction(
                    label: '设置',
                    onPressed: () => openAppSettings(),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('需要相册权限才能选择图片')));
            }
          }
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      if (status.isGranted || status.isLimited) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );

        if (image != null) {
          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: '裁剪图片',
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: '裁剪',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
              ),
            ],
          );

          if (croppedFile != null) {
            setState(() {
              _account = TotpAccount(
                id: _account.id,
                label: _account.label,
                issuer: _account.issuer,
                secret: _account.secret,
                interval: _account.interval,
                digits: _account.digits,
                avatarType: 'custom_image',
                avatarImagePath: croppedFile.path,
              );
            });

            if (widget.onUpdate != null) {
              widget.onUpdate!(
                _account.label,
                _account.issuer,
                'custom_image',
                croppedFile.path,
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('需要相册权限才能选择图片')));
        }
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败：$e')));
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _showDeleteDialog() {
    bool confirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('确认删除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('确定要删除 "${_account.label}" 吗？'),
              const SizedBox(height: 16),
              Text(
                confirmed
                    ? '确认要删除${_account.label}吗？此操作不可撤销。'
                    : '这是最后一次确认，您是否要删除${_account.label}？',
                style: TextStyle(color: Colors.red[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (!confirmed) {
                  dialogSetState(() {
                    confirmed = true;
                  });
                } else {
                  Navigator.pop(context);
                  widget.onDelete();
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(confirmed ? '确认删除' : '删除'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户详情')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: _account.getAvatarWidget(
                      size: 128,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      iconColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _account.label,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_account.issuer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _account.issuer,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentCode,
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyCode,
                        tooltip: '复制验证码',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                '$_remainingSeconds',
                                key: ValueKey<int>(_remainingSeconds),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '秒后更新',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditMenu,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
