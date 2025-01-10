import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:timezone_to_country/timezone_to_country.dart';

class IntroPage extends HookConsumerWidget with PresLogger {
  IntroPage({super.key});

  bool locationInfoLoaded = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final isStarting = useState(false);

    if (!locationInfoLoaded) {
      autoSelectRegion(ref).then((value) => loggy.debug("Auto Region selection finished!"));
      locationInfoLoaded = true;
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                width: 224,
                height: 224,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Assets.images.logo.svg(),
                ),
              ),
            ),
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 368,
              child: MultiSliver(
                children: [
                  //const LocalePrefTile(),
                  //const SliverGap(4),
                  //const RegionPrefTile(),
                  //const SliverGap(4),
                  //const EnableAnalyticsPrefTile(),
                  const SliverGap(4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text.rich(
                      t.intro.termsAndPolicyCaution(
                        tap: (text) => TextSpan(
                          text: text,
                          style: const TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await UriUtils.tryLaunch(
                                Uri.parse(Constants.termsAndConditionsUrl),
                              );
                            },
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: FilledButton(
                      onPressed: () async {
                        if (isStarting.value) return;
                        isStarting.value = true;
                        if (!ref.read(analyticsControllerProvider).requireValue) {
                          loggy.info("disabling analytics per user request");
                          try {
                            await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
                          } catch (error, stackTrace) {
                            loggy.error(
                              "could not disable analytics",
                              error,
                              stackTrace,
                            );
                          }
                        }
                        await ref.read(Preferences.introCompleted.notifier).update(true);
                      },
                      child: isStarting.value
                          ? LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : Text(t.intro.start),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> autoSelectRegion(WidgetRef ref) async {
    try {
      //final countryCode = await TimeZoneToCountry.getLocalCountryCode();
      final regionLocale = RegionLocale(Region.cn, AppLocale.zhCn);
      // loggy.debug(
      //   'Timezone Region: ${regionLocale.region} Locale: ${regionLocale.locale}',
      // );
      await ref.read(ConfigOptions.region.notifier).update(regionLocale.region);
      await ref.watch(ConfigOptions.directDnsAddress.notifier).reset();
      await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
      return;
    } catch (e) {
      loggy.warning(
        'Could not get the local country code based on timezone',
        e,
      );
    }
  }
}

class RegionLocale {
  final Region region;
  final AppLocale locale;

  RegionLocale(this.region, this.locale);
}
