import 'package:auth_totp/auth_totp.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class TotpAccount {
  final String id;
  final String label;
  final String issuer;
  final String secret;
  final int interval;
  final int digits;
  final String avatarType;
  final String? avatarImagePath;

  TotpAccount({
    required this.id,
    required this.label,
    required this.issuer,
    required this.secret,
    this.interval = 30,
    this.digits = 6,
    this.avatarType = 'auto',
    this.avatarImagePath,
  });

  String generateCode() {
    return AuthTOTP.generateTOTPCode(secretKey: secret, interval: interval);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'issuer': issuer,
    'secret': secret,
    'interval': interval,
    'digits': digits,
    'avatarType': avatarType,
    'avatarImagePath': avatarImagePath,
  };

  factory TotpAccount.fromJson(Map<String, dynamic> json) {
    return TotpAccount(
      id: json['id'],
      label: json['label'],
      issuer: json['issuer'],
      secret: json['secret'],
      interval: json['interval'] ?? 30,
      digits: json['digits'] ?? 6,
      avatarType: json['avatarType'] ?? 'auto',
      avatarImagePath: json['avatarImagePath'],
    );
  }

  String get resolvedAvatarType {
    if (avatarImagePath != null && avatarImagePath!.isNotEmpty) {
      return 'custom_image';
    }
    if (avatarType.isNotEmpty && avatarType != 'auto') {
      return avatarType;
    }

    final labelKey = label.toLowerCase();
    final issuerKey = issuer.toLowerCase();
    if (labelKey.contains('github') || labelKey.contains('git')) {
      return 'code';
    }
    if (labelKey.contains('google')) {
      return 'google';
    }
    if (labelKey.contains('microsoft') ||
        labelKey.contains('azure') ||
        labelKey.contains('office')) {
      return 'microsoft';
    }
    if (labelKey.contains('amazon') || labelKey.contains('aws')) {
      return 'shop';
    }
    if (labelKey.contains('apple')) {
      return 'apple';
    }

    if (issuerKey.contains('github') || issuerKey.contains('git')) {
      return 'code';
    }
    if (issuerKey.contains('google')) {
      return 'google';
    }
    if (issuerKey.contains('microsoft') ||
        issuerKey.contains('azure') ||
        issuerKey.contains('office')) {
      return 'microsoft';
    }
    if (issuerKey.contains('amazon') || issuerKey.contains('shop')) {
      return 'shop';
    }
    if (issuerKey.contains('apple')) {
      return 'apple';
    }

    return 'default';
  }

  IconData get avatarIcon {
    switch (resolvedAvatarType) {
      case 'code':
        return Icons.code;
      case 'google':
        //返回google logo，暂时用别的代替
        return Icons.logo_dev_sharp;
      case 'microsoft':
        return Icons.window;
      case 'shop':
        return Icons.shopping_cart;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.account_circle;
    }
  }

  Widget getAvatarWidget({
    required double size,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    if (resolvedAvatarType == 'custom_image' && avatarImagePath != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(avatarImagePath!)),
        backgroundColor: backgroundColor,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: Icon(avatarIcon, color: iconColor, size: size * 0.6),
    );
  }
}
