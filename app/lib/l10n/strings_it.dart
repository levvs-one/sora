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
  String get connEmpty => 'No connections';

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
  String latencyMs(int value) {
    return '$value ms';
  }

  @override
  String speedMbps(double value) {
    return '$value Mbps';
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
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'Indirizzo proxy';

  @override
  String get copied => 'Copiato';

  @override
  String get launchAtLogin => 'Cominciamo dal sistema';

  @override
  String get launchAtLoginDetail => 'Sora si avvierà automaticamente all\'accesso e resterà nell\'area di notifica.';

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
  String get programsEmpty => 'Nessuna applicazione trovata. Prova un altro nome.';

  @override
  String get selectExe => 'Scegli un file .exe';

  @override
  String get speedtest => 'Velocità';

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
  String get updateSignaturePending =>
      'I file di aggiornamento vengono confrontati con i checksum pubblicati con la release.';

  @override
  String get updateManualSigWarning =>
      'I file qui sotto corrispondono ai checksum della release. Esegui il comando se li hai scaricati dalla release ufficiale.';

  @override
  String get updateVersionRevoked =>
      'This version has been recalled by the developer. Please wait for a fixed release.';

  @override
  String get updateRolloutPending =>
      'A newer version is rolling out gradually and will be offered to you automatically.';

  @override
  String updateRollbacking(String version) {
    return 'Rolling back to version $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'The update to $version did not pass the health check, so Sora was rolled back to $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Automatic rollback failed. If the new version does not work, reinstall the previous release manually.';

  @override
  String get updateRollbackCacheError =>
      'Could not prepare a verified rollback copy of the current version, so the update was not installed.';

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
  String extRatingLabel(String rating) {
    return 'Rating $rating of 5';
  }

  @override
  String extByAuthor(String author) {
    return 'by $author';
  }

  @override
  String extInstallsCount(String count) {
    return '$count installs';
  }

  @override
  String get extInstallOne => '1 install';

  @override
  String get extBadgeVerified => 'Verified';

  @override
  String get extBadgeTop => 'Top this week';

  @override
  String get extBadgeNew => 'New';

  @override
  String get extBadgeStaff => 'Sora team';

  @override
  String get extSideloadShort => 'Not from catalog';

  @override
  String get extSideloadWarning =>
      'Not from the team catalog. The author\'s key is self-attested: install only if you trust the author.';

  @override
  String extInstallTitle(String name) {
    return 'Install $name';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Update $name';
  }

  @override
  String get extPermissionsIntro => 'This extension will be able to:';

  @override
  String get extPermissionsWidened => 'The update asks for new permissions:';

  @override
  String get extDangerousAck => 'I understand these permissions are powerful';

  @override
  String get extInstall => 'Install';

  @override
  String get extUpdate => 'Update';

  @override
  String get extCancel => 'Cancel';

  @override
  String get extConfirm => 'Confirm';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Catalog';

  @override
  String get extInstalled => 'Installed';

  @override
  String get extSearchHint => 'Search extensions';

  @override
  String get extCatAll => 'All';

  @override
  String get extCatTools => 'Tools';

  @override
  String get extCatThemes => 'Themes';

  @override
  String get extCatAutomation => 'Automation';

  @override
  String get extCatStats => 'Statistics';

  @override
  String get extCatNetwork => 'Network';

  @override
  String get extSortBy => 'Sort by';

  @override
  String get extSortPopular => 'Most popular';

  @override
  String get extSortRating => 'Highest rated';

  @override
  String get extSortName => 'Name';

  @override
  String get extCatalogError => 'Could not load the catalog';

  @override
  String get extRetry => 'Retry';

  @override
  String get extEmptySearch => 'Nothing found';

  @override
  String get extEmptyInstalled => 'No extensions installed yet.\nFind one in the catalog or install from a file.';

  @override
  String get extInstallFromFile => 'Install from file';

  @override
  String get extInstallFromUrl => 'Install from URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Download';

  @override
  String get extDownloading => 'Downloading…';

  @override
  String get extVerifying => 'Verifying…';

  @override
  String get extInstalling => 'Installing…';

  @override
  String get extInstallFailed => 'Install failed';

  @override
  String get extErrSignature => 'The signature check failed. The file may be damaged or tampered with.';

  @override
  String get extErrManifest => 'The extension manifest is invalid.';

  @override
  String get extErrNetwork => 'Network error. Check your connection and try again.';

  @override
  String get extErrHash => 'The download does not match the catalog. It may have been tampered with.';

  @override
  String extErrMinApp(String version) {
    return 'This extension needs app version $version or newer.';
  }

  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';

  @override
  String get extErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get extErrAuthorKeyChanged =>
      'This update is signed with a different author key than the installed version, so it was blocked. If you trust the new key, uninstall the extension and install it again explicitly.';

  @override
  String get extUpdateAvailable => 'Update available';

  @override
  String get extDisabled => 'Disabled';

  @override
  String extToggleEnabled(String name) {
    return 'Enable $name';
  }

  @override
  String get extSearchInstalled => 'Search installed';

  @override
  String get extUpdateAll => 'Update all';

  @override
  String extUpdatesAvailable(int count) {
    return '$count updates available';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count updated';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Sensitive';

  @override
  String get extRiskDangerous => 'High risk';

  @override
  String get extPermissionsRemoved => 'No longer requested:';

  @override
  String get extUpdateFailedKept => 'The previous version is still installed.';

  @override
  String get extConflictsTitle => 'Extension conflicts';

  @override
  String get extConflictsIntro =>
      'Queste estensioni vogliono la stessa cosa. Scegli quale funziona; l’altra resta installata.';

  @override
  String get extConflictTheme => 'App theme';

  @override
  String get extConflictNetHooks => 'Network hooks';

  @override
  String extConflictWinner(String name) {
    return '$name wins';
  }

  @override
  String extConflictsCount(int count) {
    return '$count conflicts need your decision';
  }

  @override
  String get extConflictsResolve => 'Resolve';

  @override
  String get extConflictNote =>
      'Your choice is saved on this device and will be applied once the engine supports these capabilities.';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extAuthor => 'Author';

  @override
  String get extRating => 'Rating';

  @override
  String get extInstalls => 'Installs';

  @override
  String get extVersion => 'Version';

  @override
  String get extAbout => 'About';

  @override
  String get extPermissionsTitle => 'Permissions';

  @override
  String get extNoPermissions => 'No special permissions.';

  @override
  String get extSettings => 'Settings';

  @override
  String get extSaveSettings => 'Save settings';

  @override
  String get extSaving => 'Saving…';

  @override
  String extUpdateTo(String version) {
    return 'Update to $version';
  }

  @override
  String get extEnabled => 'Enabled';

  @override
  String extRollbackTo(String version) {
    return 'Roll back to $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Roll back to version $version?';
  }

  @override
  String get extUninstall => 'Uninstall';

  @override
  String extUninstallConfirm(String name) {
    return 'Remove “$name” and its settings?';
  }

  @override
  String get extPanelUnavailable => 'The panel is unavailable. The extension may have been disabled or removed.';

  @override
  String get extPermConnectionsRead => 'See the list of active connections';

  @override
  String get extPermServersRead => 'See your server list';

  @override
  String get extPermSettingsRead => 'Read app settings';

  @override
  String get extPermSettingsWrite => 'Change app settings';

  @override
  String get extPermNotifications => 'Show notifications';

  @override
  String get extPermTray => 'Add tray menu entries';

  @override
  String get extPermUiPanel => 'Show panels inside the app';

  @override
  String get extPermThemeApply => 'Apply themes to the app';

  @override
  String get extPermRoutingRules => 'Add routing rules (affects where traffic goes)';

  @override
  String get extPermNetHooks => 'Hook into the network path (DPI bypass modules)';

  @override
  String get extPermNetFetch => 'Fetch URLs from an allowlist';

  @override
  String get extPermBackground => 'Run background tasks';

  @override
  String get extPermBackgroundDetail =>
      'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Runs in the background';

  @override
  String get extCapFilterTitle => 'Capabilities';

  @override
  String get extCapNetHook => 'Bypasses & network hooks';

  @override
  String get extCapPanel => 'Panels';

  @override
  String get extCapRouting => 'Routing rules';

  @override
  String get extCapTheme => 'Themes';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Changelog';

  @override
  String get extImageFailed => 'Couldn\'t load the image';

  @override
  String get extRatingHow => 'How ratings work';

  @override
  String get extRatingHowBody =>
      'Ratings use a Bayesian average: an extension with few ratings stays near the middle until more people vote, so a single 5-star review cannot push a new extension to the top. Recent ratings weigh more than old ones, and only one rating per account counts.';

  @override
  String get extScreenshots => 'Screenshots';

  @override
  String get extSortRelevance => 'Relevance';

  @override
  String get extPermNetworkDetail =>
      'Scarica dati da Internet tramite la VPN. Sono consentiti solo gli host qui sotto, tutto il resto è bloccato.';

  @override
  String get extBgTitle => 'Background task';

  @override
  String get extBgEnabled => 'Run in the background';

  @override
  String get extBgInterval => 'Run every';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minutes', one: '# minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# hours', one: '# hour');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'L’attività viene eseguita secondo la pianificazione finché Sora è aperto, anche nell’area di notifica. L’intervallo minimo è di 15 minuti.';

  @override
  String get extBgDisabledNote => 'Enable the extension to manage its background task.';

  @override
  String get extCapNetwork => 'Network access';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Network: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'In $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostica HTTP';

  @override
  String get diagnosticNoData => 'Nessuna richiesta registrata ancora. Apri prima un sito Web di test di velocità.';

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
  String get qrScanHint => 'Scegli uno screenshot o una foto con un codice QR, oppure incolla un link';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Nessun codice QR trovato in questa immagine.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Apri immagine';

  @override
  String get connGroupByProcess => 'By process';

  @override
  String get connListView => 'As list';

  @override
  String get connCopyHost => 'Copy host';

  @override
  String get connAddRule => 'Add rule';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# connections', one: '# connection');
    return '$_temp0';
  }

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
  String get dnsLastCheck => 'Last check';

  @override
  String get dnsNeverChecked => 'Not checked yet';

  @override
  String get dnsLeakCheckTunnelDns => 'Tunnel DNS resolvers';

  @override
  String get dnsLeakCheckSystemResolvers => 'System resolvers';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Kill switch DNS cover';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Set the tunnel DNS in the DNS settings above.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Check which resolvers your system would use outside the tunnel.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Enable the kill switch so DNS stays inside the tunnel.';

  @override
  String get dnsLeakCheckEncryptedDns => 'OS encrypted DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS answer spoofing';

  @override
  String get dnsLeakFixReviewEncryptedDns => 'Check which encrypted DNS endpoints your system uses outside the tunnel.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Use encrypted DNS (DoT or DoH) for the tunnel so resolvers cannot forge answers.';

  @override
  String get dnsCheckNeedsConnection => 'Connect to the VPN first, then check for leaks.';

  @override
  String get dnsExpected => 'Expected';

  @override
  String get dnsActual => 'Observed';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Speed';

  @override
  String get sortName => 'Name';

  @override
  String get measureSpeed => 'Measure speed';

  @override
  String get benchmarkStale => 'outdated';

  @override
  String get autoSelectMode => 'Auto-select server';

  @override
  String get autoSelectPing => 'Fastest ping';

  @override
  String get autoSelectSpeed => 'Fastest speed';

  @override
  String get autoSelectSmart => 'Smart choice';

  @override
  String get coreWatchUnstable => 'The link to the core is unstable';

  @override
  String get watchReconnect => 'Reconnect';

  @override
  String get coreRestoringLink => 'Restoring the link to the core…';

  @override
  String get crashRestoreTitle => 'The last session was interrupted';

  @override
  String get restoreOnCrash => 'Restore session after a crash';

  @override
  String get crashRestore => 'Restore';

  @override
  String get crashDismiss => 'Not now';

  @override
  String get overrideTitle => 'My edits';

  @override
  String get overrideEdit => 'Edit servers';

  @override
  String get overrideHide => 'Hide';

  @override
  String get overrideUnhide => 'Show';

  @override
  String get overrideClear => 'Clear edits';

  @override
  String get overrideEmpty => 'No edits yet';

  @override
  String get overrideCustomRules => 'Custom rules';

  @override
  String get errBenchmarkUnsupported => 'Speed measurement needs a newer core';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Measuring $done of $total…';
  }

  @override
  String get profiles => 'Network profiles';

  @override
  String get profilesEmpty => 'No profiles yet. Create one to apply settings automatically on known networks.';

  @override
  String get profileAdd => 'Add profile';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileSsids => 'Wi-Fi networks (SSID)';

  @override
  String get profileSsidsHint => 'Home, Office, comma separated';

  @override
  String get profileGateways => 'Gateways';

  @override
  String get profileAsns => 'AS numbers';

  @override
  String get profileAutoApply => 'Apply automatically';

  @override
  String get profileAutoApplyHint => 'Ask before applying when off';

  @override
  String get profileSnapshot => 'Remember current settings';

  @override
  String get profileSnapshotDone => 'Current settings saved into the profile';

  @override
  String get profileDelete => 'Delete profile';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Apply profile \"$name\"?';
  }

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(Object name) {
    return 'Profile \"$name\" applied';
  }

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(Object info) {
    return 'Now: $info';
  }

  @override
  String get networkUnknown => 'Network info unavailable';

  @override
  String get profileNoTriggers => 'Add at least one trigger: SSID, gateway or ASN';

  @override
  String get chains => 'Proxy chains';

  @override
  String get chainsEmpty => 'No chains yet. Link 2–3 servers so traffic hops through each of them.';

  @override
  String get chainAdd => 'New chain';

  @override
  String get chainName => 'Chain name';

  @override
  String get chainPickServers => 'Pick 2–3 servers';

  @override
  String get chainOrderHint => 'Drag to reorder: traffic enters at the top and exits at the bottom.';

  @override
  String get chainTooFew => 'Pick at least 2 servers';

  @override
  String get chainTooMany => 'A chain holds at most 3 servers';

  @override
  String get chainEstimate => 'Estimated latency';

  @override
  String get chainSave => 'Save chain';

  @override
  String get chainDelete => 'Delete chain';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(Object n) {
    return 'Hop $n';
  }

  @override
  String get chainEntry => 'Entry';

  @override
  String get chainExit => 'Exit';

  @override
  String get sync => 'Device sync';

  @override
  String get syncDevices => 'My devices';

  @override
  String get syncEmpty => 'No paired devices. Pair another device over the local network.';

  @override
  String get syncPair => 'Pair a device';

  @override
  String get syncShowCode => 'Show my code';

  @override
  String get syncScanCode => 'Scan a code';

  @override
  String get syncRevoke => 'Revoke';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Revoke \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Last sync: $time';
  }

  @override
  String get syncNever => 'Never';

  @override
  String get syncNoLan => 'Devices must be on the same local network';

  @override
  String get syncPaired => 'Device paired';

  @override
  String get syncPairingTitle => 'Pair with this device';

  @override
  String get syncWaiting => 'Waiting for the other device…';

  @override
  String get syncSecureNote => 'End-to-end encrypted channel. No accounts, no cloud servers.';

  @override
  String get zapretWithVpn => 'DPI bypass for direct traffic';

  @override
  String get zapretWithVpnHint =>
      'Runs zapret next to the VPN tunnel: tunneled traffic uses the VPN, direct traffic goes through the bypass.';

  @override
  String get chainDuplicate => 'Each server can appear only once';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';

  @override
  String get autoSwitchOnDegradeDetail =>
      'If the selected server slows down a lot or stops answering, Sora switches to the best measured one, at most once every 10 minutes.';

  @override
  String get tunStackMixed => 'Mixed';

  @override
  String get tunStackSystem => 'System';

  @override
  String get customServerAdd => 'Add custom server';

  @override
  String get customServers => 'My servers';

  @override
  String get customServerName => 'Name';

  @override
  String get customServerNameHint => 'E.g. My VPS';

  @override
  String get customServerNameRequired => 'Enter a name';

  @override
  String get customServerAddress => 'Address';

  @override
  String get customServerAddressHint => 'example.com or 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Enter the server address';

  @override
  String get customServerAddressInvalid => 'Invalid address';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port must be a number from 1 to 65535';

  @override
  String get customServerProtocol => 'Protocol';

  @override
  String get customServerCredentials => 'Credentials';

  @override
  String get customServerOptional => 'Optional';

  @override
  String get customServerShowSecret => 'Show secret';

  @override
  String get customServerHideSecret => 'Hide secret';

  @override
  String get customServerBadge => 'custom';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Add a server manually: address, port and protocol';

  @override
  String get customServerTest => 'Test';

  @override
  String get leakTestTitle => 'Leak test';

  @override
  String get leakTestIntro =>
      'Probes whether traffic can leave the device outside the tunnel: direct DNS and ICMP, IPv6 egress, and the system resolvers. Run it while connected.';

  @override
  String get leakTestRun => 'Run test';

  @override
  String get leakTestCancel => 'Cancel';

  @override
  String get leakTestNeedsConnection => 'Connect to run the leak test.';

  @override
  String leakTestProgress(int count) {
    return 'Tests completed: $count';
  }

  @override
  String get leakTestAllClear => 'No leaks found';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# leaks found', one: '# leak found');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Kill switch is on, run the test again to verify.';

  @override
  String get leakTestCheckDirectDns => 'Direct DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'System resolvers';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tunnel connectivity';

  @override
  String get leakTestCheckTunnelDns => 'Tunnel DNS';

  @override
  String get noticeDegraded => 'The server slowed down, switched to the best measured one';

  @override
  String get obfs => 'Traffic obfuscation';

  @override
  String get syncCodeExpired => 'The code expired';

  @override
  String get syncDaemonFailed => 'Couldn\'t start the sync service';

  @override
  String get syncDaemonMissing => 'The sora-sync component wasn\'t found. Reinstall the app to enable device sync.';

  @override
  String get syncDaemonStarting => 'Starting the sync service…';

  @override
  String get syncErrAuth => 'The sync service rejected the access token. Restart the app and try again.';

  @override
  String get syncErrNotFound => 'The device is no longer paired';

  @override
  String get syncErrPairingActive => 'A pairing session is already open';

  @override
  String get syncErrUnreachable =>
      'The other device didn\'t answer. Make sure it\'s on the same network and showing its code.';

  @override
  String get syncError => 'Sync error';

  @override
  String syncExpiresIn(String duration) {
    return 'Code expires in $duration';
  }

  @override
  String get syncJoining => 'Pairing with the device…';

  @override
  String get syncLegacyCleared =>
      'The old device list was never actually paired, so it was cleared. Pair your devices again, for real this time.';

  @override
  String get syncNewCode => 'New code';

  @override
  String syncPairedWith(String name) {
    return '$name paired';
  }

  @override
  String get syncRetry => 'Try again';

  @override
  String get syncStopShowing => 'Stop showing';

  @override
  String get syncSyncNow => 'Sync now';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Received $pulled, sent $pushed';
  }

  @override
  String get syncResultTitle => 'Sync result';

  @override
  String get syncPulled => 'Received';

  @override
  String get syncPushed => 'Sent';

  @override
  String get syncNoChanges => 'No changes';

  @override
  String get syncDocKindSubscriptions => 'Subscriptions';

  @override
  String get syncDocKindSettings => 'App settings';

  @override
  String get syncDocKindOverrides => 'Subscription overrides';

  @override
  String get syncDocKindProfiles => 'Network profiles';

  @override
  String get syncDocKindChains => 'Proxy chains';

  @override
  String syncFrom(String name) {
    return 'from $name';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Per Shadowsocks: metodo:password, ad esempio chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => 'Cattura dei pacchetti';

  @override
  String get diagnosticEvents => 'Eventi di Windows';

  @override
  String get diagnosticCapture => 'Cattura per 10 secondi';

  @override
  String get diagnosticRequiresTun => 'L\'acquisizione dei pacchetti richiede una connessione Sora TUN attiva.';

  @override
  String get diagnosticUnavailable => 'Questa diagnostica non è disponibile su questa piattaforma.';

  @override
  String get extErrRevoked =>
      'Il team di Sora ha ritirato questa versione dell’estensione perché non è sicura o non funziona.';

  @override
  String get extErrRevocationsExpired =>
      'Non è stato possibile rinnovare l’elenco delle estensioni ritirate. L’installazione è bloccata finché non viene rinnovato: controlla la rete e riprova.';

  @override
  String extRevokedDisabled(String names) {
    return 'Estensioni ritirate disattivate: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Chiave privata';

  @override
  String get customServerWgAddresses => 'Indirizzi dell’interfaccia';

  @override
  String get customServerWgPeerKey => 'Chiave pubblica del server';

  @override
  String get customServerWgPresharedKey => 'Chiave precondivisa';

  @override
  String get customServerWgAllowedIps => 'IP consentiti';

  @override
  String get customServerWgKeepalive => 'Keepalive, secondi';

  @override
  String get customServerWgKeyInvalid => 'La chiave deve essere di 32 byte in base64, come la stampa wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'Inserisci prefissi separati da virgole, come 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Inserisci un numero di secondi da 0 a 65535.';

  @override
  String get strictKillSwitch => 'Blocco di rete rigoroso';

  @override
  String get strictKillSwitchWarning =>
      'Dopo la connessione blocca il traffico esterno alla VPN anche in caso di arresto anomalo, riavvio o chiusura dell’app. Solo la disconnessione o la disattivazione di questa opzione ripristina l’accesso. Dopo il riavvio del sistema, il blocco riprende solo se è attiva la connessione all’avvio.';

  @override
  String get extWorkerFailed =>
      'L’attività in background dell’estensione non è riuscita. Controlla il registro dell’estensione.';

  @override
  String get extAssetRejected => 'File dell’estensione rifiutato: colori illeggibili o regole non valide.';
}
