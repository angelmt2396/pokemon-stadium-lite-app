import 'package:flutter/material.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
