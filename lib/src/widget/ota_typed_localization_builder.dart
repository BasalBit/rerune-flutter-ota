import 'package:flutter/widgets.dart';

import '../controller/ota_localization_controller.dart';

typedef ReRuneDelegateFactory<T> =
    LocalizationsDelegate<T> Function(
      BuildContext context,
      ReRuneLocalizationController controller,
      int revision,
    );

typedef ReRuneLocalizationWidgetBuilder<T> =
    Widget Function(BuildContext context, LocalizationsDelegate<T> delegate);

enum ReRuneLocalizationRefreshMode { anyControllerChange, fetchedUpdatesOnly }

class ReRuneBuilder<T> extends StatelessWidget {
  const ReRuneBuilder({
    super.key,
    required this.controller,
    required this.delegateFactory,
    required this.builder,
    this.refreshMode = ReRuneLocalizationRefreshMode.anyControllerChange,
  });

  final ReRuneLocalizationController controller;
  final ReRuneDelegateFactory<T> delegateFactory;
  final ReRuneLocalizationWidgetBuilder<T> builder;
  final ReRuneLocalizationRefreshMode refreshMode;

  @override
  Widget build(BuildContext context) {
    if (refreshMode == ReRuneLocalizationRefreshMode.fetchedUpdatesOnly) {
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
