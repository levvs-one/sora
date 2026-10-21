// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get stateOff => 'Não conectado';

  @override
  String get stateConnecting => 'Conectando';

  @override
  String get stateConnected => 'Conectada';

  @override
  String get stateReconnecting => 'Reconectando';

  @override
  String get stateDisconnecting => 'Desconectando';

  @override
  String get stateFailed => 'Não conectado';

  @override
  String get coreMissing => 'O serviço Sora não está respondendo';

  @override
  String get serverAuto => 'Mais rápido';

  @override
  String get serverBypass => 'Nenhum servidor';

  @override
  String get addSubscription => 'Adicionar assinatura';

  @override
  String get servers => 'Servidoras';

  @override
  String get settings => 'Configurações';

  @override
  String get subscription => 'Subscrição';

  @override
  String get subscriptionLink => 'Link de assinatura';

  @override
  String get add => 'Adicionar';

  @override
  String get refresh => 'Atualizar';

  @override
  String get rename => 'Renomear';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get name => 'Nome';

  @override
  String deleteSubscription(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get routes => 'Rotas';

  @override
  String get presetGlobal => 'Tudo através de VPN';

  @override
  String get presetRu => 'Rússia direto';

  @override
  String get presetIr => 'Irã direto';

  @override
  String get presetCn => 'China direto';

  @override
  String get blockAds => 'Bloquear anúncios';

  @override
  String get killSwitch => 'Internet apenas através de VPN';

  @override
  String get engine => 'Motor';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animações';

  @override
  String get logs => 'Registro';

  @override
  String get about => 'Sobre';

  @override
  String get logsAll => 'Todos';

  @override
  String get logsImportant => 'Importante';

  @override
  String get logsErrors => 'Erros';

  @override
  String get search => 'Procurar';

  @override
  String get export => 'Salvar em arquivo';

  @override
  String get clear => 'Clara';

  @override
  String get logsEmpty => 'Nada aqui';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get notInstalled => 'Não instalado';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get license => 'Licença';

  @override
  String usage(String used, String total) {
    return '$used de $total';
  }

  @override
  String until(String date) {
    return 'até $date';
  }

  @override
  String get expired => 'Expirada';

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
    return '${n}B';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '${n}MB';
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
  String get errGeneric => 'Algo deu errado';

  @override
  String get errCore => 'O serviço Sora não está respondendo';

  @override
  String get errAuth => 'Sem acesso ao serviço Sora';

  @override
  String get errVersion => 'Atualização Sora: o aplicativo e o serviço são versões diferentes';

  @override
  String get errBusy => 'Espere, o comando anterior ainda está em execução';

  @override
  String get errEngineMissing => 'Nenhum mecanismo encontrado para este servidor';

  @override
  String get errEngineStart => 'O motor não ligou';

  @override
  String get errEngineStopped => 'O motor parou';

  @override
  String get errTunnel => 'Sem permissão para criar a conexão VPN';

  @override
  String get errServers => 'O servidor está configurado com um erro';

  @override
  String get errNetwork => 'Não é possível acessar o servidor';

  @override
  String get errTimeout => 'O servidor não respondeu a tempo';

  @override
  String get errFirewall => 'Não foi possível bloquear a internet fora da VPN';

  @override
  String get errSubFetch => 'Não foi possível carregar a assinatura';

  @override
  String get errSubFormat => 'Este não é um link de assinatura';

  @override
  String get errSubEmpty => 'A assinatura não tem servidores';

  @override
  String get errSubDuplicate => 'Esta assinatura já foi adicionada';

  @override
  String get errSubLimit => 'Muitas assinaturas';

  @override
  String get errSubScheme => 'O link deve começar com https://';

  @override
  String get errSecretStore => 'O armazenamento Sora está danificado ou indisponível';

  @override
  String get errNoServers => 'Adicione uma assinatura para se conectar';

  @override
  String get exportText => 'Texto';

  @override
  String get connections => 'Conexões';

  @override
  String get close => 'Fechar';

  @override
  String get chainDirect => 'Direta';

  @override
  String get chainBlocked => 'Bloqueado';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Luz';

  @override
  String get themeDark => 'Escura';

  @override
  String get language => 'Linguagem';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Conexão';

  @override
  String get sectionNoServer => 'Nenhum servidor';

  @override
  String get sectionPing => 'Pingar';

  @override
  String get sectionLog => 'Diagnóstica';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Endereços, separados por vírgula';

  @override
  String get fragment => 'Fragmentação TLS';

  @override
  String get fragmentPackets => 'O que dividir';

  @override
  String get fragmentLength => 'Tamanho da peça';

  @override
  String get fragmentInterval => 'Pausa entre as peças';

  @override
  String get byDefault => 'Padrão';

  @override
  String get rangeHint => 'Por exemplo, 100-200';

  @override
  String get splitPos => 'Posições divididas';

  @override
  String get splitPosHint => 'Por exemplo, 1, midsld';

  @override
  String get disorder => 'Reordenar peças';

  @override
  String get tlsRecord => 'Divida o registro TLS';

  @override
  String get tlsRecordNo => 'Não';

  @override
  String get tlsRecordSni => 'No nome do site';

  @override
  String get tlsRecordFirst => 'Após o primeiro byte';

  @override
  String get hostCase => 'Alterar caso de host';

  @override
  String get probeMethod => 'Método';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Através do motor';

  @override
  String get probeConnect => 'Somente conexão';

  @override
  String get probeUrl => 'Endereço de teste';

  @override
  String get probeTimeout => 'Espere';

  @override
  String seconds(int n) {
    return '${n}s';
  }

  @override
  String get subscriptions => 'Assinaturas';

  @override
  String get subscriptionSettings => 'Configurações';

  @override
  String get userAgent => 'Agente do usuário';

  @override
  String get autoUpdate => 'Atualizar automaticamente';

  @override
  String get updateInterval => 'Com que frequência';

  @override
  String get intervalProvider => 'Como o provedor pede';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get logLevel => 'O que gravar';

  @override
  String get levelDebug => 'Tudo';

  @override
  String get levelInfo => 'Habitual';

  @override
  String get levelWarning => 'Importante';

  @override
  String get levelError => 'Apenas erros';

  @override
  String get recordDestinations => 'Registrar endereços de sites';

  @override
  String get reset => 'Redefinir configurações';

  @override
  String get resetConfirm => 'Redefinir todas as configurações?';

  @override
  String get resetAction => 'Reiniciar';

  @override
  String get invalidValue => 'Este valor não funcionará';

  @override
  String get website => 'Página de assinatura';

  @override
  String get providerWebsite => 'Site do provedor';

  @override
  String get support => 'Apoiar';

  @override
  String controlPortQuestion(String engine) {
    return '$engine é controlado por meio de uma porta neste computador. Outros programas serão capazes de dizer que uma VPN está ativada.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Escolha $engine';
  }

  @override
  String get rules => 'Regras personalizadas';

  @override
  String get ruleAdd => 'Nova regra';

  @override
  String get ruleHint => 'Site, IP ou programa';

  @override
  String get ruleDirect => 'Direta';

  @override
  String get ruleProxy => 'Através de VPN';

  @override
  String get ruleBlock => 'Bloquear';

  @override
  String get failover => 'Falha na ativação';

  @override
  String get connectOnStart => 'Conecte-se no início';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'a assinatura termina em # dias',
      one: 'a assinatura termina no dia #',
      zero: 'a assinatura termina em algumas horas',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left esquerdo';
  }

  @override
  String get ruleInvalid => 'Isto não se parece com um site, um IP ou um programa';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores #, por sua vez',
      one: 'Servidor #, por sua vez',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores #, os mais rápidos',
      one: 'Servidor #, o mais rápido',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modo';

  @override
  String get tunnelTun => 'Todo o tráfego';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'Endereço proxy';

  @override
  String get copied => 'Copiada';

  @override
  String get launchAtLogin => 'Comece com o sistema';

  @override
  String get launchAtLoginDetail => 'O Sora será iniciado automaticamente ao entrar e ficará na bandeja do sistema.';

  @override
  String get closeToTray => 'Manter na bandeja quando fechado';

  @override
  String get notifications => 'Notificações';

  @override
  String get trayOpen => 'Abra Sora';

  @override
  String get trayConnect => 'Conectar';

  @override
  String get trayDisconnect => 'Desconectar';

  @override
  String get trayServer => 'Servidora';

  @override
  String get trayQuit => 'Sair de Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora ainda está na bandeja';

  @override
  String get noticeInTrayBody => 'Sair do menu de seu ícone';

  @override
  String get noticeLost => 'Conexão perdida';

  @override
  String get noticeLostBody => 'Sora está se reconectando';

  @override
  String get noticeRestored => 'Conectado novamente';

  @override
  String get noticeFailed => 'Não foi possível conectar';

  @override
  String get noticeBackup => 'O servidor principal não respondeu; o backup transporta o tráfego';

  @override
  String get noticeNext => 'O servidor não respondeu; o próximo carrega o tráfego';

  @override
  String get noticeMainBack => 'O servidor principal responde novamente e transporta o tráfego';

  @override
  String get noticeSubscription => 'Subscrição';

  @override
  String get importTitle => 'Adicionar esta assinatura?';

  @override
  String get importSealed =>
      'Este link é criptografado para Happ e somente Happ pode lê-lo. Peça ao seu provedor o link de assinatura simples.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'sem resposta';

  @override
  String get home => 'Lar';

  @override
  String get navRules => 'Regras';

  @override
  String get navConnections => 'Conexões';

  @override
  String get navLogs => 'Registros';

  @override
  String get navAbout => 'Sobre';

  @override
  String get sidebarToggle => 'Alternar barra lateral';

  @override
  String get more => 'Mais';

  @override
  String get less => 'Menos';

  @override
  String get currentServer => 'Servidor atual';

  @override
  String get trafficDown => 'Baixada';

  @override
  String get trafficUp => 'Enviado';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Regras ativas: $count';
  }

  @override
  String get recentNotifications => 'Notificações recentes';

  @override
  String get notificationsEmpty => 'Os eventos de conexão e assinatura aparecerão aqui';

  @override
  String get retryConnect => 'Tentar novamente a conexão';

  @override
  String get openLogs => 'Registros abertos';

  @override
  String get tourReplay => 'Mostrar guia novamente';

  @override
  String tourStep(int step) {
    return 'Etapa $step de 5';
  }

  @override
  String get tourBack => 'Voltar';

  @override
  String get tourNext => 'Próxima';

  @override
  String get tourSkip => 'Pular';

  @override
  String get tourFinish => 'Feita';

  @override
  String get tourAdd => 'Adicione o link de assinatura do seu provedor.';

  @override
  String get tourServer => 'Escolha um servidor. “Mais rápido” seleciona um para você.';

  @override
  String get tourConnect => 'Clique aqui para conectar ou desconectar.';

  @override
  String get tourMode => 'Escolha um modo. Kill switch bloqueia a Internet se a VPN cair.';

  @override
  String get tourSettings => 'Abra as configurações. Você pode reproduzir este guia lá.';

  @override
  String get chooseProgram => 'Escolha um programa';

  @override
  String get installedApps => 'Aplicativos instalados';

  @override
  String get runningProcesses => 'Executando processos';

  @override
  String get programsFailed => 'Não foi possível carregar aplicativos';

  @override
  String get programsEmpty => 'Nenhum aplicativo encontrado. Tente outro nome.';

  @override
  String get selectExe => 'Escolha um arquivo .exe';

  @override
  String get trafficUnavailable => 'Os contadores ainda não estão disponíveis';

  @override
  String get speedtest => 'Velocidade';

  @override
  String get speedtestCheck => 'Verifique a velocidade';

  @override
  String get speedtestSearch => 'Encontre um serviço';

  @override
  String get speedtestEmpty => 'Nenhuma correspondência. Altere a pesquisa.';

  @override
  String get speedtestBackToList => 'Voltar aos serviços';

  @override
  String get speedtestOpenBrowser => 'Abrir no navegador';

  @override
  String get speedtestUnavailable =>
      'O navegador incorporado não pôde ser iniciado. Abra o serviço no navegador do sistema.';

  @override
  String get speedtestPageFailed =>
      'A página não pôde carregar. Recarregue-o ou abra o serviço no navegador do sistema.';

  @override
  String get speedtestExternalFailed => 'O navegador do sistema não pôde abrir. Tente novamente.';

  @override
  String get modes => 'Modos';

  @override
  String get proxyShort => 'Procurador';

  @override
  String get tunMode => 'Todo o tráfego (TUN)';

  @override
  String get checkUpdates => 'Verifique se há atualizações';

  @override
  String get updates => 'Atualizações de aplicativos';

  @override
  String updateAvailable(String version) {
    return 'A versão $version está disponível';
  }

  @override
  String get updateOpenAbout => 'Ver atualização';

  @override
  String updateNotes(String version) {
    return 'Mudanças em $version';
  }

  @override
  String get updateCheck => 'Verifique se há atualizações';

  @override
  String get updateChecking => 'Verificando...';

  @override
  String get updateNoNotes => 'O lançamento não possui notas.';

  @override
  String get updateDropWarning =>
      'A conexão VPN cairá por alguns segundos enquanto Sora e seu núcleo são atualizados. Continuar?';

  @override
  String get updateWaitConnection => 'Aguarde até que a conexão VPN e o núcleo estejam prontos.';

  @override
  String get updateDownloading => 'Baixando e verificando arquivos...';

  @override
  String get updateInstalling => 'Preparando a atualização ou aguardando autenticação do administrador...';

  @override
  String get updateNetworkError => 'Não foi possível baixar a atualização. Tente novamente.';

  @override
  String get updateReleaseError => 'Os dados de lançamento ou arquivos necessários estão ausentes ou são inválidos.';

  @override
  String get updateChecksumError => 'O download não corresponde ao SHA256SUMS. Nada foi instalado.';

  @override
  String get updateInstallError => 'A atualização não terminou. A autenticação pode ter sido cancelada.';

  @override
  String get updateUnsupported =>
      'Este executável não pertence a um par de pacotes Sora compatível. Use as instruções de instalação da versão.';

  @override
  String get updateManual =>
      'Execute este comando em um terminal para instalar os dois pacotes verificados e reabra Sora. Os arquivos ficam no diretório de download. A conexão VPN cairá.';

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
  String get updateCopyCommand => 'Comando copiar';

  @override
  String get updateChecksDisabled => 'As verificações automáticas estão desativadas nas Configurações.';

  @override
  String get updateInstalled => 'Atualização instalada. Abra novamente Sora.';

  @override
  String get projectLinks => 'Projeto';

  @override
  String get githubReleases => 'Lançamentos e downloads';

  @override
  String get telegramChannel => 'Canal Telegram';

  @override
  String get licenses => 'Licenças';

  @override
  String get componentLicenses => 'Licenças de componentes';

  @override
  String get appCopyright => '© 2026 levvs-one e colaboradores';

  @override
  String get collapseServers => 'Recolher servidores';

  @override
  String get expandServers => 'Expandir servidores';

  @override
  String get hideDescription => 'Ocultar descrição';

  @override
  String get showDescription => 'Mostrar descrição';

  @override
  String get pendingConnectionChanges => 'Reconecte-se para aplicar essas alterações.';

  @override
  String get reconnectNow => 'Aplicar e reconectar';

  @override
  String get bypassLimitations =>
      'Este modo ignora DPI apenas para HTTP e TLS, não suporta UDP nem altera seu IP. Use um servidor VPN para voz Discord, chamadas e endereços Telegram bloqueados.';

  @override
  String get errEngineUnsupported =>
      'O mecanismo selecionado não suporta este perfil ou configurações. Escolha Auto ou um motor compatível.';

  @override
  String get errRestore =>
      'A limpeza da conexão estava incompleta. Tente desconectar novamente; veja o log para detalhes.';

  @override
  String get errSessionEnded => 'Esta sessão já terminou. Atualize o estado da conexão.';

  @override
  String get retryDisconnect => 'Tente desconectar novamente';

  @override
  String get tunStack => 'Pilha TUN';

  @override
  String get modesInfo => 'Sobre modos';

  @override
  String get modesGuideTitle => 'Modos e motores';

  @override
  String get modesGuide =>
      'Escolha Automático se não tiver certeza de qual mecanismo seu servidor precisa. Sora verifica o perfil e as configurações antes de conectar. Um mecanismo não pode aumentar a largura de banda do seu plano: o desempenho depende do servidor, da rota, do protocolo e da rede.\n\n## Modos\n\n### Todo o tráfego (TUN)\n\nSora cria uma interface de rede virtual e roteia o tráfego de aplicativos por meio dela, incluindo TCP e UDP. Use este modo para Telegram, jogos e voz Discord. As regras podem enviar sites ou programas específicos diretamente ou bloqueá-los. O serviço de rede precisa de permissão e de um servidor que suporte o protocolo necessário.\n\n###Proxy System\n\nSora configura um proxy HTTP/SOCKS local. Aplicativos que respeitam as configurações de proxy do sistema o utilizam. Aplicativos com sua própria pilha de rede podem se conectar diretamente; As chamadas UDP e de voz geralmente precisam de TUN. Este modo é adequado para navegadores e aplicativos com suporte a proxy.\n\n### Nenhum servidor\n\nEm Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir e remodelar solicitações HTTP/TLS e ignorar algumas verificações de DPI. Seu IP permanece o mesmo e as conexões vão diretamente para o site. Os resultados dependem do seu provedor e do método de bloqueio.\n\nA integração atual usa tpws para HTTP e TLS sobre TCP. Ele não ignora o bloqueio de IP nem retransmite UDP e não pode garantir as conexões MTProto do Telegram. Use um servidor VPN com TUN para voz Discord, chamadas Telegram e esses tipos de restrições.\n\n## Motores\n\n### Automático\n\nSora seleciona um mecanismo instalado que suporta todo o plano de conexão: protocolos de servidor, transportes, grupos, fragmentação e modo. Uma escolha manual incompatível é rejeitada antes de interromper a conexão atual. Escolha Automático ou outro mecanismo e aplique as configurações novamente.\n\n### sing-box\n\nOs novos pacotes Sora incluem [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), um fork de [sing-box](https://github.com/SagerNet/sing-box), adicionando XHTTP e VLESS Encryption do lado do cliente. Sora reconhece a construção e seus recursos. Uma compilação upstream sem XHTTP não obtém esse recurso apenas pelo seu nome.\n\nOs protocolos suportados incluem VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard e os parâmetros AmneziaWG 1.x/2.x Sora pode importar. Perfis JSON Xray completos requerem Xray. Novos campos AWG 3.x ainda não podem ser importados. sing-box usa uma porta de controle local protegida por senha, que outros aplicativos no computador podem detectar.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) suporta fragmentação VLESS, REALITY, XHTTP, VLESS Encryption e TLS. Ele também executa perfis completos do provedor Xray, preservando seu roteamento e grupos. Esses perfis não podem ser convertidos automaticamente para outro mecanismo sem alterar seu comportamento.\n\nO Xray incluído removeu a configuração que desativa a verificação do certificado TLS (`allowInsecure`). Seleciona automaticamente sing-box ou mihomo para servidores comuns que exigem essa configuração. Selecionar Xray reporta manualmente a incompatibilidade antes de interromper a conexão atual. Perfis JSON completos mais antigos precisam de um perfil de provedor atualizado com um certificado verificável ou PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) oferece suporte a grupos de fallback e balanceamento de carga ordenados, XHTTP e AmneziaWG. Escolha-o quando o failover automático para um servidor de backup for importante. A configuração de fragmentação TLS do Sora não está disponível com este mecanismo.\n\n## Compatibilidade em Sora\n\n| Recurso | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN e TCP/UDP | Sim | Sim | Sim |\n| XHTTP | Sim | Sim | Sim |\n| VLESS Encryption | Sim | Sim | Sim |\n| Perfil Xray completo | Não | Sim | Não |\n| TUIC/AnyTLS | Ambos | Não | TUIC |\n| Fragmentação TLS | Sim | Sim | Não |\n| AmneziaWG 1.x/2.x | Sim¹ | Não | Sim |\n| Grupo substituto ordenado | Não | Não² | Sim |\n\n¹ Perfis com J1/J2/J3/Itime utilizam mihomo; esses campos nunca devem ser descartados silenciosamente. ² Para um grupo de perfis Xray completos, o aplicativo seleciona um perfil de backup. O suporte depende da versão instalada; verifique sua versão em Sobre.\n\n## Pilha TUN\n\nA pilha lida com TCP e UDP dentro da interface virtual. No painel de modos, Xray e mihomo oferecem gVisor, System, Mixed e MIPS. Cada mecanismo salva sua própria preferência. Os modos proxy System e sem servidor não usam essa preferência.\n\n- **Mixed** — TCP usa a pilha do sistema, enquanto gVisor lida com UDP. Este é o padrão do mihomo no Linux. No Windows, Xray e mihomo usam MIPS por padrão.\n- **System** — usa a pilha do sistema. Tente outra opção se os aplicativos de rede encontrarem problemas.\n- **gVisor** — lida com o tráfego no espaço do usuário.\n- **MIPS** — pilha IP própria do mihomo, disponível na versão 1.19.32 do pacote.\n\nNo Linux, o Xray usa seu gVisor integrado por padrão. System, Mixed e MIPS em Linux usam mihomo como mecanismo TUN, encaminhando TCP e UDP para Xray por meio de um link SOCKS local autenticado. Xray mantém o protocolo, perfil do provedor e roteamento. Essas três opções requerem um mihomo instalado. Em Windows, Xray usa mihomo 1.19.32 ou posterior para as quatro pilhas TUN. Os protocolos e o roteamento permanecem no Xray. As regras de aplicativos nessa combinação permitem apenas conexões diretas e bloqueio; no Linux, elas exigem o gVisor integrado do Xray.\n\nA ponte executa um segundo processo. Em três medições ociosas no Linux, ele usou cerca de 32–36 MiB a mais de memória física do que o Xray TUN nativo. Isso não mede a carga de download: os custos de CPU e memória dependem das conexões. sing-box não possui seletor de pilha. Nenhuma pilha garante melhor desempenho em todas as redes. Escolha uma pilha e selecione Aplicar e reconecte para experimentá-la em sua rede.\n\n## Aplicando configurações\n\nSelecionar um servidor reconecta automaticamente. As configurações de modo, mecanismo, DNS e regras são salvas imediatamente; durante uma conexão ativa, clique em Aplicar e reconecte para usá-los. Reiniciar um mecanismo pode interromper downloads e chamadas. Cliques repetidos não iniciam conexões paralelas; a desconexão encerra a transição e libera a conexão.\n\nA Internet somente por meio de VPN bloqueia o tráfego direto quando um túnel cai. Afeta toda a máquina. Uma desconexão explícita remove as regras do Sora. Se a limpeza não terminar, tente desconectar novamente e abra o log.\n\n## Documentação do projeto\n\n- [sing-box-lx: configuração e suporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentação sing-box](https://sing-box.sagernet.org/)\n- [Documentação Xray](https://xtls.github.io/)\n- [Documentação mihomo](https://wiki.metacubex.one/)\n- [zapret: funcionamento e limitações](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Verifique servidores';

  @override
  String get extensions => 'Extensões';

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
    return 'Em $name';
  }

  @override
  String get diagnosticHttp => 'Diagnóstico HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Nenhuma solicitação registrada ainda. Abra primeiro um site de teste de velocidade.';

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
  String get qrScanHint => 'Escolha uma captura ou foto com um código QR, ou cole um link';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Nenhum código QR encontrado nesta imagem.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Abrir imagem';

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
      'Para Shadowsocks: método:senha, por exemplo chacha20-ietf-poly1305:senha';

  @override
  String get diagnosticPackets => 'Captura de pacotes';

  @override
  String get diagnosticEvents => 'Eventos do Windows';

  @override
  String get diagnosticCapture => 'Capture por 10 segundos';

  @override
  String get diagnosticRequiresTun => 'A captura de pacotes precisa de uma conexão Sora TUN ativa.';

  @override
  String get diagnosticUnavailable => 'Este diagnóstico não está disponível nesta plataforma.';

  @override
  String get extErrRevoked => 'A equipe do Sora retirou esta versão da extensão porque é insegura ou está quebrada.';

  @override
  String get extErrRevocationsExpired =>
      'Não foi possível renovar a lista de extensões retiradas. A instalação fica bloqueada até que seja renovada: verifique a rede e tente novamente.';

  @override
  String extRevokedDisabled(String names) {
    return 'Extensões retiradas foram desativadas: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Chave privada';

  @override
  String get customServerWgAddresses => 'Endereços da interface';

  @override
  String get customServerWgPeerKey => 'Chave pública do servidor';

  @override
  String get customServerWgPresharedKey => 'Chave pré-compartilhada';

  @override
  String get customServerWgAllowedIps => 'IPs permitidos';

  @override
  String get customServerWgKeepalive => 'Keepalive, segundos';

  @override
  String get customServerWgKeyInvalid => 'A chave deve ter 32 bytes em base64, como o wg genkey imprime.';

  @override
  String get customServerWgCidrInvalid => 'Digite prefixos separados por vírgula, como 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Digite um número de segundos de 0 a 65535.';
}
