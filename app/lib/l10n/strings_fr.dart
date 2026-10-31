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
  String get connEmpty => 'Aucune connexion';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Non installé';

  @override
  String get sourceCode => 'Code source';

  @override
  String get reportProblem => 'Signaler un problème';

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
  String get errAuth => 'L’accès au service Sora a été refusé';

  @override
  String get errVersion => 'L’application Sora et son service ont des versions différentes';

  @override
  String get errBusy => 'La commande précédente est toujours en cours';

  @override
  String get errEngineMissing => 'Le moteur nécessaire à ce serveur est introuvable';

  @override
  String get errEngineStart => 'Le moteur n’a pas pu démarrer';

  @override
  String get errEngineStopped => 'Le moteur s’est arrêté';

  @override
  String get errTunnel => 'Ce mode VPN est indisponible';

  @override
  String get errTimeout => 'Le serveur n’a pas répondu à temps';

  @override
  String get errFirewall => 'L’accès à Internet en dehors du VPN n’a pas pu être bloqué';

  @override
  String get errSubFetch => 'L’abonnement n’a pas pu être téléchargé';

  @override
  String get deviceIdentity => 'Identifiant de l\'appareil';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Réinitialiser l\'identifiant';

  @override
  String get deviceIdentityResetConfirm => 'Réinitialiser l\'identifiant de l\'appareil ?';

  @override
  String get errSubDeviceLimit => 'Limite d\'appareils atteinte';

  @override
  String get errSubDeviceRequired => 'Le fournisseur exige un identifiant d\'appareil';

  @override
  String get errSubFormat => 'Le format de l’abonnement n’est pas reconnu';

  @override
  String get errSubEmpty => 'L’abonnement ne contient aucun serveur';

  @override
  String get errSubDuplicate => 'Cet abonnement a déjà été ajouté';

  @override
  String get errSubLimit => 'La limite d’abonnements est atteinte';

  @override
  String get errSubScheme => 'Schéma de lien d’abonnement non pris en charge';

  @override
  String get errSecretStore => 'Le stockage de Sora est endommagé ou inaccessible';

  @override
  String get errNoServers => 'Aucun serveur n’est disponible pour la connexion';

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
  String get themeSystem => 'Comme le système';

  @override
  String get themeLight => 'Lumière';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Comme le système';

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
  String get splitPos => 'Positions fractionnées';

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
      other: 'l\'abonnement se termine dans les jours $days',
      one: 'l\'abonnement se termine le jour $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serveurs $count, les plus rapides',
      one: 'Serveur $count, le plus rapide',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelProxy => 'proxy System';

  @override
  String get proxyAddress => 'Adresse proxy';

  @override
  String get copied => 'Copié';

  @override
  String get launchAtLogin => 'Commencez par le système';

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
  String get importSealed => 'Ce lien est crypté pour Happ et seul Happ peut le lire';

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
  String get notificationsEmpty => 'Aucune notification';

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
  String get programsEmpty => 'Aucune application trouvée';

  @override
  String get selectExe => 'Choisissez un fichier .exe';

  @override
  String get speedtest => 'Vitesse';

  @override
  String get speedtestSearch => 'Trouver un service';

  @override
  String get speedtestEmpty => 'Aucun match';

  @override
  String get speedtestBackToList => 'Retour aux prestations';

  @override
  String get speedtestOpenBrowser => 'Ouvrir dans le navigateur';

  @override
  String get speedtestUnavailable => 'Le navigateur intégré n\'a pas pu démarrer';

  @override
  String get speedtestPageFailed => 'La page n\'a pas pu se charger';

  @override
  String get speedtestExternalFailed => 'Le navigateur système n\'a pas pu s\'ouvrir';

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
  String get updateDropWarning => 'Déconnecter pour mettre à jour ?';

  @override
  String get updateWaitConnection => 'La connexion n’est pas prête';

  @override
  String get updateDownloading => 'Téléchargement et vérification des fichiers...';

  @override
  String get updateInstalling =>
      'Préparation de la mise à jour ou attente de l\'authentification de l\'administrateur...';

  @override
  String get updateNetworkError => 'Impossible de télécharger la mise à jour';

  @override
  String get updateReleaseError => 'Les données de version ou les fichiers requis sont manquants ou invalides.';

  @override
  String get updateChecksumError => 'Le téléchargement ne correspond pas à SHA256SUMS';

  @override
  String get updateInstallError => 'La mise à jour n\'est pas terminée';

  @override
  String get updateUnsupported => 'Cet exécutable n\'appartient pas à une paire de packages Sora prise en charge';

  @override
  String get updateManual =>
      'Exécutez cette commande dans un terminal pour installer les deux packages vérifiés, puis rouvrez Sora. Les fichiers restent dans le répertoire de téléchargement. La connexion VPN sera interrompue.';

  @override
  String get updateVersionRevoked => 'Le développeur a retiré cette version';

  @override
  String get updateRolloutPending =>
      'Une version plus récente est déployée progressivement et vous sera proposée automatiquement.';

  @override
  String updateRollbacking(String version) {
    return 'Revenir à la version $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'La mise à jour vers $version n\'a pas réussi le contrôle de santé, donc Sora a été restauré vers $fromVersion.';
  }

  @override
  String get updateRollbackError => 'La restauration automatique a échoué';

  @override
  String get updateRollbackCacheError =>
      'Impossible de préparer une copie de restauration vérifiée de la version actuelle, la mise à jour n\'a donc pas été installée.';

  @override
  String get updateCopyCommand => 'Commande Copier';

  @override
  String get updateChecksDisabled => 'Les vérifications automatiques sont désactivées dans les paramètres.';

  @override
  String get updateInstalled => 'Mise à jour installée';

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
  String get collapseServers => 'Réduire les serveurs';

  @override
  String get expandServers => 'Développer les serveurs';

  @override
  String get hideDescription => 'Masquer la description';

  @override
  String get showDescription => 'Afficher la description';

  @override
  String get errEngineUnsupported => 'Le moteur sélectionné ne prend pas en charge ce profil ou ces paramètres';

  @override
  String get errRestore => 'Le nettoyage de la connexion était incomplet';

  @override
  String get errSessionEnded => 'Cette séance est déjà terminée';

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
      'Choisissez Auto si vous n\'êtes pas sûr du moteur dont votre serveur a besoin. Sora vérifie le profil et les paramètres avant de se connecter. Un moteur ne peut pas augmenter la bande passante de votre forfait : les performances dépendent du serveur, de la route, du protocole et du réseau.\n\n## Modes\n\n### Tout le trafic (TUN)\n\nSora crée une interface réseau virtuelle et achemine le trafic des applications via celle-ci, y compris TCP et UDP. Utilisez ce mode pour le Telegram, les jeux et la voix Discord. Les règles peuvent envoyer directement des sites ou des programmes spécifiques ou les bloquer. Le service réseau a besoin d\'une autorisation et d\'un serveur prenant en charge le protocole requis.\n\n### System proxy\n\nSora configure un proxy HTTP/SOCKS local. Les applications qui respectent les paramètres du proxy système l\'utilisent. Les applications disposant de leur propre pile réseau peuvent se connecter directement ; Les appels UDP et vocaux nécessitent généralement TUN. Ce mode convient aux navigateurs et aux applications prenant en charge les proxy.\n\n### Aucun serveur\n\nSur Linux, Sora utilise [zapret](https://github.com/bol-van/zapret) pour diviser et remodeler les requêtes HTTP/TLS et contourner certaines vérifications DPI. Votre IP reste la même et les connexions se font directement sur le site Internet. Les résultats dépendent de votre fournisseur et de la méthode de blocage.\n\nL\'intégration actuelle utilise tpws pour HTTP et TLS sur TCP. Il ne contourne pas le blocage IP ni le relais UDP et ne peut pas garantir les connexions MTProto du Telegram. Utilisez un serveur VPN avec TUN pour la voix Discord, les appels Telegram et ce type de restrictions.\n\n## Moteurs\n\n### Automatique\n\nSora sélectionne un moteur installé qui prend en charge l\'ensemble du plan de connexion : protocoles de serveur, transports, groupes, fragmentation et mode. Un choix manuel incompatible est rejeté avant d\'arrêter la connexion en cours. Choisissez Auto ou un autre moteur et appliquez à nouveau les paramètres.\n\n### sing-box\n\nLes nouveaux packages Sora incluent [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), un fork de [sing-box](https://github.com/SagerNet/sing-box), ajoutant XHTTP et VLESS Encryption côté client. Sora reconnaît la construction et ses capacités. Une version en amont sans XHTTP n’obtient pas cette fonctionnalité grâce à son seul nom.\n\nLes protocoles pris en charge incluent VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard et les paramètres AmneziaWG 1.x/2.x que Sora peut importer. Les profils JSON Xray complets nécessitent Xray. Les nouveaux champs AWG 3.x ne peuvent pas encore être importés. sing-box utilise un port de contrôle local protégé par mot de passe, que d\'autres applications sur l\'ordinateur peuvent détecter.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) prend en charge la fragmentation VLESS, REALITY, XHTTP, VLESS Encryption et TLS. Il exécute également des profils complets de fournisseur Xray tout en préservant leur routage et leurs groupes. De tels profils ne peuvent pas être automatiquement convertis vers un autre moteur sans modifier leur comportement.\n\nLe Xray fourni a supprimé le paramètre qui désactive la vérification du certificat TLS (`allowInsecure`). Sélectionne automatiquement sing-box ou mihomo pour les serveurs ordinaires nécessitant ce paramètre. La sélection de Xray signale manuellement l’incompatibilité avant d’arrêter la connexion actuelle. Les anciens profils JSON complets nécessitent un profil de fournisseur mis à jour avec un certificat ou un code PIN de certificat vérifiable.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) prend en charge les groupes de secours et d\'équilibrage de charge ordonnés, XHTTP et AmneziaWG. Choisissez-le lorsque le basculement automatique vers un serveur de sauvegarde est important. Le paramètre de fragmentation TLS du Sora n\'est pas disponible avec ce moteur.\n\n## Compatibilité dans Sora\n\n| Fonctionnalité | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN et TCP/UDP | Oui | Oui | Oui |\n| XHTTP | Oui | Oui | Oui |\n| VLESS Encryption | Oui | Oui | Oui |\n| Profil complet Xray | Non | Oui | Non |\n| TUIC / AnyTLS | Les deux | Non | TUIC |\n| mieru | Non | Non | Oui |\n| NaiveProxy | Oui | Non | Non |\n| Fragmentation TLS | Oui | Oui | Non |\n| AmneziaWG 1.x/2.x | Oui¹ | Non | Oui |\n| Groupe de secours ordonné | Non | Non² | Oui |\n\n¹ Les profils avec J1/J2/J3/Itime utilisent mihomo ; ces champs ne doivent jamais être ignorés en silence. ² Pour un groupe de profils Xray complets, l\'application sélectionne un profil de sauvegarde. La prise en charge dépend de la version installée ; vérifiez sa version dans À propos.\n\n## Pile TUN\n\nLa pile gère TCP et UDP à l\'intérieur de l\'interface virtuelle. Dans le panneau des modes, Xray et mihomo proposent gVisor, System, Mixed et MIPS. Chaque moteur enregistre sa propre préférence. Les modes proxy et sans serveur System n\'utilisent pas cette préférence.\n\n- **Mixed**: TCP utilise la pile système, tandis que gVisor gère UDP. Il s’agit de la valeur par défaut de mihomo sous Linux. Sous Windows, Xray et mihomo utilisent MIPS par défaut.\n- **System**: utilise la pile système. Essayez une autre option si les applications réseau rencontrent des problèmes.\n- **gVisor**: gère le trafic dans l\'espace utilisateur.\n- **MIPS**: La propre pile IP de mihomo, disponible dans la version groupée 1.19.32.\n\nSur Linux, Xray utilise par défaut son gVisor intégré. System, Mixed et MIPS sur Linux utilisent mihomo comme moteur TUN, transmettant TCP et UDP à Xray via une liaison SOCKS locale authentifiée. Xray conserve le protocole, le profil du fournisseur et le routage. Ces trois options nécessitent un mihomo installé. Sur Windows, Xray utilise mihomo 1.19.32 ou une version ultérieure pour les quatre piles TUN. Les protocoles et le routage restent dans Xray. Les règles des applications dans cette combinaison permettent uniquement les connexions directes et le blocage ; sous Linux, elles nécessitent le gVisor intégré de Xray.\n\nLe pont exécute un deuxième processus. Lors de trois mesures inactives sur le Linux, il a utilisé environ 32 à 36 Mio de mémoire physique de plus que le Xray TUN natif. Cela ne mesure pas la charge de téléchargement : les coûts du processeur et de la mémoire dépendent des connexions. Le sing-box n\'a pas de sélecteur de pile. Aucune pile ne garantit de meilleures performances sur chaque réseau.\n\n## Application des paramètres\n\nLa sélection d’un serveur rétablit automatiquement la connexion. Vos modifications du mode, du moteur, du DNS ou des règles sont appliquées une seule fois après une courte pause avec reconnexion automatique ; les mises à jour en arrière-plan ne reconnectent pas le VPN. Le redémarrage du moteur peut interrompre les téléchargements et les appels.\n\nInternet uniquement via VPN bloque le trafic direct lorsqu\'un tunnel tombe. Cela affecte toute la machine. Une déconnexion explicite supprime les règles de Sora. Si le nettoyage ne se termine pas, réessayez de vous déconnecter et ouvrez le journal.\n\n## Documentation du projet\n\n- [sing-box-lx : configuration et support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentation sing-box](https://sing-box.sagernet.org/)\n- [Documentation Xray](https://xtls.github.io/)\n- [Documentation mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret : fonctionnement et limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC transporte TCP dans un appel vidéo Jitsi, Yandex Telemost ou WB Stream. Importez un lien olcrtc:// ou un code QR. Le protocole fonctionne avec sing-box, Xray et mihomo en modes proxy et TUN ; UDP n’est pas pris en charge. Les deux extrémités doivent utiliser des versions OLC2 compatibles. Le projet d’origine est archivé.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Rallonges';

  @override
  String extRatingLabel(String rating) {
    return 'Note $rating sur 5';
  }

  @override
  String extByAuthor(String author) {
    return 'par $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Installations : $count';
  }

  @override
  String get extInstallOne => '1 installation';

  @override
  String get extSideloadWarning => 'Clé autosignée';

  @override
  String get extPermissionsWidened => 'La mise à jour demande de nouvelles autorisations :';

  @override
  String get extInstall => 'Installer';

  @override
  String get extUpdate => 'Mettre à jour';

  @override
  String get extCancel => 'Annuler';

  @override
  String get extConfirm => 'Confirmer';

  @override
  String get extCatalog => 'Catalogue';

  @override
  String get extInstalled => 'Extensions installées';

  @override
  String get extSearchHint => 'Rechercher des extensions';

  @override
  String get extCatAll => 'Tous';

  @override
  String get extCatTools => 'Outils';

  @override
  String get extCatThemes => 'Thèmes';

  @override
  String get extCatAutomation => 'Automatisation';

  @override
  String get extCatStats => 'Statistiques';

  @override
  String get extCatNetwork => 'Réseau';

  @override
  String get extSortBy => 'Trier par';

  @override
  String get extSortPopular => 'Les plus populaires';

  @override
  String get extSortRating => 'Le mieux noté';

  @override
  String get extSortName => 'Nom';

  @override
  String get extCatalogError => 'Impossible de charger le catalogue';

  @override
  String get extRetry => 'Réessayer';

  @override
  String get extEmptySearch => 'Rien trouvé';

  @override
  String get extEmptyInstalled => 'Aucune extension installée pour le moment';

  @override
  String get extInstallFromFile => 'Installer à partir d\'un fichier';

  @override
  String get extInstallFromUrl => 'Installer à partir de URL';

  @override
  String get extDownload => 'Télécharger';

  @override
  String get extDownloading => 'Téléchargement…';

  @override
  String get extVerifying => 'Vérification…';

  @override
  String get extInstalling => 'Installation…';

  @override
  String get extErrSignature => 'La vérification de la signature a échoué';

  @override
  String get extErrManifest => 'Le manifeste d’extension n’est pas valide.';

  @override
  String get extErrNetwork => 'Erreur réseau';

  @override
  String get extErrHash => 'Le téléchargement ne correspond pas au catalogue';

  @override
  String extErrMinApp(String version) {
    return 'Cette extension nécessite la version de l\'application $version ou une version plus récente.';
  }

  @override
  String get extErrHttpsOnly => 'Seuls les liens https:// sont autorisés';

  @override
  String get extErrGeneric => 'Quelque chose s\'est mal passé';

  @override
  String get extErrAuthorKeyChanged =>
      'Cette mise à jour est signée avec une clé d\'auteur différente de celle de la version installée, elle a donc été bloquée';

  @override
  String get extDisabled => 'Désactivé';

  @override
  String extToggleEnabled(String name) {
    return 'Activer $name';
  }

  @override
  String get extSearchInstalled => 'Rechercher parmi les extensions installées';

  @override
  String get extUpdateAll => 'Tout mettre à jour';

  @override
  String extUpdatesAvailable(int count) {
    return 'Mises à jour $count disponibles';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count mis à jour';
  }

  @override
  String get extRiskNormal => 'Normale';

  @override
  String get extRiskSensitive => 'Sensible';

  @override
  String get extRiskDangerous => 'Risque élevé';

  @override
  String get extPermissionsRemoved => 'Plus demandé :';

  @override
  String get extUpdateFailedKept => 'La version précédente est toujours installée.';

  @override
  String get extConflictsTitle => 'Conflits d\'extensions';

  @override
  String get extConflictTheme => 'Thème de l\'application';

  @override
  String get extConflictNetHooks => 'Crochets réseau';

  @override
  String extConflictWinner(String name) {
    return '$name gagne';
  }

  @override
  String extConflictsCount(int count) {
    return 'Conflits d\'extensions: $count';
  }

  @override
  String get extConflictsResolve => 'Résoudre les conflits';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extPermissionsTitle => 'Autorisations';

  @override
  String get extNoPermissions => 'Aucune autorisation spéciale.';

  @override
  String get extSettings => 'Paramètres';

  @override
  String get extSaveSettings => 'Enregistrer les paramètres';

  @override
  String extUpdateTo(String version) {
    return 'Mettre à jour vers $version';
  }

  @override
  String get extEnabled => 'Activé';

  @override
  String extRollbackTo(String version) {
    return 'Revenir à $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Revenir à la version $version ?';
  }

  @override
  String get extUninstall => 'Désinstaller';

  @override
  String extUninstallConfirm(String name) {
    return 'Supprimer « $name » et ses paramètres ?';
  }

  @override
  String get extPanelUnavailable => 'Le panneau de l’extension est indisponible.';

  @override
  String get extPermConnectionsRead => 'Voir la liste des connexions actives';

  @override
  String get extPermServersRead => 'Voir une liste de vos serveurs';

  @override
  String get extPermSettingsRead => 'Lire les paramètres de l\'application';

  @override
  String get extPermSettingsWrite => 'Modifier les paramètres de l\'application';

  @override
  String get extPermNotifications => 'Afficher les notifications';

  @override
  String get extPermTray => 'Ajouter des éléments au menu de la barre d\'état';

  @override
  String get extPermUiPanel => 'Afficher les panneaux dans l\'application';

  @override
  String get extPermThemeApply => 'Appliquer des thèmes';

  @override
  String get extPermRoutingRules => 'Ajouter des règles de routage';

  @override
  String get extPermNetHooks => 'Intégrer dans le chemin réseau';

  @override
  String get extPermNetFetch => 'Demander URL à partir de la liste autorisée';

  @override
  String get extPermBackground => 'Exécuter des tâches en arrière-plan';

  @override
  String get extPermNotYetActive => 'Désactivé';

  @override
  String get extCapBackground => 'Fonctionne en arrière-plan';

  @override
  String get extCapNetHook => 'Contournements et hooks réseau';

  @override
  String get extCapPanel => 'Panneaux d\'interface';

  @override
  String get extCapRouting => 'Règles de routage';

  @override
  String get extCapTheme => 'Thèmes';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Journal des modifications';

  @override
  String get extImageFailed => 'Impossible de charger l\'image';

  @override
  String get extScreenshots => 'Captures d\'écran';

  @override
  String get extSortRelevance => 'Pertinence';

  @override
  String get extBgTitle => 'Tâche en arrière-plan';

  @override
  String get extBgEnabled => 'Exécuter en arrière-plan';

  @override
  String get extBgInterval => 'Exécuter toutes les';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutes', one: '$count minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count heures', one: '$count heure');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Accès au réseau';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Réseau : $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Dans $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostic HTTP';

  @override
  String get diagnosticNoData => 'Aucune demande enregistrée pour l\'instant';

  @override
  String get qrShareTitle => 'Partager le code QR';

  @override
  String get qrScanTitle => 'Scanner le code QR';

  @override
  String get qrCopyLink => 'Copier le lien';

  @override
  String get qrWarning => 'Ne partagez ce code qu’avec des personnes de confiance.';

  @override
  String get qrFromClipboard => 'Coller depuis le presse-papiers';

  @override
  String get qrNoCode => 'Aucun code QR trouvé dans cette image.';

  @override
  String get qrInvalid => 'Ce code QR ne contient pas de lien valide.';

  @override
  String get qrScan => 'Scanner QR';

  @override
  String get qrFromImage => 'Ouvrir une image';

  @override
  String get connGroupByProcess => 'Regrouper par processus';

  @override
  String get connListView => 'Liste';

  @override
  String get connCopyHost => 'Copier l\'hôte';

  @override
  String get connAddRule => 'Ajouter une règle';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connexions',
      one: '$count connexion',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Préréglage';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Personnalisé';

  @override
  String get dnsCheck => 'Vérifier les fuites de données';

  @override
  String get dnsChecking => 'Vérification...';

  @override
  String get dnsNoLeak => 'Aucune fuite trouvée';

  @override
  String get dnsLeakFound => 'Fuite détectée';

  @override
  String get dnsLastCheck => 'Dernière vérification';

  @override
  String get dnsNeverChecked => 'Pas encore testé';

  @override
  String get dnsLeakCheckTunnelDns => 'Résolveurs DNS du tunnel';

  @override
  String get dnsLeakCheckSystemResolvers => 'Résolveurs système';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Protection DNS du coupe-circuit';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Configurez DNS pour le tunnel dans les paramètres DNS ci-dessus.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Vérifiez quels résolveurs votre système utiliserait en dehors du tunnel.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Activez le coupe-circuit pour que le trafic DNS reste dans le tunnel.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS chiffré du système';

  @override
  String get dnsLeakCheckDnsSpoof => 'Réponses DNS falsifiées';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Vérifiez quels points de terminaison DNS chiffrés votre système utilise en dehors du tunnel.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Utilisez un DNS chiffré (DoT ou DoH) pour le tunnel afin que les résolveurs ne puissent pas falsifier les réponses.';

  @override
  String get dnsCheckNeedsConnection => 'Connectez-vous d\'abord au VPN, puis vérifiez s\'il y a des fuites.';

  @override
  String get dnsExpected => 'Attendu';

  @override
  String get dnsActual => 'Observé';

  @override
  String get measureSpeed => 'Mesurer la vitesse';

  @override
  String get benchmarkStale => 'obsolète';

  @override
  String get autoSelectMode => 'Sélection automatique du serveur';

  @override
  String get autoSelectPing => 'Ping le plus rapide';

  @override
  String get autoSelectSpeed => 'Vitesse la plus rapide';

  @override
  String get autoSelectSmart => 'Choix intelligent';

  @override
  String get coreWatchUnstable => 'La connexion au cœur est instable';

  @override
  String get watchReconnect => 'Reconnecter';

  @override
  String get crashRestoreTitle => 'La dernière séance a été interrompue';

  @override
  String get restoreOnCrash => 'Restaurer la session après un crash';

  @override
  String get crashRestore => 'Restaurer';

  @override
  String get crashDismiss => 'Pas maintenant';

  @override
  String get overrideTitle => 'Mes modifications';

  @override
  String get overrideEdit => 'Modifier les serveurs';

  @override
  String get overrideHide => 'Masquer';

  @override
  String get overrideUnhide => 'Afficher';

  @override
  String get overrideClear => 'Réinitialiser les modifications';

  @override
  String get overrideEmpty => 'Aucune modification pour l\'instant';

  @override
  String get overrideCustomRules => 'Règles propres';

  @override
  String get errBenchmarkUnsupported => 'La mesure de vitesse nécessite une version plus récente du cœur';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Mesure de $done à partir de $total…';
  }

  @override
  String get profiles => 'Profils réseau';

  @override
  String get profilesEmpty => 'Aucun profil pour l\'instant';

  @override
  String get profileAdd => 'Ajouter un profil';

  @override
  String get profileName => 'Nom du profil';

  @override
  String get profileSsids => 'Réseaux Wi-Fi (SSID)';

  @override
  String get profileGateways => 'Passerelles réseau';

  @override
  String get profileAsns => 'Numéros AS';

  @override
  String get profileAutoApply => 'Appliquer automatiquement';

  @override
  String get profileSnapshot => 'Mémoriser les paramètres actuels';

  @override
  String get profileSnapshotDone => 'Paramètres actuels enregistrés dans le profil';

  @override
  String get profileDelete => 'Supprimer le profil';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Supprimer le profil \"$name\" ?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Appliquer le profil « $name » ?';
  }

  @override
  String get profileApply => 'Appliquer';

  @override
  String profileApplied(Object name) {
    return 'Profil « $name » appliqué';
  }

  @override
  String get profileUndo => 'Annuler';

  @override
  String get profileActive => 'Actif';

  @override
  String networkNow(Object info) {
    return 'Maintenant : $info';
  }

  @override
  String get networkUnknown => 'Informations réseau indisponibles';

  @override
  String get profileNoTriggers => 'Aucune condition de profil';

  @override
  String get chains => 'Chaînes proxy';

  @override
  String get chainsEmpty => 'Pas encore de chaînes';

  @override
  String get chainAdd => 'Nouvelle chaîne';

  @override
  String get chainName => 'Nom de la chaîne';

  @override
  String get chainTooFew => 'Une chaîne nécessite au moins deux serveurs';

  @override
  String get chainTooMany => 'Une chaîne ne peut pas dépasser trois serveurs';

  @override
  String get chainEstimate => 'Latence estimée';

  @override
  String get chainSave => 'Enregistrer la chaîne';

  @override
  String get chainDelete => 'Supprimer la chaîne';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Supprimer la chaîne \"$name\" ?';
  }

  @override
  String get chainUnsupported => 'Le moteur sélectionné ne prend pas en charge les chaînes';

  @override
  String get chainHopMissing => 'Un serveur de la chaîne n’est plus disponible';

  @override
  String chainHop(Object n) {
    return 'Saut $n';
  }

  @override
  String get chainEntry => 'Entrée';

  @override
  String get chainExit => 'Sortie';

  @override
  String get sync => 'Synchronisation des appareils';

  @override
  String get syncDevices => 'Mes appareils';

  @override
  String get syncEmpty => 'Aucun appareil couplé';

  @override
  String get syncPair => 'Associer l\'appareil';

  @override
  String get syncShowCode => 'Afficher mon code';

  @override
  String get syncScanCode => 'Scanner le code';

  @override
  String get syncRevoke => 'Retirer';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Révoquer « $name » ?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get syncNever => 'Jamais';

  @override
  String get syncPaired => 'Appareil couplé';

  @override
  String get syncPairingTitle => 'Associer avec cet appareil Système';

  @override
  String get syncWaiting => 'En attente de l\'autre appareil…';

  @override
  String get zapretWithVpn => 'Contourner le filtrage DPI pour le trafic réseau direct';

  @override
  String get chainDuplicate => 'Un serveur figure plusieurs fois dans la chaîne';

  @override
  String get edit => 'Modifier';

  @override
  String get remove => 'Supprimer';

  @override
  String get autoSwitchOnDegrade => 'Auto-allumage sur dégradation';

  @override
  String get tunStackMixed => 'Mixte';

  @override
  String get tunStackSystem => 'Système';

  @override
  String get customServerAdd => 'Ajouter un serveur personnalisé';

  @override
  String get customServers => 'Mes serveurs';

  @override
  String get customServerName => 'Nom';

  @override
  String get customServerNameRequired => 'Nom manquant';

  @override
  String get customServerAddress => 'Adresse';

  @override
  String get customServerAddressRequired => 'Adresse manquante';

  @override
  String get customServerAddressInvalid => 'Adresse invalide';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Port non valide';

  @override
  String get customServerProtocol => 'Protocole';

  @override
  String get customServerCredentials => 'Informations de connexion';

  @override
  String get customServerShowSecret => 'Afficher le secret';

  @override
  String get customServerHideSecret => 'Masquer le secret';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Supprimer le serveur « $name » ?';
  }

  @override
  String get leakTestTitle => 'Test de fuite de données';

  @override
  String get leakTestRun => 'Vérifier';

  @override
  String get leakTestCancel => 'Annuler';

  @override
  String get leakTestNeedsConnection => 'Connectez-vous au VPN pour tester les fuites de données.';

  @override
  String leakTestProgress(int count) {
    return 'Tests terminés : $count';
  }

  @override
  String get leakTestAllClear => 'Aucune fuite trouvée';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuites détectées',
      one: '$count fuite détectée',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Correction';

  @override
  String get leakTestFixedNote => 'Le coupe-circuit est activé. Relancez le test pour vérifier.';

  @override
  String get leakTestCheckDirectDns => 'Direct DNS';

  @override
  String get leakTestCheckIcmpEcho => 'Écho ICMP';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Résolveurs système';

  @override
  String get leakTestCheckTunnelConnectivity => 'Connectivité des tunnels';

  @override
  String get leakTestCheckTunnelDns => 'DNS à travers le tunnel';

  @override
  String get noticeDegraded =>
      'Le serveur est devenu lent. Sora est passé au meilleur serveur trouvé lors de la mesure.';

  @override
  String get obfs => 'Camouflage du trafic';

  @override
  String get syncCodeExpired => 'Le code a expiré';

  @override
  String get syncDaemonFailed => 'Impossible de démarrer le service de synchronisation';

  @override
  String get syncDaemonMissing => 'Le composant sora-sync n\'a pas été trouvé';

  @override
  String get syncDaemonStarting => 'Démarrage du service de synchronisation…';

  @override
  String get syncErrAuth => 'Le service de synchronisation a rejeté le jeton d\'accès';

  @override
  String get syncErrNotFound => 'L\'appareil n\'est plus couplé';

  @override
  String get syncErrPairingActive => 'Une session d\'appairage est déjà ouverte';

  @override
  String get syncErrUnreachable => 'L\'autre appareil n\'a pas répondu';

  @override
  String get syncError => 'Erreur de synchronisation';

  @override
  String syncExpiresIn(String duration) {
    return 'Le code expire dans $duration';
  }

  @override
  String get syncJoining => 'Couplage avec l\'appareil…';

  @override
  String get syncNewCode => 'Nouveau code';

  @override
  String syncPairedWith(String name) {
    return 'Associé à $name';
  }

  @override
  String get syncRetry => 'Répéter';

  @override
  String get syncStopShowing => 'Masquer le code';

  @override
  String get syncSyncNow => 'Synchroniser maintenant';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Reçu $pulled, envoyé $pushed';
  }

  @override
  String get syncResultTitle => 'Résultat de la synchronisation';

  @override
  String get syncPulled => 'Reçu';

  @override
  String get syncPushed => 'Envoyé';

  @override
  String get syncNoChanges => 'Aucun changement détecté';

  @override
  String get syncDocKindSubscriptions => 'Abonnements';

  @override
  String get syncDocKindSettings => 'Paramètres de l\'application';

  @override
  String get syncDocKindOverrides => 'Modifications des abonnements';

  @override
  String get syncDocKindProfiles => 'Profils réseau';

  @override
  String get syncDocKindChains => 'Chaînes proxy';

  @override
  String syncFrom(String name) {
    return 'depuis $name';
  }

  @override
  String get syncThisDevice => 'Cet appareil';

  @override
  String get syncUnavailableAndroid => 'Synchronisation indisponible sur Android';

  @override
  String get diagnosticPackets => 'Capture de paquets';

  @override
  String get diagnosticEvents => 'Événements Windows';

  @override
  String get diagnosticCapture => 'Capturez pendant 10 secondes';

  @override
  String get diagnosticRequiresTun => 'La capture de paquets nécessite une connexion Sora TUN active.';

  @override
  String get diagnosticUnavailable => 'Ce diagnostic n\'est pas disponible sur cette plateforme.';

  @override
  String get extErrRevoked =>
      'L’équipe Sora a retiré cette version de l’extension, car elle est dangereuse ou défectueuse.';

  @override
  String get extErrRevocationsExpired => 'L’installation est bloquée jusqu’à la mise à jour de la liste de révocation.';

  @override
  String extRevokedDisabled(String names) {
    return 'Des extensions retirées ont été désactivées : $names';
  }

  @override
  String get customServerWgPrivateKey => 'Clé privée';

  @override
  String get customServerWgAddresses => 'Adresses de l’interface';

  @override
  String get customServerWgPeerKey => 'Clé publique du serveur';

  @override
  String get customServerWgPresharedKey => 'Clé prépartagée';

  @override
  String get customServerWgAllowedIps => 'IP autorisées';

  @override
  String get customServerWgKeepalive => 'Keepalive, secondes';

  @override
  String get customServerWgKeyInvalid => 'Clé WireGuard non valide';

  @override
  String get customServerWgCidrInvalid => 'Préfixe CIDR non valide';

  @override
  String get customServerWgKeepaliveInvalid => 'Intervalle keepalive non valide';

  @override
  String get strictKillSwitch => 'Coupe-circuit strict';

  @override
  String get strictKillSwitchWarning => 'Bloquer le trafic hors VPN après la fermeture ?';

  @override
  String get extWorkerFailed => 'La tâche en arrière-plan de l’extension a échoué';

  @override
  String get extAssetRejected => 'Le fichier de l’extension contient des couleurs illisibles ou des règles invalides';

  @override
  String get extVerifiedSora => 'Vérifié par Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count o';
  }

  @override
  String get extOpen => 'Ouvrir';

  @override
  String get customServerOwn => 'Serveur personnel';

  @override
  String get customServerPaste => 'Coller un lien';

  @override
  String get customServerUser => 'Identifiant';

  @override
  String get customServerPassword => 'Mot de passe';

  @override
  String get customServerSecretRequired => 'Valeur manquante';

  @override
  String get customServerLinkInvalid => 'Lien du serveur invalide';

  @override
  String get errInternal => 'Erreur interne de Sora';

  @override
  String get errTls => 'Certificat du serveur refusé';

  @override
  String get errFileAccess => 'Accès au fichier impossible';

  @override
  String get errDataLimit => 'Trop de données';

  @override
  String get errCredentials => 'Identifiants enregistrés introuvables';

  @override
  String subscriptionStale(String time) {
    return 'Dernière mise à jour : $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Pas encore mis à jour';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Le serveur a renvoyé le code HTTP $status',
      zero: 'Le serveur a refusé la requête',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Paramètres du serveur incomplets ou non pris en charge';

  @override
  String get errServerIds => 'Deux serveurs ont le même identifiant';

  @override
  String get errRoutingGroup => 'Le routage renvoie à des serveurs absents ou à un groupe endommagé';

  @override
  String get errConnections => 'Liste des connexions indisponible';

  @override
  String get errLogs => 'Ce service ne conserve pas de journal';

  @override
  String get errDiagnostics => 'Impossible de recueillir le diagnostic';

  @override
  String get errMissingItem => 'L’élément demandé n’existe plus';

  @override
  String get errInvalidRequest => 'La demande contient des valeurs incorrectes';

  @override
  String get errProxyLogin => 'Le proxy système ne prend pas en charge cette connexion';

  @override
  String get errLogFilter => 'Filtre du journal incorrect';

  @override
  String get errSubRedirect => 'Le serveur a redirigé vers une adresse non sûre';

  @override
  String get errProxySetup => 'Impossible de configurer le proxy système';

  @override
  String get notificationsToday => 'Aujourd’hui';

  @override
  String get notificationsYesterday => 'Hier';

  @override
  String get notificationsMarkRead => 'Tout marquer comme lu';

  @override
  String get notificationsUnread => 'Non lu';

  @override
  String get desktopNotifications => 'Notifications du bureau';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'L’intervalle de mise à jour de l’abonnement n’est pas valide';

  @override
  String get errRule => 'Une règle de routage n’est pas valide';

  @override
  String get errDns => 'Les paramètres DNS ne sont pas valides';

  @override
  String get errEndpoint => 'L’adresse du serveur à tester n’est pas valide';

  @override
  String get errCancelled => 'La requête a été annulée';

  @override
  String get customServerOptions => 'Paramètres de connexion';

  @override
  String get customServerTransport => 'Transport';

  @override
  String get customServerSecurity => 'Sécurité';

  @override
  String get customServerCipher => 'Chiffrement';

  @override
  String get customServerWgInterface => 'Interface';

  @override
  String get customServerWgPeer => 'Pair';

  @override
  String extAvailableOn(String platforms) {
    return 'Disponible sur : $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Modifier le trafic TCP de toutes les applications ?';

  @override
  String get winwsRequirements => 'Ce mode VPN est indisponible';

  @override
  String get emptyServersTitle => 'Ajoutez un serveur ou un abonnement';

  @override
  String get emptyServersBody =>
      'Collez le lien d\'abonnement de votre service VPN, ajoutez votre propre serveur ou scannez un code QR.';

  @override
  String get qrShort => 'Code QR';

  @override
  String get extAboutHello => 'Panneau d\'exemple : affiche les connexions actives et envoie une notification de test.';

  @override
  String get extAboutZapret =>
      'Contourne les blocages sans VPN en modifiant le début des connexions pour que le fournisseur ne reconnaisse pas le site.';

  @override
  String get extAboutByedpi => 'Contourne les blocages sans VPN via le proxy local ByeDPI.';

  @override
  String get modeTunHint => 'Tout le trafic de l\'ordinateur passe par le VPN';

  @override
  String get modeProxyHint => 'Seulement les navigateurs et applis qui utilisent le proxy système';

  @override
  String get modeBypassHint => 'Contourner les blocages sans serveur VPN';

  @override
  String get modeExtensionHint => 'Contournement fourni par une extension';

  @override
  String get engineInfo =>
      'Le moteur établit la connexion au serveur.\n\nAuto : Sora choisit un moteur qui prend en charge le protocole du serveur.\nsing-box : rapide et polyvalent.\nXray : idéal pour VLESS avec REALITY et XHTTP.\nmihomo : abonnements Clash et règles souples.\n\nNe changez de moteur que si un serveur ne se connecte pas en Auto.';

  @override
  String get tunStackInfo =>
      'Comment le trafic passe du système au VPN.\n\nSystème : le plus rapide, via la pile réseau du système.\ngVisor : sa propre pile, compatible avec la plupart des applis.\nMixte : TCP via le système, UDP via gVisor.\n\nSi des sites ou des jeux fonctionnent mal, essayez une autre pile.';

  @override
  String get protection => 'Protection';

  @override
  String get killSwitchInfo =>
      'Si le VPN se coupe, Sora bloque Internet pour qu\'aucun trafic ne sorte hors du tunnel. L\'accès revient dès que le VPN se reconnecte ou est désactivé.';

  @override
  String get strictKillSwitchInfo =>
      'Le blocage reste actif après avoir quitté Sora et après un redémarrage, jusqu\'à ce que vous le désactiviez ici.';

  @override
  String get zapretWithVpnInfo => 'Les sites que vos règles envoient hors du VPN bénéficient du contournement Zapret.';

  @override
  String get failoverInfo => 'Si un serveur ne répond plus, Sora passe de lui-même au suivant qui fonctionne.';

  @override
  String get ipv6Info =>
      'Faire passer l\'IPv6 par le VPN. Désactivez si le serveur n\'a pas d\'IPv6 et que les sites chargent lentement.';

  @override
  String get fragmentInfo =>
      'Découpe le début d\'une connexion TLS pour que le filtre du fournisseur ne voie pas le nom du site. Utile quand un serveur est bloqué par SNI.';

  @override
  String get splitPosInfo =>
      'Où couper le premier paquet : un numéro d\'octet ou un repère comme midsld (milieu du domaine). Séparez plusieurs valeurs par des virgules.';

  @override
  String get disorderInfo =>
      'Envoie les parties d\'un paquet dans l\'ordre inverse pour dérouter les filtres qui le réassemblent dans l\'ordre.';

  @override
  String get tlsRecordInfo =>
      'Divise le hello TLS en plusieurs enregistrements pour que le nom du site ne soit jamais d\'un seul tenant.';

  @override
  String get hostCaseInfo =>
      'Change la casse de l\'en-tête Host des requêtes HTTP (Host → hoSt) pour que les anciens filtres ne les reconnaissent plus.';

  @override
  String get probeMethodInfo =>
      'Via le moteur : délai réel vers un site à travers le serveur, le plus précis.\nConnexion seule : simple connexion TCP au serveur, rapide mais ne teste pas le VPN.\nPoignée de main TLS : TCP et TLS avec le serveur.\nICMP : ping classique ; certains serveurs n\'y répondent pas.\nAuto : via le moteur, sinon une connexion.';

  @override
  String get autoSelectInfo =>
      'Comment « Le plus rapide » choisit un serveur : selon le ping, la vitesse mesurée ou les deux.';

  @override
  String get autoSwitchInfo => 'Si le serveur actuel devient nettement plus lent, Sora passe à un serveur plus rapide.';

  @override
  String get probeTls => 'Poignée de main TLS';

  @override
  String get probeIcmp => 'ICMP (ping)';
}
