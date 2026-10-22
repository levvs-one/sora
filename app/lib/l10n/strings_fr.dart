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
  String get programsEmpty => 'Aucune application trouvée. Essayez un autre nom.';

  @override
  String get selectExe => 'Choisissez un fichier .exe';

  @override
  String get speedtest => 'Vitesse';

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
      'Les fichiers de mise à jour sont vérifiés avec les sommes de contrôle publiées avec la version.';

  @override
  String get updateManualSigWarning =>
      'Les fichiers ci-dessous correspondent aux sommes de contrôle de la version. Lancez la commande si vous les avez téléchargés depuis la version officielle.';

  @override
  String get updateVersionRevoked => 'Le développeur a retiré cette version. Veuillez attendre une version corrigée.';

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
  String get updateRollbackError =>
      'La restauration automatique a échoué. Si la nouvelle version ne fonctionne pas, réinstallez manuellement la version précédente.';

  @override
  String get updateRollbackCacheError =>
      'Impossible de préparer une copie de restauration vérifiée de la version actuelle, la mise à jour n\'a donc pas été installée.';

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
      'Choisissez Auto si vous n\'êtes pas sûr du moteur dont votre serveur a besoin. Sora vérifie le profil et les paramètres avant de se connecter. Un moteur ne peut pas augmenter la bande passante de votre forfait : les performances dépendent du serveur, de la route, du protocole et du réseau.\n\n## Modes\n\n### Tout le trafic (TUN)\n\nSora crée une interface réseau virtuelle et achemine le trafic des applications via celle-ci, y compris TCP et UDP. Utilisez ce mode pour le Telegram, les jeux et la voix Discord. Les règles peuvent envoyer directement des sites ou des programmes spécifiques ou les bloquer. Le service réseau a besoin d\'une autorisation et d\'un serveur prenant en charge le protocole requis.\n\n### System proxy\n\nSora configure un proxy HTTP/SOCKS local. Les applications qui respectent les paramètres du proxy système l\'utilisent. Les applications disposant de leur propre pile réseau peuvent se connecter directement ; Les appels UDP et vocaux nécessitent généralement TUN. Ce mode convient aux navigateurs et aux applications prenant en charge les proxy.\n\n### Aucun serveur\n\nSur Linux, Sora utilise [zapret](https://github.com/bol-van/zapret) pour diviser et remodeler les requêtes HTTP/TLS et contourner certaines vérifications DPI. Votre IP reste la même et les connexions se font directement sur le site Internet. Les résultats dépendent de votre fournisseur et de la méthode de blocage.\n\nL\'intégration actuelle utilise tpws pour HTTP et TLS sur TCP. Il ne contourne pas le blocage IP ni le relais UDP et ne peut pas garantir les connexions MTProto du Telegram. Utilisez un serveur VPN avec TUN pour la voix Discord, les appels Telegram et ce type de restrictions.\n\n## Moteurs\n\n### Automatique\n\nSora sélectionne un moteur installé qui prend en charge l\'ensemble du plan de connexion : protocoles de serveur, transports, groupes, fragmentation et mode. Un choix manuel incompatible est rejeté avant d\'arrêter la connexion en cours. Choisissez Auto ou un autre moteur et appliquez à nouveau les paramètres.\n\n### sing-box\n\nLes nouveaux packages Sora incluent [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), un fork de [sing-box](https://github.com/SagerNet/sing-box), ajoutant XHTTP et VLESS Encryption côté client. Sora reconnaît la construction et ses capacités. Une version en amont sans XHTTP n’obtient pas cette fonctionnalité grâce à son seul nom.\n\nLes protocoles pris en charge incluent VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard et les paramètres AmneziaWG 1.x/2.x que Sora peut importer. Les profils JSON Xray complets nécessitent Xray. Les nouveaux champs AWG 3.x ne peuvent pas encore être importés. sing-box utilise un port de contrôle local protégé par mot de passe, que d\'autres applications sur l\'ordinateur peuvent détecter.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) prend en charge la fragmentation VLESS, REALITY, XHTTP, VLESS Encryption et TLS. Il exécute également des profils complets de fournisseur Xray tout en préservant leur routage et leurs groupes. De tels profils ne peuvent pas être automatiquement convertis vers un autre moteur sans modifier leur comportement.\n\nLe Xray fourni a supprimé le paramètre qui désactive la vérification du certificat TLS (`allowInsecure`). Sélectionne automatiquement sing-box ou mihomo pour les serveurs ordinaires nécessitant ce paramètre. La sélection de Xray signale manuellement l’incompatibilité avant d’arrêter la connexion actuelle. Les anciens profils JSON complets nécessitent un profil de fournisseur mis à jour avec un certificat ou un code PIN de certificat vérifiable.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) prend en charge les groupes de secours et d\'équilibrage de charge ordonnés, XHTTP et AmneziaWG. Choisissez-le lorsque le basculement automatique vers un serveur de sauvegarde est important. Le paramètre de fragmentation TLS du Sora n\'est pas disponible avec ce moteur.\n\n## Compatibilité dans Sora\n\n| Fonctionnalité | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN et TCP/UDP | Oui | Oui | Oui |\n| XHTTP | Oui | Oui | Oui |\n| VLESS Encryption | Oui | Oui | Oui |\n| Profil complet Xray | Non | Oui | Non |\n| TUIC / AnyTLS | Les deux | Non | TUIC |\n| Fragmentation TLS | Oui | Oui | Non |\n| AmneziaWG 1.x/2.x | Oui¹ | Non | Oui |\n| Groupe de secours ordonné | Non | Non² | Oui |\n\n¹ Les profils avec J1/J2/J3/Itime utilisent mihomo ; ces champs ne doivent jamais être ignorés en silence. ² Pour un groupe de profils Xray complets, l\'application sélectionne un profil de sauvegarde. La prise en charge dépend de la version installée ; vérifiez sa version dans À propos.\n\n## Pile TUN\n\nLa pile gère TCP et UDP à l\'intérieur de l\'interface virtuelle. Dans le panneau des modes, Xray et mihomo proposent gVisor, System, Mixed et MIPS. Chaque moteur enregistre sa propre préférence. Les modes proxy et sans serveur System n\'utilisent pas cette préférence.\n\n- **Mixed**: TCP utilise la pile système, tandis que gVisor gère UDP. Il s’agit de la valeur par défaut de mihomo sous Linux. Sous Windows, Xray et mihomo utilisent MIPS par défaut.\n- **System**: utilise la pile système. Essayez une autre option si les applications réseau rencontrent des problèmes.\n- **gVisor**: gère le trafic dans l\'espace utilisateur.\n- **MIPS**: La propre pile IP de mihomo, disponible dans la version groupée 1.19.32.\n\nSur Linux, Xray utilise par défaut son gVisor intégré. System, Mixed et MIPS sur Linux utilisent mihomo comme moteur TUN, transmettant TCP et UDP à Xray via une liaison SOCKS locale authentifiée. Xray conserve le protocole, le profil du fournisseur et le routage. Ces trois options nécessitent un mihomo installé. Sur Windows, Xray utilise mihomo 1.19.32 ou une version ultérieure pour les quatre piles TUN. Les protocoles et le routage restent dans Xray. Les règles des applications dans cette combinaison permettent uniquement les connexions directes et le blocage ; sous Linux, elles nécessitent le gVisor intégré de Xray.\n\nLe pont exécute un deuxième processus. Lors de trois mesures inactives sur le Linux, il a utilisé environ 32 à 36 Mio de mémoire physique de plus que le Xray TUN natif. Cela ne mesure pas la charge de téléchargement : les coûts du processeur et de la mémoire dépendent des connexions. Le sing-box n\'a pas de sélecteur de pile. Aucune pile ne garantit de meilleures performances sur chaque réseau. Choisissez une pile et sélectionnez Appliquer et reconnectez-vous pour l\'essayer sur votre réseau.\n\n## Application des paramètres\n\nLa sélection d\'un serveur se reconnecte automatiquement. Les paramètres de mode, de moteur, de DNS et de règles sont enregistrés immédiatement ; lors d\'une connexion active, cliquez sur Appliquer et reconnectez-vous pour les utiliser. Le redémarrage d\'un moteur peut interrompre les téléchargements et les appels. Les clics répétés ne démarrent pas de connexions parallèles ; la déconnexion met fin à la transition et libère la connexion.\n\nInternet uniquement via VPN bloque le trafic direct lorsqu\'un tunnel tombe. Cela affecte toute la machine. Une déconnexion explicite supprime les règles de Sora. Si le nettoyage ne se termine pas, réessayez de vous déconnecter et ouvrez le journal.\n\n## Documentation du projet\n\n- [sing-box-lx : configuration et support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentation sing-box](https://sing-box.sagernet.org/)\n- [Documentation Xray](https://xtls.github.io/)\n- [Documentation mihomo](https://wiki.metacubex.one/)\n- [zapret : fonctionnement et limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Vérifier les serveurs';

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
  String get extBadgeVerified => 'Vérifié';

  @override
  String get extBadgeTop => 'Les plus populaires cette semaine';

  @override
  String get extBadgeNew => 'Nouveau';

  @override
  String get extBadgeStaff => 'L\'équipe Sora';

  @override
  String get extSideloadShort => 'Pas du catalogue';

  @override
  String get extSideloadWarning =>
      'Cette extension ne provient pas du catalogue de l\'équipe. Seul l\'auteur s\'est porté garant de sa clé : installez-la uniquement si vous faites confiance à l\'auteur.';

  @override
  String extInstallTitle(String name) {
    return 'Installer « $name »';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Mettre à jour « $name »';
  }

  @override
  String get extPermissionsIntro => 'Cette extension pourra :';

  @override
  String get extPermissionsWidened => 'La mise à jour demande de nouvelles autorisations :';

  @override
  String get extDangerousAck => 'Je comprends que ces autorisations sont sérieuses';

  @override
  String get extInstall => 'Installer';

  @override
  String get extUpdate => 'Mettre à jour';

  @override
  String get extCancel => 'Annuler';

  @override
  String get extConfirm => 'Confirmer';

  @override
  String get extOk => 'OK';

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
  String get extEmptyInstalled =>
      'Aucune extension installée pour le moment.\nTrouvez-en un dans le catalogue ou installez-le à partir d\'un fichier.';

  @override
  String get extInstallFromFile => 'Installer à partir d\'un fichier';

  @override
  String get extInstallFromUrl => 'Installer à partir de URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Télécharger';

  @override
  String get extDownloading => 'Téléchargement…';

  @override
  String get extVerifying => 'Vérification…';

  @override
  String get extInstalling => 'Installation…';

  @override
  String get extInstallFailed => 'Échec de l\'installation';

  @override
  String get extErrSignature => 'La vérification de la signature a échoué. Le fichier peut être endommagé ou falsifié.';

  @override
  String get extErrManifest => 'Le manifeste d’extension n’est pas valide.';

  @override
  String get extErrNetwork => 'Erreur réseau. Vérifiez votre connexion et réessayez.';

  @override
  String get extErrHash => 'Le téléchargement ne correspond pas au catalogue. Il a peut-être été falsifié.';

  @override
  String extErrMinApp(String version) {
    return 'Cette extension nécessite la version de l\'application $version ou une version plus récente.';
  }

  @override
  String get extErrHttpsOnly => 'Seuls les liens https:// sont autorisés';

  @override
  String get extErrGeneric => 'Quelque chose s\'est mal passé. Veuillez réessayer.';

  @override
  String get extErrAuthorKeyChanged =>
      'Cette mise à jour est signée avec une clé d\'auteur différente de celle de la version installée, elle a donc été bloquée. Si vous faites confiance à la nouvelle clé, désinstallez l\'extension et réinstallez-la explicitement.';

  @override
  String get extUpdateAvailable => 'Mise à jour disponible';

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
  String get extConflictsIntro =>
      'Ces extensions veulent la même chose. Choisissez celle qui fonctionne ; l’autre reste installée.';

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
    return 'Les conflits $count nécessitent votre décision';
  }

  @override
  String get extConflictsResolve => 'Résoudre les conflits';

  @override
  String get extConflictNote =>
      'Votre choix est enregistré sur cet appareil. Un thème change immédiatement ; les hooks réseau ne s\'exécutent pas dans cette version.';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extAuthor => 'Auteur';

  @override
  String get extRating => 'Note';

  @override
  String get extInstalls => 'Installations';

  @override
  String get extVersion => 'Version';

  @override
  String get extAbout => 'À propos de cette extension';

  @override
  String get extPermissionsTitle => 'Autorisations';

  @override
  String get extNoPermissions => 'Aucune autorisation spéciale.';

  @override
  String get extSettings => 'Paramètres';

  @override
  String get extSaveSettings => 'Enregistrer les paramètres';

  @override
  String get extSaving => 'Sauvegarde…';

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
  String get extPanelUnavailable =>
      'Le panneau n\'est pas disponible. L\'extension a peut-être été désactivée ou supprimée.';

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
  String get extPermRoutingRules => 'Ajouter des règles de routage (affecte la destination du trafic réseau)';

  @override
  String get extPermNetHooks => 'Intégrer dans le chemin réseau (modules de contournement DPI)';

  @override
  String get extPermNetFetch => 'Demander URL à partir de la liste autorisée';

  @override
  String get extPermBackground => 'Exécuter des tâches en arrière-plan';

  @override
  String get extPermBackgroundDetail =>
      'Exécute les tâches planifiées même lorsque le panneau est fermé. Vous pouvez le suspendre ou modifier la fréquence d\'exécution dans les paramètres de l\'extension.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

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
  String get extRatingHow => 'Comment fonctionnent les notations';

  @override
  String get extRatingHowBody =>
      'Les notes utilisent une moyenne bayésienne : une extension avec peu de notes reste proche du milieu jusqu\'à ce que davantage de personnes votent, de sorte qu\'un seul avis 5 étoiles ne peut pas pousser une nouvelle extension vers le haut. Les notes récentes pèsent plus que les anciennes, et une seule note par compte compte.';

  @override
  String get extScreenshots => 'Captures d\'écran';

  @override
  String get extSortRelevance => 'Pertinence';

  @override
  String get extPermNetworkDetail =>
      'Récupère des données sur Internet via le VPN. Seuls les hôtes ci-dessous sont autorisés, tout le reste est bloqué.';

  @override
  String get extBgTitle => 'Tâche en arrière-plan';

  @override
  String get extBgEnabled => 'Exécuter en arrière-plan';

  @override
  String get extBgInterval => 'Exécuter toutes les';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minutes', one: '# minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# heures', one: '# heure');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'La tâche s’exécute selon le calendrier tant que Sora est ouvert, y compris dans la zone de notification. L’intervalle minimal est de 15 minutes.';

  @override
  String get extBgDisabledNote => 'Autoriser l\'extension à gérer sa tâche en arrière-plan.';

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
  String get diagnosticNoData =>
      'Aucune demande enregistrée pour l\'instant. Ouvrez d’abord un site Web de test de vitesse.';

  @override
  String get qrShareTitle => 'Partager le code QR';

  @override
  String get qrScanTitle => 'Scanner le code QR';

  @override
  String get qrCopyLink => 'Copier le lien';

  @override
  String get qrShowLink => 'Afficher le lien';

  @override
  String get qrHideLink => 'Masquer le lien';

  @override
  String get qrWarning => 'Ce code QR contient les détails de connexion. Ne le montrez pas à des étrangers.';

  @override
  String get qrScanHint => 'Choisissez une capture ou une photo avec un code QR, ou collez un lien';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# connexions', one: '# connexion');
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
  String get sortBy => 'Trier par';

  @override
  String get sortSubscription => 'Dans l’ordre de l’abonnement';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Vitesse';

  @override
  String get sortName => 'Nom';

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
  String get coreWatchUnstable => 'La connexion au noyau Sora est instable';

  @override
  String get watchReconnect => 'Reconnecter';

  @override
  String get coreRestoringLink => 'Rétablissement de la connexion au noyau Sora…';

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
  String get errBenchmarkUnsupported => 'La mesure de la vitesse nécessite un noyau plus récent';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Mesure de $done à partir de $total…';
  }

  @override
  String get profiles => 'Profils réseau';

  @override
  String get profilesEmpty =>
      'Aucun profil pour l\'instant. Créez-en un pour appliquer automatiquement les paramètres sur les réseaux connus.';

  @override
  String get profileAdd => 'Ajouter un profil';

  @override
  String get profileName => 'Nom du profil';

  @override
  String get profileSsids => 'Réseaux Wi-Fi (SSID)';

  @override
  String get profileSsidsHint => 'Domicile, Bureau séparés par des virgules';

  @override
  String get profileGateways => 'Passerelles réseau';

  @override
  String get profileAsns => 'Numéros AS';

  @override
  String get profileAutoApply => 'Appliquer automatiquement';

  @override
  String get profileAutoApplyHint =>
      'Si cette option est désactivée, une confirmation est demandée avant d’appliquer le profil.';

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
  String get profileNoTriggers => 'Ajoutez au moins un déclencheur : SSID, passerelle ou ASN';

  @override
  String get chains => 'Chaînes proxy';

  @override
  String get chainsEmpty => 'Pas encore de chaînes. Reliez 2 à 3 serveurs pour que le trafic passe par chacun d\'eux.';

  @override
  String get chainAdd => 'Nouvelle chaîne';

  @override
  String get chainName => 'Nom de la chaîne';

  @override
  String get chainPickServers => 'Choisissez 2 à 3 serveurs';

  @override
  String get chainOrderHint => 'Faites glisser pour réorganiser : le trafic entre par le haut et sort par le bas.';

  @override
  String get chainTooFew => 'Choisissez au moins 2 serveurs';

  @override
  String get chainTooMany => 'Une chaîne contient au maximum 3 serveurs';

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
  String get chainUnsupported => 'Le moteur actuel ne peut pas construire de chaînes';

  @override
  String get chainHopMissing => 'Un des serveurs de la chaîne n\'est plus disponible';

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
  String get syncEmpty => 'Aucun appareil couplé. Associez un autre appareil sur le réseau local.';

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
  String get syncNoLan => 'Les appareils doivent être sur le même réseau local';

  @override
  String get syncPaired => 'Appareil couplé';

  @override
  String get syncPairingTitle => 'Associer avec cet appareil Système';

  @override
  String get syncWaiting => 'En attente de l\'autre appareil…';

  @override
  String get syncSecureNote => 'Canal crypté de bout en bout. Pas de comptes, pas de serveurs cloud.';

  @override
  String get zapretWithVpn => 'Contourner le filtrage DPI pour le trafic réseau direct';

  @override
  String get zapretWithVpnHint =>
      'Exécute zapret en parallèle du tunnel VPN : le trafic du tunnel passe par le VPN, le trafic direct par le mécanisme de contournement.';

  @override
  String get chainDuplicate => 'Chaque serveur ne peut apparaître qu\'une seule fois';

  @override
  String get edit => 'Modifier';

  @override
  String get remove => 'Supprimer';

  @override
  String get autoSwitchOnDegrade => 'Auto-allumage sur dégradation';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Si le serveur sélectionné ralentit fortement ou ne répond plus, Sora passe au meilleur serveur mesuré, au maximum une fois toutes les 10 minutes.';

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
  String get customServerNameHint => 'Par exemple : mon VPS';

  @override
  String get customServerNameRequired => 'Entrez le nom';

  @override
  String get customServerAddress => 'Adresse';

  @override
  String get customServerAddressHint => 'example.com ou 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Entrez l\'adresse du serveur';

  @override
  String get customServerAddressInvalid => 'Adresse invalide';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Le port doit être un nombre compris entre 1 et 65535';

  @override
  String get customServerProtocol => 'Protocole';

  @override
  String get customServerCredentials => 'Informations de connexion';

  @override
  String get customServerOptional => 'Facultatif';

  @override
  String get customServerShowSecret => 'Afficher le secret';

  @override
  String get customServerHideSecret => 'Masquer le secret';

  @override
  String get customServerBadge => 'personnalisé';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Supprimer le serveur « $name » ?';
  }

  @override
  String get customServerEmptyHint => 'Ajouter un serveur manuellement : adresse, port et protocole';

  @override
  String get customServerTest => 'Essai';

  @override
  String get leakTestTitle => 'Test de fuite de données';

  @override
  String get leakTestIntro =>
      'Vérifie si du trafic peut quitter l’appareil en dehors du tunnel : requêtes DNS et ICMP directes, sortie IPv6 et résolveurs système. Lancez le test en étant connecté.';

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
      other: '# fuites détectées',
      one: '# fuite détectée',
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
  String get syncDaemonMissing =>
      'Le composant sora-sync n\'a pas été trouvé. Réinstallez l\'application pour activer la synchronisation des appareils.';

  @override
  String get syncDaemonStarting => 'Démarrage du service de synchronisation…';

  @override
  String get syncErrAuth =>
      'Le service de synchronisation a rejeté le jeton d\'accès. Redémarrez l\'application et réessayez.';

  @override
  String get syncErrNotFound => 'L\'appareil n\'est plus couplé';

  @override
  String get syncErrPairingActive => 'Une session d\'appairage est déjà ouverte';

  @override
  String get syncErrUnreachable =>
      'L\'autre appareil n\'a pas répondu. Assurez-vous qu\'il est sur le même réseau et qu\'il affiche son code.';

  @override
  String get syncError => 'Erreur de synchronisation';

  @override
  String syncExpiresIn(String duration) {
    return 'Le code expire dans $duration';
  }

  @override
  String get syncJoining => 'Couplage avec l\'appareil…';

  @override
  String get syncLegacyCleared =>
      'L\'ancienne liste d\'appareils n\'a jamais été réellement couplée, elle a donc été effacée. Associez à nouveau vos appareils, pour de vrai cette fois.';

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
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Pour Shadowsocks : méthode:mot de passe, par exemple chacha20-ietf-poly1305:motdepasse';

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
  String get extErrRevocationsExpired =>
      'La liste des extensions retirées n’a pas pu être renouvelée. L’installation est bloquée jusqu’à son renouvellement : vérifiez le réseau et réessayez.';

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
  String get customServerWgKeyInvalid => 'La clé doit faire 32 octets en base64, comme l’affiche wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'Saisissez des préfixes séparés par des virgules, comme 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Saisissez un nombre de secondes entre 0 et 65535.';

  @override
  String get strictKillSwitch => 'Coupe-circuit strict';

  @override
  String get strictKillSwitchWarning =>
      'Après la connexion, bloque le trafic hors VPN même après un plantage, un redémarrage ou la fermeture de l’application. Seule la déconnexion ou la désactivation de cette option rétablit l’accès. Après un redémarrage du système, le blocage reprend uniquement si la connexion au démarrage est activée.';

  @override
  String get extWorkerFailed => 'La tâche en arrière-plan de l’extension a échoué. Consultez son journal.';

  @override
  String get extAssetRejected => 'Fichier d’extension refusé : couleurs illisibles ou règles invalides.';
}
