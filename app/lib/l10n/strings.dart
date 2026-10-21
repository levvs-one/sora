import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_ar.dart';
import 'strings_az.dart';
import 'strings_be.dart';
import 'strings_bn.dart';
import 'strings_de.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_fa.dart';
import 'strings_fr.dart';
import 'strings_hi.dart';
import 'strings_hy.dart';
import 'strings_id.dart';
import 'strings_it.dart';
import 'strings_ja.dart';
import 'strings_ka.dart';
import 'strings_kk.dart';
import 'strings_ko.dart';
import 'strings_ky.dart';
import 'strings_pl.dart';
import 'strings_pt.dart';
import 'strings_ru.dart';
import 'strings_tg.dart';
import 'strings_th.dart';
import 'strings_tk.dart';
import 'strings_tr.dart';
import 'strings_uk.dart';
import 'strings_ur.dart';
import 'strings_uz.dart';
import 'strings_vi.dart';
import 'strings_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('az'),
    Locale('be'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('hy'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ka'),
    Locale('kk'),
    Locale('ko'),
    Locale('ky'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tg'),
    Locale('th'),
    Locale('tk'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('uz'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @stateOff.
  ///
  /// In ru, this message translates to:
  /// **'Не подключено'**
  String get stateOff;

  /// No description provided for @stateConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение'**
  String get stateConnecting;

  /// No description provided for @stateConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключено'**
  String get stateConnected;

  /// No description provided for @stateReconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Переподключение'**
  String get stateReconnecting;

  /// No description provided for @stateDisconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Отключение'**
  String get stateDisconnecting;

  /// No description provided for @stateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не подключено'**
  String get stateFailed;

  /// No description provided for @coreMissing.
  ///
  /// In ru, this message translates to:
  /// **'Служба Sora не отвечает'**
  String get coreMissing;

  /// No description provided for @serverAuto.
  ///
  /// In ru, this message translates to:
  /// **'Самый быстрый'**
  String get serverAuto;

  /// No description provided for @serverBypass.
  ///
  /// In ru, this message translates to:
  /// **'Без сервера'**
  String get serverBypass;

  /// No description provided for @addSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку'**
  String get addSubscription;

  /// No description provided for @servers.
  ///
  /// In ru, this message translates to:
  /// **'Серверы'**
  String get servers;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @subscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get subscription;

  /// No description provided for @subscriptionLink.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на подписку'**
  String get subscriptionLink;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get refresh;

  /// No description provided for @rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @name.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get name;

  /// No description provided for @deleteSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Удалить «{name}»?'**
  String deleteSubscription(String name);

  /// No description provided for @routes.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты'**
  String get routes;

  /// No description provided for @presetGlobal.
  ///
  /// In ru, this message translates to:
  /// **'Всё через VPN'**
  String get presetGlobal;

  /// No description provided for @presetRu.
  ///
  /// In ru, this message translates to:
  /// **'Россия напрямую'**
  String get presetRu;

  /// No description provided for @presetIr.
  ///
  /// In ru, this message translates to:
  /// **'Иран напрямую'**
  String get presetIr;

  /// No description provided for @presetCn.
  ///
  /// In ru, this message translates to:
  /// **'Китай напрямую'**
  String get presetCn;

  /// No description provided for @blockAds.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать рекламу'**
  String get blockAds;

  /// No description provided for @killSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Интернет только через VPN'**
  String get killSwitch;

  /// No description provided for @engine.
  ///
  /// In ru, this message translates to:
  /// **'Ядро'**
  String get engine;

  /// No description provided for @engineAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get engineAuto;

  /// No description provided for @animations.
  ///
  /// In ru, this message translates to:
  /// **'Анимации'**
  String get animations;

  /// No description provided for @logs.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get logs;

  /// No description provided for @about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get about;

  /// No description provided for @logsAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get logsAll;

  /// No description provided for @logsImportant.
  ///
  /// In ru, this message translates to:
  /// **'Важное'**
  String get logsImportant;

  /// No description provided for @logsErrors.
  ///
  /// In ru, this message translates to:
  /// **'Ошибки'**
  String get logsErrors;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @export.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в файл'**
  String get export;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// No description provided for @logsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пусто'**
  String get logsEmpty;

  /// No description provided for @connEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединений'**
  String get connEmpty;

  /// No description provided for @appVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String appVersion(String version);

  /// No description provided for @notInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Не установлено'**
  String get notInstalled;

  /// No description provided for @sourceCode.
  ///
  /// In ru, this message translates to:
  /// **'Исходный код'**
  String get sourceCode;

  /// No description provided for @license.
  ///
  /// In ru, this message translates to:
  /// **'Лицензия'**
  String get license;

  /// No description provided for @usage.
  ///
  /// In ru, this message translates to:
  /// **'{used} из {total}'**
  String usage(String used, String total);

  /// No description provided for @until.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String until(String date);

  /// No description provided for @expired.
  ///
  /// In ru, this message translates to:
  /// **'Срок истёк'**
  String get expired;

  /// No description provided for @milliseconds.
  ///
  /// In ru, this message translates to:
  /// **'{n} мс'**
  String milliseconds(int n);

  /// No description provided for @latencyMs.
  ///
  /// In ru, this message translates to:
  /// **'{value} мс'**
  String latencyMs(int value);

  /// No description provided for @speedMbps.
  ///
  /// In ru, this message translates to:
  /// **'{value} Мбит/с'**
  String speedMbps(double value);

  /// No description provided for @bytesB.
  ///
  /// In ru, this message translates to:
  /// **'{n} Б'**
  String bytesB(String n);

  /// No description provided for @bytesKB.
  ///
  /// In ru, this message translates to:
  /// **'{n} КБ'**
  String bytesKB(String n);

  /// No description provided for @bytesMB.
  ///
  /// In ru, this message translates to:
  /// **'{n} МБ'**
  String bytesMB(String n);

  /// No description provided for @bytesGB.
  ///
  /// In ru, this message translates to:
  /// **'{n} ГБ'**
  String bytesGB(String n);

  /// No description provided for @bytesTB.
  ///
  /// In ru, this message translates to:
  /// **'{n} ТБ'**
  String bytesTB(String n);

  /// No description provided for @errGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get errGeneric;

  /// No description provided for @errCore.
  ///
  /// In ru, this message translates to:
  /// **'Служба Sora не отвечает'**
  String get errCore;

  /// No description provided for @errAuth.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к службе Sora'**
  String get errAuth;

  /// No description provided for @errVersion.
  ///
  /// In ru, this message translates to:
  /// **'Обновите Sora: приложение и служба разных версий'**
  String get errVersion;

  /// No description provided for @errBusy.
  ///
  /// In ru, this message translates to:
  /// **'Подождите, предыдущая команда ещё выполняется'**
  String get errBusy;

  /// No description provided for @errEngineMissing.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено ядро для этого сервера'**
  String get errEngineMissing;

  /// No description provided for @errEngineStart.
  ///
  /// In ru, this message translates to:
  /// **'Ядро не запустилось'**
  String get errEngineStart;

  /// No description provided for @errEngineStopped.
  ///
  /// In ru, this message translates to:
  /// **'Ядро остановилось'**
  String get errEngineStopped;

  /// No description provided for @errTunnel.
  ///
  /// In ru, this message translates to:
  /// **'Нет прав на создание VPN-подключения'**
  String get errTunnel;

  /// No description provided for @errServers.
  ///
  /// In ru, this message translates to:
  /// **'Сервер настроен с ошибкой'**
  String get errServers;

  /// No description provided for @errNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не ответил вовремя'**
  String get errTimeout;

  /// No description provided for @errFirewall.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить блокировку интернета без VPN'**
  String get errFirewall;

  /// No description provided for @errSubFetch.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить подписку'**
  String get errSubFetch;

  /// No description provided for @errSubFormat.
  ///
  /// In ru, this message translates to:
  /// **'Это не ссылка на подписку'**
  String get errSubFormat;

  /// No description provided for @errSubEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В подписке нет серверов'**
  String get errSubEmpty;

  /// No description provided for @errSubDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Эта подписка уже добавлена'**
  String get errSubDuplicate;

  /// No description provided for @errSubLimit.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много подписок'**
  String get errSubLimit;

  /// No description provided for @errSubScheme.
  ///
  /// In ru, this message translates to:
  /// **'Нужна ссылка, начинающаяся с https://'**
  String get errSubScheme;

  /// No description provided for @errSecretStore.
  ///
  /// In ru, this message translates to:
  /// **'Хранилище Sora повреждено или недоступно'**
  String get errSecretStore;

  /// No description provided for @errNoServers.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте подписку, чтобы подключиться'**
  String get errNoServers;

  /// No description provided for @exportText.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get exportText;

  /// No description provided for @connections.
  ///
  /// In ru, this message translates to:
  /// **'Соединения'**
  String get connections;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @chainDirect.
  ///
  /// In ru, this message translates to:
  /// **'Напрямую'**
  String get chainDirect;

  /// No description provided for @chainBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировано'**
  String get chainBlocked;

  /// No description provided for @theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get languageSystem;

  /// No description provided for @sectionConnection.
  ///
  /// In ru, this message translates to:
  /// **'Подключение'**
  String get sectionConnection;

  /// No description provided for @sectionNoServer.
  ///
  /// In ru, this message translates to:
  /// **'Без сервера'**
  String get sectionNoServer;

  /// No description provided for @sectionPing.
  ///
  /// In ru, this message translates to:
  /// **'Пинг'**
  String get sectionPing;

  /// No description provided for @sectionLog.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика'**
  String get sectionLog;

  /// No description provided for @ipv6.
  ///
  /// In ru, this message translates to:
  /// **'IPv6'**
  String get ipv6;

  /// No description provided for @dns.
  ///
  /// In ru, this message translates to:
  /// **'DNS'**
  String get dns;

  /// No description provided for @dnsAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get dnsAuto;

  /// No description provided for @dnsHint.
  ///
  /// In ru, this message translates to:
  /// **'Адреса через запятую'**
  String get dnsHint;

  /// No description provided for @fragment.
  ///
  /// In ru, this message translates to:
  /// **'Фрагментация TLS'**
  String get fragment;

  /// No description provided for @fragmentPackets.
  ///
  /// In ru, this message translates to:
  /// **'Что дробить'**
  String get fragmentPackets;

  /// No description provided for @fragmentLength.
  ///
  /// In ru, this message translates to:
  /// **'Размер частей'**
  String get fragmentLength;

  /// No description provided for @fragmentInterval.
  ///
  /// In ru, this message translates to:
  /// **'Пауза между частями'**
  String get fragmentInterval;

  /// No description provided for @byDefault.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get byDefault;

  /// No description provided for @rangeHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, 100-200'**
  String get rangeHint;

  /// No description provided for @splitPos.
  ///
  /// In ru, this message translates to:
  /// **'Места разбиения'**
  String get splitPos;

  /// No description provided for @splitPosHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, 1, midsld'**
  String get splitPosHint;

  /// No description provided for @disorder.
  ///
  /// In ru, this message translates to:
  /// **'Менять порядок частей'**
  String get disorder;

  /// No description provided for @tlsRecord.
  ///
  /// In ru, this message translates to:
  /// **'Делить TLS-запись'**
  String get tlsRecord;

  /// No description provided for @tlsRecordNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get tlsRecordNo;

  /// No description provided for @tlsRecordSni.
  ///
  /// In ru, this message translates to:
  /// **'По имени сайта'**
  String get tlsRecordSni;

  /// No description provided for @tlsRecordFirst.
  ///
  /// In ru, this message translates to:
  /// **'После первого байта'**
  String get tlsRecordFirst;

  /// No description provided for @hostCase.
  ///
  /// In ru, this message translates to:
  /// **'Менять регистр Host'**
  String get hostCase;

  /// No description provided for @probeMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ'**
  String get probeMethod;

  /// No description provided for @probeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get probeAuto;

  /// No description provided for @probeEngine.
  ///
  /// In ru, this message translates to:
  /// **'Через ядро'**
  String get probeEngine;

  /// No description provided for @probeConnect.
  ///
  /// In ru, this message translates to:
  /// **'Только соединение'**
  String get probeConnect;

  /// No description provided for @probeUrl.
  ///
  /// In ru, this message translates to:
  /// **'Адрес проверки'**
  String get probeUrl;

  /// No description provided for @probeTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание'**
  String get probeTimeout;

  /// No description provided for @seconds.
  ///
  /// In ru, this message translates to:
  /// **'{n} с'**
  String seconds(int n);

  /// No description provided for @subscriptions.
  ///
  /// In ru, this message translates to:
  /// **'Подписки'**
  String get subscriptions;

  /// No description provided for @subscriptionSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get subscriptionSettings;

  /// No description provided for @userAgent.
  ///
  /// In ru, this message translates to:
  /// **'User-Agent'**
  String get userAgent;

  /// No description provided for @autoUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновлять автоматически'**
  String get autoUpdate;

  /// No description provided for @updateInterval.
  ///
  /// In ru, this message translates to:
  /// **'Как часто'**
  String get updateInterval;

  /// No description provided for @intervalProvider.
  ///
  /// In ru, this message translates to:
  /// **'Как просит провайдер'**
  String get intervalProvider;

  /// No description provided for @hours.
  ///
  /// In ru, this message translates to:
  /// **'{n} ч'**
  String hours(int n);

  /// No description provided for @updateNow.
  ///
  /// In ru, this message translates to:
  /// **'Обновить сейчас'**
  String get updateNow;

  /// No description provided for @logLevel.
  ///
  /// In ru, this message translates to:
  /// **'Что записывать'**
  String get logLevel;

  /// No description provided for @levelDebug.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get levelDebug;

  /// No description provided for @levelInfo.
  ///
  /// In ru, this message translates to:
  /// **'Обычное'**
  String get levelInfo;

  /// No description provided for @levelWarning.
  ///
  /// In ru, this message translates to:
  /// **'Важное'**
  String get levelWarning;

  /// No description provided for @levelError.
  ///
  /// In ru, this message translates to:
  /// **'Только ошибки'**
  String get levelError;

  /// No description provided for @recordDestinations.
  ///
  /// In ru, this message translates to:
  /// **'Записывать адреса сайтов'**
  String get recordDestinations;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get reset;

  /// No description provided for @resetConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все настройки?'**
  String get resetConfirm;

  /// No description provided for @resetAction.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetAction;

  /// No description provided for @invalidValue.
  ///
  /// In ru, this message translates to:
  /// **'Такое значение не подойдёт'**
  String get invalidValue;

  /// No description provided for @website.
  ///
  /// In ru, this message translates to:
  /// **'Сайт подписки'**
  String get website;

  /// No description provided for @providerWebsite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт провайдера'**
  String get providerWebsite;

  /// No description provided for @support.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get support;

  /// No description provided for @controlPortQuestion.
  ///
  /// In ru, this message translates to:
  /// **'{engine} управляется через порт на этом компьютере. Другие программы смогут заметить, что VPN включён.'**
  String controlPortQuestion(String engine);

  /// No description provided for @chooseEngine.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать {engine}'**
  String chooseEngine(String engine);

  /// No description provided for @rules.
  ///
  /// In ru, this message translates to:
  /// **'Свои правила'**
  String get rules;

  /// No description provided for @ruleAdd.
  ///
  /// In ru, this message translates to:
  /// **'Новое правило'**
  String get ruleAdd;

  /// No description provided for @ruleHint.
  ///
  /// In ru, this message translates to:
  /// **'Сайт, IP или программа'**
  String get ruleHint;

  /// No description provided for @ruleDirect.
  ///
  /// In ru, this message translates to:
  /// **'Напрямую'**
  String get ruleDirect;

  /// No description provided for @ruleProxy.
  ///
  /// In ru, this message translates to:
  /// **'Через VPN'**
  String get ruleProxy;

  /// No description provided for @ruleBlock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get ruleBlock;

  /// No description provided for @failover.
  ///
  /// In ru, this message translates to:
  /// **'Переключаться при сбое'**
  String get failover;

  /// No description provided for @connectOnStart.
  ///
  /// In ru, this message translates to:
  /// **'Подключаться при запуске'**
  String get connectOnStart;

  /// No description provided for @expiresIn.
  ///
  /// In ru, this message translates to:
  /// **'{name}: подписка закончится через {days, plural, =0{несколько часов} one{# день} few{# дня} other{# дней}}'**
  String expiresIn(String name, int days);

  /// No description provided for @trafficLow.
  ///
  /// In ru, this message translates to:
  /// **'{name}: осталось {left}'**
  String trafficLow(String name, String left);

  /// No description provided for @ruleInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Не похоже на сайт, IP или программу'**
  String get ruleInvalid;

  /// No description provided for @groupOrdered.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# сервер} few{# сервера} other{# серверов}}, по очереди'**
  String groupOrdered(int count);

  /// No description provided for @groupBest.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# сервер} few{# сервера} other{# серверов}}, самый быстрый'**
  String groupBest(int count);

  /// No description provided for @tunnelMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим'**
  String get tunnelMode;

  /// No description provided for @tunnelTun.
  ///
  /// In ru, this message translates to:
  /// **'Весь трафик'**
  String get tunnelTun;

  /// No description provided for @tunnelProxy.
  ///
  /// In ru, this message translates to:
  /// **'Системный прокси'**
  String get tunnelProxy;

  /// No description provided for @proxyAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес прокси'**
  String get proxyAddress;

  /// No description provided for @copied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get copied;

  /// No description provided for @launchAtLogin.
  ///
  /// In ru, this message translates to:
  /// **'Запускать вместе с системой'**
  String get launchAtLogin;

  /// No description provided for @launchAtLoginDetail.
  ///
  /// In ru, this message translates to:
  /// **'Sora будет автоматически запускаться при входе в систему и оставаться в трее.'**
  String get launchAtLoginDetail;

  /// No description provided for @closeToTray.
  ///
  /// In ru, this message translates to:
  /// **'Сворачивать в трей при закрытии'**
  String get closeToTray;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @trayOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть Sora'**
  String get trayOpen;

  /// No description provided for @trayConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get trayConnect;

  /// No description provided for @trayDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get trayDisconnect;

  /// No description provided for @trayServer.
  ///
  /// In ru, this message translates to:
  /// **'Сервер'**
  String get trayServer;

  /// No description provided for @trayQuit.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из Sora'**
  String get trayQuit;

  /// No description provided for @trayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Sora: {state}'**
  String trayTooltip(String state);

  /// No description provided for @trayTooltipServer.
  ///
  /// In ru, this message translates to:
  /// **'Sora: {state}, {server}'**
  String trayTooltipServer(String state, String server);

  /// No description provided for @noticeInTray.
  ///
  /// In ru, this message translates to:
  /// **'Sora осталась в трее'**
  String get noticeInTray;

  /// No description provided for @noticeInTrayBody.
  ///
  /// In ru, this message translates to:
  /// **'Выйти можно из меню значка'**
  String get noticeInTrayBody;

  /// No description provided for @noticeLost.
  ///
  /// In ru, this message translates to:
  /// **'Соединение прервалось'**
  String get noticeLost;

  /// No description provided for @noticeLostBody.
  ///
  /// In ru, this message translates to:
  /// **'Sora переподключается'**
  String get noticeLostBody;

  /// No description provided for @noticeRestored.
  ///
  /// In ru, this message translates to:
  /// **'Снова подключено'**
  String get noticeRestored;

  /// No description provided for @noticeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться'**
  String get noticeFailed;

  /// No description provided for @noticeBackup.
  ///
  /// In ru, this message translates to:
  /// **'Основной сервер не ответил, работает запасной'**
  String get noticeBackup;

  /// No description provided for @noticeNext.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не ответил, работает следующий'**
  String get noticeNext;

  /// No description provided for @noticeMainBack.
  ///
  /// In ru, this message translates to:
  /// **'Основной сервер снова отвечает, трафик идёт через него'**
  String get noticeMainBack;

  /// No description provided for @noticeSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get noticeSubscription;

  /// No description provided for @importTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку?'**
  String get importTitle;

  /// No description provided for @importSealed.
  ///
  /// In ru, this message translates to:
  /// **'Эта ссылка зашифрована для Happ, прочитать её может только Happ. Попросите у провайдера обычную ссылку на подписку.'**
  String get importSealed;

  /// No description provided for @understood.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get understood;

  /// No description provided for @noAnswer.
  ///
  /// In ru, this message translates to:
  /// **'нет ответа'**
  String get noAnswer;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @navRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила'**
  String get navRules;

  /// No description provided for @navConnections.
  ///
  /// In ru, this message translates to:
  /// **'Подключения'**
  String get navConnections;

  /// No description provided for @navLogs.
  ///
  /// In ru, this message translates to:
  /// **'Логи'**
  String get navLogs;

  /// No description provided for @navAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get navAbout;

  /// No description provided for @sidebarToggle.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть меню'**
  String get sidebarToggle;

  /// No description provided for @more.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get more;

  /// No description provided for @less.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get less;

  /// No description provided for @currentServer.
  ///
  /// In ru, this message translates to:
  /// **'Текущий сервер'**
  String get currentServer;

  /// No description provided for @trafficDown.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get trafficDown;

  /// No description provided for @trafficUp.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get trafficUp;

  /// No description provided for @perSecond.
  ///
  /// In ru, this message translates to:
  /// **'{value}/с'**
  String perSecond(String value);

  /// No description provided for @activeRules.
  ///
  /// In ru, this message translates to:
  /// **'Активные правила: {count}'**
  String activeRules(int count);

  /// No description provided for @recentNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Последние уведомления'**
  String get recentNotifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся события подключения и подписок'**
  String get notificationsEmpty;

  /// No description provided for @retryConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключиться снова'**
  String get retryConnect;

  /// No description provided for @openLogs.
  ///
  /// In ru, this message translates to:
  /// **'Открыть логи'**
  String get openLogs;

  /// No description provided for @tourReplay.
  ///
  /// In ru, this message translates to:
  /// **'Показать гайд снова'**
  String get tourReplay;

  /// No description provided for @tourStep.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из 5'**
  String tourStep(int step);

  /// No description provided for @tourBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get tourBack;

  /// No description provided for @tourNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get tourNext;

  /// No description provided for @tourSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get tourSkip;

  /// No description provided for @tourFinish.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get tourFinish;

  /// No description provided for @tourAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте ссылку на подписку от провайдера.'**
  String get tourAdd;

  /// No description provided for @tourServer.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сервер. «Самый быстрый» подберёт его за вас.'**
  String get tourServer;

  /// No description provided for @tourConnect.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите здесь, чтобы подключиться или отключиться.'**
  String get tourConnect;

  /// No description provided for @tourMode.
  ///
  /// In ru, this message translates to:
  /// **'Выберите режим. Kill switch блокирует интернет при обрыве VPN.'**
  String get tourMode;

  /// No description provided for @tourSettings.
  ///
  /// In ru, this message translates to:
  /// **'Откройте настройки. Здесь можно показать гайд снова.'**
  String get tourSettings;

  /// No description provided for @chooseProgram.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать программу'**
  String get chooseProgram;

  /// No description provided for @installedApps.
  ///
  /// In ru, this message translates to:
  /// **'Установленные программы'**
  String get installedApps;

  /// No description provided for @runningProcesses.
  ///
  /// In ru, this message translates to:
  /// **'Запущенные процессы'**
  String get runningProcesses;

  /// No description provided for @programsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить список программ'**
  String get programsFailed;

  /// No description provided for @programsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Программы не найдены. Попробуйте другое имя.'**
  String get programsEmpty;

  /// No description provided for @selectExe.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать файл .exe'**
  String get selectExe;

  /// No description provided for @trafficUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Счётчики пока недоступны'**
  String get trafficUnavailable;

  /// No description provided for @speedtest.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get speedtest;

  /// No description provided for @speedtestCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить скорость'**
  String get speedtestCheck;

  /// No description provided for @speedtestSearch.
  ///
  /// In ru, this message translates to:
  /// **'Найти сервис'**
  String get speedtestSearch;

  /// No description provided for @speedtestEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено. Измените запрос.'**
  String get speedtestEmpty;

  /// No description provided for @speedtestBackToList.
  ///
  /// In ru, this message translates to:
  /// **'К списку сервисов'**
  String get speedtestBackToList;

  /// No description provided for @speedtestOpenBrowser.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get speedtestOpenBrowser;

  /// No description provided for @speedtestUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Встроенный браузер не запустился. Откройте сервис в системном браузере.'**
  String get speedtestUnavailable;

  /// No description provided for @speedtestPageFailed.
  ///
  /// In ru, this message translates to:
  /// **'Страница не загрузилась. Обновите её или откройте сервис в системном браузере.'**
  String get speedtestPageFailed;

  /// No description provided for @speedtestExternalFailed.
  ///
  /// In ru, this message translates to:
  /// **'Системный браузер не открылся. Попробуйте ещё раз.'**
  String get speedtestExternalFailed;

  /// No description provided for @modes.
  ///
  /// In ru, this message translates to:
  /// **'Режимы'**
  String get modes;

  /// No description provided for @proxyShort.
  ///
  /// In ru, this message translates to:
  /// **'Прокси'**
  String get proxyShort;

  /// No description provided for @tunMode.
  ///
  /// In ru, this message translates to:
  /// **'Весь трафик (TUN)'**
  String get tunMode;

  /// No description provided for @checkUpdates.
  ///
  /// In ru, this message translates to:
  /// **'Проверять обновления'**
  String get checkUpdates;

  /// No description provided for @updates.
  ///
  /// In ru, this message translates to:
  /// **'Обновления приложения'**
  String get updates;

  /// No description provided for @updateAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступна версия {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateOpenAbout.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть обновление'**
  String get updateOpenAbout;

  /// No description provided for @updateNotes.
  ///
  /// In ru, this message translates to:
  /// **'Что изменилось в {version}'**
  String updateNotes(String version);

  /// No description provided for @updateCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить обновления'**
  String get updateCheck;

  /// No description provided for @updateChecking.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем...'**
  String get updateChecking;

  /// No description provided for @updateNoNotes.
  ///
  /// In ru, this message translates to:
  /// **'Автор релиза не добавил описание.'**
  String get updateNoNotes;

  /// No description provided for @updateDropWarning.
  ///
  /// In ru, this message translates to:
  /// **'При обновлении Sora и ядра VPN-соединение прервётся на несколько секунд. Продолжить?'**
  String get updateDropWarning;

  /// No description provided for @updateWaitConnection.
  ///
  /// In ru, this message translates to:
  /// **'Дождитесь завершения подключения и готовности службы Sora.'**
  String get updateWaitConnection;

  /// No description provided for @updateDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Скачиваем и проверяем файлы...'**
  String get updateDownloading;

  /// No description provided for @updateInstalling.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка обновления или ожидание пароля администратора...'**
  String get updateInstalling;

  /// No description provided for @updateNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать обновление. Попробуйте ещё раз.'**
  String get updateNetworkError;

  /// No description provided for @updateReleaseError.
  ///
  /// In ru, this message translates to:
  /// **'Данные релиза или нужные файлы отсутствуют либо некорректны.'**
  String get updateReleaseError;

  /// No description provided for @updateChecksumError.
  ///
  /// In ru, this message translates to:
  /// **'Файл не совпадает с SHA256SUMS. Установка не запускалась.'**
  String get updateChecksumError;

  /// No description provided for @updateInstallError.
  ///
  /// In ru, this message translates to:
  /// **'Обновление не завершилось. Возможно, запрос прав был отменён.'**
  String get updateInstallError;

  /// No description provided for @updateUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Этот файл приложения не принадлежит поддерживаемой паре пакетов Sora. Используйте инструкцию установки из описания релиза.'**
  String get updateUnsupported;

  /// No description provided for @updateManual.
  ///
  /// In ru, this message translates to:
  /// **'Выполните команду в терминале для установки обоих проверенных пакетов, затем откройте Sora снова. Файлы сохранены в каталоге загрузки. VPN-соединение прервётся.'**
  String get updateManual;

  /// No description provided for @updateSignaturePending.
  ///
  /// In ru, this message translates to:
  /// **'Подлинность релиза пока не проверяется подписью — церемония ключа подписи ещё не проведена. Файлы сверяются по SHA-256 с манифестом, полученным по TLS.'**
  String get updateSignaturePending;

  /// No description provided for @updateManualSigWarning.
  ///
  /// In ru, this message translates to:
  /// **'Внимание: подпись манифеста не проверена — файлы ниже сверены только по хэшам. Выполняйте команду, только если доверяете каналу релиза.'**
  String get updateManualSigWarning;

  /// No description provided for @updateVersionRevoked.
  ///
  /// In ru, this message translates to:
  /// **'Эта версия отозвана разработчиком. Дождитесь исправленного релиза.'**
  String get updateVersionRevoked;

  /// No description provided for @updateRolloutPending.
  ///
  /// In ru, this message translates to:
  /// **'Новая версия распространяется постепенно и будет предложена вам автоматически.'**
  String get updateRolloutPending;

  /// No description provided for @updateRollbacking.
  ///
  /// In ru, this message translates to:
  /// **'Откатываемся к версии {version}...'**
  String updateRollbacking(String version);

  /// No description provided for @updateRolledBack.
  ///
  /// In ru, this message translates to:
  /// **'Обновление до {version} не прошло проверку работоспособности, поэтому Sora откатилась к {fromVersion}.'**
  String updateRolledBack(String version, String fromVersion);

  /// No description provided for @updateRollbackError.
  ///
  /// In ru, this message translates to:
  /// **'Автоматический откат не удался. Если новая версия не работает, переустановите предыдущий релиз вручную.'**
  String get updateRollbackError;

  /// No description provided for @updateRollbackCacheError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить проверенную копию текущей версии для отката, поэтому обновление не установлено.'**
  String get updateRollbackCacheError;

  /// No description provided for @updateCopyCommand.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать команду'**
  String get updateCopyCommand;

  /// No description provided for @updateChecksDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Автоматические проверки отключены в настройках.'**
  String get updateChecksDisabled;

  /// No description provided for @updateInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Обновление установлено. Откройте Sora снова.'**
  String get updateInstalled;

  /// No description provided for @projectLinks.
  ///
  /// In ru, this message translates to:
  /// **'Проект'**
  String get projectLinks;

  /// No description provided for @githubReleases.
  ///
  /// In ru, this message translates to:
  /// **'Релизы и загрузки'**
  String get githubReleases;

  /// No description provided for @telegramChannel.
  ///
  /// In ru, this message translates to:
  /// **'Канал в Telegram'**
  String get telegramChannel;

  /// No description provided for @licenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии'**
  String get licenses;

  /// No description provided for @componentLicenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии компонентов'**
  String get componentLicenses;

  /// No description provided for @appCopyright.
  ///
  /// In ru, this message translates to:
  /// **'© 2026 levvs-one и участники проекта'**
  String get appCopyright;

  /// No description provided for @collapseServers.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть серверы'**
  String get collapseServers;

  /// No description provided for @expandServers.
  ///
  /// In ru, this message translates to:
  /// **'Показать серверы'**
  String get expandServers;

  /// No description provided for @hideDescription.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть описание'**
  String get hideDescription;

  /// No description provided for @showDescription.
  ///
  /// In ru, this message translates to:
  /// **'Показать описание'**
  String get showDescription;

  /// No description provided for @pendingConnectionChanges.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы применить изменения, переподключитесь.'**
  String get pendingConnectionChanges;

  /// No description provided for @reconnectNow.
  ///
  /// In ru, this message translates to:
  /// **'Применить и переподключить'**
  String get reconnectNow;

  /// No description provided for @bypassLimitations.
  ///
  /// In ru, this message translates to:
  /// **'Этот режим обходит DPI только для HTTP и TLS, не поддерживает UDP и не меняет IP. Для голоса Discord, звонков и заблокированных адресов Telegram используйте VPN-сервер.'**
  String get bypassLimitations;

  /// No description provided for @errEngineUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Выбранное ядро не поддерживает этот профиль или настройки. Выберите «Авто» либо совместимое ядро.'**
  String get errEngineUnsupported;

  /// No description provided for @errRestore.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось полностью очистить подключение. Повторите отключение; подробности — в журнале.'**
  String get errRestore;

  /// No description provided for @errSessionEnded.
  ///
  /// In ru, this message translates to:
  /// **'Эта сессия уже завершена. Обновите состояние подключения.'**
  String get errSessionEnded;

  /// No description provided for @retryDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Повторить отключение'**
  String get retryDisconnect;

  /// No description provided for @tunStack.
  ///
  /// In ru, this message translates to:
  /// **'Стек TUN'**
  String get tunStack;

  /// No description provided for @modesInfo.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее о режимах'**
  String get modesInfo;

  /// No description provided for @modesGuideTitle.
  ///
  /// In ru, this message translates to:
  /// **'Режимы и ядра'**
  String get modesGuideTitle;

  /// No description provided for @modesGuide.
  ///
  /// In ru, this message translates to:
  /// **'Выбирайте «Авто», если не знаете, какое ядро нужно серверу. Sora сверяет поддержку профиля и настроек перед подключением. Само ядро не меняет скорость тарифа: результат зависит от сервера, маршрута, протокола и сети.\n\n## Режимы\n\n### Весь трафик (TUN)\n\nSora создаёт виртуальный сетевой интерфейс и направляет через него трафик приложений, включая TCP и UDP. Это подходящий режим для Telegram, игр и голосовой связи Discord. Правила могут отправлять отдельные сайты и программы напрямую или блокировать их. Для работы нужны права сетевой службы и сервер, поддерживающий нужный протокол.\n\n### Системный прокси\n\nSora задаёт локальный HTTP/SOCKS-прокси. Его используют приложения, которые учитывают системные настройки прокси. Программа со своим сетевым стеком может пройти напрямую; UDP и голосовые звонки обычно требуют TUN. Этот режим удобен для браузеров и приложений с поддержкой прокси.\n\n### Без сервера\n\nВ Linux Sora использует [zapret](https://github.com/bol-van/zapret): разбивает и меняет HTTP/TLS-запросы, чтобы обходить некоторые проверки DPI. Адрес IP остаётся вашим, соединение идёт к сайту напрямую. Результат зависит от провайдера и способа блокировки.\n\nТекущая интеграция использует tpws и обрабатывает TCP для HTTP и TLS. Она не обходит блокировку по IP, не пересылает UDP и не гарантирует работу Telegram с MTProto. Для голоса Discord, звонков Telegram и таких блокировок выберите VPN-сервер и TUN.\n\n## Ядра\n\n### Авто\n\nSora выбирает установленное ядро, которое поддерживает весь план подключения. Важно всё сразу: протоколы серверов, транспорт, группы, фрагментация и режим. Если выбранный вручную движок несовместим, новое подключение отклоняется до отключения текущего. Выберите «Авто» или другое ядро и примените настройки снова.\n\n### sing-box\n\nВ новых пакетах Sora используется [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box). Он добавляет клиентский XHTTP и VLESS Encryption. Sora распознаёт сборку и её возможности; стандартный sing-box без XHTTP не получает эту возможность по одному лишь названию.\n\nПоддерживаются VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard и параметры AmneziaWG 1.x/2.x, которые умеет импортировать Sora. Полные JSON-профили Xray требуют Xray. Новые параметры AWG 3.x ещё не импортируются. Управление sing-box использует защищённый паролем локальный порт; другие программы на компьютере могут заметить его наличие.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) подходит для VLESS, REALITY, XHTTP, VLESS Encryption и TLS-фрагментации. Он также запускает полные профили Xray от провайдера, сохраняя их маршрутизацию и группы. Профиль такого вида нельзя автоматически превратить в конфиг другого движка без изменения его поведения.\n\nВ поставляемом Xray удалён параметр отключения проверки TLS-сертификата (`allowInsecure`). Для таких обычных серверов «Авто» выбирает sing-box или mihomo. При ручном выборе Xray Sora сообщает о несовместимости до отключения текущего соединения. Для старого полного JSON-профиля нужен обновлённый профиль провайдера с проверяемым сертификатом или его отпечатком.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) поддерживает группы с последовательным резервом и балансировкой, а также XHTTP и AmneziaWG. Выбирайте его, если важен автоматический переход на запасной сервер. Фрагментация TLS из настроек Sora для этого ядра недоступна.\n\n## Совместимость в Sora\n\n| Возможность | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| TUN и TCP/UDP в Linux | Да | Да | Да |\n| XHTTP | Да | Да | Да |\n| VLESS Encryption | Да | Да | Да |\n| Полный профиль Xray | Нет | Да | Нет |\n| TUIC / AnyTLS | Оба | Нет | TUIC |\n| TLS-фрагментация | Да | Да | Нет |\n| AmneziaWG 1.x/2.x | Да¹ | Нет | Да |\n| Группа с резервом | Нет | Нет² | Да |\n\n¹ Профили с J1/J2/J3/Itime направляются в mihomo; эти параметры нельзя молча отбрасывать. ² Для группы полных профилей Xray запасной профиль выбирает приложение. Точная поддержка зависит от установленной сборки. Её версию можно посмотреть в «О приложении».\n\n## Стек TUN\n\nСтек обрабатывает TCP и UDP внутри виртуального интерфейса. В панели режимов у Xray и mihomo можно выбрать gVisor, System, Mixed или MIPS. Выбор сохраняется отдельно для каждого ядра. В режиме системного прокси и «Без сервера» этот выбор не используется.\n\n- **Mixed** — TCP использует системный стек, UDP обрабатывает gVisor. Это вариант по умолчанию для mihomo в Linux. В Windows Xray и mihomo по умолчанию используют MIPS.\n- **System** — использует системный стек. При проблемах с сетевыми программами попробуйте другой вариант.\n- **gVisor** — обрабатывает трафик в пользовательском пространстве.\n- **MIPS** — собственный IP-стек mihomo, доступный в поставляемой версии 1.19.32.\n\nВ Linux у Xray gVisor работает встроенно и выбран по умолчанию. System, Mixed и MIPS в Linux подключаются через TUN-движок mihomo: он передаёт TCP и UDP в Xray по защищённому локальному SOCKS. Протокол, профиль провайдера и маршрутизация остаются в Xray. Для этих трёх вариантов нужен установленный mihomo. В Windows Xray использует mihomo 1.19.32 или новее для всех четырёх стеков TUN. Протоколы и маршрутизация остаются в Xray. Правила приложений в этой связке поддерживают только прямое соединение и блокировку; на Linux они требуют встроенного gVisor Xray.\n\nСвязка запускает второй процесс. В трёх замерах в Linux без трафика она потребляла примерно на 32–36 МиБ больше физической памяти, чем встроенный TUN Xray. Это не оценка нагрузки при скачивании: расходы процессора и память зависят от соединений. Для sing-box переключатель не добавляется. Ни один вариант не гарантирует более высокую скорость во всех сетях. Смените стек и нажмите «Применить и переподключить», чтобы проверить результат в своей сети.\n\n## Когда применяются настройки\n\nВыбор сервера автоматически переподключает соединение. Режим, ядро, DNS и правила сохраняются сразу; при активном соединении нажмите «Применить и переподключить», чтобы они вступили в силу. Перезапуск ядра может прервать загрузки и звонки. Частые нажатия не запускают параллельные подключения; отключение завершает переход и освобождает соединение.\n\n«Интернет только через VPN» блокирует прямой выход при обрыве туннеля. Это ограничение действует на всю машину, поэтому используйте его осознанно. При явном отключении Sora снимает свои правила. Если очистка не завершилась, повторите отключение и откройте журнал.\n\n## Документация проектов\n\n- [sing-box-lx: настройки и поддержка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.ru.md)\n- [sing-box: документация](https://sing-box.sagernet.org/)\n- [Xray: документация](https://xtls.github.io/)\n- [mihomo: документация](https://wiki.metacubex.one/)\n- [zapret: описание и ограничения](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n'**
  String get modesGuide;

  /// No description provided for @probeServers.
  ///
  /// In ru, this message translates to:
  /// **'Проверить серверы'**
  String get probeServers;

  /// No description provided for @extensions.
  ///
  /// In ru, this message translates to:
  /// **'Расширения'**
  String get extensions;

  /// No description provided for @extRatingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оценка {rating} из 5'**
  String extRatingLabel(String rating);

  /// No description provided for @extByAuthor.
  ///
  /// In ru, this message translates to:
  /// **'{author}'**
  String extByAuthor(String author);

  /// No description provided for @extInstallsCount.
  ///
  /// In ru, this message translates to:
  /// **'установок: {count}'**
  String extInstallsCount(String count);

  /// No description provided for @extInstallOne.
  ///
  /// In ru, this message translates to:
  /// **'1 установка'**
  String get extInstallOne;

  /// No description provided for @extBadgeVerified.
  ///
  /// In ru, this message translates to:
  /// **'Проверено'**
  String get extBadgeVerified;

  /// No description provided for @extBadgeTop.
  ///
  /// In ru, this message translates to:
  /// **'Топ недели'**
  String get extBadgeTop;

  /// No description provided for @extBadgeNew.
  ///
  /// In ru, this message translates to:
  /// **'Новое'**
  String get extBadgeNew;

  /// No description provided for @extBadgeStaff.
  ///
  /// In ru, this message translates to:
  /// **'Команда Sora'**
  String get extBadgeStaff;

  /// No description provided for @extSideloadShort.
  ///
  /// In ru, this message translates to:
  /// **'Не из каталога'**
  String get extSideloadShort;

  /// No description provided for @extSideloadWarning.
  ///
  /// In ru, this message translates to:
  /// **'Не из каталога команды. Ключ автора не проверен: устанавливайте, только если доверяете автору.'**
  String get extSideloadWarning;

  /// No description provided for @extInstallTitle.
  ///
  /// In ru, this message translates to:
  /// **'Установить «{name}»'**
  String extInstallTitle(String name);

  /// No description provided for @extUpdateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Обновить «{name}»'**
  String extUpdateTitle(String name);

  /// No description provided for @extPermissionsIntro.
  ///
  /// In ru, this message translates to:
  /// **'Расширение сможет:'**
  String get extPermissionsIntro;

  /// No description provided for @extPermissionsWidened.
  ///
  /// In ru, this message translates to:
  /// **'Обновление запрашивает новые разрешения:'**
  String get extPermissionsWidened;

  /// No description provided for @extDangerousAck.
  ///
  /// In ru, this message translates to:
  /// **'Я понимаю, что эти разрешения серьёзные'**
  String get extDangerousAck;

  /// No description provided for @extInstall.
  ///
  /// In ru, this message translates to:
  /// **'Установить'**
  String get extInstall;

  /// No description provided for @extUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get extUpdate;

  /// No description provided for @extCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get extCancel;

  /// No description provided for @extConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get extConfirm;

  /// No description provided for @extOk.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get extOk;

  /// No description provided for @extCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get extCatalog;

  /// No description provided for @extInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Установленные'**
  String get extInstalled;

  /// No description provided for @extSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск расширений'**
  String get extSearchHint;

  /// No description provided for @extCatAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get extCatAll;

  /// No description provided for @extCatTools.
  ///
  /// In ru, this message translates to:
  /// **'Инструменты'**
  String get extCatTools;

  /// No description provided for @extCatThemes.
  ///
  /// In ru, this message translates to:
  /// **'Темы'**
  String get extCatThemes;

  /// No description provided for @extCatAutomation.
  ///
  /// In ru, this message translates to:
  /// **'Автоматизация'**
  String get extCatAutomation;

  /// No description provided for @extCatStats.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get extCatStats;

  /// No description provided for @extCatNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Сеть'**
  String get extCatNetwork;

  /// No description provided for @extSortBy.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get extSortBy;

  /// No description provided for @extSortPopular.
  ///
  /// In ru, this message translates to:
  /// **'По популярности'**
  String get extSortPopular;

  /// No description provided for @extSortRating.
  ///
  /// In ru, this message translates to:
  /// **'По рейтингу'**
  String get extSortRating;

  /// No description provided for @extSortName.
  ///
  /// In ru, this message translates to:
  /// **'По названию'**
  String get extSortName;

  /// No description provided for @extCatalogError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить каталог'**
  String get extCatalogError;

  /// No description provided for @extRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get extRetry;

  /// No description provided for @extEmptySearch.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get extEmptySearch;

  /// No description provided for @extEmptyInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет установленных расширений.\nНайдите в каталоге или установите из файла.'**
  String get extEmptyInstalled;

  /// No description provided for @extInstallFromFile.
  ///
  /// In ru, this message translates to:
  /// **'Установить из файла'**
  String get extInstallFromFile;

  /// No description provided for @extInstallFromUrl.
  ///
  /// In ru, this message translates to:
  /// **'Установить по ссылке'**
  String get extInstallFromUrl;

  /// No description provided for @extUrlHint.
  ///
  /// In ru, this message translates to:
  /// **'https://…/extension.soraext'**
  String get extUrlHint;

  /// No description provided for @extDownload.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get extDownload;

  /// No description provided for @extDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Скачивание…'**
  String get extDownloading;

  /// No description provided for @extVerifying.
  ///
  /// In ru, this message translates to:
  /// **'Проверка…'**
  String get extVerifying;

  /// No description provided for @extInstalling.
  ///
  /// In ru, this message translates to:
  /// **'Установка…'**
  String get extInstalling;

  /// No description provided for @extInstallFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось установить'**
  String get extInstallFailed;

  /// No description provided for @extErrSignature.
  ///
  /// In ru, this message translates to:
  /// **'Проверка подписи не пройдена. Файл может быть повреждён или подменён.'**
  String get extErrSignature;

  /// No description provided for @extErrManifest.
  ///
  /// In ru, this message translates to:
  /// **'Манифест расширения некорректен.'**
  String get extErrManifest;

  /// No description provided for @extErrNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте соединение и попробуйте снова.'**
  String get extErrNetwork;

  /// No description provided for @extErrHash.
  ///
  /// In ru, this message translates to:
  /// **'Скачанный файл не совпадает с каталогом. Возможно, он подменён.'**
  String get extErrHash;

  /// No description provided for @extErrMinApp.
  ///
  /// In ru, this message translates to:
  /// **'Расширению нужна версия приложения {version} или новее.'**
  String extErrMinApp(String version);

  /// No description provided for @extErrHttpsOnly.
  ///
  /// In ru, this message translates to:
  /// **'Разрешены только ссылки https://'**
  String get extErrHttpsOnly;

  /// No description provided for @extErrGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Попробуйте снова.'**
  String get extErrGeneric;

  /// No description provided for @extErrAuthorKeyChanged.
  ///
  /// In ru, this message translates to:
  /// **'Это обновление подписано другим ключом автора, а не тем, что у установленной версии, поэтому оно заблокировано. Если вы доверяете новому ключу, удалите расширение и установите его заново явно.'**
  String get extErrAuthorKeyChanged;

  /// No description provided for @extUpdateAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление'**
  String get extUpdateAvailable;

  /// No description provided for @extDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get extDisabled;

  /// No description provided for @extToggleEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Включить {name}'**
  String extToggleEnabled(String name);

  /// No description provided for @extSearchInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Поиск установленных'**
  String get extSearchInstalled;

  /// No description provided for @extUpdateAll.
  ///
  /// In ru, this message translates to:
  /// **'Обновить все'**
  String get extUpdateAll;

  /// No description provided for @extUpdatesAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновлений: {count}'**
  String extUpdatesAvailable(int count);

  /// No description provided for @extUpdatedCount.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено: {count}'**
  String extUpdatedCount(int count);

  /// No description provided for @extRiskNormal.
  ///
  /// In ru, this message translates to:
  /// **'Обычный'**
  String get extRiskNormal;

  /// No description provided for @extRiskSensitive.
  ///
  /// In ru, this message translates to:
  /// **'Чувствительный'**
  String get extRiskSensitive;

  /// No description provided for @extRiskDangerous.
  ///
  /// In ru, this message translates to:
  /// **'Высокий риск'**
  String get extRiskDangerous;

  /// No description provided for @extPermissionsRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Больше не запрашивается:'**
  String get extPermissionsRemoved;

  /// No description provided for @extUpdateFailedKept.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущая версия осталась установлена.'**
  String get extUpdateFailedKept;

  /// No description provided for @extConflictsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Конфликты расширений'**
  String get extConflictsTitle;

  /// No description provided for @extConflictsIntro.
  ///
  /// In ru, this message translates to:
  /// **'Эти расширения претендуют на одно и то же. Выберите победителя — другое останется установлено. Когда спорная возможность появится в движке, работать будет только победитель.'**
  String get extConflictsIntro;

  /// No description provided for @extConflictRoutingRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила маршрутизации'**
  String get extConflictRoutingRules;

  /// No description provided for @extConflictTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема приложения'**
  String get extConflictTheme;

  /// No description provided for @extConflictNetHooks.
  ///
  /// In ru, this message translates to:
  /// **'Сетевые хуки'**
  String get extConflictNetHooks;

  /// No description provided for @extConflictWinner.
  ///
  /// In ru, this message translates to:
  /// **'Побеждает: {name}'**
  String extConflictWinner(String name);

  /// No description provided for @extConflictsCount.
  ///
  /// In ru, this message translates to:
  /// **'Требуют решения: {count}'**
  String extConflictsCount(int count);

  /// No description provided for @extConflictsResolve.
  ///
  /// In ru, this message translates to:
  /// **'Решить'**
  String get extConflictsResolve;

  /// No description provided for @extConflictNote.
  ///
  /// In ru, this message translates to:
  /// **'Ваш выбор сохраняется на этом устройстве и будет применён, когда движок начнёт поддерживать эти возможности.'**
  String get extConflictNote;

  /// No description provided for @extVersionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String extVersionLabel(String version);

  /// No description provided for @extAuthor.
  ///
  /// In ru, this message translates to:
  /// **'Автор'**
  String get extAuthor;

  /// No description provided for @extRating.
  ///
  /// In ru, this message translates to:
  /// **'Оценка'**
  String get extRating;

  /// No description provided for @extInstalls.
  ///
  /// In ru, this message translates to:
  /// **'Установки'**
  String get extInstalls;

  /// No description provided for @extVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get extVersion;

  /// No description provided for @extAbout.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get extAbout;

  /// No description provided for @extPermissionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешения'**
  String get extPermissionsTitle;

  /// No description provided for @extNoPermissions.
  ///
  /// In ru, this message translates to:
  /// **'Особых разрешений не требуется.'**
  String get extNoPermissions;

  /// No description provided for @extSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get extSettings;

  /// No description provided for @extSaveSettings.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить настройки'**
  String get extSaveSettings;

  /// No description provided for @extSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get extSaving;

  /// No description provided for @extUpdateTo.
  ///
  /// In ru, this message translates to:
  /// **'Обновить до {version}'**
  String extUpdateTo(String version);

  /// No description provided for @extEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get extEnabled;

  /// No description provided for @extRollbackTo.
  ///
  /// In ru, this message translates to:
  /// **'Откатить до {version}'**
  String extRollbackTo(String version);

  /// No description provided for @extRollbackConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Откатить до версии {version}?'**
  String extRollbackConfirm(String version);

  /// No description provided for @extUninstall.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get extUninstall;

  /// No description provided for @extUninstallConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить «{name}» и его настройки?'**
  String extUninstallConfirm(String name);

  /// No description provided for @extPanelUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Панель недоступна. Возможно, расширение отключено или удалено.'**
  String get extPanelUnavailable;

  /// No description provided for @extPermConnectionsRead.
  ///
  /// In ru, this message translates to:
  /// **'Видеть список активных соединений'**
  String get extPermConnectionsRead;

  /// No description provided for @extPermServersRead.
  ///
  /// In ru, this message translates to:
  /// **'Видеть список ваших серверов'**
  String get extPermServersRead;

  /// No description provided for @extPermSettingsRead.
  ///
  /// In ru, this message translates to:
  /// **'Читать настройки приложения'**
  String get extPermSettingsRead;

  /// No description provided for @extPermSettingsWrite.
  ///
  /// In ru, this message translates to:
  /// **'Изменять настройки приложения'**
  String get extPermSettingsWrite;

  /// No description provided for @extPermNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Показывать уведомления'**
  String get extPermNotifications;

  /// No description provided for @extPermTray.
  ///
  /// In ru, this message translates to:
  /// **'Добавлять пункты в меню трея'**
  String get extPermTray;

  /// No description provided for @extPermUiPanel.
  ///
  /// In ru, this message translates to:
  /// **'Показывать панели в приложении'**
  String get extPermUiPanel;

  /// No description provided for @extPermThemeApply.
  ///
  /// In ru, this message translates to:
  /// **'Применять темы оформления'**
  String get extPermThemeApply;

  /// No description provided for @extPermRoutingRules.
  ///
  /// In ru, this message translates to:
  /// **'Добавлять правила маршрутизации (влияет на трафик)'**
  String get extPermRoutingRules;

  /// No description provided for @extPermNetHooks.
  ///
  /// In ru, this message translates to:
  /// **'Встраиваться в сетевой тракт (модули обхода DPI)'**
  String get extPermNetHooks;

  /// No description provided for @extPermNetFetch.
  ///
  /// In ru, this message translates to:
  /// **'Запрашивать URL из разрешённого списка'**
  String get extPermNetFetch;

  /// No description provided for @extPermBackground.
  ///
  /// In ru, this message translates to:
  /// **'Выполнять фоновые задачи'**
  String get extPermBackground;

  /// No description provided for @extPermBackgroundDetail.
  ///
  /// In ru, this message translates to:
  /// **'Выполняет задачи по расписанию, даже когда панель расширения закрыта. Приостановить или изменить интервал можно в настройках расширения. Фоновое выполнение пока недоступно в этой версии Sora.'**
  String get extPermBackgroundDetail;

  /// No description provided for @extPermNotYetActive.
  ///
  /// In ru, this message translates to:
  /// **'Пока не активно в этой версии Sora — это разрешение сейчас ничего не изменит.'**
  String get extPermNotYetActive;

  /// No description provided for @extCapBackground.
  ///
  /// In ru, this message translates to:
  /// **'Работает в фоновом режиме'**
  String get extCapBackground;

  /// No description provided for @extCapFilterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возможности'**
  String get extCapFilterTitle;

  /// No description provided for @extCapNetHook.
  ///
  /// In ru, this message translates to:
  /// **'Обходы и сетевые хуки'**
  String get extCapNetHook;

  /// No description provided for @extCapPanel.
  ///
  /// In ru, this message translates to:
  /// **'Панели'**
  String get extCapPanel;

  /// No description provided for @extCapRouting.
  ///
  /// In ru, this message translates to:
  /// **'Правила маршрутизации'**
  String get extCapRouting;

  /// No description provided for @extCapTheme.
  ///
  /// In ru, this message translates to:
  /// **'Темы'**
  String get extCapTheme;

  /// No description provided for @extCapWidget.
  ///
  /// In ru, this message translates to:
  /// **'Виджеты'**
  String get extCapWidget;

  /// No description provided for @extCatalogCached.
  ///
  /// In ru, this message translates to:
  /// **'Кэш каталога · {date}'**
  String extCatalogCached(String date);

  /// No description provided for @extChangelog.
  ///
  /// In ru, this message translates to:
  /// **'История версий'**
  String get extChangelog;

  /// No description provided for @extImageFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить изображение'**
  String get extImageFailed;

  /// No description provided for @extRatingHow.
  ///
  /// In ru, this message translates to:
  /// **'Как считаются оценки'**
  String get extRatingHow;

  /// No description provided for @extRatingHowBody.
  ///
  /// In ru, this message translates to:
  /// **'Оценки считаются по байесовскому среднему: расширение с малым числом оценок остаётся около середины, пока не проголосует больше людей, — один отзыв «5 звёзд» не выведет новое расширение в топ. Свежие оценки весят больше старых, с одного аккаунта засчитывается только одна оценка.'**
  String get extRatingHowBody;

  /// No description provided for @extScreenshots.
  ///
  /// In ru, this message translates to:
  /// **'Скриншоты'**
  String get extScreenshots;

  /// No description provided for @extSortRelevance.
  ///
  /// In ru, this message translates to:
  /// **'Сначала подходящие'**
  String get extSortRelevance;

  /// No description provided for @extPermNetworkDetail.
  ///
  /// In ru, this message translates to:
  /// **'Загружает данные из интернета. Разрешены только хосты из списка ниже — всё остальное заблокировано. Сетевые запросы пока недоступны в этой версии Sora.'**
  String get extPermNetworkDetail;

  /// No description provided for @extBgTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фоновая задача'**
  String get extBgTitle;

  /// No description provided for @extBgEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Выполнять в фоне'**
  String get extBgEnabled;

  /// No description provided for @extBgInterval.
  ///
  /// In ru, this message translates to:
  /// **'Запускать каждые'**
  String get extBgInterval;

  /// No description provided for @extBgMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# минуту} few{# минуты} other{# минут}}'**
  String extBgMinutes(int count);

  /// No description provided for @extBgHours.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# час} few{# часа} other{# часов}}'**
  String extBgHours(int count);

  /// No description provided for @extBgNote.
  ///
  /// In ru, this message translates to:
  /// **'Фоновое выполнение недоступно в этой версии Sora. Ваше расписание сохранено и начнёт действовать автоматически, когда появится фоновый рантайм. Минимальный интервал — 15 минут.'**
  String get extBgNote;

  /// No description provided for @extBgRuntimeBadge.
  ///
  /// In ru, this message translates to:
  /// **'Пока недоступно'**
  String get extBgRuntimeBadge;

  /// No description provided for @extBgDisabledNote.
  ///
  /// In ru, this message translates to:
  /// **'Включите расширение, чтобы управлять его фоновой задачей.'**
  String get extBgDisabledNote;

  /// No description provided for @extCapNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к сети'**
  String get extCapNetwork;

  /// No description provided for @extCapNetworkHosts.
  ///
  /// In ru, this message translates to:
  /// **'Сеть: {hosts}'**
  String extCapNetworkHosts(String hosts);

  /// No description provided for @exportLogFile.
  ///
  /// In ru, this message translates to:
  /// **'В {name}'**
  String exportLogFile(String name);

  /// No description provided for @diagnosticHttp.
  ///
  /// In ru, this message translates to:
  /// **'HTTP-диагностика'**
  String get diagnosticHttp;

  /// No description provided for @diagnosticArchive.
  ///
  /// In ru, this message translates to:
  /// **'Архив диагностики ядра'**
  String get diagnosticArchive;

  /// No description provided for @diagnosticNoData.
  ///
  /// In ru, this message translates to:
  /// **'Запросов пока нет. Сначала откройте сайт проверки скорости.'**
  String get diagnosticNoData;

  /// No description provided for @qrShareTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться QR-кодом'**
  String get qrShareTitle;

  /// No description provided for @qrScanTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR-код'**
  String get qrScanTitle;

  /// No description provided for @qrCopyLink.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку'**
  String get qrCopyLink;

  /// No description provided for @qrShowLink.
  ///
  /// In ru, this message translates to:
  /// **'Показать ссылку'**
  String get qrShowLink;

  /// No description provided for @qrHideLink.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть ссылку'**
  String get qrHideLink;

  /// No description provided for @qrWarning.
  ///
  /// In ru, this message translates to:
  /// **'QR-код содержит данные для подключения. Не показывайте его посторонним.'**
  String get qrWarning;

  /// No description provided for @qrScanHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите снимок экрана или фото с QR-кодом либо вставьте ссылку'**
  String get qrScanHint;

  /// No description provided for @qrFromClipboard.
  ///
  /// In ru, this message translates to:
  /// **'Вставить из буфера обмена'**
  String get qrFromClipboard;

  /// No description provided for @qrNoCode.
  ///
  /// In ru, this message translates to:
  /// **'На изображении не найден QR-код.'**
  String get qrNoCode;

  /// No description provided for @qrInvalid.
  ///
  /// In ru, this message translates to:
  /// **'В этом QR-коде нет корректной ссылки.'**
  String get qrInvalid;

  /// No description provided for @qrScan.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR'**
  String get qrScan;

  /// No description provided for @qrFromImage.
  ///
  /// In ru, this message translates to:
  /// **'Открыть изображение'**
  String get qrFromImage;

  /// No description provided for @connGroupByProcess.
  ///
  /// In ru, this message translates to:
  /// **'По процессам'**
  String get connGroupByProcess;

  /// No description provided for @connListView.
  ///
  /// In ru, this message translates to:
  /// **'Списком'**
  String get connListView;

  /// No description provided for @connCopyHost.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать хост'**
  String get connCopyHost;

  /// No description provided for @connAddRule.
  ///
  /// In ru, this message translates to:
  /// **'Добавить правило'**
  String get connAddRule;

  /// No description provided for @connConnectionsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# соединение} few{# соединения} other{# соединений}}'**
  String connConnectionsCount(num count);

  /// No description provided for @dnsPreset.
  ///
  /// In ru, this message translates to:
  /// **'Пресет'**
  String get dnsPreset;

  /// No description provided for @dnsPresetCloudflare.
  ///
  /// In ru, this message translates to:
  /// **'Cloudflare'**
  String get dnsPresetCloudflare;

  /// No description provided for @dnsPresetGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Google'**
  String get dnsPresetGoogle;

  /// No description provided for @dnsPresetQuad9.
  ///
  /// In ru, this message translates to:
  /// **'Quad9'**
  String get dnsPresetQuad9;

  /// No description provided for @dnsPresetAdGuard.
  ///
  /// In ru, this message translates to:
  /// **'AdGuard'**
  String get dnsPresetAdGuard;

  /// No description provided for @dnsPresetCustom.
  ///
  /// In ru, this message translates to:
  /// **'Свой'**
  String get dnsPresetCustom;

  /// No description provided for @dnsCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить утечки'**
  String get dnsCheck;

  /// No description provided for @dnsChecking.
  ///
  /// In ru, this message translates to:
  /// **'Проверка...'**
  String get dnsChecking;

  /// No description provided for @dnsNoLeak.
  ///
  /// In ru, this message translates to:
  /// **'Утечек не найдено'**
  String get dnsNoLeak;

  /// No description provided for @dnsLeakFound.
  ///
  /// In ru, this message translates to:
  /// **'Обнаружена утечка'**
  String get dnsLeakFound;

  /// No description provided for @dnsLastCheck.
  ///
  /// In ru, this message translates to:
  /// **'Последняя проверка'**
  String get dnsLastCheck;

  /// No description provided for @dnsNeverChecked.
  ///
  /// In ru, this message translates to:
  /// **'Ещё не проверялось'**
  String get dnsNeverChecked;

  /// No description provided for @dnsLeakCheckTunnelDns.
  ///
  /// In ru, this message translates to:
  /// **'Резолверы DNS туннеля'**
  String get dnsLeakCheckTunnelDns;

  /// No description provided for @dnsLeakCheckSystemResolvers.
  ///
  /// In ru, this message translates to:
  /// **'Системные резолверы'**
  String get dnsLeakCheckSystemResolvers;

  /// No description provided for @dnsLeakCheckKillSwitchDns.
  ///
  /// In ru, this message translates to:
  /// **'Kill switch закрывает DNS'**
  String get dnsLeakCheckKillSwitchDns;

  /// No description provided for @dnsLeakFixConfigureTunnelDns.
  ///
  /// In ru, this message translates to:
  /// **'Задайте DNS туннеля в настройках выше.'**
  String get dnsLeakFixConfigureTunnelDns;

  /// No description provided for @dnsLeakFixReviewSystemResolvers.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте, какие резолверы система использует вне туннеля.'**
  String get dnsLeakFixReviewSystemResolvers;

  /// No description provided for @dnsLeakFixEnableKillSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Включите kill switch, чтобы DNS оставался в туннеле.'**
  String get dnsLeakFixEnableKillSwitch;

  /// No description provided for @dnsLeakCheckEncryptedDns.
  ///
  /// In ru, this message translates to:
  /// **'Зашифрованный DNS системы'**
  String get dnsLeakCheckEncryptedDns;

  /// No description provided for @dnsLeakCheckDnsSpoof.
  ///
  /// In ru, this message translates to:
  /// **'Подмена ответов DNS'**
  String get dnsLeakCheckDnsSpoof;

  /// No description provided for @dnsLeakFixReviewEncryptedDns.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте, какие конечные точки зашифрованного DNS система использует вне туннеля.'**
  String get dnsLeakFixReviewEncryptedDns;

  /// No description provided for @dnsLeakFixUseEncryptedDns.
  ///
  /// In ru, this message translates to:
  /// **'Используйте зашифрованный DNS (DoT или DoH) в туннеле, чтобы резолверы не могли подделывать ответы.'**
  String get dnsLeakFixUseEncryptedDns;

  /// No description provided for @dnsCheckNeedsConnection.
  ///
  /// In ru, this message translates to:
  /// **'Сначала подключитесь к VPN, затем проверьте утечки.'**
  String get dnsCheckNeedsConnection;

  /// No description provided for @dnsExpected.
  ///
  /// In ru, this message translates to:
  /// **'Ожидалось'**
  String get dnsExpected;

  /// No description provided for @dnsActual.
  ///
  /// In ru, this message translates to:
  /// **'Обнаружено'**
  String get dnsActual;

  /// No description provided for @sortBy.
  ///
  /// In ru, this message translates to:
  /// **'Сортировать'**
  String get sortBy;

  /// No description provided for @sortPing.
  ///
  /// In ru, this message translates to:
  /// **'Пинг'**
  String get sortPing;

  /// No description provided for @sortSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get sortSpeed;

  /// No description provided for @sortName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get sortName;

  /// No description provided for @measureSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Замерить скорость'**
  String get measureSpeed;

  /// No description provided for @benchmarkStale.
  ///
  /// In ru, this message translates to:
  /// **'устарело'**
  String get benchmarkStale;

  /// No description provided for @autoSelectMode.
  ///
  /// In ru, this message translates to:
  /// **'Автовыбор сервера'**
  String get autoSelectMode;

  /// No description provided for @autoSelectPing.
  ///
  /// In ru, this message translates to:
  /// **'Самый быстрый пинг'**
  String get autoSelectPing;

  /// No description provided for @autoSelectSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Самая высокая скорость'**
  String get autoSelectSpeed;

  /// No description provided for @autoSelectSmart.
  ///
  /// In ru, this message translates to:
  /// **'Умный выбор'**
  String get autoSelectSmart;

  /// No description provided for @coreWatchUnstable.
  ///
  /// In ru, this message translates to:
  /// **'Связь с ядром нестабильна'**
  String get coreWatchUnstable;

  /// No description provided for @watchReconnect.
  ///
  /// In ru, this message translates to:
  /// **'Переподключить'**
  String get watchReconnect;

  /// No description provided for @coreRestoringLink.
  ///
  /// In ru, this message translates to:
  /// **'Восстанавливаю связь с ядром…'**
  String get coreRestoringLink;

  /// No description provided for @crashRestoreTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прошлое соединение оборвалось'**
  String get crashRestoreTitle;

  /// No description provided for @restoreOnCrash.
  ///
  /// In ru, this message translates to:
  /// **'Восстанавливать сессию после сбоя'**
  String get restoreOnCrash;

  /// No description provided for @crashRestore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get crashRestore;

  /// No description provided for @crashDismiss.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get crashDismiss;

  /// No description provided for @overrideTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои правки'**
  String get overrideTitle;

  /// No description provided for @overrideEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать серверы'**
  String get overrideEdit;

  /// No description provided for @overrideHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get overrideHide;

  /// No description provided for @overrideUnhide.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get overrideUnhide;

  /// No description provided for @overrideClear.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить правки'**
  String get overrideClear;

  /// No description provided for @overrideEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет правок'**
  String get overrideEmpty;

  /// No description provided for @overrideCustomRules.
  ///
  /// In ru, this message translates to:
  /// **'Свои правила'**
  String get overrideCustomRules;

  /// No description provided for @errBenchmarkUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Для замера скорости нужна новая версия ядра'**
  String get errBenchmarkUnsupported;

  /// No description provided for @benchmarkProgress.
  ///
  /// In ru, this message translates to:
  /// **'Замер {done} из {total}…'**
  String benchmarkProgress(Object done, Object total);

  /// No description provided for @profiles.
  ///
  /// In ru, this message translates to:
  /// **'Сетевые профили'**
  String get profiles;

  /// No description provided for @profilesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Профилей пока нет. Создайте профиль, чтобы настройки применялись автоматически в известных сетях.'**
  String get profilesEmpty;

  /// No description provided for @profileAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить профиль'**
  String get profileAdd;

  /// No description provided for @profileName.
  ///
  /// In ru, this message translates to:
  /// **'Название профиля'**
  String get profileName;

  /// No description provided for @profileSsids.
  ///
  /// In ru, this message translates to:
  /// **'Wi-Fi-сети (SSID)'**
  String get profileSsids;

  /// No description provided for @profileSsidsHint.
  ///
  /// In ru, this message translates to:
  /// **'Дом, Офис — через запятую'**
  String get profileSsidsHint;

  /// No description provided for @profileGateways.
  ///
  /// In ru, this message translates to:
  /// **'Шлюзы'**
  String get profileGateways;

  /// No description provided for @profileAsns.
  ///
  /// In ru, this message translates to:
  /// **'Номера AS'**
  String get profileAsns;

  /// No description provided for @profileAutoApply.
  ///
  /// In ru, this message translates to:
  /// **'Применять автоматически'**
  String get profileAutoApply;

  /// No description provided for @profileAutoApplyHint.
  ///
  /// In ru, this message translates to:
  /// **'Если выключено — спрашивать перед применением'**
  String get profileAutoApplyHint;

  /// No description provided for @profileSnapshot.
  ///
  /// In ru, this message translates to:
  /// **'Запомнить текущие настройки'**
  String get profileSnapshot;

  /// No description provided for @profileSnapshotDone.
  ///
  /// In ru, this message translates to:
  /// **'Текущие настройки сохранены в профиль'**
  String get profileSnapshotDone;

  /// No description provided for @profileDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль'**
  String get profileDelete;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль «{name}»?'**
  String profileDeleteConfirm(Object name);

  /// No description provided for @profileApplyAsk.
  ///
  /// In ru, this message translates to:
  /// **'Применить профиль «{name}»?'**
  String profileApplyAsk(Object name);

  /// No description provided for @profileApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get profileApply;

  /// No description provided for @profileApplied.
  ///
  /// In ru, this message translates to:
  /// **'Профиль «{name}» применён'**
  String profileApplied(Object name);

  /// No description provided for @profileUndo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get profileUndo;

  /// No description provided for @profileActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get profileActive;

  /// No description provided for @networkNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас: {info}'**
  String networkNow(Object info);

  /// No description provided for @networkUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных о сети'**
  String get networkUnknown;

  /// No description provided for @profileNoTriggers.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы один триггер: SSID, шлюз или ASN'**
  String get profileNoTriggers;

  /// No description provided for @chains.
  ///
  /// In ru, this message translates to:
  /// **'Цепочки прокси'**
  String get chains;

  /// No description provided for @chainsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Цепочек пока нет. Свяжите 2–3 сервера, чтобы трафик шёл через каждый из них.'**
  String get chainsEmpty;

  /// No description provided for @chainAdd.
  ///
  /// In ru, this message translates to:
  /// **'Новая цепочка'**
  String get chainAdd;

  /// No description provided for @chainName.
  ///
  /// In ru, this message translates to:
  /// **'Название цепочки'**
  String get chainName;

  /// No description provided for @chainPickServers.
  ///
  /// In ru, this message translates to:
  /// **'Выберите 2–3 сервера'**
  String get chainPickServers;

  /// No description provided for @chainOrderHint.
  ///
  /// In ru, this message translates to:
  /// **'Перетащите, чтобы изменить порядок: трафик входит сверху, выходит снизу.'**
  String get chainOrderHint;

  /// No description provided for @chainTooFew.
  ///
  /// In ru, this message translates to:
  /// **'Выберите минимум 2 сервера'**
  String get chainTooFew;

  /// No description provided for @chainTooMany.
  ///
  /// In ru, this message translates to:
  /// **'В цепочке максимум 3 сервера'**
  String get chainTooMany;

  /// No description provided for @chainEstimate.
  ///
  /// In ru, this message translates to:
  /// **'Примерная задержка'**
  String get chainEstimate;

  /// No description provided for @chainSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить цепочку'**
  String get chainSave;

  /// No description provided for @chainDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить цепочку'**
  String get chainDelete;

  /// No description provided for @chainDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить цепочку «{name}»?'**
  String chainDeleteConfirm(Object name);

  /// No description provided for @chainUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Текущий движок не умеет строить цепочки'**
  String get chainUnsupported;

  /// No description provided for @chainHopMissing.
  ///
  /// In ru, this message translates to:
  /// **'Один из серверов цепочки больше недоступен'**
  String get chainHopMissing;

  /// No description provided for @chainHop.
  ///
  /// In ru, this message translates to:
  /// **'Хоп {n}'**
  String chainHop(Object n);

  /// No description provided for @chainEntry.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get chainEntry;

  /// No description provided for @chainExit.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get chainExit;

  /// No description provided for @sync.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация устройств'**
  String get sync;

  /// No description provided for @syncDevices.
  ///
  /// In ru, this message translates to:
  /// **'Мои устройства'**
  String get syncDevices;

  /// No description provided for @syncEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет спаренных устройств. Спарьте другое устройство в локальной сети.'**
  String get syncEmpty;

  /// No description provided for @syncPair.
  ///
  /// In ru, this message translates to:
  /// **'Спарить устройство'**
  String get syncPair;

  /// No description provided for @syncShowCode.
  ///
  /// In ru, this message translates to:
  /// **'Показать мой код'**
  String get syncShowCode;

  /// No description provided for @syncScanCode.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать код'**
  String get syncScanCode;

  /// No description provided for @syncRevoke.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать'**
  String get syncRevoke;

  /// No description provided for @syncRevokeConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать «{name}»?'**
  String syncRevokeConfirm(Object name);

  /// No description provided for @syncLastSync.
  ///
  /// In ru, this message translates to:
  /// **'Последняя синхронизация: {time}'**
  String syncLastSync(Object time);

  /// No description provided for @syncNever.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get syncNever;

  /// No description provided for @syncWhat.
  ///
  /// In ru, this message translates to:
  /// **'Что синхронизируется'**
  String get syncWhat;

  /// No description provided for @syncWhatBody.
  ///
  /// In ru, this message translates to:
  /// **'Подписки, правила, настройки и сетевые профили. Никогда не синхронизируются: локальные логи, IPC-токены.'**
  String get syncWhatBody;

  /// No description provided for @syncNoLan.
  ///
  /// In ru, this message translates to:
  /// **'Устройства должны быть в одной локальной сети'**
  String get syncNoLan;

  /// No description provided for @syncPaired.
  ///
  /// In ru, this message translates to:
  /// **'Устройство спарено'**
  String get syncPaired;

  /// No description provided for @syncPairingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спарить с этим устройством'**
  String get syncPairingTitle;

  /// No description provided for @syncWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание другого устройства…'**
  String get syncWaiting;

  /// No description provided for @syncSecureNote.
  ///
  /// In ru, this message translates to:
  /// **'Канал защищён сквозным шифрованием. Никаких аккаунтов и облачных серверов.'**
  String get syncSecureNote;

  /// No description provided for @zapretWithVpn.
  ///
  /// In ru, this message translates to:
  /// **'DPI-обход для прямого трафика'**
  String get zapretWithVpn;

  /// No description provided for @zapretWithVpnHint.
  ///
  /// In ru, this message translates to:
  /// **'Запускает zapret рядом с VPN-туннелем: туннелированный трафик идёт через VPN, прямой — через обход.'**
  String get zapretWithVpnHint;

  /// No description provided for @chainDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Каждый сервер — только один раз'**
  String get chainDuplicate;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get remove;

  /// No description provided for @autoSwitchOnDegrade.
  ///
  /// In ru, this message translates to:
  /// **'Автопереключение при деградации'**
  String get autoSwitchOnDegrade;

  /// No description provided for @autoSwitchOnDegradeDetail.
  ///
  /// In ru, this message translates to:
  /// **'Если выбранный сервер сильно замедлится или перестанет отвечать, Sora переключится на лучший из измеренных — не чаще одного раза в 10 минут.'**
  String get autoSwitchOnDegradeDetail;

  /// No description provided for @tunStackMixed.
  ///
  /// In ru, this message translates to:
  /// **'Смешанный'**
  String get tunStackMixed;

  /// No description provided for @tunStackSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системный'**
  String get tunStackSystem;

  /// No description provided for @censorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика блокировок'**
  String get censorTitle;

  /// No description provided for @censorHistory.
  ///
  /// In ru, this message translates to:
  /// **'История проверок'**
  String get censorHistory;

  /// No description provided for @censorEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Проверок пока не было. Если соединение не удастся установить, детектор проверит, не блокирует ли его провайдер.'**
  String get censorEmpty;

  /// No description provided for @censorExplainer.
  ///
  /// In ru, this message translates to:
  /// **'Это не ошибка приложения: похоже, провайдер ограничивает соединение. Маскировка меняет способ подключения и часто помогает.'**
  String get censorExplainer;

  /// No description provided for @censorNoProfile.
  ///
  /// In ru, this message translates to:
  /// **'Для этого вердикта нет подходящего профиля'**
  String get censorNoProfile;

  /// No description provided for @censorApplyProfile.
  ///
  /// In ru, this message translates to:
  /// **'Применить рекомендованный профиль'**
  String get censorApplyProfile;

  /// No description provided for @censorEnable.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get censorEnable;

  /// No description provided for @censorDetails.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get censorDetails;

  /// No description provided for @censorNotNow.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get censorNotNow;

  /// No description provided for @censorPromptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возможно, соединение блокируют'**
  String get censorPromptTitle;

  /// No description provided for @censorPromptBody.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, провайдер блокирует соединение (уверенность {confidence}%). Попробовать маскировку?'**
  String censorPromptBody(int confidence);

  /// No description provided for @censorConfidence.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность: {confidence}%'**
  String censorConfidence(int confidence);

  /// No description provided for @censorKindBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Блокировка обнаружена'**
  String get censorKindBlocked;

  /// No description provided for @censorKindLikely.
  ///
  /// In ru, this message translates to:
  /// **'Похоже на блокировку'**
  String get censorKindLikely;

  /// No description provided for @censorKindClear.
  ///
  /// In ru, this message translates to:
  /// **'Блокировка не обнаружена'**
  String get censorKindClear;

  /// No description provided for @censorKindUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить'**
  String get censorKindUnknown;

  /// No description provided for @censorReasonTlsReset.
  ///
  /// In ru, this message translates to:
  /// **'TLS-соединения сбрасываются — характерный признак фильтрации'**
  String get censorReasonTlsReset;

  /// No description provided for @censorReasonHttpBlock.
  ///
  /// In ru, this message translates to:
  /// **'HTTP-запросы блокируются'**
  String get censorReasonHttpBlock;

  /// No description provided for @censorReasonDnsSpoofed.
  ///
  /// In ru, this message translates to:
  /// **'DNS-ответы подменяются'**
  String get censorReasonDnsSpoofed;

  /// No description provided for @censorReasonConnectTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Соединения обрываются по таймауту'**
  String get censorReasonConnectTimeout;

  /// No description provided for @customServerAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить свой сервер'**
  String get customServerAdd;

  /// No description provided for @customServers.
  ///
  /// In ru, this message translates to:
  /// **'Мои серверы'**
  String get customServers;

  /// No description provided for @customServerName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get customServerName;

  /// No description provided for @customServerNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: мой VPS'**
  String get customServerNameHint;

  /// No description provided for @customServerNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get customServerNameRequired;

  /// No description provided for @customServerAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get customServerAddress;

  /// No description provided for @customServerAddressHint.
  ///
  /// In ru, this message translates to:
  /// **'example.com или 192.0.2.1'**
  String get customServerAddressHint;

  /// No description provided for @customServerAddressRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите адрес сервера'**
  String get customServerAddressRequired;

  /// No description provided for @customServerAddressInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный адрес'**
  String get customServerAddressInvalid;

  /// No description provided for @customServerPort.
  ///
  /// In ru, this message translates to:
  /// **'Порт'**
  String get customServerPort;

  /// No description provided for @customServerPortHint.
  ///
  /// In ru, this message translates to:
  /// **'443'**
  String get customServerPortHint;

  /// No description provided for @customServerPortInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Порт — число от 1 до 65535'**
  String get customServerPortInvalid;

  /// No description provided for @customServerProtocol.
  ///
  /// In ru, this message translates to:
  /// **'Протокол'**
  String get customServerProtocol;

  /// No description provided for @customServerCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Данные для входа'**
  String get customServerCredentials;

  /// No description provided for @customServerOptional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get customServerOptional;

  /// No description provided for @customServerShowSecret.
  ///
  /// In ru, this message translates to:
  /// **'Показать секрет'**
  String get customServerShowSecret;

  /// No description provided for @customServerHideSecret.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть секрет'**
  String get customServerHideSecret;

  /// No description provided for @customServerBadge.
  ///
  /// In ru, this message translates to:
  /// **'свой'**
  String get customServerBadge;

  /// No description provided for @flowAuto.
  ///
  /// In ru, this message translates to:
  /// **'авто'**
  String get flowAuto;

  /// No description provided for @customServerDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сервер «{name}»?'**
  String customServerDeleteConfirm(String name);

  /// No description provided for @customServerEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте сервер вручную: адрес, порт и протокол'**
  String get customServerEmptyHint;

  /// No description provided for @customServerTest.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get customServerTest;

  /// No description provided for @errObfsUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Установленный core слишком стар для профилей маскировки. Обновите Sora, чтобы применять их.'**
  String get errObfsUnsupported;

  /// No description provided for @leakTestTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка утечек'**
  String get leakTestTitle;

  /// No description provided for @leakTestIntro.
  ///
  /// In ru, this message translates to:
  /// **'Проверяет, может ли трафик покинуть устройство в обход туннеля: прямые DNS- и ICMP-запросы, утечки IPv6 и системные резолверы. Запускайте при активном подключении.'**
  String get leakTestIntro;

  /// No description provided for @leakTestRun.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get leakTestRun;

  /// No description provided for @leakTestCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get leakTestCancel;

  /// No description provided for @leakTestNeedsConnection.
  ///
  /// In ru, this message translates to:
  /// **'Подключитесь, чтобы проверить утечки.'**
  String get leakTestNeedsConnection;

  /// No description provided for @leakTestProgress.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено тестов: {count}'**
  String leakTestProgress(int count);

  /// No description provided for @leakTestAllClear.
  ///
  /// In ru, this message translates to:
  /// **'Утечек не найдено'**
  String get leakTestAllClear;

  /// No description provided for @leakTestFound.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Найдена # утечка} few{Найдены # утечки} other{Найдено # утечек}}'**
  String leakTestFound(int count);

  /// No description provided for @leakTestSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Пропущен — неприменим в этой сессии'**
  String get leakTestSkipped;

  /// No description provided for @leakTestFix.
  ///
  /// In ru, this message translates to:
  /// **'Исправить'**
  String get leakTestFix;

  /// No description provided for @leakTestFixedNote.
  ///
  /// In ru, this message translates to:
  /// **'Kill switch включён — запустите проверку снова.'**
  String get leakTestFixedNote;

  /// No description provided for @leakTestCheckDirectDns.
  ///
  /// In ru, this message translates to:
  /// **'Прямой DNS'**
  String get leakTestCheckDirectDns;

  /// No description provided for @leakTestCheckIcmpEcho.
  ///
  /// In ru, this message translates to:
  /// **'ICMP echo'**
  String get leakTestCheckIcmpEcho;

  /// No description provided for @leakTestCheckIpv6.
  ///
  /// In ru, this message translates to:
  /// **'IPv6'**
  String get leakTestCheckIpv6;

  /// No description provided for @leakTestCheckSystemResolvers.
  ///
  /// In ru, this message translates to:
  /// **'Системные резолверы'**
  String get leakTestCheckSystemResolvers;

  /// No description provided for @leakTestCheckTunnelConnectivity.
  ///
  /// In ru, this message translates to:
  /// **'Связность туннеля'**
  String get leakTestCheckTunnelConnectivity;

  /// No description provided for @leakTestCheckTunnelDns.
  ///
  /// In ru, this message translates to:
  /// **'DNS через туннель'**
  String get leakTestCheckTunnelDns;

  /// No description provided for @noticeDegraded.
  ///
  /// In ru, this message translates to:
  /// **'Сервер замедлился — переключено на лучший из измеренных'**
  String get noticeDegraded;

  /// No description provided for @obfs.
  ///
  /// In ru, this message translates to:
  /// **'Маскировка трафика'**
  String get obfs;

  /// No description provided for @obfsPreset.
  ///
  /// In ru, this message translates to:
  /// **'Пресет'**
  String get obfsPreset;

  /// No description provided for @obfsPresetAggressive.
  ///
  /// In ru, this message translates to:
  /// **'Максимальная маскировка'**
  String get obfsPresetAggressive;

  /// No description provided for @obfsPresetBalanced.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get obfsPresetBalanced;

  /// No description provided for @obfsPresetOff.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get obfsPresetOff;

  /// No description provided for @obfsPresetCustom.
  ///
  /// In ru, this message translates to:
  /// **'Вручную'**
  String get obfsPresetCustom;

  /// No description provided for @obfsManual.
  ///
  /// In ru, this message translates to:
  /// **'Ручные настройки'**
  String get obfsManual;

  /// No description provided for @obfsUtls.
  ///
  /// In ru, this message translates to:
  /// **'uTLS-профиль'**
  String get obfsUtls;

  /// No description provided for @obfsUtlsAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get obfsUtlsAuto;

  /// No description provided for @obfsJitter.
  ///
  /// In ru, this message translates to:
  /// **'Джиттер'**
  String get obfsJitter;

  /// No description provided for @obfsJitterNeedsFragment.
  ///
  /// In ru, this message translates to:
  /// **'Джиттер работает только при включённой фрагментации.'**
  String get obfsJitterNeedsFragment;

  /// No description provided for @obfsFineTune.
  ///
  /// In ru, this message translates to:
  /// **'Размеры и задержки'**
  String get obfsFineTune;

  /// No description provided for @obfsDetecting.
  ///
  /// In ru, this message translates to:
  /// **'Определение возможностей…'**
  String get obfsDetecting;

  /// No description provided for @obfsCapabilities.
  ///
  /// In ru, this message translates to:
  /// **'Возможности движка'**
  String get obfsCapabilities;

  /// No description provided for @obfsCompatibleEngines.
  ///
  /// In ru, this message translates to:
  /// **'Совместимые движки: {engines}'**
  String obfsCompatibleEngines(String engines);

  /// No description provided for @obfsSupported.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживается'**
  String get obfsSupported;

  /// No description provided for @obfsUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Не поддерживается'**
  String get obfsUnsupported;

  /// No description provided for @obfsUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Возможности пока определяются.'**
  String get obfsUnknown;

  /// No description provided for @syncCodeExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия кода истёк'**
  String get syncCodeExpired;

  /// No description provided for @syncDaemonFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить службу синхронизации'**
  String get syncDaemonFailed;

  /// No description provided for @syncDaemonMissing.
  ///
  /// In ru, this message translates to:
  /// **'Компонент sora-sync не найден. Переустановите приложение, чтобы включить синхронизацию устройств.'**
  String get syncDaemonMissing;

  /// No description provided for @syncDaemonStarting.
  ///
  /// In ru, this message translates to:
  /// **'Запуск службы синхронизации…'**
  String get syncDaemonStarting;

  /// No description provided for @syncErrAuth.
  ///
  /// In ru, this message translates to:
  /// **'Служба синхронизации отклонила токен доступа. Перезапустите приложение и попробуйте снова.'**
  String get syncErrAuth;

  /// No description provided for @syncErrNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Устройство больше не спарено'**
  String get syncErrNotFound;

  /// No description provided for @syncErrPairingActive.
  ///
  /// In ru, this message translates to:
  /// **'Сессия спаривания уже открыта'**
  String get syncErrPairingActive;

  /// No description provided for @syncErrUnreachable.
  ///
  /// In ru, this message translates to:
  /// **'Другое устройство не отвечает. Убедитесь, что оно в той же сети и показывает свой код.'**
  String get syncErrUnreachable;

  /// No description provided for @syncError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка синхронизации'**
  String get syncError;

  /// No description provided for @syncExpiresIn.
  ///
  /// In ru, this message translates to:
  /// **'Код истечёт через {duration}'**
  String syncExpiresIn(String duration);

  /// No description provided for @syncJoining.
  ///
  /// In ru, this message translates to:
  /// **'Спаривание с устройством…'**
  String get syncJoining;

  /// No description provided for @syncLegacyCleared.
  ///
  /// In ru, this message translates to:
  /// **'Старый список устройств никогда не был по-настоящему спарен, поэтому он очищен. Спарьте устройства заново — теперь по-настоящему.'**
  String get syncLegacyCleared;

  /// No description provided for @syncNewCode.
  ///
  /// In ru, this message translates to:
  /// **'Новый код'**
  String get syncNewCode;

  /// No description provided for @syncPairedWith.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» спарено'**
  String syncPairedWith(String name);

  /// No description provided for @syncRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get syncRetry;

  /// No description provided for @syncStopShowing.
  ///
  /// In ru, this message translates to:
  /// **'Прекратить показ'**
  String get syncStopShowing;

  /// No description provided for @syncSyncNow.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировать'**
  String get syncSyncNow;

  /// No description provided for @syncSyncResult.
  ///
  /// In ru, this message translates to:
  /// **'Получено: {pulled} · отправлено: {pushed}'**
  String syncSyncResult(int pulled, int pushed);

  /// No description provided for @syncResultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Результат синхронизации'**
  String get syncResultTitle;

  /// No description provided for @syncPulled.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get syncPulled;

  /// No description provided for @syncPushed.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get syncPushed;

  /// No description provided for @syncNoChanges.
  ///
  /// In ru, this message translates to:
  /// **'Нет изменений'**
  String get syncNoChanges;

  /// No description provided for @syncDocKindSubscriptions.
  ///
  /// In ru, this message translates to:
  /// **'Подписки'**
  String get syncDocKindSubscriptions;

  /// No description provided for @syncDocKindSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get syncDocKindSettings;

  /// No description provided for @syncDocKindOverrides.
  ///
  /// In ru, this message translates to:
  /// **'Переопределения подписок'**
  String get syncDocKindOverrides;

  /// No description provided for @syncDocKindProfiles.
  ///
  /// In ru, this message translates to:
  /// **'Сетевые профили'**
  String get syncDocKindProfiles;

  /// No description provided for @syncDocKindChains.
  ///
  /// In ru, this message translates to:
  /// **'Цепочки прокси'**
  String get syncDocKindChains;

  /// No description provided for @syncDocKindObfs.
  ///
  /// In ru, this message translates to:
  /// **'Маскировка трафика'**
  String get syncDocKindObfs;

  /// No description provided for @syncFrom.
  ///
  /// In ru, this message translates to:
  /// **'с {name}'**
  String syncFrom(String name);

  /// No description provided for @syncThisDevice.
  ///
  /// In ru, this message translates to:
  /// **'Это устройство'**
  String get syncThisDevice;

  /// No description provided for @syncUnavailableAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация устройств пока недоступна на Android — там не может работать служба синхронизации.'**
  String get syncUnavailableAndroid;

  /// No description provided for @smartPickReason.
  ///
  /// In ru, this message translates to:
  /// **'Выбран умным режимом: пинг {ping}, скорость {speed}'**
  String smartPickReason(String ping, String speed);

  /// No description provided for @serverReliability.
  ///
  /// In ru, this message translates to:
  /// **'Надёжность {pct}%'**
  String serverReliability(int pct);

  /// No description provided for @customServerShadowsocksCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Для Shadowsocks: метод:пароль, например chacha20-ietf-poly1305:пароль'**
  String get customServerShadowsocksCredentials;

  /// No description provided for @diagnosticPackets.
  ///
  /// In ru, this message translates to:
  /// **'Захват пакетов'**
  String get diagnosticPackets;

  /// No description provided for @diagnosticEvents.
  ///
  /// In ru, this message translates to:
  /// **'События Windows'**
  String get diagnosticEvents;

  /// No description provided for @diagnosticCapture.
  ///
  /// In ru, this message translates to:
  /// **'Записать 10 секунд'**
  String get diagnosticCapture;

  /// No description provided for @diagnosticRequiresTun.
  ///
  /// In ru, this message translates to:
  /// **'Для захвата пакетов нужно активное TUN-подключение Sora.'**
  String get diagnosticRequiresTun;

  /// No description provided for @diagnosticUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Эта диагностика недоступна на данной платформе.'**
  String get diagnosticUnavailable;

  /// No description provided for @extErrRevoked.
  ///
  /// In ru, this message translates to:
  /// **'Команда Sora отозвала эту версию расширения: она небезопасна или сломана.'**
  String get extErrRevoked;

  /// No description provided for @extErrRevocationsExpired.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить список отозванных расширений. Установка недоступна, пока он не обновится: проверьте сеть и попробуйте снова.'**
  String get extErrRevocationsExpired;

  /// No description provided for @extRevokedDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключены отозванные расширения: {names}'**
  String extRevokedDisabled(String names);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'az',
    'be',
    'bn',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'hy',
    'id',
    'it',
    'ja',
    'ka',
    'kk',
    'ko',
    'ky',
    'pl',
    'pt',
    'ru',
    'tg',
    'th',
    'tk',
    'tr',
    'uk',
    'ur',
    'uz',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return SZhHans();
          case 'Hant':
            return SZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'az':
      return SAz();
    case 'be':
      return SBe();
    case 'bn':
      return SBn();
    case 'de':
      return SDe();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'fa':
      return SFa();
    case 'fr':
      return SFr();
    case 'hi':
      return SHi();
    case 'hy':
      return SHy();
    case 'id':
      return SId();
    case 'it':
      return SIt();
    case 'ja':
      return SJa();
    case 'ka':
      return SKa();
    case 'kk':
      return SKk();
    case 'ko':
      return SKo();
    case 'ky':
      return SKy();
    case 'pl':
      return SPl();
    case 'pt':
      return SPt();
    case 'ru':
      return SRu();
    case 'tg':
      return STg();
    case 'th':
      return STh();
    case 'tk':
      return STk();
    case 'tr':
      return STr();
    case 'uk':
      return SUk();
    case 'ur':
      return SUr();
    case 'uz':
      return SUz();
    case 'vi':
      return SVi();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
