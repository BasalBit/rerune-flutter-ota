import 'package:flutter/widgets.dart';

import '../controller/ota_localization_controller.dart';
import '../delegate/ota_localizations_delegate.dart';

typedef OtaLocalizationWidgetBuilder =
    Widget Function(BuildContext context, OtaLocalizationsDelegate delegate);

class OtaLocalizationBuilder extends StatelessWidget {
  const OtaLocalizationBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  final OtaLocalizationController controller;
  final OtaLocalizationWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return builder(context, controller.buildDelegate());
      },
    );
  }
}
