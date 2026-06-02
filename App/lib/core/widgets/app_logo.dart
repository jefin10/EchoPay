import 'package:flutter/material.dart';

enum LogoType { full, textOnly, iconOnly }

/// A small helper widget that renders one of the three provided
/// logo assets. The files are expected to be declared in pubspec.yaml
/// under `assets/` as `full_logo.png`, `text_logo.png`, and
/// `icon_logo.png`.

class AppLogo extends StatelessWidget {
  final LogoType type;
  final double? width;
  final double? height;

  const AppLogo({
    Key? key,
    this.type = LogoType.full,
    this.width,
    this.height,
  }) : super(key: key);

  String get _assetName {
    switch (type) {
      case LogoType.full:
        return 'assets/full-logo.png';
      case LogoType.textOnly:
        return 'assets/text-logo.png';
      case LogoType.iconOnly:
        return 'assets/symbol-logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetName,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
