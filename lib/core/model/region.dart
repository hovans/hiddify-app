import 'package:hiddify/core/localization/translations.dart';

enum Region {
  cn,
  other;

  String present(TranslationsEn t) => switch (this) {
        cn => t.settings.general.regions.cn,
        other => t.settings.general.regions.other,
      };
}
