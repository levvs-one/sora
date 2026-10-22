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
  String get connEmpty => 'Nessuna connessione';

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
  String get themeSystem => 'Come il sistema';

  @override
  String get themeLight => 'Leggera';

  @override
  String get themeDark => 'Buia';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Come il sistema';

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
      'Lo sviluppatore ha ritirato questa versione. Please wait for a corrected release.';

  @override
  String get updateRolloutPending =>
      'Una versione più recente verrà lanciata gradualmente e ti verrà offerta automaticamente.';

  @override
  String updateRollbacking(String version) {
    return 'Ripristino della versione $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'L\'aggiornamento a $version non ha superato il controllo di integrità, quindi Sora è stato riportato a $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Rollback automatico non riuscito. Se la nuova versione non funziona, reinstallare manualmente la versione precedente.';

  @override
  String get updateRollbackCacheError =>
      'Impossibile preparare una copia di rollback verificata della versione corrente, quindi l\'aggiornamento non è stato installato.';

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
    return 'Valutazione $rating di 5';
  }

  @override
  String extByAuthor(String author) {
    return 'di $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Installazioni: $count';
  }

  @override
  String get extInstallOne => '1 installazione';

  @override
  String get extBadgeVerified => 'Verificato';

  @override
  String get extBadgeTop => 'Most popular this week';

  @override
  String get extBadgeNew => 'Nuovo';

  @override
  String get extBadgeStaff => 'La squadra Sora';

  @override
  String get extSideloadShort => 'Non dal catalogo';

  @override
  String get extSideloadWarning =>
      'Questa estensione non è presente nel catalogo del team. Solo l\'autore ha garantito per la propria chiave: installala solo se ti fidi dell\'autore.';

  @override
  String extInstallTitle(String name) {
    return 'Installa «$name»';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Aggiorna «$name»';
  }

  @override
  String get extPermissionsIntro => 'Questa estensione sarà in grado di:';

  @override
  String get extPermissionsWidened => 'L\'aggiornamento richiede nuove autorizzazioni:';

  @override
  String get extDangerousAck => 'Capisco che questi permessi sono seri';

  @override
  String get extInstall => 'Installa';

  @override
  String get extUpdate => 'Aggiorna';

  @override
  String get extCancel => 'Annulla';

  @override
  String get extConfirm => 'Conferma';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Catalogo';

  @override
  String get extInstalled => 'Estensioni installate';

  @override
  String get extSearchHint => 'Cerca estensioni';

  @override
  String get extCatAll => 'Tutti';

  @override
  String get extCatTools => 'Strumenti';

  @override
  String get extCatThemes => 'Temi';

  @override
  String get extCatAutomation => 'Automazione';

  @override
  String get extCatStats => 'Statistiche';

  @override
  String get extCatNetwork => 'Rete';

  @override
  String get extSortBy => 'Ordina per';

  @override
  String get extSortPopular => 'Il più popolare';

  @override
  String get extSortRating => 'Voto più alto';

  @override
  String get extSortName => 'Nome';

  @override
  String get extCatalogError => 'Impossibile caricare il catalogo';

  @override
  String get extRetry => 'Riprova';

  @override
  String get extEmptySearch => 'Non è stato trovato nulla';

  @override
  String get extEmptyInstalled =>
      'Nessuna estensione ancora installata.\nTrovane uno nel catalogo o installalo da un file.';

  @override
  String get extInstallFromFile => 'Installa da file';

  @override
  String get extInstallFromUrl => 'Installa da URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Scarica';

  @override
  String get extDownloading => 'Download in corso…';

  @override
  String get extVerifying => 'Verifica…';

  @override
  String get extInstalling => 'Installazione…';

  @override
  String get extInstallFailed => 'Installazione non riuscita';

  @override
  String get extErrSignature =>
      'Il controllo della firma non è riuscito. Il file potrebbe essere danneggiato o manomesso.';

  @override
  String get extErrManifest => 'Il manifest dell\'estensione non è valido.';

  @override
  String get extErrNetwork => 'Errore di rete. Controlla la connessione e riprova.';

  @override
  String get extErrHash => 'Il download non corrisponde al catalogo. Potrebbe essere stato manomesso.';

  @override
  String extErrMinApp(String version) {
    return 'Questa estensione richiede la versione dell\'app $version o successiva.';
  }

  @override
  String get extErrHttpsOnly => 'Sono consentiti solo i collegamenti https://';

  @override
  String get extErrGeneric => 'Qualcosa è andato storto. Per favore riprova.';

  @override
  String get extErrAuthorKeyChanged =>
      'Questo aggiornamento è firmato con una chiave autore diversa rispetto alla versione installata, quindi è stato bloccato. Se ti fidi della nuova chiave, disinstalla l\'estensione e installala di nuovo esplicitamente.';

  @override
  String get extUpdateAvailable => 'Aggiornamento disponibile';

  @override
  String get extDisabled => 'Disattivato';

  @override
  String extToggleEnabled(String name) {
    return 'Abilita $name';
  }

  @override
  String get extSearchInstalled => 'Cerca tra le estensioni installate';

  @override
  String get extUpdateAll => 'Aggiorna tutto';

  @override
  String extUpdatesAvailable(int count) {
    return '$count aggiornamenti disponibili';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count aggiornato';
  }

  @override
  String get extRiskNormal => 'Normale';

  @override
  String get extRiskSensitive => 'Sensibile';

  @override
  String get extRiskDangerous => 'Rischio alto';

  @override
  String get extPermissionsRemoved => 'Non più richiesto:';

  @override
  String get extUpdateFailedKept => 'La versione precedente è ancora installata.';

  @override
  String get extConflictsTitle => 'Conflitti di estensione';

  @override
  String get extConflictsIntro =>
      'Queste estensioni vogliono la stessa cosa. Scegli quale funziona; l’altra resta installata.';

  @override
  String get extConflictTheme => 'Tema dell\'app';

  @override
  String get extConflictNetHooks => 'Ganci di rete';

  @override
  String extConflictWinner(String name) {
    return '$name vince';
  }

  @override
  String extConflictsCount(int count) {
    return '$count i conflitti richiedono la tua decisione';
  }

  @override
  String get extConflictsResolve => 'Risolvere i conflitti';

  @override
  String get extConflictNote =>
      'La tua scelta viene salvata su questo dispositivo. Un tema cambia subito; gli hook di rete non vengono eseguiti in questa versione.';

  @override
  String extVersionLabel(String version) {
    return 'Versione $version';
  }

  @override
  String get extAuthor => 'Autore';

  @override
  String get extRating => 'Valutazione';

  @override
  String get extInstalls => 'Installazioni';

  @override
  String get extVersion => 'Versione';

  @override
  String get extAbout => 'Informazioni su questa estensione';

  @override
  String get extPermissionsTitle => 'Autorizzazioni';

  @override
  String get extNoPermissions => 'Nessuna autorizzazione speciale.';

  @override
  String get extSettings => 'Impostazioni';

  @override
  String get extSaveSettings => 'Salva le impostazioni';

  @override
  String get extSaving => 'Salvataggio…';

  @override
  String extUpdateTo(String version) {
    return 'Aggiorna alla $version';
  }

  @override
  String get extEnabled => 'Attivato';

  @override
  String extRollbackTo(String version) {
    return 'Torna alla $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Rollback alla versione $version?';
  }

  @override
  String get extUninstall => 'Disinstalla';

  @override
  String extUninstallConfirm(String name) {
    return 'Rimuovere “$name” e le relative impostazioni?';
  }

  @override
  String get extPanelUnavailable =>
      'Il pannello non è disponibile. L\'estensione potrebbe essere stata disabilitata o rimossa.';

  @override
  String get extPermConnectionsRead => 'Visualizza l\'elenco delle connessioni attive';

  @override
  String get extPermServersRead => 'Visualizza un elenco dei tuoi server';

  @override
  String get extPermSettingsRead => 'Leggi le impostazioni dell\'app';

  @override
  String get extPermSettingsWrite => 'Modificare le impostazioni dell\'app';

  @override
  String get extPermNotifications => 'Mostra notifiche';

  @override
  String get extPermTray => 'Aggiungi elementi al menu della barra delle applicazioni';

  @override
  String get extPermUiPanel => 'Mostra i pannelli all\'interno dell\'app';

  @override
  String get extPermThemeApply => 'Applica temi';

  @override
  String get extPermRoutingRules => 'Aggiungi regole di routing (influisce su dove va il traffico di rete)';

  @override
  String get extPermNetHooks => 'Integrazione nel percorso di rete (DPI moduli bypass)';

  @override
  String get extPermNetFetch => 'Richiedi URL dall\'elenco consentito';

  @override
  String get extPermBackground => 'Esegui attività in background';

  @override
  String get extPermBackgroundDetail =>
      'Esegue le attività pianificate anche quando il pannello è chiuso. Puoi metterlo in pausa o modificare la frequenza con cui viene eseguito nelle impostazioni dell\'estensione.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Viene eseguito in background';

  @override
  String get extCapNetHook => 'Aggiramenti e hook di rete';

  @override
  String get extCapPanel => 'Pannelli di interfaccia';

  @override
  String get extCapRouting => 'Regole di instradamento';

  @override
  String get extCapTheme => 'Temi';

  @override
  String get extCapWidget => 'Widget';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Registro delle modifiche';

  @override
  String get extImageFailed => 'Impossibile caricare l\'immagine';

  @override
  String get extRatingHow => 'Come funzionano le valutazioni';

  @override
  String get extRatingHowBody =>
      'Le valutazioni utilizzano una media bayesiana: un\'estensione con poche valutazioni rimane quasi al centro finché non votano più persone, quindi una singola recensione a 5 stelle non può spingere una nuova estensione in cima. Le valutazioni recenti pesano più di quelle vecchie e conta solo una valutazione per account.';

  @override
  String get extScreenshots => 'Schermate';

  @override
  String get extSortRelevance => 'Rilevanza';

  @override
  String get extPermNetworkDetail =>
      'Scarica dati da Internet tramite la VPN. Sono consentiti solo gli host qui sotto, tutto il resto è bloccato.';

  @override
  String get extBgTitle => 'Attività in background';

  @override
  String get extBgEnabled => 'Esegui in background';

  @override
  String get extBgInterval => 'Esegui ogni';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minuti', one: '# minuto');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# ore', one: '# ora');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'L’attività viene eseguita secondo la pianificazione finché Sora è aperto, anche nell’area di notifica. L’intervallo minimo è di 15 minuti.';

  @override
  String get extBgDisabledNote => 'Abilita l\'estensione a gestire la sua attività in background.';

  @override
  String get extCapNetwork => 'Accesso alla rete';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Rete: $hosts';
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
  String get qrShareTitle => 'Condividi il codice QR';

  @override
  String get qrScanTitle => 'Scansiona il codice QR';

  @override
  String get qrCopyLink => 'Copia collegamento';

  @override
  String get qrWarning => 'Condividi il codice solo con persone fidate.';

  @override
  String get qrScanHint => 'Scegli uno screenshot o una foto con un codice QR, oppure incolla un link';

  @override
  String get qrFromClipboard => 'Incolla dagli appunti';

  @override
  String get qrNoCode => 'Nessun codice QR trovato in questa immagine.';

  @override
  String get qrInvalid => 'Questo codice QR non contiene un collegamento valido.';

  @override
  String get qrScan => 'Scansione QR';

  @override
  String get qrFromImage => 'Apri immagine';

  @override
  String get connGroupByProcess => 'Raggruppare per processo';

  @override
  String get connListView => 'Elenco';

  @override
  String get connCopyHost => 'Copia host';

  @override
  String get connAddRule => 'Aggiungi regola';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# connessioni', one: '# connessione');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Preimpostato';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Personalizzato';

  @override
  String get dnsCheck => 'Verificare la presenza di perdite di dati';

  @override
  String get dnsChecking => 'Controllo...';

  @override
  String get dnsNoLeak => 'Nessuna fuga di notizie trovata';

  @override
  String get dnsLeakFound => 'Perdita rilevata';

  @override
  String get dnsLastCheck => 'Ultimo controllo';

  @override
  String get dnsNeverChecked => 'Non ancora testato';

  @override
  String get dnsLeakCheckTunnelDns => 'Resolver DNS del tunnel';

  @override
  String get dnsLeakCheckSystemResolvers => 'Resolver di sistema';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Protezione DNS del blocco di rete';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Configurare DNS per il tunnel nelle impostazioni DNS sopra.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Controlla quali risolutori utilizzerebbe il tuo sistema al di fuori del tunnel.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Attiva il blocco di rete per mantenere il traffico DNS nel tunnel.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS cifrato del sistema operativo';

  @override
  String get dnsLeakCheckDnsSpoof => 'Risposte DNS contraffatte';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Controlla quali endpoint DNS crittografati utilizza il tuo sistema all\'esterno del tunnel.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Utilizzare DNS crittografato (DoT o DoH) per il tunnel in modo che i risolutori non possano falsificare le risposte.';

  @override
  String get dnsCheckNeedsConnection => 'Connettersi prima a VPN, quindi verificare eventuali perdite.';

  @override
  String get dnsExpected => 'Previsto';

  @override
  String get dnsActual => 'Osservato';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get sortSubscription => 'Come nell’abbonamento';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Velocità';

  @override
  String get sortName => 'Nome';

  @override
  String get measureSpeed => 'Misurare la velocità';

  @override
  String get benchmarkStale => 'obsoleto';

  @override
  String get autoSelectMode => 'Selezione automatica del server';

  @override
  String get autoSelectPing => 'Ping più veloce';

  @override
  String get autoSelectSpeed => 'Velocità massima';

  @override
  String get autoSelectSmart => 'Scelta intelligente';

  @override
  String get coreWatchUnstable => 'La connessione al nucleo Sora è instabile';

  @override
  String get watchReconnect => 'Riconnetti';

  @override
  String get coreRestoringLink => 'Ripristino della connessione al nucleo Sora…';

  @override
  String get crashRestoreTitle => 'L\'ultima seduta è stata interrotta';

  @override
  String get restoreOnCrash => 'Ripristina la sessione dopo un arresto anomalo';

  @override
  String get crashRestore => 'Ripristina';

  @override
  String get crashDismiss => 'Non ora';

  @override
  String get overrideTitle => 'Le mie modifiche';

  @override
  String get overrideEdit => 'Modifica i server';

  @override
  String get overrideHide => 'Nascondi';

  @override
  String get overrideUnhide => 'Mostra';

  @override
  String get overrideClear => 'Reimposta le modifiche';

  @override
  String get overrideEmpty => 'Ancora nessuna modifica';

  @override
  String get overrideCustomRules => 'Regole proprie';

  @override
  String get errBenchmarkUnsupported => 'La misurazione della velocità necessita di un nucleo più recente';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Misurazione di $done da $total…';
  }

  @override
  String get profiles => 'Profili di rete';

  @override
  String get profilesEmpty =>
      'Nessun profilo ancora. Creane uno per applicare automaticamente le impostazioni sulle reti conosciute.';

  @override
  String get profileAdd => 'Aggiungi profilo';

  @override
  String get profileName => 'Nome del profilo';

  @override
  String get profileSsids => 'Wi-Fi reti (SSID)';

  @override
  String get profileSsidsHint => 'Casa, Ufficio separati da virgole';

  @override
  String get profileGateways => 'Gateway di rete';

  @override
  String get profileAsns => 'AS numeri';

  @override
  String get profileAutoApply => 'Applica automaticamente';

  @override
  String get profileAutoApplyHint => 'Se disattivato, chiedi conferma prima di applicare il profilo.';

  @override
  String get profileSnapshot => 'Ricorda le impostazioni attuali';

  @override
  String get profileSnapshotDone => 'Impostazioni correnti salvate nel profilo';

  @override
  String get profileDelete => 'Cancella profilo';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Eliminare il profilo \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Applicare il profilo \"$name\"?';
  }

  @override
  String get profileApply => 'Applica';

  @override
  String profileApplied(Object name) {
    return 'Profilo “$name” applicato';
  }

  @override
  String get profileUndo => 'Annulla';

  @override
  String get profileActive => 'Attivo';

  @override
  String networkNow(Object info) {
    return 'Adesso: $info';
  }

  @override
  String get networkUnknown => 'Informazioni di rete non disponibili';

  @override
  String get profileNoTriggers => 'Aggiungi almeno un trigger: SSID, gateway o ASN';

  @override
  String get chains => 'Catene proxy';

  @override
  String get chainsEmpty =>
      'Ancora nessuna catena. Collega 2-3 server in modo che il traffico passi attraverso ciascuno di essi.';

  @override
  String get chainAdd => 'Nuova catena';

  @override
  String get chainName => 'Nome della catena';

  @override
  String get chainPickServers => 'Scegli 2-3 server';

  @override
  String get chainOrderHint => 'Trascina per riordinare: il traffico entra in alto ed esce in basso.';

  @override
  String get chainTooFew => 'Scegli almeno 2 server';

  @override
  String get chainTooMany => 'Una catena contiene al massimo 3 server';

  @override
  String get chainEstimate => 'Latenza stimata';

  @override
  String get chainSave => 'Salva catena';

  @override
  String get chainDelete => 'Elimina catena';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Eliminare la catena \"$name\"?';
  }

  @override
  String get chainUnsupported => 'Il motore attuale non può costruire catene';

  @override
  String get chainHopMissing => 'Uno dei server della catena non è più disponibile';

  @override
  String chainHop(Object n) {
    return 'Salto $n';
  }

  @override
  String get chainEntry => 'Ingresso';

  @override
  String get chainExit => 'Uscita';

  @override
  String get sync => 'Sincronizzazione del dispositivo';

  @override
  String get syncDevices => 'I miei dispositivi';

  @override
  String get syncEmpty => 'Nessun dispositivo associato. Associa un altro dispositivo sulla rete locale.';

  @override
  String get syncPair => 'Associa il dispositivo';

  @override
  String get syncShowCode => 'Mostra il mio codice';

  @override
  String get syncScanCode => 'Scansiona il codice';

  @override
  String get syncRevoke => 'Ritira';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Revoca \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String get syncNever => 'Mai';

  @override
  String get syncNoLan => 'I dispositivi devono trovarsi sulla stessa rete locale';

  @override
  String get syncPaired => 'Dispositivo accoppiato';

  @override
  String get syncPairingTitle => 'Accoppia con questo dispositivo';

  @override
  String get syncWaiting => 'In attesa dell\'altro dispositivo…';

  @override
  String get syncSecureNote => 'Canale crittografato end-to-end. Nessun account, nessun server cloud.';

  @override
  String get zapretWithVpn => 'Ignora il filtro DPI per il traffico di rete diretto';

  @override
  String get zapretWithVpnHint =>
      'Esegue zapret insieme al tunnel VPN: il traffico nel tunnel usa la VPN, quello diretto passa per il sistema di aggiramento.';

  @override
  String get chainDuplicate => 'Ciascun server può apparire solo una volta';

  @override
  String get edit => 'Modifica';

  @override
  String get remove => 'Rimuovi';

  @override
  String get autoSwitchOnDegrade => 'Degrado accensione automatica';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Se il server selezionato rallenta molto o smette di rispondere, Sora passa al migliore in base alle misurazioni, al massimo una volta ogni 10 minuti.';

  @override
  String get tunStackMixed => 'Misto';

  @override
  String get tunStackSystem => 'Sistema';

  @override
  String get customServerAdd => 'Aggiungi server personalizzato';

  @override
  String get customServers => 'I miei server';

  @override
  String get customServerName => 'Nome';

  @override
  String get customServerNameHint => 'Ad esempio: il mio VPS';

  @override
  String get customServerNameRequired => 'Inserisci il nome';

  @override
  String get customServerAddress => 'Indirizzo';

  @override
  String get customServerAddressHint => 'example.com o 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Immettere l\'indirizzo del server';

  @override
  String get customServerAddressInvalid => 'Indirizzo non valido';

  @override
  String get customServerPort => 'Porta';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'La porta deve essere un numero compreso tra 1 e 65535';

  @override
  String get customServerProtocol => 'Protocollo';

  @override
  String get customServerCredentials => 'Informazioni di accesso';

  @override
  String get customServerOptional => 'Opzionale';

  @override
  String get customServerShowSecret => 'Mostra segreto';

  @override
  String get customServerHideSecret => 'Nascondi segreto';

  @override
  String get customServerBadge => 'personalizzato';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Eliminare il server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Aggiungere manualmente un server: indirizzo, porta e protocollo';

  @override
  String get customServerTest => 'Prova';

  @override
  String get leakTestTitle => 'Test per perdite di dati';

  @override
  String get leakTestIntro =>
      'Verifica se il traffico può uscire dal dispositivo al di fuori del tunnel: richieste DNS e ICMP dirette, traffico IPv6 in uscita e resolver di sistema. Esegui il test durante la connessione.';

  @override
  String get leakTestRun => 'Controlla';

  @override
  String get leakTestCancel => 'Annulla';

  @override
  String get leakTestNeedsConnection => 'Connettersi a VPN per verificare eventuali fughe di dati.';

  @override
  String leakTestProgress(int count) {
    return 'Test completati: $count';
  }

  @override
  String get leakTestAllClear => 'Nessuna fuga di notizie trovata';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# perdite rilevate',
      one: '# perdita rilevata',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Correzione';

  @override
  String get leakTestFixedNote => 'Il blocco di rete è attivo. Ripeti il test per verificare.';

  @override
  String get leakTestCheckDirectDns => 'Diretto DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP eco';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Resolver di sistema';

  @override
  String get leakTestCheckTunnelConnectivity => 'Connettività tra tunnel';

  @override
  String get leakTestCheckTunnelDns => 'DNS attraverso il tunnel';

  @override
  String get noticeDegraded =>
      'Il server è diventato lento. Sora è passato al miglior server trovato durante la misurazione.';

  @override
  String get obfs => 'Offuscamento del traffico';

  @override
  String get syncCodeExpired => 'Il codice è scaduto';

  @override
  String get syncDaemonFailed => 'Impossibile avviare il servizio di sincronizzazione';

  @override
  String get syncDaemonMissing =>
      'Il componente sora-sync non è stato trovato. Reinstallare l\'app per abilitare la sincronizzazione del dispositivo.';

  @override
  String get syncDaemonStarting => 'Avvio del servizio di sincronizzazione…';

  @override
  String get syncErrAuth =>
      'Il servizio di sincronizzazione ha rifiutato il token di accesso. Riavvia l\'app e riprova.';

  @override
  String get syncErrNotFound => 'Il dispositivo non è più associato';

  @override
  String get syncErrPairingActive => 'Una sessione di abbinamento è già aperta';

  @override
  String get syncErrUnreachable =>
      'L\'altro dispositivo non ha risposto. Assicurati che sia sulla stessa rete e che mostri il relativo codice.';

  @override
  String get syncError => 'Errore di sincronizzazione';

  @override
  String syncExpiresIn(String duration) {
    return 'Il codice scade tra $duration';
  }

  @override
  String get syncJoining => 'Associazione con il dispositivo…';

  @override
  String get syncLegacyCleared =>
      'Il vecchio elenco dei dispositivi non è mai stato effettivamente accoppiato, quindi è stato cancellato. Accoppia nuovamente i tuoi dispositivi, questa volta per davvero.';

  @override
  String get syncNewCode => 'Nuovo codice';

  @override
  String syncPairedWith(String name) {
    return 'Accoppiato con $name';
  }

  @override
  String get syncRetry => 'Ripeti';

  @override
  String get syncStopShowing => 'Nascondi codice';

  @override
  String get syncSyncNow => 'Sincronizza ora';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Ricevuto $pulled, inviato $pushed';
  }

  @override
  String get syncResultTitle => 'Risultato della sincronizzazione';

  @override
  String get syncPulled => 'Ricevuto';

  @override
  String get syncPushed => 'Inviato';

  @override
  String get syncNoChanges => 'Nessuna modifica rilevata';

  @override
  String get syncDocKindSubscriptions => 'Sottoscrizioni';

  @override
  String get syncDocKindSettings => 'Impostazioni dell\'app';

  @override
  String get syncDocKindOverrides => 'Personalizzazioni delle sottoscrizioni';

  @override
  String get syncDocKindProfiles => 'Profili di rete';

  @override
  String get syncDocKindChains => 'Catene proxy';

  @override
  String syncFrom(String name) {
    return 'da $name';
  }

  @override
  String get syncThisDevice => 'Questo dispositivo';

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
