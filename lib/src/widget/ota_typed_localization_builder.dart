import 'package:flutter/widgets.dart';

import '../controller/ota_localization_controller.dart';

typedef OtaTypedDelegateFactory<T> =
    LocalizationsDelegate<T> Function(
      BuildContext context,
      OtaLocalizationController controller,
      int revision,
    );

typedef OtaTypedLocalizationWidgetBuilder<T> =
    Widget Function(BuildContext context, LocalizationsDelegate<T> delegate);

class OtaTypedLocalizationBuilder<T> extends StatelessWidget {
  const OtaTypedLocalizationBuilder({
    super.key,
    required this.controller,
    required this.delegateFactory,
    required this.builder,
  });

  final OtaLocalizationController controller;
  final OtaTypedDelegateFactory<T> delegateFactory;
  final OtaTypedLocalizationWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final delegate = delegateFactory(
          context,
          controller,
          controller.revision,
        );
        return builder(context, delegate);
      },
    );
  }
}
