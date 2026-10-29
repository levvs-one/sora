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
  String get connEmpty => 'Sin conexiones';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get notInstalled => 'No instalado';

  @override
  String get sourceCode => 'código fuente';

  @override
  String get reportProblem => 'Informar de un problema';

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
  String get errCore => 'El servicio de Sora no responde';

  @override
  String get errAuth => 'Se ha denegado el acceso al servicio de Sora';

  @override
  String get errVersion => 'La aplicación y el servicio de Sora tienen versiones distintas';

  @override
  String get errBusy => 'El comando anterior sigue ejecutándose';

  @override
  String get errEngineMissing => 'Falta el motor necesario para este servidor';

  @override
  String get errEngineStart => 'El motor no pudo iniciarse';

  @override
  String get errEngineStopped => 'El motor se ha detenido';

  @override
  String get errTunnel => 'Este modo VPN no está disponible';

  @override
  String get errTimeout => 'El servidor no respondió a tiempo';

  @override
  String get errFirewall => 'No se pudo bloquear el acceso a Internet fuera de la VPN';

  @override
  String get errSubFetch => 'No se pudo descargar la suscripción';

  @override
  String get deviceIdentity => 'Identificador del dispositivo';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Restablecer identificador';

  @override
  String get deviceIdentityResetConfirm => '¿Restablecer el identificador del dispositivo?';

  @override
  String get errSubDeviceLimit => 'Se alcanzó el límite de dispositivos';

  @override
  String get errSubDeviceRequired => 'El proveedor requiere un identificador de dispositivo';

  @override
  String get errSubFormat => 'No se reconoce el formato de la suscripción';

  @override
  String get errSubEmpty => 'La suscripción no contiene servidores';

  @override
  String get errSubDuplicate => 'Esta suscripción ya está añadida';

  @override
  String get errSubLimit => 'Se ha alcanzado el límite de suscripciones';

  @override
  String get errSubScheme => 'Esquema de enlace de suscripción no compatible';

  @override
  String get errSecretStore => 'El almacenamiento de Sora está dañado o no es accesible';

  @override
  String get errNoServers => 'No hay servidores a los que conectarse';

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
  String get themeSystem => 'Según el sistema';

  @override
  String get themeLight => 'Ligera';

  @override
  String get themeDark => 'Oscura';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Según el sistema';

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
  String get splitPos => 'Posiciones divididas';

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
      other: 'la suscripción finaliza en días $days',
      one: 'la suscripción finaliza el día $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores $count, la más rápida',
      one: 'Servidor $count, la más rápida',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modo';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'dirección proxy';

  @override
  String get copied => 'Copiada';

  @override
  String get launchAtLogin => 'Comience con el sistema';

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
  String get importSealed => 'Este enlace está cifrado para Happ y solo Happ puede leerlo';

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
  String get notificationsEmpty => 'No hay notificaciones';

  @override
  String get retryConnect => 'Reintentar conexión';

  @override
  String get openLogs => 'Abrir registros';

  @override
  String get tourBack => 'Atrás';

  @override
  String get tourNext => 'Próxima';

  @override
  String get chooseProgram => 'Elige un programa';

  @override
  String get installedApps => 'Aplicaciones instaladas';

  @override
  String get runningProcesses => 'Procesos en ejecución';

  @override
  String get programsEmpty => 'No se encontraron aplicaciones';

  @override
  String get selectExe => 'Elija un archivo .exe';

  @override
  String get speedtest => 'Velocidad';

  @override
  String get speedtestSearch => 'encontrar un servicio';

  @override
  String get speedtestEmpty => 'Sin coincidencias';

  @override
  String get speedtestBackToList => 'Volver a servicios';

  @override
  String get speedtestOpenBrowser => 'Abrir en el navegador';

  @override
  String get speedtestUnavailable => 'El navegador integrado no pudo iniciarse';

  @override
  String get speedtestPageFailed => 'La página no se pudo cargar';

  @override
  String get speedtestExternalFailed => 'El navegador del sistema no se pudo abrir';

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
  String get updateDropWarning => '¿Desconectar para actualizar?';

  @override
  String get updateWaitConnection => 'La conexión no está lista';

  @override
  String get updateNetworkError => 'No se pudo descargar la actualización';

  @override
  String get updateReleaseError => 'Los datos de publicación o los archivos requeridos faltan o no son válidos.';

  @override
  String get updateChecksumError => 'La descarga no coincide con SHA256SUMS';

  @override
  String get updateInstallError => 'La actualización no terminó';

  @override
  String get updateUnsupported => 'Este ejecutable no pertenece a ningún par de paquetes Sora compatible';

  @override
  String get updateVersionRevoked => 'El desarrollador ha retirado esta versión';

  @override
  String updateRollbacking(String version) {
    return 'Regresando a la versión $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'La actualización a $version no pasó la verificación de estado, por lo que Sora se revirtió a $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Falló la reversión automática';

  @override
  String get updateRollbackCacheError =>
      'No se pudo preparar una copia de reversión verificada de la versión actual, por lo que no se instaló la actualización.';

  @override
  String get updateCopyCommand => 'comando copiar';

  @override
  String get updateInstalled => 'Actualización instalada';

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
  String get collapseServers => 'Colapsar servidores';

  @override
  String get expandServers => 'Ampliar servidores';

  @override
  String get hideDescription => 'Ocultar descripción';

  @override
  String get showDescription => 'Mostrar descripción';

  @override
  String get errEngineUnsupported => 'El motor seleccionado no admite este perfil o configuración';

  @override
  String get errRestore => 'La limpieza de la conexión fue incompleta';

  @override
  String get errSessionEnded => 'Esta sesión ya ha terminado';

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
      'Elija Auto si no está seguro de qué motor necesita su servidor. Sora comprueba el perfil y la configuración antes de conectarse. Un motor no puede aumentar el ancho de banda de su plan: el rendimiento depende del servidor, la ruta, el protocolo y la red.\n\n## Modos\n\n### Todo el tráfico (TUN)\n\nSora crea una interfaz de red virtual y enruta el tráfico de aplicaciones a través de ella, incluidos TCP y UDP. Utilice este modo para Telegram, juegos y voz Discord. Las reglas pueden enviar sitios o programas específicos directamente o bloquearlos. El servicio de red necesita permiso y un servidor que admita el protocolo requerido.\n\n### Proxy System\n\nSora configura un proxy HTTP/SOCKS local. Las aplicaciones que respetan la configuración del proxy del sistema lo utilizan. Las aplicaciones con su propia pila de red pueden conectarse directamente; UDP y las llamadas de voz generalmente necesitan TUN. Este modo se adapta a navegadores y aplicaciones compatibles con proxy.\n\n### Sin servidor\n\nEn Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir y remodelar solicitudes HTTP/TLS y omitir algunas comprobaciones de DPI. Su IP sigue siendo la misma y las conexiones van directamente al sitio web. Los resultados dependen de su proveedor y del método de bloqueo.\n\nLa integración actual utiliza tpws para HTTP y TLS sobre TCP. No evita el bloqueo de IP ni retransmite UDP y no puede garantizar las conexiones MTProto del Telegram. Utilice un servidor VPN con TUN para voz Discord, llamadas Telegram y este tipo de restricciones.\n\n## Motores\n\n### Automático\n\nSora selecciona un motor instalado que soporta todo el plan de conexión: protocolos de servidor, transportes, grupos, fragmentación y modo. Una elección manual incompatible se rechaza antes de detener la conexión actual. Elija Auto u otro motor y aplique la configuración nuevamente.\n\n### sing-box\n\nLos nuevos paquetes Sora incluyen [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), una bifurcación de [sing-box](https://github.com/SagerNet/sing-box), agregando XHTTP y VLESS Encryption del lado del cliente. Sora reconoce la construcción y sus capacidades. Una versión ascendente sin XHTTP no obtiene esta capacidad solo por su nombre.\n\nLos protocolos admitidos incluyen VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard y los parámetros AmneziaWG 1.x/2.x que Sora puede importar. Los perfiles JSON Xray completos requieren Xray. Aún no se pueden importar nuevos campos AWG 3.x. sing-box utiliza un puerto de control local protegido con contraseña, que otras aplicaciones de la computadora pueden detectar.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) admite fragmentación VLESS, REALITY, XHTTP, VLESS Encryption y TLS. También ejecuta perfiles completos del proveedor Xray conservando al mismo tiempo sus enrutamientos y grupos. Estos perfiles no se pueden convertir automáticamente a otro motor sin cambiar su comportamiento.\n\nEl Xray incluido eliminó la configuración que deshabilita la verificación del certificado TLS (`allowInsecure`). Selecciona automáticamente sing-box o mihomo para servidores normales que requieren esta configuración. Al seleccionar Xray manualmente se informa de incompatibilidad antes de detener la conexión actual. Los perfiles JSON completos más antiguos necesitan un perfil de proveedor actualizado con un certificado verificable o un PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) admite grupos de equilibrio de carga y respaldo ordenados, XHTTP y AmneziaWG. Elíjalo cuando sea importante la conmutación por error automática a un servidor de respaldo. La configuración de fragmentación TLS de Sora no está disponible con este motor.\n\n## Compatibilidad en Sora\n\n| Característica | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN y TCP/UDP | Sí | Sí | Sí |\n| XHTTP | Sí | Sí | Sí |\n| VLESS Encryption | Sí | Sí | Sí |\n| Perfil completo Xray | No | Sí | No |\n| TUIC / AnyTLS | Ambos | No | TUIC |\n| mieru | No | No | Sí |\n| NaiveProxy | Sí | No | No |\n| Fragmentación TLS | Sí | Sí | No |\n| AmneziaWG 1.x/2.x | Sí¹ | No | Sí |\n| Grupo de reserva ordenado | No | No² | Sí |\n\n¹ Los perfiles con J1/J2/J3/Itime utilizan mihomo; estos campos nunca deben descartarse silenciosamente. ² Para un grupo de perfiles Xray completos, la aplicación selecciona un perfil de respaldo. El soporte depende de la compilación instalada; consulte su versión en Acerca de.\n\n## pila TUN\n\nLa pila maneja TCP y UDP dentro de la interfaz virtual. En el panel de modos, Xray y mihomo ofrecen gVisor, System, Mixed y MIPS. Cada motor guarda sus propias preferencias. Los modos System proxy y Serverless no utilizan esta preferencia.\n\n- **Mixed**: TCP utiliza la pila del sistema, mientras que gVisor maneja UDP. Este es el valor predeterminado para mihomo en Linux. En Windows, Xray y mihomo usan MIPS de forma predeterminada.\n- **System**: utiliza la pila del sistema. Pruebe otra opción si las aplicaciones de red encuentran problemas.\n- **gVisor**: maneja el tráfico en el espacio de usuario.\n- **MIPS**: pila de IP propia de mihomo, disponible en la versión incluida 1.19.32.\n\nEn Linux, Xray utiliza su gVisor integrado de forma predeterminada. System, Mixed y MIPS en Linux utilizan mihomo como motor TUN, reenviando TCP y UDP a Xray a través de un enlace SOCKS local autenticado. Xray conserva el protocolo, el perfil del proveedor y el enrutamiento. Estas tres opciones requieren un mihomo instalado. En Windows, Xray utiliza mihomo 1.19.32 o posterior para las cuatro pilas TUN. Los protocolos y el enrutamiento permanecen en Xray. Las reglas de aplicaciones en esta combinación solo admiten conexiones directas y bloqueo; en Linux requieren el gVisor integrado de Xray.\n\nEl puente ejecuta un segundo proceso. En tres mediciones inactivas en Linux, utilizó entre 32 y 36 MiB más de memoria física que el Xray TUN nativo. Esto no mide la carga de descarga: los costos de CPU y memoria dependen de las conexiones. sing-box no tiene selector de pila. Ninguna pila garantiza un mejor rendimiento en todas las redes.\n\n## Aplicar configuración\n\nAl seleccionar un servidor, la conexión se restablece automáticamente. Tus cambios de modo, motor, DNS o reglas se aplican una sola vez tras una breve pausa con reconexión automática; las actualizaciones en segundo plano no reconectan la VPN. Reiniciar el motor puede interrumpir las descargas y las llamadas.\n\nInternet solo a través de VPN bloquea el tráfico directo cuando cae un túnel. Afecta a toda la máquina. Una desconexión explícita elimina las reglas de Sora. Si la limpieza no finaliza, vuelva a intentar desconectarse y abra el registro.\n\n## Documentación del proyecto\n\n- [sing-box-lx: configuración y soporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentación sing-box](https://sing-box.sagernet.org/)\n- [Documentación Xray](https://xtls.github.io/)\n- [Documentación mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: funcionamiento y limitaciones](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC transporta TCP mediante una videollamada en Jitsi, Yandex Telemost o WB Stream. Importe un enlace olcrtc:// o un código QR. Funciona con sing-box, Xray y mihomo en los modos proxy y TUN; no admite UDP. Ambos extremos necesitan versiones compatibles con OLC2. El proyecto original está archivado.\n';

  @override
  String get probeServers => 'Silbido';

  @override
  String get extensions => 'Extensiones';

  @override
  String extRatingLabel(String rating) {
    return 'Calificación $rating de 5';
  }

  @override
  String extByAuthor(String author) {
    return 'por $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Instalaciones: $count';
  }

  @override
  String get extInstallOne => '1 instalación';

  @override
  String get extSideloadWarning => 'Clave autofirmada';

  @override
  String get extPermissionsWidened => 'La actualización solicita nuevos permisos:';

  @override
  String get extInstall => 'Instalar';

  @override
  String get extUpdate => 'Actualizar';

  @override
  String get extCancel => 'Cancelar';

  @override
  String get extConfirm => 'Confirmar';

  @override
  String get extCatalog => 'Catálogo';

  @override
  String get extInstalled => 'Extensiones instaladas';

  @override
  String get extSearchHint => 'Buscar extensiones';

  @override
  String get extCatAll => 'Todos';

  @override
  String get extCatTools => 'Herramientas';

  @override
  String get extCatThemes => 'Temas';

  @override
  String get extCatAutomation => 'Automatización';

  @override
  String get extCatStats => 'Estadísticas';

  @override
  String get extCatNetwork => 'Red';

  @override
  String get extSortBy => 'Ordenar por';

  @override
  String get extSortPopular => 'Más popular';

  @override
  String get extSortRating => 'Mejor calificado';

  @override
  String get extSortName => 'Nombre';

  @override
  String get extCatalogError => 'No se pudo cargar el catálogo';

  @override
  String get extRetry => 'Reintentar';

  @override
  String get extEmptySearch => 'No se encontró nada';

  @override
  String get extEmptyInstalled => 'Aún no hay extensiones instaladas';

  @override
  String get extInstallFromFile => 'Instalar desde archivo';

  @override
  String get extInstallFromUrl => 'Instalar desde URL';

  @override
  String get extDownload => 'Descargar';

  @override
  String get extDownloading => 'Descargando…';

  @override
  String get extVerifying => 'Verificando…';

  @override
  String get extInstalling => 'Instalando…';

  @override
  String get extErrSignature => 'La verificación de firma falló';

  @override
  String get extErrManifest => 'El manifiesto de extensión no es válido.';

  @override
  String get extErrNetwork => 'Error de red';

  @override
  String get extErrHash => 'La descarga no coincide con el catálogo';

  @override
  String extErrMinApp(String version) {
    return 'Esta extensión necesita la versión de la aplicación $version o más reciente.';
  }

  @override
  String get extErrHttpsOnly => 'Sólo se permiten enlaces https://';

  @override
  String get extErrGeneric => 'Algo salió mal';

  @override
  String get extErrAuthorKeyChanged =>
      'Esta actualización está firmada con una clave de autor diferente a la versión instalada, por lo que fue bloqueada';

  @override
  String get extDisabled => 'Desactivado';

  @override
  String extToggleEnabled(String name) {
    return 'Habilitar $name';
  }

  @override
  String get extSearchInstalled => 'Buscar extensiones instaladas';

  @override
  String get extUpdateAll => 'Actualizar todo';

  @override
  String extUpdatesAvailable(int count) {
    return '$count actualizaciones disponibles';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count actualizado';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Sensible';

  @override
  String get extRiskDangerous => 'Alto riesgo';

  @override
  String get extPermissionsRemoved => 'Ya no se solicita:';

  @override
  String get extUpdateFailedKept => 'La versión anterior aún está instalada.';

  @override
  String get extConflictsTitle => 'Conflictos de extensión';

  @override
  String get extConflictTheme => 'Tema de la aplicación';

  @override
  String get extConflictNetHooks => 'Ganchos de red';

  @override
  String extConflictWinner(String name) {
    return '$name gana';
  }

  @override
  String extConflictsCount(int count) {
    return 'Conflictos de extensión: $count';
  }

  @override
  String get extConflictsResolve => 'Resolver conflictos';

  @override
  String extVersionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get extPermissionsTitle => 'Permisos';

  @override
  String get extNoPermissions => 'Sin permisos especiales.';

  @override
  String get extSettings => 'Ajustes';

  @override
  String get extSaveSettings => 'Guardar ajustes';

  @override
  String extUpdateTo(String version) {
    return 'Actualizar a $version';
  }

  @override
  String get extEnabled => 'Activado';

  @override
  String extRollbackTo(String version) {
    return 'Volver a $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return '¿Revertir a la versión $version?';
  }

  @override
  String get extUninstall => 'Desinstalar';

  @override
  String extUninstallConfirm(String name) {
    return '¿Eliminar “$name” y sus configuraciones?';
  }

  @override
  String get extPanelUnavailable => 'El panel de la extensión no está disponible.';

  @override
  String get extPermConnectionsRead => 'Ver lista de conexiones activas';

  @override
  String get extPermServersRead => 'Ver una lista de sus servidores';

  @override
  String get extPermSettingsRead => 'Leer la configuración de la aplicación';

  @override
  String get extPermSettingsWrite => 'Cambiar la configuración de la aplicación';

  @override
  String get extPermNotifications => 'Mostrar notificaciones';

  @override
  String get extPermTray => 'Agregar elementos al menú de la bandeja';

  @override
  String get extPermUiPanel => 'Mostrar paneles dentro de la aplicación';

  @override
  String get extPermThemeApply => 'Aplicar temas';

  @override
  String get extPermRoutingRules => 'Agregar reglas de enrutamiento';

  @override
  String get extPermNetHooks => 'Integrar en la ruta de red';

  @override
  String get extPermNetFetch => 'Solicitar URL de la lista permitida';

  @override
  String get extPermBackground => 'Ejecutar tareas en segundo plano';

  @override
  String get extPermNotYetActive => 'Desactivado';

  @override
  String get extCapBackground => 'Se ejecuta en segundo plano';

  @override
  String get extCapNetHook => 'Evasión de bloqueos y enganches de red';

  @override
  String get extCapPanel => 'Paneles de interfaz';

  @override
  String get extCapRouting => 'Reglas de enrutamiento';

  @override
  String get extCapTheme => 'Temas';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Registro de cambios';

  @override
  String get extImageFailed => 'No se pudo cargar la imagen';

  @override
  String get extScreenshots => 'Capturas de pantalla';

  @override
  String get extSortRelevance => 'Relevancia';

  @override
  String get extBgTitle => 'Tarea en segundo plano';

  @override
  String get extBgEnabled => 'Ejecutar en segundo plano';

  @override
  String get extBgInterval => 'Ejecutar cada';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutos', one: '$count minuto');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count horas', one: '$count hora');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Acceso a la red';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Red: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'En $name';
  }

  @override
  String get diagnosticHttp => 'Diagnóstico HTTP';

  @override
  String get diagnosticNoData => 'Aún no hay solicitudes registradas';

  @override
  String get qrShareTitle => 'Compartir código QR';

  @override
  String get qrScanTitle => 'Escanear código QR';

  @override
  String get qrCopyLink => 'Copiar enlace';

  @override
  String get qrFromClipboard => 'Pegar desde el portapapeles';

  @override
  String get qrNoCode => 'No se encontró ningún código QR en esta imagen.';

  @override
  String get qrInvalid => 'Este código QR no contiene un enlace válido.';

  @override
  String get qrScan => 'Escanear QR';

  @override
  String get qrFromImage => 'Abrir imagen';

  @override
  String get connGroupByProcess => 'Agrupar por proceso';

  @override
  String get connListView => 'Lista';

  @override
  String get connCopyHost => 'Copiar host';

  @override
  String get connAddRule => 'Agregar regla';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conexiones',
      one: '$count conexión',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Preestablecido';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Personalizado';

  @override
  String get dnsCheck => 'Verificar fugas de datos';

  @override
  String get dnsChecking => 'Comprobando...';

  @override
  String get dnsNoLeak => 'No se encontraron fugas';

  @override
  String get dnsLeakFound => 'Fuga detectada';

  @override
  String get dnsLastCheck => 'Última comprobación';

  @override
  String get dnsNeverChecked => 'Aún no probado';

  @override
  String get dnsLeakCheckTunnelDns => 'Resolutores DNS del túnel';

  @override
  String get dnsLeakCheckSystemResolvers => 'Resolutores del sistema';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Protección DNS del bloqueo de red';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS cifrado del sistema operativo';

  @override
  String get dnsLeakCheckDnsSpoof => 'Respuestas DNS falsificadas';

  @override
  String get dnsExpected => 'Esperado';

  @override
  String get dnsActual => 'Observado';

  @override
  String get measureSpeed => 'Medir velocidad';

  @override
  String get benchmarkStale => 'anticuado';

  @override
  String get autoSelectMode => 'Servidor de selección automática';

  @override
  String get autoSelectPing => 'Ping más rápido';

  @override
  String get autoSelectSpeed => 'Velocidad más rápida';

  @override
  String get autoSelectSmart => 'Elección inteligente';

  @override
  String get coreWatchUnstable => 'La conexión con el núcleo es inestable';

  @override
  String get watchReconnect => 'Reconectar';

  @override
  String get crashRestoreTitle => 'La última sesión fue interrumpida';

  @override
  String get restoreOnCrash => 'Restaurar sesión después de un bloqueo';

  @override
  String get crashRestore => 'Restaurar';

  @override
  String get crashDismiss => 'Ahora no';

  @override
  String get overrideTitle => 'Mis ediciones';

  @override
  String get overrideEdit => 'Editar servidores';

  @override
  String get overrideHide => 'Ocultar';

  @override
  String get overrideUnhide => 'Mostrar';

  @override
  String get overrideClear => 'Restablecer ediciones';

  @override
  String get overrideEmpty => 'Aún no hay ediciones';

  @override
  String get overrideCustomRules => 'Reglas propias';

  @override
  String get errBenchmarkUnsupported => 'La medición de velocidad requiere un núcleo más reciente';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Medición de $done de $total…';
  }

  @override
  String get profiles => 'Perfiles de red';

  @override
  String get profilesEmpty => 'Aún no hay perfiles';

  @override
  String get profileAdd => 'Agregar perfil';

  @override
  String get profileName => 'Nombre del perfil';

  @override
  String get profileSsids => 'Redes Wi-Fi (SSID)';

  @override
  String get profileGateways => 'Pasarelas de red';

  @override
  String get profileAsns => 'AS números';

  @override
  String get profileAutoApply => 'Aplicar automáticamente';

  @override
  String get profileSnapshot => 'Recordar la configuración actual';

  @override
  String get profileSnapshotDone => 'Configuraciones actuales guardadas en el perfil';

  @override
  String get profileDelete => 'Eliminar perfil';

  @override
  String profileDeleteConfirm(Object name) {
    return '¿Eliminar perfil \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '¿Aplicar perfil \"$name\"?';
  }

  @override
  String get profileApply => 'Aplicar';

  @override
  String profileApplied(Object name) {
    return 'Perfil “$name” aplicado';
  }

  @override
  String get profileUndo => 'Cancelar';

  @override
  String get profileActive => 'Activo';

  @override
  String networkNow(Object info) {
    return 'Ahora: $info';
  }

  @override
  String get networkUnknown => 'Información de red no disponible';

  @override
  String get profileNoTriggers => 'No hay condiciones del perfil';

  @override
  String get chains => 'Cadenas de proxy';

  @override
  String get chainsEmpty => 'Aún no hay cadenas';

  @override
  String get chainAdd => 'Nueva cadena';

  @override
  String get chainName => 'Nombre de la cadena';

  @override
  String get chainTooFew => 'Una cadena necesita al menos dos servidores';

  @override
  String get chainTooMany => 'Una cadena puede tener un máximo de tres servidores';

  @override
  String get chainEstimate => 'Latencia estimada';

  @override
  String get chainSave => 'Guardar cadena';

  @override
  String get chainDelete => 'Eliminar cadena';

  @override
  String chainDeleteConfirm(Object name) {
    return '¿Eliminar la cadena \"$name\"?';
  }

  @override
  String get chainUnsupported => 'El motor seleccionado no admite cadenas';

  @override
  String get chainHopMissing => 'Un servidor de la cadena ya no está disponible';

  @override
  String chainHop(Object n) {
    return 'Salto $n';
  }

  @override
  String get chainEntry => 'Entrada';

  @override
  String get chainExit => 'Salida';

  @override
  String get sync => 'Sincronización de dispositivos';

  @override
  String get syncDevices => 'Mis dispositivos';

  @override
  String get syncEmpty => 'No hay dispositivos emparejados';

  @override
  String get syncPair => 'Emparejar dispositivo';

  @override
  String get syncShowCode => 'Mostrar mi código';

  @override
  String get syncScanCode => 'Código de escaneo';

  @override
  String get syncRevoke => 'Retirar';

  @override
  String syncRevokeConfirm(Object name) {
    return '¿Revocar \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Última sincronización: $time';
  }

  @override
  String get syncNever => 'Nunca';

  @override
  String get syncPaired => 'Dispositivo emparejado';

  @override
  String get syncPairingTitle => 'Emparejar con este dispositivo';

  @override
  String get syncWaiting => 'Esperando el otro dispositivo…';

  @override
  String get zapretWithVpn => 'Omitir el filtrado DPI para el tráfico directo de red';

  @override
  String get chainDuplicate => 'Un servidor aparece varias veces en la cadena';

  @override
  String get edit => 'Editar';

  @override
  String get remove => 'Quitar';

  @override
  String get autoSwitchOnDegrade => 'Autoencendido en degradación';

  @override
  String get tunStackMixed => 'Mixto';

  @override
  String get tunStackSystem => 'Sistema';

  @override
  String get customServerAdd => 'Agregar servidor personalizado';

  @override
  String get customServers => 'Mis servidores';

  @override
  String get customServerName => 'Nombre';

  @override
  String get customServerNameRequired => 'Falta el nombre';

  @override
  String get customServerAddress => 'Dirección';

  @override
  String get customServerAddressRequired => 'Falta la dirección';

  @override
  String get customServerAddressInvalid => 'Dirección no válida';

  @override
  String get customServerPort => 'Puerto';

  @override
  String get customServerPortInvalid => 'Puerto no válido';

  @override
  String get customServerProtocol => 'Protocolo';

  @override
  String get customServerCredentials => 'Información de inicio de sesión';

  @override
  String get customServerShowSecret => 'Mostrar secreto';

  @override
  String get customServerHideSecret => 'Ocultar secreto';

  @override
  String customServerDeleteConfirm(String name) {
    return '¿Eliminar el servidor “$name”?';
  }

  @override
  String get leakTestTitle => 'Prueba de fugas de datos';

  @override
  String get leakTestRun => 'Comprobar';

  @override
  String get leakTestCancel => 'Cancelar';

  @override
  String leakTestProgress(int count) {
    return 'Pruebas completadas: $count';
  }

  @override
  String get leakTestAllClear => 'No se encontraron fugas';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fugas encontradas',
      one: '$count fuga encontrada',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Arreglar';

  @override
  String get leakTestCheckDirectDns => 'Directo DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP eco';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Resolutores del sistema';

  @override
  String get leakTestCheckTunnelConnectivity => 'Conectividad del túnel';

  @override
  String get leakTestCheckTunnelDns => 'DNS a través del túnel';

  @override
  String get noticeDegraded =>
      'El servidor se volvió lento. Sora cambió al mejor servidor encontrado durante la medición.';

  @override
  String get obfs => 'Ofuscación del tráfico';

  @override
  String get syncCodeExpired => 'El código ha caducado';

  @override
  String get syncDaemonFailed => 'No se pudo iniciar el servicio de sincronización';

  @override
  String get syncDaemonMissing => 'No se encontró el componente sora-sync';

  @override
  String get syncDaemonStarting => 'Iniciando el servicio de sincronización…';

  @override
  String get syncErrAuth => 'El servicio de sincronización rechazó el token de acceso';

  @override
  String get syncErrNotFound => 'El dispositivo ya no está emparejado';

  @override
  String get syncErrPairingActive => 'Ya hay una sesión de emparejamiento abierta';

  @override
  String get syncErrUnreachable => 'El otro dispositivo no respondió';

  @override
  String get syncError => 'Error de sincronización';

  @override
  String syncExpiresIn(String duration) {
    return 'El código caduca en $duration';
  }

  @override
  String get syncJoining => 'Emparejamiento con el dispositivo…';

  @override
  String get syncNewCode => 'Nuevo código';

  @override
  String syncPairedWith(String name) {
    return 'Emparejado con $name';
  }

  @override
  String get syncRetry => 'Repetir';

  @override
  String get syncStopShowing => 'Ocultar código';

  @override
  String get syncSyncNow => 'Sincronizar ahora';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Recibido $pulled, enviado $pushed';
  }

  @override
  String get syncResultTitle => 'Resultado de sincronización';

  @override
  String get syncPulled => 'Recibido';

  @override
  String get syncPushed => 'Enviado';

  @override
  String get syncNoChanges => 'No se detectaron cambios';

  @override
  String get syncDocKindSubscriptions => 'Suscripciones';

  @override
  String get syncDocKindSettings => 'Configuración de la aplicación';

  @override
  String get syncDocKindOverrides => 'Ajustes personalizados de suscripciones';

  @override
  String get syncDocKindProfiles => 'Perfiles de red';

  @override
  String get syncDocKindChains => 'Cadenas de proxy';

  @override
  String syncFrom(String name) {
    return 'de $name';
  }

  @override
  String get syncThisDevice => 'Este dispositivo';

  @override
  String get syncUnavailableAndroid => 'La sincronización no está disponible en Android';

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
  String get extErrRevocationsExpired => 'La instalación está bloqueada hasta actualizar la lista de revocaciones.';

  @override
  String extRevokedDisabled(String names) {
    return 'Se desactivaron extensiones retiradas: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Clave privada';

  @override
  String get customServerWgAddresses => 'Direcciones de la interfaz';

  @override
  String get customServerWgPeerKey => 'Clave pública del servidor';

  @override
  String get customServerWgPresharedKey => 'Clave precompartida';

  @override
  String get customServerWgAllowedIps => 'IP permitidas';

  @override
  String get customServerWgKeepalive => 'Keepalive, segundos';

  @override
  String get customServerWgKeyInvalid => 'Clave WireGuard no válida';

  @override
  String get customServerWgCidrInvalid => 'Prefijo CIDR no válido';

  @override
  String get customServerWgKeepaliveInvalid => 'Intervalo keepalive no válido';

  @override
  String get strictKillSwitch => 'Bloqueo de red estricto';

  @override
  String get strictKillSwitchWarning => '¿Bloquear el tráfico fuera de la VPN al salir?';

  @override
  String get extWorkerFailed => 'Falló la tarea en segundo plano de la extensión';

  @override
  String get extAssetRejected => 'El archivo de la extensión contiene colores ilegibles o reglas no válidas';

  @override
  String get extVerifiedSora => 'Verificado por Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Abrir';

  @override
  String get customServerOwn => 'Servidor propio';

  @override
  String get customServerPaste => 'Pegar un enlace';

  @override
  String get customServerUser => 'Usuario';

  @override
  String get customServerPassword => 'Contraseña';

  @override
  String get customServerSecretRequired => 'Falta el valor';

  @override
  String get customServerLinkInvalid => 'Enlace de servidor no válido';

  @override
  String get errInternal => 'Error interno de Sora';

  @override
  String get errTls => 'Certificado del servidor rechazado';

  @override
  String get errFileAccess => 'No se puede acceder al archivo';

  @override
  String get errDataLimit => 'Demasiados datos';

  @override
  String get errCredentials => 'Faltan las credenciales guardadas';

  @override
  String subscriptionStale(String time) {
    return 'Última actualización: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Aún sin actualizar';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'El servidor devolvió el código HTTP $status',
      zero: 'El servidor rechazó la solicitud',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'La configuración del servidor está incompleta o no es compatible';

  @override
  String get errServerIds => 'Dos servidores comparten un identificador';

  @override
  String get errRoutingGroup => 'La ruta apunta a servidores ausentes o a un grupo dañado';

  @override
  String get errConnections => 'Lista de conexiones no disponible';

  @override
  String get errLogs => 'Este servicio no guarda registros';

  @override
  String get errDiagnostics => 'No se pudo recopilar el diagnóstico';

  @override
  String get errMissingItem => 'El elemento solicitado ya no existe';

  @override
  String get errInvalidRequest => 'La solicitud contiene valores inválidos';

  @override
  String get errProxyLogin => 'El proxy del sistema no admite este acceso';

  @override
  String get errLogFilter => 'Filtro de registro inválido';

  @override
  String get errSubRedirect => 'El servidor redirigió a una dirección insegura';

  @override
  String get errProxySetup => 'No se pudo configurar el proxy del sistema';

  @override
  String get notificationsToday => 'Hoy';

  @override
  String get notificationsYesterday => 'Ayer';

  @override
  String get notificationsMarkRead => 'Marcar todo como leído';

  @override
  String get notificationsUnread => 'Sin leer';

  @override
  String get desktopNotifications => 'Notificaciones del escritorio';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'El intervalo de actualización de la suscripción no es válido';

  @override
  String get errRule => 'Una regla de enrutamiento no es válida';

  @override
  String get errDns => 'La configuración DNS no es válida';

  @override
  String get errEndpoint => 'La dirección del servidor que se va a comprobar no es válida';

  @override
  String get errCancelled => 'Se ha cancelado la solicitud';

  @override
  String get customServerOptions => 'Ajustes de conexión';

  @override
  String get customServerTransport => 'Transporte';

  @override
  String get customServerSecurity => 'Seguridad';

  @override
  String get customServerCipher => 'Cifrado';

  @override
  String get customServerWgInterface => 'Interfaz';

  @override
  String get customServerWgPeer => 'Par';

  @override
  String extAvailableOn(String platforms) {
    return 'Disponible en: $platforms.';
  }

  @override
  String get winwsScopeWarning => '¿Cambiar el tráfico TCP de todas las aplicaciones?';

  @override
  String get winwsRequirements => 'Este modo VPN no está disponible';
}
