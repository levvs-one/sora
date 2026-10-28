import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';

typedef AppLanguage = ({String code, String native, String english, String russian, String country, String aliases});

const appLanguages = <AppLanguage>[
  (
    code: 'en',
    native: 'English',
    english: 'English',
    russian: 'Английский',
    country: 'gb',
    aliases: 'en eng GB GBR UK US USA',
  ),
  (
    code: 'ru',
    native: 'Русский',
    english: 'Russian',
    russian: 'Русский',
    country: 'ru',
    aliases: 'ru rus RU RUS Россия',
  ),
  (
    code: 'zh_Hans',
    native: '简体中文',
    english: 'Chinese, Simplified',
    russian: 'Китайский, упрощённый',
    country: 'cn',
    aliases: 'zh zho chi CN CHN 中国 中文 简体 简体字',
  ),
  (
    code: 'zh_Hant',
    native: '繁體中文',
    english: 'Chinese, Traditional',
    russian: 'Китайский, традиционный',
    country: 'tw',
    aliases: 'zh zho chi TW TWN HK HKG 中文 繁體 繁體字',
  ),
  (
    code: 'hi',
    native: 'हिन्दी',
    english: 'Hindi',
    russian: 'Хинди',
    country: 'in',
    aliases: 'hi hin IN IND India भारत हिंदी Индия',
  ),
  (
    code: 'es',
    native: 'Español',
    english: 'Spanish',
    russian: 'Испанский',
    country: 'es',
    aliases: 'es spa ES ESP España',
  ),
  (
    code: 'fr',
    native: 'Français',
    english: 'French',
    russian: 'Французский',
    country: 'fr',
    aliases: 'fr fra fre FR FRA France',
  ),
  (
    code: 'ar',
    native: 'العربية',
    english: 'Arabic',
    russian: 'Арабский',
    country: 'sa',
    aliases: 'ar ara SA SAU Saudi Arabia',
  ),
  (
    code: 'pt',
    native: 'Português',
    english: 'Portuguese',
    russian: 'Португальский',
    country: 'pt',
    aliases: 'pt por PT PRT BR BRA Portugal Brasil',
  ),
  (
    code: 'bn',
    native: 'বাংলা',
    english: 'Bengali',
    russian: 'Бенгальский',
    country: 'bd',
    aliases: 'bn ben BD BGD Bangladesh Bangla',
  ),
  (
    code: 'id',
    native: 'Bahasa Indonesia',
    english: 'Indonesian',
    russian: 'Индонезийский',
    country: 'id',
    aliases: 'id ind ID IDN Indonesia',
  ),
  (
    code: 'ja',
    native: '日本語',
    english: 'Japanese',
    russian: 'Японский',
    country: 'jp',
    aliases: 'ja jpn JP JPN Japan 日本',
  ),
  (
    code: 'de',
    native: 'Deutsch',
    english: 'German',
    russian: 'Немецкий',
    country: 'de',
    aliases: 'de deu ger DE DEU Deutschland',
  ),
  (
    code: 'ko',
    native: '한국어',
    english: 'Korean',
    russian: 'Корейский',
    country: 'kr',
    aliases: 'ko kor KR KOR Korea 대한민국',
  ),
  (
    code: 'tr',
    native: 'Türkçe',
    english: 'Turkish',
    russian: 'Турецкий',
    country: 'tr',
    aliases: 'tr tur TR TUR Türkiye Turkey',
  ),
  (
    code: 'vi',
    native: 'Tiếng Việt',
    english: 'Vietnamese',
    russian: 'Вьетнамский',
    country: 'vn',
    aliases: 'vi vie VN VNM Vietnam Việt Nam',
  ),
  (
    code: 'it',
    native: 'Italiano',
    english: 'Italian',
    russian: 'Итальянский',
    country: 'it',
    aliases: 'it ita IT ITA Italia',
  ),
  (
    code: 'pl',
    native: 'Polski',
    english: 'Polish',
    russian: 'Польский',
    country: 'pl',
    aliases: 'pl pol PL POL Polska',
  ),
  (
    code: 'th',
    native: 'ไทย',
    english: 'Thai',
    russian: 'Тайский',
    country: 'th',
    aliases: 'th tha TH THA Thailand ประเทศไทย',
  ),
  (
    code: 'ur',
    native: 'اردو',
    english: 'Urdu',
    russian: 'Урду',
    country: 'pk',
    aliases: 'ur urd PK PAK Pakistan پاکستان',
  ),
  (
    code: 'fa',
    native: 'فارسی',
    english: 'Persian',
    russian: 'Персидский',
    country: 'ir',
    aliases: 'fa fas per IR IRN Iran Farsi ایران',
  ),
  (
    code: 'uk',
    native: 'Українська',
    english: 'Ukrainian',
    russian: 'Украинский',
    country: 'ua',
    aliases: 'uk ukr UA UKR Україна Ukraine',
  ),
  (
    code: 'be',
    native: 'Беларуская',
    english: 'Belarusian',
    russian: 'Белорусский',
    country: 'by',
    aliases: 'be bel BY BLR Беларусь Belarus',
  ),
  (
    code: 'kk',
    native: 'Қазақша',
    english: 'Kazakh',
    russian: 'Казахский',
    country: 'kz',
    aliases: 'kk kaz KZ KAZ Қазақстан Kazakhstan',
  ),
  (
    code: 'uz',
    native: 'Oʻzbekcha',
    english: 'Uzbek',
    russian: 'Узбекский',
    country: 'uz',
    aliases: 'uz uzb UZ UZB Ўзбекча O‘zbekiston Uzbekistan',
  ),
  (
    code: 'hy',
    native: 'Հայերեն',
    english: 'Armenian',
    russian: 'Армянский',
    country: 'am',
    aliases: 'hy hye arm AM ARM Հայաստան Armenia',
  ),
  (
    code: 'az',
    native: 'Azərbaycanca',
    english: 'Azerbaijani',
    russian: 'Азербайджанский',
    country: 'az',
    aliases: 'az aze AZ AZE Azərbaycan Azerbaijan',
  ),
  (
    code: 'ka',
    native: 'ქართული',
    english: 'Georgian',
    russian: 'Грузинский',
    country: 'ge',
    aliases: 'ka kat geo GE GEO საქართველო Georgia',
  ),
  (
    code: 'ky',
    native: 'Кыргызча',
    english: 'Kyrgyz',
    russian: 'Киргизский',
    country: 'kg',
    aliases: 'ky kir KG KGZ Кыргызстан Kyrgyzstan Кыргызский',
  ),
  (
    code: 'tg',
    native: 'Тоҷикӣ',
    english: 'Tajik',
    russian: 'Таджикский',
    country: 'tj',
    aliases: 'tg tgk TJ TJK Тоҷикистон Tajikistan',
  ),
  (
    code: 'tk',
    native: 'Türkmençe',
    english: 'Turkmen',
    russian: 'Туркменский',
    country: 'tm',
    aliases: 'tk tuk TM TKM Türkmenistan Turkmenistan',
  ),
];

