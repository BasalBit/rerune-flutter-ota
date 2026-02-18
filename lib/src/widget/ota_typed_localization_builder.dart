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

enum OtaLocalizationRefreshMode { anyControllerChange, fetchedUpdatesOnly }

class OtaTypedLocalizationBuilder<T> extends StatelessWidget {
  const OtaTypedLocalizationBuilder({
    super.key,
    required this.controller,
    required this.delegateFactory,
    required this.builder,
    this.refreshMode = OtaLocalizationRefreshMode.anyControllerChange,
  });

  final OtaLocalizationController controller;
  final OtaTypedDelegateFactory<T> delegateFactory;
  final OtaTypedLocalizationWidgetBuilder<T> builder;
  final OtaLocalizationRefreshMode refreshMode;

  @override
  Widget build(BuildContext context) {
    if (refreshMode == OtaLocalizationRefreshMode.fetchedUpdatesOnly) {
      return ValueListenableBuilder<int>(
        valueListenable: controller.reRuneFetchedRevisionListenable,
        builder: (context, fetchedRevision, _) {
          final delegate = delegateFactory(
            context,
            controller,
            fetchedRevision,
          );
          return builder(context, delegate);
        },
      );
    }

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
