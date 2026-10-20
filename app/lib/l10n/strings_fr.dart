// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get stateOff => 'Non connecté';

  @override
  String get stateConnecting => 'De liaison';

  @override
  String get stateConnected => 'Connecté';

  @override
  String get stateReconnecting => 'Reconnexion';

  @override
  String get stateDisconnecting => 'Déconnexion';

  @override
  String get stateFailed => 'Non connecté';

  @override
  String get coreMissing => 'Le service Sora ne répond pas';

  @override
  String get serverAuto => 'Le plus rapide';

  @override
  String get serverBypass => 'Pas de serveur';

  @override
  String get addSubscription => 'Ajouter un abonnement';

  @override
  String get servers => 'Serveuses';

  @override
  String get settings => 'Paramètres';

  @override
  String get subscription => 'Abonnement';

  @override
  String get subscriptionLink => 'Lien d\'abonnement';

  @override
  String get add => 'Ajouter';

  @override
  String get refresh => 'Mise à jour';

  @override
  String get rename => 'Rebaptiser';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Sauvegarder';

  @override
  String get name => 'Nom';

  @override
  String deleteSubscription(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get routes => 'Itinéraires';

  @override
  String get presetGlobal => 'Tout via VPN';

  @override
  String get presetRu => 'Russie directe';

  @override
  String get presetIr => 'Iran direct';

  @override
  String get presetCn => 'Chine directe';

  @override
  String get blockAds => 'Bloquer les publicités';

  @override
  String get killSwitch => 'Internet uniquement via VPN';

  @override
  String get engine => 'Moteur';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animations';

  @override
  String get logs => 'Enregistrer';

  @override
  String get about => 'À propos';

  @override
  String get logsAll => 'Toute';

  @override
  String get logsImportant => 'Importante';

  @override
  String get logsErrors => 'Erreurs';

  @override
  String get search => 'Recherche';

  @override
  String get export => 'Enregistrer dans un fichier';

  @override
  String get clear => 'Claire';

  @override
  String get logsEmpty => 'Rien ici';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Non installé';

  @override
  String get sourceCode => 'Code source';

  @override
  String get license => 'Licence';

  @override
  String usage(String used, String total) {
    return '$used ou $total';
  }

  @override
  String until(String date) {
    return 'jusqu\'à $date';
  }

  @override
  String get expired => 'Expiré';

  @override
  String milliseconds(int n) {
    return '$n ms';
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
    return '$n Ko';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n FR';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'Quelque chose s\'est mal passé';

  @override
  String get errCore => 'Le service Sora ne répond pas';

  @override
  String get errAuth => 'Pas d\'accès au service Sora';

  @override
  String get errVersion => 'Mise à jour Sora : l\'application et le service sont des versions différentes';

  @override
  String get errBusy => 'Attendez, la commande précédente est toujours en cours d\'exécution';

  @override
  String get errEngineMissing => 'Aucun moteur trouvé pour ce serveur';

  @override
  String get errEngineStart => 'Le moteur n\'a pas démarré';

  @override
  String get errEngineStopped => 'Le moteur s\'est arrêté';

  @override
  String get errTunnel => 'Aucune autorisation pour créer la connexion VPN';

  @override
  String get errServers => 'Le serveur est configuré avec une erreur';

  @override
  String get errNetwork => 'Impossible d\'atteindre le serveur';

  @override
  String get errTimeout => 'Le serveur n\'a pas répondu à temps';

  @override
  String get errFirewall => 'Impossible de bloquer Internet en dehors du VPN';

  @override
  String get errSubFetch => 'Impossible de charger l\'abonnement';

  @override
  String get errSubFormat => 'Ceci n\'est pas un lien d\'abonnement';

  @override
  String get errSubEmpty => 'L\'abonnement n\'a pas de serveurs';

  @override
  String get errSubDuplicate => 'Cet abonnement est déjà ajouté';

  @override
  String get errSubLimit => 'Trop d\'abonnements';

  @override
  String get errSubScheme => 'Le lien doit commencer par https://';

  @override
  String get errSecretStore => 'Le stockage Sora est endommagé ou indisponible';

  @override
  String get errNoServers => 'Ajouter un abonnement pour vous connecter';

  @override
  String get exportText => 'Texte';

  @override
  String get connections => 'Relations';

  @override
  String get close => 'Fermer';

  @override
  String get chainDirect => 'Direct';

  @override
  String get chainBlocked => 'Bloquée';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lumière';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Connexion';

  @override
  String get sectionNoServer => 'Pas de serveur';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostic';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Adresses, séparées par des virgules';

  @override
  String get fragment => 'Fragmentation TLS';

  @override
  String get fragmentPackets => 'Que diviser';

  @override
  String get fragmentLength => 'Taille de la pièce';

  @override
  String get fragmentInterval => 'Pause entre les morceaux';

  @override
  String get byDefault => 'Défaut';

  @override
  String get rangeHint => 'Par exemple, 100-200';

  @override
  String get splitPos => 'Positions fractionnées';

  @override
  String get splitPosHint => 'Par exemple, 1, milieu';

  @override
  String get disorder => 'Réorganiser les pièces';

  @override
  String get tlsRecord => 'Diviser l\'enregistrement TLS';

  @override
  String get tlsRecordNo => 'Non';

  @override
  String get tlsRecordSni => 'Au nom du site';

  @override
  String get tlsRecordFirst => 'Après le premier octet';

  @override
  String get hostCase => 'Changer de cas d\'hôte';

  @override
  String get probeMethod => 'Méthode';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Grâce au moteur';

  @override
  String get probeConnect => 'Connexion uniquement';

  @override
  String get probeUrl => 'Adresse de test';

  @override
  String get probeTimeout => 'Attendez';

  @override
  String seconds(int n) {
    return '${n}s';
  }

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get subscriptionSettings => 'Paramètres';

  @override
  String get userAgent => 'Agent utilisateur';

  @override
  String get autoUpdate => 'Mettre à jour automatiquement';

  @override
  String get updateInterval => 'À quelle fréquence';

  @override
  String get intervalProvider => 'Comme le demande le fournisseur';

  @override
  String hours(int n) {
    return '${n}h';
  }

  @override
  String get updateNow => 'Mettre à jour maintenant';

  @override
  String get logLevel => 'Quoi enregistrer';

  @override
  String get levelDebug => 'Tout';

  @override
  String get levelInfo => 'Habituelle';

  @override
  String get levelWarning => 'Importante';

  @override
  String get levelError => 'Erreurs uniquement';

  @override
  String get recordDestinations => 'Enregistrer les adresses des sites';

  @override
  String get reset => 'Réinitialiser les paramètres';

  @override
  String get resetConfirm => 'Réinitialiser tous les paramètres ?';

  @override
  String get resetAction => 'Réinitialiser';

  @override
  String get invalidValue => 'Cette valeur ne fonctionnera pas';

  @override
  String get website => 'Page d\'abonnement';

  @override
  String get providerWebsite => 'Site Web du fournisseur';

  @override
  String get support => 'Soutien';

  @override
  String controlPortQuestion(String engine) {
    return '$engine est contrôlé via un port sur cet ordinateur. D\'autres programmes pourront détecter qu\'un VPN est activé.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Choisissez $engine';
  }

  @override
  String get rules => 'Règles personnalisées';

  @override
  String get ruleAdd => 'Nouvelle règle';

  @override
  String get ruleHint => 'Site, IP ou programme';

  @override
  String get ruleDirect => 'Direct';

  @override
  String get ruleProxy => 'Via VPN';

  @override
  String get ruleBlock => 'Bloc';

  @override
  String get failover => 'Échec de l\'allumage';

  @override
  String get connectOnStart => 'Se connecter au démarrage';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'l\'abonnement se termine dans les jours #',
      one: 'l\'abonnement se termine le jour #',
      zero: 'l\'abonnement se termine dans quelques heures',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name : $left gauche';
  }

  @override
  String get ruleInvalid => 'Cela ne ressemble pas à un site, une IP ou un programme';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les serveurs #, à leur tour',
      one: 'Serveur #, à son tour',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serveurs #, les plus rapides',
      one: 'Serveur #, le plus rapide',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelTun => 'Tout le trafic';

  @override
  String get tunnelProxy => 'proxy System';

  @override
  String get proxyAddress => 'Adresse proxy';

  @override
  String get copied => 'Copié';

  @override
  String get launchAtLogin => 'Commencez par le système';

  @override
  String get launchAtLoginDetail =>
      'Sora démarrera automatiquement à la connexion, en arrière-plan dans la barre d\'état.';

  @override
  String get closeToTray => 'Conserver dans le bac une fois fermé';

  @override
  String get notifications => 'Notifications';

  @override
  String get trayOpen => 'Ouvrir Sora';

  @override
  String get trayConnect => 'Connecter';

  @override
  String get trayDisconnect => 'Déconnecter';

  @override
  String get trayServer => 'Serveuse';

  @override
  String get trayQuit => 'Quitter Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora : $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora : $state, $server';
  }

  @override
  String get noticeInTray => 'Sora est toujours dans le bac';

  @override
  String get noticeInTrayBody => 'Quitter depuis le menu de son icône';

  @override
  String get noticeLost => 'Connexion perdue';

  @override
  String get noticeLostBody => 'Sora se reconnecte';

  @override
  String get noticeRestored => 'Connecté à nouveau';

  @override
  String get noticeFailed => 'Impossible de se connecter';

  @override
  String get noticeBackup => 'Le serveur principal n\'a pas répondu ; la sauvegarde transporte le trafic';

  @override
  String get noticeNext => 'Le serveur n\'a pas répondu ; le suivant transporte le trafic';

  @override
  String get noticeMainBack => 'Le serveur principal répond à nouveau et achemine le trafic';

  @override
  String get noticeSubscription => 'Abonnement';

  @override
  String get importTitle => 'Ajouter cet abonnement ?';

  @override
  String get importSealed =>
      'Ce lien est crypté pour Happ et seul Happ peut le lire. Demandez à votre fournisseur le lien d’abonnement simple.';

  @override
  String get understood => 'D\'ACCORD';

  @override
  String get noAnswer => 'pas de réponse';

  @override
  String get home => 'Maison';

  @override
  String get navRules => 'Règles';

  @override
  String get navConnections => 'Relations';

  @override
  String get navLogs => 'Journaux';

  @override
  String get navAbout => 'À propos';

  @override
  String get sidebarToggle => 'Basculer la barre latérale';

  @override
  String get more => 'Plus';

  @override
  String get less => 'Moins';

  @override
  String get currentServer => 'Serveur actuel';

  @override
  String get trafficDown => 'Téléchargé';

  @override
  String get trafficUp => 'Téléchargé';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Règles actives : $count';
  }

  @override
  String get recentNotifications => 'Notifications récentes';

  @override
  String get notificationsEmpty => 'Les événements de connexion et d\'abonnement apparaîtront ici';

  @override
  String get retryConnect => 'Réessayer la connexion';

  @override
  String get openLogs => 'Journaux ouverts';

  @override
  String get tourReplay => 'Afficher à nouveau le guide';

  @override
  String tourStep(int step) {
    return 'Étape $step sur 5';
  }

  @override
  String get tourBack => 'Dos';

  @override
  String get tourNext => 'Suivante';

  @override
  String get tourSkip => 'Sauter';

  @override
  String get tourFinish => 'Fait';

  @override
  String get tourAdd => 'Ajoutez le lien d\'abonnement de votre fournisseur.';

  @override
  String get tourServer => 'Choisissez un serveur. « Le plus rapide » en sélectionne un pour vous.';

  @override
  String get tourConnect => 'Cliquez ici pour vous connecter ou vous déconnecter.';

  @override
  String get tourMode => 'Choisissez un mode. Kill Switch bloque Internet si le VPN tombe.';

  @override
  String get tourSettings => 'Ouvrez les paramètres. Vous pouvez y rejouer ce guide.';

  @override
  String get chooseProgram => 'Choisissez un programme';

  @override
  String get installedApps => 'Applications installées';

  @override
  String get runningProcesses => 'Processus en cours d\'exécution';

  @override
  String get programsFailed => 'Impossible de charger les applications';

  @override
  String get programsEmpty => 'Aucune application trouvée. Essayez un autre nom.';

  @override
  String get selectExe => 'Choisissez un fichier .exe';

  @override
  String get trafficUnavailable => 'Les compteurs ne sont pas encore disponibles';

  @override
  String get speedtest => 'Vitesse';

  @override
  String get speedtestCheck => 'Vérifier la vitesse';

  @override
  String get speedtestSearch => 'Trouver un service';

  @override
  String get speedtestEmpty => 'Aucun match. Modifiez la recherche.';

  @override
  String get speedtestBackToList => 'Retour aux prestations';

  @override
  String get speedtestOpenBrowser => 'Ouvrir dans le navigateur';

  @override
  String get speedtestUnavailable =>
      'Le navigateur intégré n\'a pas pu démarrer. Ouvrez le service dans votre navigateur système.';

  @override
  String get speedtestPageFailed =>
      'La page n\'a pas pu se charger. Rechargez-le ou ouvrez le service dans le navigateur de votre système.';

  @override
  String get speedtestExternalFailed => 'Le navigateur système n\'a pas pu s\'ouvrir. Essayer à nouveau.';

  @override
  String get modes => 'Modes';

  @override
  String get proxyShort => 'Procuration';

  @override
  String get tunMode => 'Tout le trafic (TUN)';

  @override
  String get checkUpdates => 'Vérifier les mises à jour';

  @override
  String get updates => 'Mises à jour de l\'application';

  @override
  String updateAvailable(String version) {
    return 'La version $version est disponible';
  }

  @override
  String get updateOpenAbout => 'Afficher la mise à jour';

  @override
  String updateNotes(String version) {
    return 'Modifications apportées au $version';
  }

  @override
  String get updateCheck => 'Vérifier les mises à jour';

  @override
  String get updateChecking => 'Vérification...';

  @override
  String get updateNoNotes => 'Le communiqué ne contient aucune note.';

  @override
  String get updateDropWarning =>
      'La connexion VPN sera interrompue pendant quelques secondes pendant la mise à jour de Sora et de sa base. Continuer?';

  @override
  String get updateWaitConnection => 'Attendez que la connexion VPN et le noyau soient prêts.';

  @override
  String get updateDownloading => 'Téléchargement et vérification des fichiers...';

  @override
  String get updateInstalling =>
      'Préparation de la mise à jour ou attente de l\'authentification de l\'administrateur...';

  @override
  String get updateNetworkError => 'Impossible de télécharger la mise à jour. Essayer à nouveau.';

  @override
  String get updateReleaseError => 'Les données de version ou les fichiers requis sont manquants ou invalides.';

  @override
  String get updateChecksumError => 'Le téléchargement ne correspond pas à SHA256SUMS. Rien n\'a été installé.';

  @override
  String get updateInstallError => 'La mise à jour n\'est pas terminée. L\'authentification a peut-être été annulée.';

  @override
  String get updateUnsupported =>
      'Cet exécutable n\'appartient pas à une paire de packages Sora prise en charge. Utilisez les instructions d’installation de la version.';

  @override
  String get updateManual =>
      'Exécutez cette commande dans un terminal pour installer les deux packages vérifiés, puis rouvrez Sora. Les fichiers restent dans le répertoire de téléchargement. La connexion VPN sera interrompue.';

  @override
  String get updateSignaturePending =>
      'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';

  @override
  String get updateManualSigWarning =>
      'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

  @override
  String get updateWindowsSigBlocked =>
      'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';

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
  String get updateCopyCommand => 'Commande Copier';

  @override
  String get updateChecksDisabled => 'Les vérifications automatiques sont désactivées dans les paramètres.';

  @override
  String get updateInstalled => 'Mise à jour installée. Rouvrez Sora.';

  @override
  String get projectLinks => 'Projet';

  @override
  String get githubReleases => 'Sorties et téléchargements';

  @override
  String get telegramChannel => 'Canal Telegram';

  @override
  String get licenses => 'Licences';

  @override
  String get componentLicenses => 'Licences de composants';

  @override
  String get appCopyright => '© 2026 levvs-one et contributeurs';

  @override
  String get collapseServers => 'Réduire les serveurs';

  @override
  String get expandServers => 'Développer les serveurs';

  @override
  String get hideDescription => 'Masquer la description';

  @override
  String get showDescription => 'Afficher la description';

  @override
  String get pendingConnectionChanges => 'Reconnectez-vous pour appliquer ces modifications.';

  @override
  String get reconnectNow => 'Appliquer et reconnecter';

  @override
  String get bypassLimitations =>
      'Ce mode contourne le DPI uniquement pour HTTP et TLS, ne prend pas en charge UDP et ne modifie pas votre IP. Utilisez un serveur VPN pour la voix Discord, les appels et les adresses Telegram bloquées.';

  @override
  String get errEngineUnsupported =>
      'Le moteur sélectionné ne prend pas en charge ce profil ou ces paramètres. Choisissez Auto ou un moteur compatible.';

  @override
  String get errRestore =>
      'Le nettoyage de la connexion était incomplet. Réessayez de vous déconnecter ; voir le journal pour plus de détails.';

  @override
  String get errSessionEnded => 'Cette séance est déjà terminée. Actualisez l\'état de la connexion.';

  @override
  String get retryDisconnect => 'Réessayez de vous déconnecter';

  @override
  String get tunStack => 'Pile TUN';

  @override
  String get modesInfo => 'À propos des modes';

  @override
  String get modesGuideTitle => 'Modes et moteurs';

  @override
  String get modesGuide =>
      'Choisissez Auto si vous n\'êtes pas sûr du moteur dont votre serveur a besoin. Sora vérifie le profil et les paramètres avant de se connecter. Un moteur ne peut pas augmenter la bande passante de votre forfait : les performances dépendent du serveur, de la route, du protocole et du réseau.\n\n## Modes\n\n### Tout le trafic (TUN)\n\nSora crée une interface réseau virtuelle et achemine le trafic des applications via celle-ci, y compris TCP et UDP. Utilisez ce mode pour le Telegram, les jeux et la voix Discord. Les règles peuvent envoyer directement des sites ou des programmes spécifiques ou les bloquer. Le service réseau a besoin d\'une autorisation et d\'un serveur prenant en charge le protocole requis.\n\n### System proxy\n\nSora configure un proxy HTTP/SOCKS local. Les applications qui respectent les paramètres du proxy système l\'utilisent. Les applications disposant de leur propre pile réseau peuvent se connecter directement ; Les appels UDP et vocaux nécessitent généralement TUN. Ce mode convient aux navigateurs et aux applications prenant en charge les proxy.\n\n### Aucun serveur\n\nSur Linux, Sora utilise [zapret](https://github.com/bol-van/zapret) pour diviser et remodeler les requêtes HTTP/TLS et contourner certaines vérifications DPI. Votre IP reste la même et les connexions se font directement sur le site Internet. Les résultats dépendent de votre fournisseur et de la méthode de blocage.\n\nL\'intégration actuelle utilise tpws pour HTTP et TLS sur TCP. Il ne contourne pas le blocage IP ni le relais UDP et ne peut pas garantir les connexions MTProto du Telegram. Utilisez un serveur VPN avec TUN pour la voix Discord, les appels Telegram et ce type de restrictions.\n\n## Moteurs\n\n### Automatique\n\nSora sélectionne un moteur installé qui prend en charge l\'ensemble du plan de connexion : protocoles de serveur, transports, groupes, fragmentation et mode. Un choix manuel incompatible est rejeté avant d\'arrêter la connexion en cours. Choisissez Auto ou un autre moteur et appliquez à nouveau les paramètres.\n\n### sing-box\n\nLes nouveaux packages Sora incluent [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), un fork de [sing-box](https://github.com/SagerNet/sing-box), ajoutant XHTTP et VLESS Encryption côté client. Sora reconnaît la construction et ses capacités. Une version en amont sans XHTTP n’obtient pas cette fonctionnalité grâce à son seul nom.\n\nLes protocoles pris en charge incluent VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard et les paramètres AmneziaWG 1.x/2.x que Sora peut importer. Les profils JSON Xray complets nécessitent Xray. Les nouveaux champs AWG 3.x ne peuvent pas encore être importés. sing-box utilise un port de contrôle local protégé par mot de passe, que d\'autres applications sur l\'ordinateur peuvent détecter.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) prend en charge la fragmentation VLESS, REALITY, XHTTP, VLESS Encryption et TLS. Il exécute également des profils complets de fournisseur Xray tout en préservant leur routage et leurs groupes. De tels profils ne peuvent pas être automatiquement convertis vers un autre moteur sans modifier leur comportement.\n\nLe Xray fourni a supprimé le paramètre qui désactive la vérification du certificat TLS (`allowInsecure`). Sélectionne automatiquement sing-box ou mihomo pour les serveurs ordinaires nécessitant ce paramètre. La sélection de Xray signale manuellement l’incompatibilité avant d’arrêter la connexion actuelle. Les anciens profils JSON complets nécessitent un profil de fournisseur mis à jour avec un certificat ou un code PIN de certificat vérifiable.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) prend en charge les groupes de secours et d\'équilibrage de charge ordonnés, XHTTP et AmneziaWG. Choisissez-le lorsque le basculement automatique vers un serveur de sauvegarde est important. Le paramètre de fragmentation TLS du Sora n\'est pas disponible avec ce moteur.\n\n## Compatibilité dans Sora\n\n| Fonctionnalité | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN et TCP/UDP | Oui | Oui | Oui |\n| XHTTP | Oui | Oui | Oui |\n| VLESS Encryption | Oui | Oui | Oui |\n| Profil complet Xray | Non | Oui | Non |\n| TUIC / AnyTLS | Les deux | Non | TUIC |\n| Fragmentation TLS | Oui | Oui | Non |\n| AmneziaWG 1.x/2.x | Oui¹ | Non | Oui |\n| Groupe de secours ordonné | Non | Non² | Oui |\n\n¹ Les profils avec J1/J2/J3/Itime utilisent mihomo ; ces champs ne doivent jamais être ignorés en silence. ² Pour un groupe de profils Xray complets, l\'application sélectionne un profil de sauvegarde. La prise en charge dépend de la version installée ; vérifiez sa version dans À propos.\n\n## Pile TUN\n\nLa pile gère TCP et UDP à l\'intérieur de l\'interface virtuelle. Dans le panneau des modes, Xray et mihomo proposent gVisor, System, Mixed et MIPS. Chaque moteur enregistre sa propre préférence. Les modes proxy et sans serveur System n\'utilisent pas cette préférence.\n\n- **Mixed** — TCP utilise la pile système, tandis que gVisor gère UDP. Il s’agit de la valeur par défaut de mihomo sous Linux. Sous Windows, Xray et mihomo utilisent MIPS par défaut.\n- **System** — utilise la pile système. Essayez une autre option si les applications réseau rencontrent des problèmes.\n- **gVisor** — gère le trafic dans l\'espace utilisateur.\n- **MIPS** — La propre pile IP de mihomo, disponible dans la version groupée 1.19.32.\n\nSur Linux, Xray utilise par défaut son gVisor intégré. System, Mixed et MIPS sur Linux utilisent mihomo comme moteur TUN, transmettant TCP et UDP à Xray via une liaison SOCKS locale authentifiée. Xray conserve le protocole, le profil du fournisseur et le routage. Ces trois options nécessitent un mihomo installé. Sur Windows, Xray utilise mihomo 1.19.32 ou une version ultérieure pour les quatre piles TUN. Les protocoles et le routage restent dans Xray. Les règles des applications dans cette combinaison permettent uniquement les connexions directes et le blocage ; sous Linux, elles nécessitent le gVisor intégré de Xray.\n\nLe pont exécute un deuxième processus. Lors de trois mesures inactives sur le Linux, il a utilisé environ 32 à 36 Mio de mémoire physique de plus que le Xray TUN natif. Cela ne mesure pas la charge de téléchargement : les coûts du processeur et de la mémoire dépendent des connexions. Le sing-box n\'a pas de sélecteur de pile. Aucune pile ne garantit de meilleures performances sur chaque réseau. Choisissez une pile et sélectionnez Appliquer et reconnectez-vous pour l\'essayer sur votre réseau.\n\n## Application des paramètres\n\nLa sélection d\'un serveur se reconnecte automatiquement. Les paramètres de mode, de moteur, de DNS et de règles sont enregistrés immédiatement ; lors d\'une connexion active, cliquez sur Appliquer et reconnectez-vous pour les utiliser. Le redémarrage d\'un moteur peut interrompre les téléchargements et les appels. Les clics répétés ne démarrent pas de connexions parallèles ; la déconnexion met fin à la transition et libère la connexion.\n\nInternet uniquement via VPN bloque le trafic direct lorsqu\'un tunnel tombe. Cela affecte toute la machine. Une déconnexion explicite supprime les règles de Sora. Si le nettoyage ne se termine pas, réessayez de vous déconnecter et ouvrez le journal.\n\n## Documentation du projet\n\n- [sing-box-lx : configuration et support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentation sing-box](https://sing-box.sagernet.org/)\n- [Documentation Xray](https://xtls.github.io/)\n- [Documentation mihomo](https://wiki.metacubex.one/)\n- [zapret : fonctionnement et limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Vérifier les serveurs';

  @override
  String get extensions => 'Rallonges';

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
      'These extensions want the same thing. Choose which one wins — the other stays installed. When the contested capability is wired into the engine, only the winner will run.';

  @override
  String get extConflictRoutingRules => 'Routing rules';

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
  String get extCatalogSoonTitle => 'The team catalog is coming soon';

  @override
  String get extCatalogSoonBody =>
      'Until then, you can install extensions from a file or a link — every package is still signature-checked.';

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
      'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings. Background execution is not available in this version of Sora yet.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet — granting it changes nothing today.';

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
    return 'Cached catalog · $date';
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
      'Fetches data from the internet. Only the hosts below are allowed — everything else is blocked. Network fetch is not available in this version of Sora yet.';

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
      'Background execution is not available in this version of Sora. Your schedule is saved and will apply automatically once the background runtime ships. The shortest interval is 15 minutes.';

  @override
  String get extBgRuntimeBadge => 'Not available yet';

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
    return 'Dans $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostic HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData =>
      'Aucune demande enregistrée pour l\'instant. Ouvrez d’abord un site Web de test de vitesse.';

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
  String get qrScanHint => 'Choisissez une capture ou une photo avec un code QR, ou collez un lien';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Aucun code QR trouvé dans cette image.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Ouvrir une image';

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
  String get profileSsidsHint => 'Home, Office — comma separated';

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
  String get syncWhat => 'What syncs';

  @override
  String get syncWhatBody =>
      'Subscriptions, rules, settings and network profiles. Never synced: local logs, IPC tokens.';

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
      'If the selected server slows down a lot or stops answering, Sora switches to the best measured one — at most once every 10 minutes.';

  @override
  String get tunStackMixed => 'Mixed';

  @override
  String get tunStackSystem => 'System';

  @override
  String get censorTitle => 'Blocking diagnostics';

  @override
  String get censorHistory => 'Check history';

  @override
  String get censorEmpty =>
      'No checks yet. If a connection fails, the detector will check whether your provider is blocking it.';

  @override
  String get censorExplainer =>
      'This is not an app error: your provider seems to be limiting the connection. Masking changes how the app connects and often helps.';

  @override
  String get censorNoProfile => 'No suitable profile for this verdict';

  @override
  String get censorApplyProfile => 'Apply recommended profile';

  @override
  String get censorEnable => 'Enable';

  @override
  String get censorDetails => 'Details';

  @override
  String get censorNotNow => 'Not now';

  @override
  String get censorPromptTitle => 'Connection may be blocked';

  @override
  String censorPromptBody(int confidence) {
    return 'It looks like your provider is blocking the connection (confidence $confidence%). Try masking?';
  }

  @override
  String censorConfidence(int confidence) {
    return 'Confidence: $confidence%';
  }

  @override
  String get censorKindBlocked => 'Blocking detected';

  @override
  String get censorKindLikely => 'Looks like blocking';

  @override
  String get censorKindClear => 'No blocking detected';

  @override
  String get censorKindUnknown => 'Could not determine';

  @override
  String get censorReasonTlsReset => 'TLS connections are being reset — a typical sign of filtering';

  @override
  String get censorReasonHttpBlock => 'HTTP requests are being blocked';

  @override
  String get censorReasonDnsSpoofed => 'DNS responses are being spoofed';

  @override
  String get censorReasonConnectTimeout => 'Connections keep timing out';

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
  String get flowAuto => 'auto';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Add a server manually: address, port and protocol';

  @override
  String get customServerTest => 'Test';

  @override
  String get errObfsUnsupported => 'The installed core is too old for obfuscation profiles. Update Sora to apply them.';

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
  String get leakTestSkipped => 'Skipped — not applicable in this session';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Kill switch is on — run the test again to verify.';

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
  String get noticeDegraded => 'The server slowed down — switched to the best measured one';

  @override
  String get obfs => 'Traffic obfuscation';

  @override
  String get obfsPreset => 'Preset';

  @override
  String get obfsPresetAggressive => 'Maximum obfuscation';

  @override
  String get obfsPresetBalanced => 'Balanced';

  @override
  String get obfsPresetOff => 'Speed';

  @override
  String get obfsPresetCustom => 'Custom';

  @override
  String get obfsManual => 'Manual settings';

  @override
  String get obfsUtls => 'uTLS profile';

  @override
  String get obfsUtlsAuto => 'Auto';

  @override
  String get obfsJitter => 'Timing jitter';

  @override
  String get obfsJitterNeedsFragment => 'Jitter only works with fragmentation enabled.';

  @override
  String get obfsFineTune => 'Sizes and delays';

  @override
  String get obfsDetecting => 'Detecting capabilities…';

  @override
  String get obfsCapabilities => 'Engine capabilities';

  @override
  String obfsCompatibleEngines(String engines) {
    return 'Compatible engines: $engines';
  }

  @override
  String get obfsSupported => 'Supported';

  @override
  String get obfsUnsupported => 'Not supported';

  @override
  String get obfsUnknown => 'Capabilities are still being detected.';

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
      'The old device list was never actually paired, so it was cleared. Pair your devices again — for real this time.';

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
    return 'Received $pulled · sent $pushed';
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
  String get syncDocKindObfs => 'Traffic obfuscation';

  @override
  String syncFrom(String name) {
    return 'from $name';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet — the sync service can\'t run there.';

  @override
  String smartPickReason(String ping, String speed) {
    return 'Picked by smart mode: ping $ping, speed $speed';
  }

  @override
  String serverReliability(int pct) {
    return 'Reliability $pct%';
  }

  @override
  String get customServerShadowsocksCredentials =>
      'Pour Shadowsocks : méthode:mot de passe, par exemple chacha20-ietf-poly1305:motdepasse';
}