class LanguageButton extends StatefulWidget {
  const LanguageButton({super.key});

  @override
  State<LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<LanguageButton> {
  final _search = TextEditingController();
  final _menu = MenuController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TextSpan _highlight(String text, String query, Color color) {
    var start = 0;
    final spans = <TextSpan>[];
    for (final match in RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text)) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(fontWeight: FontWeight.w700, backgroundColor: color),
        ),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), palette = Palette.of(context), s = S.of(context);
    final locale = Localizations.localeOf(context);
    final current = appLanguages.firstWhere(
      (x) => x.code == locale.toString(),
      orElse: () => appLanguages.firstWhere((x) => x.code == locale.languageCode, orElse: () => appLanguages.first),
    );
    final width = (MediaQuery.sizeOf(context).width - 48).clamp(220.0, 296.0);
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 4),
      consumeOutsideTap: true,
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        backgroundColor: WidgetStatePropertyAll(palette.surface),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: const WidgetStatePropertyAll(4),
      ),
      menuChildren: [
        SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('language-search'),
                controller: _search,
                autofocus: true,
                // No onChanged setState: the list below listens through
                // ValueListenableBuilder, so typing rebuilds only the list,
                // not the search field and the language button.
                style: Styles.secondary.copyWith(color: palette.ink),
                decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: Icon(Symbols.search_rounded, size: 18, color: palette.ink),
                  filled: true,
                  fillColor: palette.field,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _search,
                builder: (context, value, _) {
                  final query = value.text.trim().toLowerCase();
                  final shown = appLanguages
                      .where((x) => '${x.native} ${x.english} ${x.russian} ${x.aliases}'.toLowerCase().contains(query))
                      .toList();
                  return SizedBox(
                    height: (shown.length * 56.0 + (query.isEmpty ? 40 : 0)).clamp(
                      64.0,
                      (MediaQuery.sizeOf(context).height * .45).clamp(120.0, 360.0),
                    ),
                    child: ListView(
                      primary: false,
                      padding: EdgeInsets.zero,
                      children: [
                        if (query.isEmpty)
                          MenuItemButton(
                            key: const ValueKey('language-system'),
                            leadingIcon: Icon(Symbols.language_rounded, size: 20, color: palette.ink),
                            onPressed: () => _choose('system'),
                            child: Text(s.languageSystem, style: Styles.secondary.copyWith(color: palette.ink)),
                          ),
                        if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(s.speedtestEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
                          ),
                        for (final language in shown)
                          MenuItemButton(
                            key: ValueKey('language-${language.code}'),
                            leadingIcon: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.asset(
                                'assets/flags/${language.country}.png',
                                width: 22,
                                height: 14,
                                fit: BoxFit.cover,
                              ),
                            ),
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              backgroundColor: WidgetStatePropertyAll(
                                language.code == sora.settings.language ? palette.field : null,
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            onPressed: () => _choose(language.code),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  query.isEmpty
                                      ? TextSpan(text: language.native)
                                      : _highlight(language.native, query, palette.field),
                                  style: Styles.secondary.copyWith(color: palette.ink),
                                ),
                                if (query.isNotEmpty && !language.native.toLowerCase().contains(query))
                                  Text.rich(
                                    _highlight(
                                      [
                                        language.english,
                                        language.russian,
                                        language.aliases,
                                      ].firstWhere((x) => x.toLowerCase().contains(query)),
                                      query,
                                      palette.field,
                                    ),
                                    style: Styles.caption.copyWith(color: palette.ink),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: s.language,
        child: TextButton.icon(
          key: const ValueKey('language-button'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              _search.clear();
              setState(() {});
              controller.open();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: palette.ink,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: Styles.secondary.copyWith(fontWeight: FontWeight.w600),
          ),
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset('assets/flags/${current.country}.png', width: 22, height: 14, fit: BoxFit.cover),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.native),
              const SizedBox(width: 6),
              const Icon(Symbols.keyboard_arrow_down_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _choose(String code) {
    _menu.close();
    unawaited(SoraScope.read(context).change((x) => x.language = code, replan: false));
  }
}
