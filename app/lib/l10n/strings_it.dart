// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

  @override
  String get stateOff => 'Non connesso';

  @override
  String get stateConnecting => 'Connessione';

  @override
  String get stateConnected => 'Collegata';

  @override
  String get stateReconnecting => 'Riconnessione';

  @override
  String get stateDisconnecting => 'Disconnessione';

  @override
  String get stateFailed => 'Non connesso';

  @override
  String get coreMissing => 'Il servizio Sora non risponde';

  @override
  String get serverAuto => 'Il più veloce';

  @override
  String get serverBypass => 'Nessun server';

  @override
  String get addSubscription => 'Aggiungi abbonamento';

  @override
  String get servers => 'Server';

  @override
  String get settings => 'Impostazioni';

  @override
  String get subscription => 'Sottoscrizione';

  @override
  String get subscriptionLink => 'Collegamento di abbonamento';

  @override
  String get add => 'Aggiungere';

  @override
  String get refresh => 'Aggiornamento';

  @override
  String get rename => 'Rinominare';

  @override
  String get delete => 'Eliminare';

  @override
  String get cancel => 'Cancellare';

  @override
  String get save => 'Salva';

  @override
  String get name => 'Nome';

  @override
  String deleteSubscription(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get routes => 'Percorsi';

  @override
  String get presetGlobal => 'Tutto tramite VPN';

  @override
  String get presetRu => 'Russia diretta';

  @override
  String get presetIr => 'Direttamente dall\'Iran';

  @override
  String get presetCn => 'Direttamente dalla Cina';

  @override
  String get blockAds => 'Blocca gli annunci';

  @override
  String get killSwitch => 'Internet solo tramite VPN';

  @override
  String get engine => 'Motore';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animazioni';

  @override
  String get logs => 'Tronco d\'albero';

  @override
  String get about => 'Di';

  @override
  String get logsAll => 'Tutto';

  @override
  String get logsImportant => 'Importante';

  @override
  String get logsErrors => 'Errori';

  @override
  String get search => 'Ricerca';

  @override
  String get export => 'Salva su file';

  @override
  String get clear => 'Chiara';

  @override
  String get logsEmpty => 'Niente qui';

  @override
  String appVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get notInstalled => 'Non installato';

  @override
  String get sourceCode => 'Codice sorgente';

  @override
  String get license => 'Licenza';

  @override
  String usage(String used, String total) {
    return '$used di $total';
  }

  @override
  String until(String date) {
    return 'fino a $date';
  }

  @override
  String get expired => 'Scaduta';

  @override
  String milliseconds(int n) {
    return '${n}ms';
  }

  @override
  String bytesB(String n) {
    return '$n B';
  }

  @override
  String bytesKB(String n) {
    return '${n}KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n GB';
  }

  @override
  String bytesTB(String n) {
    return '${n}TB';
  }

  @override
  String get errGeneric => 'Qualcosa è andato storto';

  @override
  String get errCore => 'Il servizio Sora non risponde';

  @override
  String get errAuth => 'Nessun accesso al servizio Sora';

  @override
  String get errVersion => 'Aggiornamento Sora: l\'app e il servizio sono versioni diverse';

  @override
  String get errBusy => 'Aspetta, il comando precedente è ancora in esecuzione';

  @override
  String get errEngineMissing => 'Nessun motore trovato per questo server';

  @override
  String get errEngineStart => 'Il motore non si è avviato';

  @override
  String get errEngineStopped => 'Il motore si fermò';

  @override
  String get errTunnel => 'Nessuna autorizzazione per creare la connessione VPN';

  @override
  String get errServers => 'Il server è configurato con un errore';

  @override
  String get errNetwork => 'Impossibile raggiungere il server';

  @override
  String get errTimeout => 'Il server non ha risposto in tempo';

  @override
  String get errFirewall => 'Impossibile bloccare Internet al di fuori della VPN';

  @override
  String get errSubFetch => 'Impossibile caricare l\'abbonamento';

  @override
  String get errSubFormat => 'Questo non è un collegamento di abbonamento';

  @override
  String get errSubEmpty => 'L\'abbonamento non ha server';

  @override
  String get errSubDuplicate => 'Questo abbonamento è già stato aggiunto';

  @override
  String get errSubLimit => 'Troppi abbonamenti';

  @override
  String get errSubScheme => 'Il collegamento deve iniziare con https://';

  @override
  String get errSecretStore => 'Lo spazio di archiviazione Sora è danneggiato o non disponibile';

  @override
  String get errNoServers => 'Aggiungi un abbonamento per connetterti';

  @override
  String get exportText => 'Testo';

  @override
  String get connections => 'Connessioni';

  @override
  String get close => 'Vicina';

  @override
  String get chainDirect => 'Diretto';

  @override
  String get chainBlocked => 'Bloccata';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Leggera';

  @override
  String get themeDark => 'Buia';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Connessione';

  @override
  String get sectionNoServer => 'Nessun server';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostica';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Indirizzi separati da virgole';

  @override
  String get fragment => 'Frammentazione TLS';

  @override
  String get fragmentPackets => 'Cosa dividere';

  @override
  String get fragmentLength => 'Dimensione del pezzo';

  @override
  String get fragmentInterval => 'Pausa tra i pezzi';

  @override
  String get byDefault => 'Predefinita';

  @override
  String get rangeHint => 'Ad esempio, 100-200';

  @override
  String get splitPos => 'Posizioni divise';

  @override
  String get splitPosHint => 'Ad esempio, 1, midsld';

  @override
  String get disorder => 'Riordina i pezzi';

  @override
  String get tlsRecord => 'Dividi il record TLS';

  @override
  String get tlsRecordNo => 'NO';

  @override
  String get tlsRecordSni => 'Al nome del sito';

  @override
  String get tlsRecordFirst => 'Dopo il primo byte';

  @override
  String get hostCase => 'Cambia caso Host';

  @override
  String get probeMethod => 'Metodo';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Attraverso il motore';

  @override
  String get probeConnect => 'Solo connessione';

  @override
  String get probeUrl => 'Indirizzo di prova';

  @override
  String get probeTimeout => 'Aspettare';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Abbonamenti';

  @override
  String get subscriptionSettings => 'Impostazioni';

  @override
  String get userAgent => 'Agente utente';

  @override
  String get autoUpdate => 'Aggiorna automaticamente';

  @override
  String get updateInterval => 'Quante volte';

  @override
  String get intervalProvider => 'Come chiede il fornitore';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Aggiorna ora';

  @override
  String get logLevel => 'Cosa registrare';

  @override
  String get levelDebug => 'Qualunque cosa';

  @override
  String get levelInfo => 'Al solito';

  @override
  String get levelWarning => 'Importante';

  @override
  String get levelError => 'Solo errori';

  @override
  String get recordDestinations => 'Registra gli indirizzi dei siti';

  @override
  String get reset => 'Ripristina le impostazioni';

  @override
  String get resetConfirm => 'Ripristinare tutte le impostazioni?';

  @override
  String get resetAction => 'Reset';

  @override
  String get invalidValue => 'Questo valore non funzionerà';

  @override
  String get website => 'Pagina di abbonamento';

  @override
  String get providerWebsite => 'Sito web del fornitore';

  @override
  String get support => 'Supporto';

  @override
  String controlPortQuestion(String engine) {
    return '$engine è controllato tramite una porta su questo computer. Altri programmi saranno in grado di dire che una VPN è attiva.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Scegli $engine';
  }

  @override
  String get rules => 'Regole personalizzate';

  @override
  String get ruleAdd => 'Nuova regola';

  @override
  String get ruleHint => 'Sito, IP o programma';

  @override
  String get ruleDirect => 'Diretto';

  @override
  String get ruleProxy => 'Tramite VPN';

  @override
  String get ruleBlock => 'Bloccare';

  @override
  String get failover => 'Accensione in caso di guasto';

  @override
  String get connectOnStart => 'Connetti all\'avvio';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'l\'abbonamento termina tra # giorni',
      one: 'l\'abbonamento termina il giorno #',
      zero: 'l\'abbonamento scade tra poche ore',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left sinistra';
  }

  @override
  String get ruleInvalid => 'Questo non sembra un sito, un IP o un programma';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I server #, a loro volta',
      one: 'Server #, a sua volta',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Server #, i più veloci',
      one: 'Server #, il più veloce',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modalità';

  @override
  String get tunnelTun => 'Tutto il traffico';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'Indirizzo proxy';

  @override
  String get copied => 'Copiato';

  @override
  String get launchAtLogin => 'Cominciamo dal sistema';

  @override
  String get closeToTray => 'Conservare nella vaschetta quando è chiuso';

  @override
  String get notifications => 'Notifiche';

  @override
  String get trayOpen => 'Apri Sora';

  @override
  String get trayConnect => 'Collegare';

  @override
  String get trayDisconnect => 'Disconnetti';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Esci da Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora è ancora nel vassoio';

  @override
  String get noticeInTrayBody => 'Esci dal menu della sua icona';

  @override
  String get noticeLost => 'Connessione persa';

  @override
  String get noticeLostBody => 'Sora si sta ricollegando';

  @override
  String get noticeRestored => 'Connesso di nuovo';

  @override
  String get noticeFailed => 'Impossibile connettersi';

  @override
  String get noticeBackup => 'Il server principale non ha risposto; il backup trasporta il traffico';

  @override
  String get noticeNext => 'Il server non ha risposto; il successivo trasporta il traffico';

  @override
  String get noticeMainBack => 'Il server principale risponde di nuovo e trasporta il traffico';

  @override
  String get noticeSubscription => 'Sottoscrizione';

  @override
  String get importTitle => 'Aggiungere questo abbonamento?';

  @override
  String get importSealed =>
      'Questo collegamento è crittografato per Happ e solo Happ può leggerlo. Chiedi al tuo provider il semplice collegamento di abbonamento.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'nessuna risposta';

  @override
  String get home => 'Casa';

  @override
  String get navRules => 'Regole';

  @override
  String get navConnections => 'Connessioni';

  @override
  String get navLogs => 'Registri';

  @override
  String get navAbout => 'Di';

  @override
  String get sidebarToggle => 'Attiva/disattiva la barra laterale';

  @override
  String get more => 'Di più';

  @override
  String get less => 'Meno';

  @override
  String get currentServer => 'Server attuale';

  @override
  String get trafficDown => 'Scaricata';

  @override
  String get trafficUp => 'Caricato';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Regole attive: $count';
  }

  @override
  String get recentNotifications => 'Notifiche recenti';

  @override
  String get notificationsEmpty => 'Gli eventi di connessione e abbonamento verranno visualizzati qui';

  @override
  String get retryConnect => 'Riprovare la connessione';

  @override
  String get openLogs => 'Apri i log';

  @override
  String get tourReplay => 'Mostra di nuovo la guida';

  @override
  String tourStep(int step) {
    return 'Passaggio $step di 5';
  }

  @override
  String get tourBack => 'Indietro';

  @override
  String get tourNext => 'Prossima';

  @override
  String get tourSkip => 'Saltare';

  @override
  String get tourFinish => 'Fatto';

  @override
  String get tourAdd => 'Aggiungi il link di abbonamento del tuo provider.';

  @override
  String get tourServer => 'Scegli un server. \"Il più veloce\" ne seleziona uno per te.';

  @override
  String get tourConnect => 'Clicca qui per connetterti o disconnetterti.';

  @override
  String get tourMode => 'Scegli una modalità. Il kill switch blocca Internet se la VPN si interrompe.';

  @override
  String get tourSettings => 'Apri le impostazioni. Puoi riprodurre questa guida lì.';

  @override
  String get chooseProgram => 'Scegli un programma';

  @override
  String get installedApps => 'Applicazioni installate';

  @override
  String get runningProcesses => 'Processi in esecuzione';

  @override
  String get programsFailed => 'Impossibile caricare le applicazioni';

  @override
  String get programsEmpty => 'Nessuna applicazione trovata. Prova un altro nome.';

  @override
  String get selectExe => 'Scegli un file .exe';

  @override
  String get trafficUnavailable => 'I contatori non sono ancora disponibili';

  @override
  String get speedtest => 'Velocità';

  @override
  String get speedtestCheck => 'Controlla la velocità';

  @override
  String get speedtestSearch => 'Trova un servizio';

  @override
  String get speedtestEmpty => 'Nessuna corrispondenza. Cambia la ricerca.';

  @override
  String get speedtestBackToList => 'Torniamo ai servizi';

  @override
  String get speedtestOpenBrowser => 'Apri nel browser';

  @override
  String get speedtestUnavailable =>
      'Impossibile avviare il browser incorporato. Apri il servizio nel browser di sistema.';

  @override
  String get speedtestPageFailed =>
      'Impossibile caricare la pagina. Ricaricalo o apri il servizio nel browser di sistema.';

  @override
  String get speedtestExternalFailed => 'Impossibile aprire il browser di sistema. Riprova.';

  @override
  String get modes => 'Modalità';

  @override
  String get proxyShort => 'Procura';

  @override
  String get tunMode => 'Tutto il traffico (TUN)';

  @override
  String get checkUpdates => 'Controlla gli aggiornamenti';

  @override
  String get updates => 'Aggiornamenti dell\'app';

  @override
  String updateAvailable(String version) {
    return 'È disponibile la versione $version';
  }

  @override
  String get updateOpenAbout => 'Visualizza aggiornamento';

  @override
  String updateNotes(String version) {
    return 'Modifiche in $version';
  }

  @override
  String get updateCheck => 'Controlla gli aggiornamenti';

  @override
  String get updateChecking => 'Controllo...';

  @override
  String get updateNoNotes => 'Il comunicato non ha note.';

  @override
  String get updateDropWarning =>
      'La connessione VPN verrà interrotta per alcuni secondi durante l\'aggiornamento di Sora e del suo core. Continuare?';

  @override
  String get updateWaitConnection => 'Attendi che la connessione VPN e il core siano pronti.';

  @override
  String get updateDownloading => 'Download e verifica dei file...';

  @override
  String get updateInstalling =>
      'Preparazione dell\'aggiornamento o attesa dell\'autenticazione dell\'amministratore...';

  @override
  String get updateNetworkError => 'Impossibile scaricare l\'aggiornamento. Riprova.';

  @override
  String get updateReleaseError => 'I dati di rilascio o i file richiesti mancano o non sono validi.';

  @override
  String get updateChecksumError => 'Il download non corrisponde a SHA256SUMS. Non è stato installato nulla.';

  @override
  String get updateInstallError =>
      'L\'aggiornamento non è terminato. L\'autenticazione potrebbe essere stata annullata.';

  @override
  String get updateUnsupported =>
      'Questo eseguibile non è di proprietà di una coppia di pacchetti Sora supportata. Utilizzare le istruzioni di installazione della versione.';

  @override
  String get updateManual =>
      'Esegui questo comando in un terminale per installare entrambi i pacchetti verificati, quindi riapri Sora. I file rimangono nella directory di download. La connessione VPN verrà interrotta.';

  @override
  String get updateCopyCommand => 'Copia comando';

  @override
  String get updateChecksDisabled => 'I controlli automatici sono disabilitati nelle Impostazioni.';

  @override
  String get updateInstalled => 'Aggiornamento installato. Riapri Sora.';

  @override
  String get projectLinks => 'Progetto';

  @override
  String get githubReleases => 'Uscite e download';

  @override
  String get telegramChannel => 'Canale Telegram';

  @override
  String get licenses => 'Licenze';

  @override
  String get componentLicenses => 'Licenze dei componenti';

  @override
  String get appCopyright => '© 2026 levvs-one e collaboratori';

  @override
  String get collapseServers => 'Comprimi i server';

  @override
  String get expandServers => 'Espandi i server';

  @override
  String get hideDescription => 'Nascondi descrizione';

  @override
  String get showDescription => 'Mostra descrizione';

  @override
  String get pendingConnectionChanges => 'Riconnettiti per applicare queste modifiche.';

  @override
  String get reconnectNow => 'Applicare e riconnettersi';

  @override
  String get bypassLimitations =>
      'Questa modalità ignora DPI solo per HTTP e TLS, non supporta UDP né modifica il tuo IP. Utilizza un server VPN per voce Discord, chiamate e indirizzi Telegram bloccati.';

  @override
  String get errEngineUnsupported =>
      'Il motore selezionato non supporta questo profilo o impostazioni. Scegli Auto o un motore compatibile.';

  @override
  String get errRestore =>
      'La pulizia della connessione era incompleta. Riprovare a disconnettersi; vedere il registro per i dettagli.';

  @override
  String get errSessionEnded => 'Questa sessione è già terminata. Aggiorna lo stato della connessione.';

  @override
  String get retryDisconnect => 'Riprovare a disconnettersi';

  @override
  String get tunStack => 'Pila TUN';

  @override
  String get modesInfo => 'A proposito di modalità';

  @override
  String get modesGuideTitle => 'Modalità e motori';

  @override
  String get modesGuide =>
      'Scegli Auto se non sei sicuro di quale motore abbia bisogno il tuo server. Sora controlla il profilo e le impostazioni prima della connessione. Un motore non può aumentare la larghezza di banda del tuo piano: le prestazioni dipendono dal server, dal percorso, dal protocollo e dalla rete.\n\n## Modalità\n\n### Tutto il traffico (TUN)\n\nSora crea un\'interfaccia di rete virtuale e instrada il traffico delle applicazioni attraverso di essa, inclusi TCP e UDP. Utilizzare questa modalità per Telegram, giochi e voce Discord. Le regole possono inviare direttamente siti o programmi specifici o bloccarli. Il servizio di rete necessita dell\'autorizzazione e di un server che supporti il ​​protocollo richiesto.\n\n###Proxy System\n\nSora configura un proxy HTTP/SOCKS locale. Le applicazioni che rispettano le impostazioni proxy del sistema lo utilizzano. Le applicazioni con il proprio stack di rete possono connettersi direttamente; UDP e le chiamate vocali generalmente necessitano di TUN. Questa modalità è adatta ai browser e alle applicazioni con supporto proxy.\n\n### Nessun server\n\nSu Linux, Sora utilizza [zapret](https://github.com/bol-van/zapret) per dividere e rimodellare le richieste HTTP/TLS e ignorare alcuni controlli DPI. Il tuo IP rimane lo stesso e le connessioni vanno direttamente al sito web. I risultati dipendono dal tuo provider e dal metodo di blocco.\n\nL\'integrazione attuale utilizza tpws per HTTP e TLS su TCP. Non bypassa il blocco IP né inoltra UDP e non può garantire le connessioni MTProto di Telegram. Utilizza un server VPN con TUN per voce Discord, chiamate Telegram e questo tipo di restrizioni.\n\n## Motori\n\n### Automatico\n\nSora seleziona un motore installato che supporta l\'intero piano di connessione: protocolli server, trasporti, gruppi, frammentazione e modalità. Una scelta manuale incompatibile viene rifiutata prima di interrompere la connessione corrente. Scegli Auto o un altro motore e applica nuovamente le impostazioni.\n\n###sing-box\n\nI nuovi pacchetti Sora includono [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), un fork di [sing-box](https://github.com/SagerNet/sing-box), aggiungendo XHTTP e VLESS Encryption lato client. Sora riconosce la build e le sue capacità. Una build upstream senza XHTTP non ottiene questa funzionalità solo dal suo nome.\n\nI protocolli supportati includono VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard e i parametri AmneziaWG 1.x/2.x Sora può importare. I profili JSON Xray completi richiedono Xray. I nuovi campi AWG 3.x non possono ancora essere importati. sing-box utilizza una porta di controllo locale protetta da password, che può essere rilevata da altre applicazioni sul computer.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) supporta VLESS, REALITY, XHTTP, VLESS Encryption e la frammentazione TLS. Esegue inoltre i profili Xray completi del provider preservandone il routing e i gruppi. Tali profili non possono essere convertiti automaticamente in un altro motore senza modificarne il comportamento.\n\nLo Xray in bundle ha rimosso l\'impostazione che disabilita la verifica del certificato TLS (`allowInsecure`). Seleziona automaticamente sing-box o mihomo per i server ordinari che richiedono questa impostazione. La selezione di Xray segnala manualmente l\'incompatibilità prima di interrompere la connessione corrente. I profili JSON completi meno recenti necessitano di un profilo provider aggiornato con un certificato verificabile o un pin del certificato.\n\n###mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) supporta i gruppi di fallback e bilanciamento del carico ordinati, XHTTP e AmneziaWG. Sceglilo quando è importante il failover automatico su un server di backup. L\'impostazione di frammentazione TLS di Sora non è disponibile con questo motore.\n\n## Compatibilità con Sora\n\n| Caratteristica | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN e TCP/UDP | Sì | Sì | Sì |\n| XHTTP | Sì | Sì | Sì |\n| VLESS Encryption | Sì | Sì | Sì |\n| Profilo completo Xray | No | Sì | No |\n| TUIC / AnyTLS | Entrambi | No | TUIC |\n| Frammentazione TLS | Sì | Sì | No |\n| AmneziaWG 1.x/2.x | Sì¹ | No | Sì |\n| Gruppo di fallback ordinato | No | No² | Sì |\n\n¹ I profili con J1/J2/J3/Itime utilizzano mihomo; questi campi non devono mai essere scartati silenziosamente. ² Per un gruppo di profili Xray completi, l\'app seleziona un profilo di backup. Il supporto dipende dalla build installata; controlla la sua versione in Informazioni.\n\n## Pila TUN\n\nLo stack gestisce TCP e UDP all\'interno dell\'interfaccia virtuale. Nel pannello delle modalità, Xray e mihomo offrono gVisor, System, Mixed e MIPS. Ogni motore salva la propria preferenza. Il proxy System e le modalità Serverless non utilizzano questa preferenza.\n\n- **Mixed**: TCP utilizza lo stack di sistema, mentre gVisor gestisce UDP. Questa è l\'impostazione predefinita per mihomo su Linux. Su Windows, Xray e mihomo usano MIPS per impostazione predefinita.\n- **System**: utilizza lo stack di sistema. Prova un\'altra opzione se le applicazioni di rete riscontrano problemi.\n- **gVisor**: gestisce il traffico nello spazio utente.\n- **MIPS**: stack IP di mihomo, disponibile nella versione in bundle 1.19.32.\n\nSu Linux, Xray utilizza il gVisor integrato per impostazione predefinita. System, Mixed e MIPS su Linux utilizzano mihomo come motore TUN, inoltrando TCP e UDP a Xray su un collegamento SOCKS locale autenticato. Xray conserva il protocollo, il profilo del provider e il routing. Queste tre opzioni richiedono uno mihomo installato. Su Windows, Xray utilizza mihomo 1.19.32 o successivo per tutti e quattro gli stack TUN. Protocolli e instradamento restano in Xray. Le regole delle applicazioni in questa combinazione supportano solo connessioni dirette e blocco; su Linux richiedono il gVisor integrato di Xray.\n\nIl bridge esegue un secondo processo. In tre misurazioni inattive su Linux, ha utilizzato circa 32-36 MiB di memoria fisica in più rispetto allo Xray TUN nativo. Questo non misura il carico di download: i costi della CPU e della memoria dipendono dalle connessioni. sing-box non dispone di selettore di stack. Nessuno stack garantisce prestazioni migliori in ogni rete. Scegli uno stack e seleziona Applica e riconnetti per provarlo nella tua rete.\n\n## Applicazione delle impostazioni\n\nLa selezione di un server si riconnette automaticamente. Le impostazioni di modalità, motore, DNS e regole vengono salvate immediatamente; durante una connessione attiva, fare clic su Applica e riconnettersi per utilizzarli. Il riavvio di un motore potrebbe interrompere download e chiamate. I clic ripetuti non avviano connessioni parallele; la disconnessione termina la transizione e rilascia la connessione.\n\nInternet solo tramite VPN blocca il traffico diretto quando un tunnel si interrompe. Colpisce l\'intera macchina. Una disconnessione esplicita rimuove le regole di Sora. Se la pulizia non viene completata, riprova a disconnettersi e ad aprire il registro.\n\n## Documentazione del progetto\n\n- [sing-box-lx: configurazione e supporto](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentazione sing-box](https://sing-box.sagernet.org/)\n- [Documentazione Xray](https://xtls.github.io/)\n- [Documentazione mihomo](https://wiki.metacubex.one/)\n- [zapret: funzionamento e limitazioni](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Controlla i server';

  @override
  String get extensions => 'Estensioni';

  @override
  String get extensionsSoon => 'Prossimamente';

  @override
  String exportLogFile(String name) {
    return 'In $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostica HTTP';

  @override
  String get diagnosticPackets => 'Cattura dei pacchetti';

  @override
  String get diagnosticEvents => 'Eventi di Windows';

  @override
  String get diagnosticCapture => 'Cattura per 10 secondi';

  @override
  String get diagnosticNoData => 'Nessuna richiesta registrata ancora. Apri prima un sito Web di test di velocità.';

  @override
  String get diagnosticRequiresTun => 'L\'acquisizione dei pacchetti richiede una connessione Sora TUN attiva.';

  @override
  String get diagnosticUnavailable => 'Questa diagnostica non è disponibile su questa piattaforma.';
  @override
  String get qrShareTitle => 'Share via QR';
  @override
  String get qrScanTitle => 'Scan QR code';
  @override
  String get qrCopyLink => 'Copy link';
  @override
  String get qrShowLink => 'Show link';
  @override
  String get qrHideLink => 'Hide link';
  @override
  String get qrWarning => 'This QR code contains connection details. Do not show it to strangers.';
  @override
  String get qrScanHint => 'Point the camera at a QR code';
  @override
  String get qrFromClipboard => 'Paste from clipboard';
  @override
  String get qrNoCamera => 'Camera is unavailable. Paste the link from the clipboard instead.';
  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';
  @override
  String get qrScan => 'Scan QR';
  @override
  String get qrTorch => 'Flashlight';
  @override
  String get connGroupByProcess => 'By process';
  @override
  String get connListView => 'As list';
  @override
  String get connCopyHost => 'Copy host';
  @override
  String get connAddRule => 'Add rule';
  @override
  String get connConnections => 'connections';
  @override
  String get dnsPreset => 'Preset';
  @override
  String get dnsPresetCloudflare => 'Cloudflare';
  @override
  String get dnsPresetGoogle => 'Google';
  @override
  String get dnsPresetQuad9 => 'Quad9';
  @override
  String get dnsPresetAdGuard => 'AdGuard';
  @override
  String get dnsPresetCustom => 'Custom';
  @override
  String get dnsCheck => 'Check for leaks';
  @override
  String get dnsChecking => 'Checking...';
  @override
  String get dnsNoLeak => 'No leaks found';
  @override
  String get dnsLeakFound => 'Leak detected';
  @override
  String get dnsFix => 'Fix';
  @override
  String get dnsLastCheck => 'Last check';
  @override
  String get dnsNeverChecked => 'Not checked yet';
  @override
  String get dnsCheckPending => 'Leak check will be available after the core update.';
  @override
  String get dnsDetails => 'Details';
}
