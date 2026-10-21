// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get stateOff => 'No conectada';

  @override
  String get stateConnecting => 'Conectando';

  @override
  String get stateConnected => 'Conectada';

  @override
  String get stateReconnecting => 'Reconectando';

  @override
  String get stateDisconnecting => 'Desconectando';

  @override
  String get stateFailed => 'No conectada';

  @override
  String get coreMissing => 'El servicio Sora no responde';

  @override
  String get serverAuto => 'Más rápida';

  @override
  String get serverBypass => 'Sin servidor';

  @override
  String get addSubscription => 'Agregar suscripción';

  @override
  String get servers => 'Servidoras';

  @override
  String get settings => 'Ajustes';

  @override
  String get subscription => 'Suscripción';

  @override
  String get subscriptionLink => 'Enlace de suscripción';

  @override
  String get add => 'Agregar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get rename => 'Rebautizar';

  @override
  String get delete => 'Borrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Ahorrar';

  @override
  String get name => 'Nombre';

  @override
  String deleteSubscription(String name) {
    return '¿Eliminar “$name”?';
  }

  @override
  String get routes => 'Rutas';

  @override
  String get presetGlobal => 'Todo a través de VPN';

  @override
  String get presetRu => 'Rusia directa';

  @override
  String get presetIr => 'Irán directo';

  @override
  String get presetCn => 'China directa';

  @override
  String get blockAds => 'Bloquear anuncios';

  @override
  String get killSwitch => 'Internet solo a través de VPN';

  @override
  String get engine => 'Motor';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'animaciones';

  @override
  String get logs => 'Registro';

  @override
  String get about => 'Acerca de';

  @override
  String get logsAll => 'Toda';

  @override
  String get logsImportant => 'Importante';

  @override
  String get logsErrors => 'Errores';

  @override
  String get search => 'Buscar';

  @override
  String get export => 'Guardar en archivo';

  @override
  String get clear => 'Clara';

  @override
  String get logsEmpty => 'Nada aquí';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get notInstalled => 'No instalado';

  @override
  String get sourceCode => 'código fuente';

  @override
  String get license => 'Licencia';

  @override
  String usage(String used, String total) {
    return '$used de $total';
  }

  @override
  String until(String date) {
    return 'hasta $date';
  }

  @override
  String get expired => 'Caducada';

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
    return '${n}KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n ES';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'algo salió mal';

  @override
  String get errCore => 'El servicio Sora no responde';

  @override
  String get errAuth => 'Sin acceso al servicio Sora';

  @override
  String get errVersion => 'Actualización Sora: la aplicación y el servicio son versiones diferentes';

  @override
  String get errBusy => 'Espera, el comando anterior todavía se está ejecutando.';

  @override
  String get errEngineMissing => 'No se encontró ningún motor para este servidor';

  @override
  String get errEngineStart => 'El motor no arrancó';

  @override
  String get errEngineStopped => 'El motor se detuvo';

  @override
  String get errTunnel => 'Sin permiso para crear la conexión VPN';

  @override
  String get errServers => 'El servidor está configurado con un error.';

  @override
  String get errNetwork => 'No se puede llegar al servidor';

  @override
  String get errTimeout => 'El servidor no respondió a tiempo.';

  @override
  String get errFirewall => 'No se pudo bloquear Internet fuera de la VPN';

  @override
  String get errSubFetch => 'No se pudo cargar la suscripción';

  @override
  String get errSubFormat => 'Este no es un enlace de suscripción.';

  @override
  String get errSubEmpty => 'La suscripción no tiene servidores.';

  @override
  String get errSubDuplicate => 'Esta suscripción ya está agregada.';

  @override
  String get errSubLimit => 'Demasiadas suscripciones';

  @override
  String get errSubScheme => 'El enlace debe comenzar con https://';

  @override
  String get errSecretStore => 'El almacenamiento Sora está dañado o no está disponible';

  @override
  String get errNoServers => 'Añade una suscripción para conectarte';

  @override
  String get exportText => 'Texto';

  @override
  String get connections => 'Conexiones';

  @override
  String get close => 'Cerca';

  @override
  String get chainDirect => 'Directa';

  @override
  String get chainBlocked => 'Obstruida';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ligera';

  @override
  String get themeDark => 'Oscura';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Conexión';

  @override
  String get sectionNoServer => 'Sin servidor';

  @override
  String get sectionPing => 'Silbido';

  @override
  String get sectionLog => 'Diagnóstica';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Direcciones, separadas por comas';

  @override
  String get fragment => 'fragmentación TLS';

  @override
  String get fragmentPackets => 'que dividir';

  @override
  String get fragmentLength => 'Tamaño de pieza';

  @override
  String get fragmentInterval => 'Pausa entre piezas';

  @override
  String get byDefault => 'Por defecto';

  @override
  String get rangeHint => 'Por ejemplo, 100-200';

  @override
  String get splitPos => 'Posiciones divididas';

  @override
  String get splitPosHint => 'Por ejemplo, 1, medio';

  @override
  String get disorder => 'Reordenar piezas';

  @override
  String get tlsRecord => 'Dividir el registro TLS';

  @override
  String get tlsRecordNo => 'No';

  @override
  String get tlsRecordSni => 'En el nombre del sitio';

  @override
  String get tlsRecordFirst => 'Después del primer byte';

  @override
  String get hostCase => 'Cambiar caso de host';

  @override
  String get probeMethod => 'Método';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'A través del motor';

  @override
  String get probeConnect => 'Sólo conexión';

  @override
  String get probeUrl => 'Dirección de prueba';

  @override
  String get probeTimeout => 'Esperar';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Suscripciones';

  @override
  String get subscriptionSettings => 'Ajustes';

  @override
  String get userAgent => 'Agente de usuario';

  @override
  String get autoUpdate => 'Actualizar automáticamente';

  @override
  String get updateInterval => 'Con qué frecuencia';

  @override
  String get intervalProvider => 'Como pregunta el proveedor';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get logLevel => 'que grabar';

  @override
  String get levelDebug => 'Toda';

  @override
  String get levelInfo => 'Habitual';

  @override
  String get levelWarning => 'Importante';

  @override
  String get levelError => 'Sólo errores';

  @override
  String get recordDestinations => 'Registrar direcciones de sitios';

  @override
  String get reset => 'Restablecer configuración';

  @override
  String get resetConfirm => '¿Restablecer todas las configuraciones?';

  @override
  String get resetAction => 'Reiniciar';

  @override
  String get invalidValue => 'Este valor no funcionará';

  @override
  String get website => 'Página de suscripción';

  @override
  String get providerWebsite => 'Sitio web del proveedor';

  @override
  String get support => 'Apoyo';

  @override
  String controlPortQuestion(String engine) {
    return '$engine se controla a través de un puerto en esta computadora. Otros programas podrán saber que hay una VPN activada.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Elija $engine';
  }

  @override
  String get rules => 'Reglas personalizadas';

  @override
  String get ruleAdd => 'Nueva regla';

  @override
  String get ruleHint => 'Sitio, IP o programa';

  @override
  String get ruleDirect => 'Directa';

  @override
  String get ruleProxy => 'A través de VPN';

  @override
  String get ruleBlock => 'Bloquear';

  @override
  String get failover => 'Fallo de encendido';

  @override
  String get connectOnStart => 'Conectar al inicio';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'la suscripción finaliza en días #',
      one: 'la suscripción finaliza el día #',
      zero: 'la suscripción finaliza en unas horas',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left izquierda';
  }

  @override
  String get ruleInvalid => 'Esto no parece un sitio, una IP o un programa.';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores #, a su vez',
      one: 'Servidor #, a su vez',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores #, la más rápida',
      one: 'Servidor #, la más rápida',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modo';

  @override
  String get tunnelTun => 'Todo el tráfico';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'dirección proxy';

  @override
  String get copied => 'Copiada';

  @override
  String get launchAtLogin => 'Comience con el sistema';

  @override
  String get launchAtLoginDetail =>
      'Sora se iniciará automáticamente al iniciar sesión y quedará en la bandeja del sistema.';

  @override
  String get closeToTray => 'Mantener en la bandeja cuando esté cerrada.';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get trayOpen => 'Abierto Sora';

  @override
  String get trayConnect => 'Conectar';

  @override
  String get trayDisconnect => 'Desconectar';

  @override
  String get trayServer => 'Servidora';

  @override
  String get trayQuit => 'Salir de Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora todavía está en la bandeja.';

  @override
  String get noticeInTrayBody => 'Salir desde el menú de su icono';

  @override
  String get noticeLost => 'Conexión perdida';

  @override
  String get noticeLostBody => 'Sora se está reconectando';

  @override
  String get noticeRestored => 'Conectada de nuevo';

  @override
  String get noticeFailed => 'No se pudo conectar';

  @override
  String get noticeBackup => 'El servidor principal no respondió; la copia de seguridad lleva el tráfico';

  @override
  String get noticeNext => 'El servidor no respondió; el siguiente lleva el tráfico';

  @override
  String get noticeMainBack => 'El servidor principal responde nuevamente y transporta el tráfico.';

  @override
  String get noticeSubscription => 'Suscripción';

  @override
  String get importTitle => '¿Agregar esta suscripción?';

  @override
  String get importSealed =>
      'Este enlace está cifrado para Happ y solo Happ puede leerlo. Pídale a su proveedor el enlace de suscripción simple.';

  @override
  String get understood => 'DE ACUERDO';

  @override
  String get noAnswer => 'sin respuesta';

  @override
  String get home => 'Hogar';

  @override
  String get navRules => 'Normas';

  @override
  String get navConnections => 'Conexiones';

  @override
  String get navLogs => 'Registros';

  @override
  String get navAbout => 'Acerca de';

  @override
  String get sidebarToggle => 'Alternar barra lateral';

  @override
  String get more => 'Más';

  @override
  String get less => 'Menos';

  @override
  String get currentServer => 'Servidor actual';

  @override
  String get trafficDown => 'Descargada';

  @override
  String get trafficUp => 'subido';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Reglas activas: $count';
  }

  @override
  String get recentNotifications => 'Notificaciones recientes';

  @override
  String get notificationsEmpty => 'Los eventos de conexión y suscripción aparecerán aquí';

  @override
  String get retryConnect => 'Reintentar conexión';

  @override
  String get openLogs => 'Abrir registros';

  @override
  String get tourReplay => 'Mostrar guía nuevamente';

  @override
  String tourStep(int step) {
    return 'Paso $step de 5';
  }

  @override
  String get tourBack => 'Atrás';

  @override
  String get tourNext => 'Próxima';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get tourFinish => 'Hecho';

  @override
  String get tourAdd => 'Agregue el enlace de suscripción de su proveedor.';

  @override
  String get tourServer => 'Elige un servidor. \"Más rápido\" selecciona uno por usted.';

  @override
  String get tourConnect => 'Haga clic aquí para conectarse o desconectarse.';

  @override
  String get tourMode => 'Elige un modo. Kill Switch bloquea Internet si la VPN se cae.';

  @override
  String get tourSettings => 'Abra la configuración. Puedes reproducir esta guía allí.';

  @override
  String get chooseProgram => 'Elige un programa';

  @override
  String get installedApps => 'Aplicaciones instaladas';

  @override
  String get runningProcesses => 'Procesos en ejecución';

  @override
  String get programsFailed => 'No se pudieron cargar aplicaciones';

  @override
  String get programsEmpty => 'No se encontraron aplicaciones. Prueba con otro nombre.';

  @override
  String get selectExe => 'Elija un archivo .exe';

  @override
  String get trafficUnavailable => 'Los contadores aún no están disponibles';

  @override
  String get speedtest => 'Velocidad';

  @override
  String get speedtestCheck => 'comprobar velocidad';

  @override
  String get speedtestSearch => 'encontrar un servicio';

  @override
  String get speedtestEmpty => 'Sin coincidencias. Cambia la búsqueda.';

  @override
  String get speedtestBackToList => 'Volver a servicios';

  @override
  String get speedtestOpenBrowser => 'Abrir en el navegador';

  @override
  String get speedtestUnavailable =>
      'El navegador integrado no pudo iniciarse. Abra el servicio en el navegador de su sistema.';

  @override
  String get speedtestPageFailed =>
      'La página no se pudo cargar. Vuelva a cargarlo o abra el servicio en el navegador de su sistema.';

  @override
  String get speedtestExternalFailed => 'El navegador del sistema no se pudo abrir. Intentar otra vez.';

  @override
  String get modes => 'Modos';

  @override
  String get proxyShort => 'Apoderada';

  @override
  String get tunMode => 'Todo el tráfico (TUN)';

  @override
  String get checkUpdates => 'Buscar actualizaciones';

  @override
  String get updates => 'Actualizaciones de aplicaciones';

  @override
  String updateAvailable(String version) {
    return 'La versión $version está disponible';
  }

  @override
  String get updateOpenAbout => 'Ver actualización';

  @override
  String updateNotes(String version) {
    return 'Cambios en $version';
  }

  @override
  String get updateCheck => 'Buscar actualizaciones';

  @override
  String get updateChecking => 'De cheques...';

  @override
  String get updateNoNotes => 'El comunicado no tiene notas.';

  @override
  String get updateDropWarning =>
      'La conexión VPN se cortará durante unos segundos mientras Sora y su actualización principal. ¿Continuar?';

  @override
  String get updateWaitConnection => 'Espere a que la conexión VPN y el núcleo estén listos.';

  @override
  String get updateDownloading => 'Descargando y verificando archivos...';

  @override
  String get updateInstalling => 'Preparando la actualización o esperando la autenticación del administrador...';

  @override
  String get updateNetworkError => 'No se pudo descargar la actualización. Intentar otra vez.';

  @override
  String get updateReleaseError => 'Los datos de publicación o los archivos requeridos faltan o no son válidos.';

  @override
  String get updateChecksumError => 'La descarga no coincide con SHA256SUMS. No se instaló nada.';

  @override
  String get updateInstallError => 'La actualización no terminó. Es posible que se haya cancelado la autenticación.';

  @override
  String get updateUnsupported =>
      'Este ejecutable no pertenece a ningún par de paquetes Sora compatible. Utilice las instrucciones de instalación de la versión.';

  @override
  String get updateManual =>
      'Ejecute este comando en una terminal para instalar ambos paquetes verificados y luego vuelva a abrir Sora. Los archivos permanecen en el directorio de descarga. La conexión VPN se cortará.';

  @override
  String get updateSignaturePending =>
      'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';

  @override
  String get updateManualSigWarning =>
      'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

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
  String get updateCopyCommand => 'comando copiar';

  @override
  String get updateChecksDisabled => 'Las comprobaciones automáticas están deshabilitadas en Configuración.';

  @override
  String get updateInstalled => 'Actualización instalada. Vuelva a abrir Sora.';

  @override
  String get projectLinks => 'Proyecto';

  @override
  String get githubReleases => 'Lanzamientos y descargas';

  @override
  String get telegramChannel => 'Canal Telegram';

  @override
  String get licenses => 'Licencias';

  @override
  String get componentLicenses => 'Licencias de componentes';

  @override
  String get appCopyright => '© 2026 levvs-one y colaboradores';

  @override
  String get collapseServers => 'Colapsar servidores';

  @override
  String get expandServers => 'Ampliar servidores';

  @override
  String get hideDescription => 'Ocultar descripción';

  @override
  String get showDescription => 'Mostrar descripción';

  @override
  String get pendingConnectionChanges => 'Vuelva a conectarse para aplicar estos cambios.';

  @override
  String get reconnectNow => 'Aplicar y reconectar';

  @override
  String get bypassLimitations =>
      'Este modo omite DPI solo para HTTP y TLS, no admite UDP ni cambia su IP. Utilice un servidor VPN para voz Discord, llamadas y direcciones Telegram bloqueadas.';

  @override
  String get errEngineUnsupported =>
      'El motor seleccionado no admite este perfil o configuración. Elija Auto o un motor compatible.';

  @override
  String get errRestore =>
      'La limpieza de la conexión fue incompleta. Vuelva a intentar desconectarse; consulte el registro para obtener más detalles.';

  @override
  String get errSessionEnded => 'Esta sesión ya ha terminado. Actualiza el estado de la conexión.';

  @override
  String get retryDisconnect => 'Reintentar desconectar';

  @override
  String get tunStack => 'pila TUN';

  @override
  String get modesInfo => 'Acerca de los modos';

  @override
  String get modesGuideTitle => 'Modos y motores';

  @override
  String get modesGuide =>
      'Elija Auto si no está seguro de qué motor necesita su servidor. Sora comprueba el perfil y la configuración antes de conectarse. Un motor no puede aumentar el ancho de banda de su plan: el rendimiento depende del servidor, la ruta, el protocolo y la red.\n\n## Modos\n\n### Todo el tráfico (TUN)\n\nSora crea una interfaz de red virtual y enruta el tráfico de aplicaciones a través de ella, incluidos TCP y UDP. Utilice este modo para Telegram, juegos y voz Discord. Las reglas pueden enviar sitios o programas específicos directamente o bloquearlos. El servicio de red necesita permiso y un servidor que admita el protocolo requerido.\n\n### Proxy System\n\nSora configura un proxy HTTP/SOCKS local. Las aplicaciones que respetan la configuración del proxy del sistema lo utilizan. Las aplicaciones con su propia pila de red pueden conectarse directamente; UDP y las llamadas de voz generalmente necesitan TUN. Este modo se adapta a navegadores y aplicaciones compatibles con proxy.\n\n### Sin servidor\n\nEn Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir y remodelar solicitudes HTTP/TLS y omitir algunas comprobaciones de DPI. Su IP sigue siendo la misma y las conexiones van directamente al sitio web. Los resultados dependen de su proveedor y del método de bloqueo.\n\nLa integración actual utiliza tpws para HTTP y TLS sobre TCP. No evita el bloqueo de IP ni retransmite UDP y no puede garantizar las conexiones MTProto del Telegram. Utilice un servidor VPN con TUN para voz Discord, llamadas Telegram y este tipo de restricciones.\n\n## Motores\n\n### Automático\n\nSora selecciona un motor instalado que soporta todo el plan de conexión: protocolos de servidor, transportes, grupos, fragmentación y modo. Una elección manual incompatible se rechaza antes de detener la conexión actual. Elija Auto u otro motor y aplique la configuración nuevamente.\n\n### sing-box\n\nLos nuevos paquetes Sora incluyen [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), una bifurcación de [sing-box](https://github.com/SagerNet/sing-box), agregando XHTTP y VLESS Encryption del lado del cliente. Sora reconoce la construcción y sus capacidades. Una versión ascendente sin XHTTP no obtiene esta capacidad solo por su nombre.\n\nLos protocolos admitidos incluyen VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard y los parámetros AmneziaWG 1.x/2.x que Sora puede importar. Los perfiles JSON Xray completos requieren Xray. Aún no se pueden importar nuevos campos AWG 3.x. sing-box utiliza un puerto de control local protegido con contraseña, que otras aplicaciones de la computadora pueden detectar.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) admite fragmentación VLESS, REALITY, XHTTP, VLESS Encryption y TLS. También ejecuta perfiles completos del proveedor Xray conservando al mismo tiempo sus enrutamientos y grupos. Estos perfiles no se pueden convertir automáticamente a otro motor sin cambiar su comportamiento.\n\nEl Xray incluido eliminó la configuración que deshabilita la verificación del certificado TLS (`allowInsecure`). Selecciona automáticamente sing-box o mihomo para servidores normales que requieren esta configuración. Al seleccionar Xray manualmente se informa de incompatibilidad antes de detener la conexión actual. Los perfiles JSON completos más antiguos necesitan un perfil de proveedor actualizado con un certificado verificable o un PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) admite grupos de equilibrio de carga y respaldo ordenados, XHTTP y AmneziaWG. Elíjalo cuando sea importante la conmutación por error automática a un servidor de respaldo. La configuración de fragmentación TLS de Sora no está disponible con este motor.\n\n## Compatibilidad en Sora\n\n| Característica | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN y TCP/UDP | Sí | Sí | Sí |\n| XHTTP | Sí | Sí | Sí |\n| VLESS Encryption | Sí | Sí | Sí |\n| Perfil completo Xray | No | Sí | No |\n| TUIC / AnyTLS | Ambos | No | TUIC |\n| Fragmentación TLS | Sí | Sí | No |\n| AmneziaWG 1.x/2.x | Sí¹ | No | Sí |\n| Grupo de reserva ordenado | No | No² | Sí |\n\n¹ Los perfiles con J1/J2/J3/Itime utilizan mihomo; estos campos nunca deben descartarse silenciosamente. ² Para un grupo de perfiles Xray completos, la aplicación selecciona un perfil de respaldo. El soporte depende de la compilación instalada; consulte su versión en Acerca de.\n\n## pila TUN\n\nLa pila maneja TCP y UDP dentro de la interfaz virtual. En el panel de modos, Xray y mihomo ofrecen gVisor, System, Mixed y MIPS. Cada motor guarda sus propias preferencias. Los modos System proxy y Serverless no utilizan esta preferencia.\n\n- **Mixed**: TCP utiliza la pila del sistema, mientras que gVisor maneja UDP. Este es el valor predeterminado para mihomo en Linux. En Windows, Xray y mihomo usan MIPS de forma predeterminada.\n- **System**: utiliza la pila del sistema. Pruebe otra opción si las aplicaciones de red encuentran problemas.\n- **gVisor**: maneja el tráfico en el espacio de usuario.\n- **MIPS**: pila de IP propia de mihomo, disponible en la versión incluida 1.19.32.\n\nEn Linux, Xray utiliza su gVisor integrado de forma predeterminada. System, Mixed y MIPS en Linux utilizan mihomo como motor TUN, reenviando TCP y UDP a Xray a través de un enlace SOCKS local autenticado. Xray conserva el protocolo, el perfil del proveedor y el enrutamiento. Estas tres opciones requieren un mihomo instalado. En Windows, Xray utiliza mihomo 1.19.32 o posterior para las cuatro pilas TUN. Los protocolos y el enrutamiento permanecen en Xray. Las reglas de aplicaciones en esta combinación solo admiten conexiones directas y bloqueo; en Linux requieren el gVisor integrado de Xray.\n\nEl puente ejecuta un segundo proceso. En tres mediciones inactivas en Linux, utilizó entre 32 y 36 MiB más de memoria física que el Xray TUN nativo. Esto no mide la carga de descarga: los costos de CPU y memoria dependen de las conexiones. sing-box no tiene selector de pila. Ninguna pila garantiza un mejor rendimiento en todas las redes. Elija una pila y seleccione Aplicar y volver a conectarse para probarla en su red.\n\n## Aplicar configuración\n\nAl seleccionar un servidor se vuelve a conectar automáticamente. La configuración de modo, motor, DNS y reglas se guarda inmediatamente; durante una conexión activa, haga clic en Aplicar y vuelva a conectarse para usarlos. Reiniciar un motor puede interrumpir las descargas y las llamadas. Los clics repetidos no inician conexiones paralelas; la desconexión finaliza la transición y libera la conexión.\n\nInternet solo a través de VPN bloquea el tráfico directo cuando cae un túnel. Afecta a toda la máquina. Una desconexión explícita elimina las reglas de Sora. Si la limpieza no finaliza, vuelva a intentar desconectarse y abra el registro.\n\n## Documentación del proyecto\n\n- [sing-box-lx: configuración y soporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentación sing-box](https://sing-box.sagernet.org/)\n- [Documentación Xray](https://xtls.github.io/)\n- [Documentación mihomo](https://wiki.metacubex.one/)\n- [zapret: funcionamiento y limitaciones](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'comprobar servidores';

  @override
  String get extensions => 'Extensiones';

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
    return 'En $name';
  }

  @override
  String get diagnosticHttp => 'Diagnóstico HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData =>
      'Aún no hay solicitudes registradas. Primero abra un sitio web de prueba de velocidad.';

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
  String get qrScanHint => 'Elige una captura o foto con un código QR, o pega un enlace';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'No se encontró ningún código QR en esta imagen.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Abrir imagen';

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
      'Para Shadowsocks: método:contraseña, por ejemplo chacha20-ietf-poly1305:contraseña';

  @override
  String get diagnosticPackets => 'captura de paquetes';

  @override
  String get diagnosticEvents => 'Eventos de Windows';

  @override
  String get diagnosticCapture => 'Captura durante 10 segundos';

  @override
  String get diagnosticRequiresTun => 'La captura de paquetes necesita una conexión Sora TUN activa.';

  @override
  String get diagnosticUnavailable => 'Este diagnóstico no está disponible en esta plataforma.';

  @override
  String get extErrRevoked => 'El equipo de Sora retiró esta versión de la extensión porque es insegura o no funciona.';

  @override
  String get extErrRevocationsExpired =>
      'No se pudo renovar la lista de extensiones retiradas. La instalación está bloqueada hasta que se renueve: revisa la red e inténtalo de nuevo.';

  @override
  String extRevokedDisabled(String names) {
    return 'Se desactivaron extensiones retiradas: $names';
  }
}
