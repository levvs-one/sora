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
  String get connEmpty => 'Sem conexões';

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get notInstalled => 'Não instalado';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get reportProblem => 'Relatar um problema';

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
  String get errAuth => 'O acesso ao serviço Sora foi negado';

  @override
  String get errVersion => 'O aplicativo e o serviço Sora estão em versões diferentes';

  @override
  String get errBusy => 'O comando anterior ainda está em execução';

  @override
  String get errEngineMissing => 'O mecanismo necessário para este servidor não foi encontrado';

  @override
  String get errEngineStart => 'O mecanismo não pôde ser iniciado';

  @override
  String get errEngineStopped => 'O mecanismo parou';

  @override
  String get errTunnel => 'Este modo VPN não está disponível';

  @override
  String get errTimeout => 'O servidor não respondeu a tempo';

  @override
  String get errFirewall => 'Não foi possível bloquear o acesso à Internet fora da VPN';

  @override
  String get errSubFetch => 'Não foi possível baixar a assinatura';

  @override
  String get deviceIdentity => 'Identificador do dispositivo';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Redefinir identificador';

  @override
  String get deviceIdentityResetConfirm => 'Redefinir o identificador do dispositivo?';

  @override
  String get errSubDeviceLimit => 'Limite de dispositivos atingido';

  @override
  String get errSubDeviceRequired => 'O provedor exige um identificador do dispositivo';

  @override
  String get errSubFormat => 'O formato da assinatura não foi reconhecido';

  @override
  String get errSubEmpty => 'A assinatura não contém servidores';

  @override
  String get errSubDuplicate => 'Esta assinatura já foi adicionada';

  @override
  String get errSubLimit => 'O limite de assinaturas foi atingido';

  @override
  String get errSubScheme => 'Esquema de link de assinatura não suportado';

  @override
  String get errSecretStore => 'O armazenamento do Sora está danificado ou inacessível';

  @override
  String get errNoServers => 'Não há servidores para se conectar';

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
  String get themeSystem => 'Como no sistema';

  @override
  String get themeLight => 'Luz';

  @override
  String get themeDark => 'Escura';

  @override
  String get language => 'Linguagem';

  @override
  String get languageSystem => 'Como no sistema';

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
  String get splitPos => 'Posições divididas';

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
      other: 'a assinatura termina em $days dias',
      one: 'a assinatura termina no dia $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servidores $count, os mais rápidos',
      one: 'Servidor $count, o mais rápido',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modo';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'Endereço proxy';

  @override
  String get copied => 'Copiada';

  @override
  String get launchAtLogin => 'Comece com o sistema';

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
  String get importSealed => 'Este link é criptografado para Happ e somente Happ pode lê-lo';

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
  String get notificationsEmpty => 'Sem notificações';

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
  String get programsEmpty => 'Nenhum aplicativo encontrado';

  @override
  String get selectExe => 'Escolha um arquivo .exe';

  @override
  String get speedtest => 'Velocidade';

  @override
  String get speedtestSearch => 'Encontre um serviço';

  @override
  String get speedtestEmpty => 'Nenhuma correspondência';

  @override
  String get speedtestBackToList => 'Voltar aos serviços';

  @override
  String get speedtestOpenBrowser => 'Abrir no navegador';

  @override
  String get speedtestUnavailable => 'O navegador incorporado não pôde ser iniciado';

  @override
  String get speedtestPageFailed => 'A página não pôde carregar';

  @override
  String get speedtestExternalFailed => 'O navegador do sistema não pôde abrir';

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
  String get updateDropWarning => 'Desconectar para atualizar?';

  @override
  String get updateWaitConnection => 'A conexão não está pronta';

  @override
  String get updateDownloading => 'Baixando e verificando arquivos...';

  @override
  String get updateInstalling => 'Preparando a atualização ou aguardando autenticação do administrador...';

  @override
  String get updateNetworkError => 'Não foi possível baixar a atualização';

  @override
  String get updateReleaseError => 'Os dados de lançamento ou arquivos necessários estão ausentes ou são inválidos.';

  @override
  String get updateChecksumError => 'O download não corresponde ao SHA256SUMS';

  @override
  String get updateInstallError => 'A atualização não terminou';

  @override
  String get updateUnsupported => 'Este executável não pertence a um par de pacotes Sora compatível';

  @override
  String get updateManual =>
      'Execute este comando em um terminal para instalar os dois pacotes verificados e reabra Sora. Os arquivos ficam no diretório de download. A conexão VPN cairá.';

  @override
  String get updateVersionRevoked => 'O desenvolvedor retirou esta versão';

  @override
  String get updateRolloutPending =>
      'Uma versão mais recente está sendo lançada gradualmente e será oferecida a você automaticamente.';

  @override
  String updateRollbacking(String version) {
    return 'Revertendo para a versão $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'A atualização para $version não passou na verificação de integridade, então Sora foi revertido para $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Falha na reversão automática';

  @override
  String get updateRollbackCacheError =>
      'Não foi possível preparar uma cópia de reversão verificada da versão atual, portanto a atualização não foi instalada.';

  @override
  String get updateCopyCommand => 'Comando copiar';

  @override
  String get updateChecksDisabled => 'As verificações automáticas estão desativadas nas Configurações.';

  @override
  String get updateInstalled => 'Atualização instalada';

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
  String get collapseServers => 'Recolher servidores';

  @override
  String get expandServers => 'Expandir servidores';

  @override
  String get hideDescription => 'Ocultar descrição';

  @override
  String get showDescription => 'Mostrar descrição';

  @override
  String get errEngineUnsupported => 'O mecanismo selecionado não suporta este perfil ou configurações';

  @override
  String get errRestore => 'A limpeza da conexão estava incompleta';

  @override
  String get errSessionEnded => 'Esta sessão já terminou';

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
      'Escolha Automático se não tiver certeza de qual mecanismo seu servidor precisa. Sora verifica o perfil e as configurações antes de conectar. Um mecanismo não pode aumentar a largura de banda do seu plano: o desempenho depende do servidor, da rota, do protocolo e da rede.\n\n## Modos\n\n### Todo o tráfego (TUN)\n\nSora cria uma interface de rede virtual e roteia o tráfego de aplicativos por meio dela, incluindo TCP e UDP. Use este modo para Telegram, jogos e voz Discord. As regras podem enviar sites ou programas específicos diretamente ou bloqueá-los. O serviço de rede precisa de permissão e de um servidor que suporte o protocolo necessário.\n\n###Proxy System\n\nSora configura um proxy HTTP/SOCKS local. Aplicativos que respeitam as configurações de proxy do sistema o utilizam. Aplicativos com sua própria pilha de rede podem se conectar diretamente; As chamadas UDP e de voz geralmente precisam de TUN. Este modo é adequado para navegadores e aplicativos com suporte a proxy.\n\n### Nenhum servidor\n\nEm Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir e remodelar solicitações HTTP/TLS e ignorar algumas verificações de DPI. Seu IP permanece o mesmo e as conexões vão diretamente para o site. Os resultados dependem do seu provedor e do método de bloqueio.\n\nA integração atual usa tpws para HTTP e TLS sobre TCP. Ele não ignora o bloqueio de IP nem retransmite UDP e não pode garantir as conexões MTProto do Telegram. Use um servidor VPN com TUN para voz Discord, chamadas Telegram e esses tipos de restrições.\n\n## Motores\n\n### Automático\n\nSora seleciona um mecanismo instalado que suporta todo o plano de conexão: protocolos de servidor, transportes, grupos, fragmentação e modo. Uma escolha manual incompatível é rejeitada antes de interromper a conexão atual. Escolha Automático ou outro mecanismo e aplique as configurações novamente.\n\n### sing-box\n\nOs novos pacotes Sora incluem [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), um fork de [sing-box](https://github.com/SagerNet/sing-box), adicionando XHTTP e VLESS Encryption do lado do cliente. Sora reconhece a construção e seus recursos. Uma compilação upstream sem XHTTP não obtém esse recurso apenas pelo seu nome.\n\nOs protocolos suportados incluem VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard e os parâmetros AmneziaWG 1.x/2.x Sora pode importar. Perfis JSON Xray completos requerem Xray. Novos campos AWG 3.x ainda não podem ser importados. sing-box usa uma porta de controle local protegida por senha, que outros aplicativos no computador podem detectar.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) suporta fragmentação VLESS, REALITY, XHTTP, VLESS Encryption e TLS. Ele também executa perfis completos do provedor Xray, preservando seu roteamento e grupos. Esses perfis não podem ser convertidos automaticamente para outro mecanismo sem alterar seu comportamento.\n\nO Xray incluído removeu a configuração que desativa a verificação do certificado TLS (`allowInsecure`). Seleciona automaticamente sing-box ou mihomo para servidores comuns que exigem essa configuração. Selecionar Xray reporta manualmente a incompatibilidade antes de interromper a conexão atual. Perfis JSON completos mais antigos precisam de um perfil de provedor atualizado com um certificado verificável ou PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) oferece suporte a grupos de fallback e balanceamento de carga ordenados, XHTTP e AmneziaWG. Escolha-o quando o failover automático para um servidor de backup for importante. A configuração de fragmentação TLS do Sora não está disponível com este mecanismo.\n\n## Compatibilidade em Sora\n\n| Recurso | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN e TCP/UDP | Sim | Sim | Sim |\n| XHTTP | Sim | Sim | Sim |\n| VLESS Encryption | Sim | Sim | Sim |\n| Perfil Xray completo | Não | Sim | Não |\n| TUIC/AnyTLS | Ambos | Não | TUIC |\n| mieru | Não | Não | Sim |\n| NaiveProxy | Sim | Não | Não |\n| Fragmentação TLS | Sim | Sim | Não |\n| AmneziaWG 1.x/2.x | Sim¹ | Não | Sim |\n| Grupo substituto ordenado | Não | Não² | Sim |\n\n¹ Perfis com J1/J2/J3/Itime utilizam mihomo; esses campos nunca devem ser descartados silenciosamente. ² Para um grupo de perfis Xray completos, o aplicativo seleciona um perfil de backup. O suporte depende da versão instalada; verifique sua versão em Sobre.\n\n## Pilha TUN\n\nA pilha lida com TCP e UDP dentro da interface virtual. No painel de modos, Xray e mihomo oferecem gVisor, System, Mixed e MIPS. Cada mecanismo salva sua própria preferência. Os modos proxy System e sem servidor não usam essa preferência.\n\n- **Mixed**: TCP usa a pilha do sistema, enquanto gVisor lida com UDP. Este é o padrão do mihomo no Linux. No Windows, Xray e mihomo usam MIPS por padrão.\n- **System**: usa a pilha do sistema. Tente outra opção se os aplicativos de rede encontrarem problemas.\n- **gVisor**: lida com o tráfego no espaço do usuário.\n- **MIPS**: pilha IP própria do mihomo, disponível na versão 1.19.32 do pacote.\n\nNo Linux, o Xray usa seu gVisor integrado por padrão. System, Mixed e MIPS em Linux usam mihomo como mecanismo TUN, encaminhando TCP e UDP para Xray por meio de um link SOCKS local autenticado. Xray mantém o protocolo, perfil do provedor e roteamento. Essas três opções requerem um mihomo instalado. Em Windows, Xray usa mihomo 1.19.32 ou posterior para as quatro pilhas TUN. Os protocolos e o roteamento permanecem no Xray. As regras de aplicativos nessa combinação permitem apenas conexões diretas e bloqueio; no Linux, elas exigem o gVisor integrado do Xray.\n\nA ponte executa um segundo processo. Em três medições ociosas no Linux, ele usou cerca de 32–36 MiB a mais de memória física do que o Xray TUN nativo. Isso não mede a carga de download: os custos de CPU e memória dependem das conexões. sing-box não possui seletor de pilha. Nenhuma pilha garante melhor desempenho em todas as redes.\n\n## Aplicando configurações\n\nSelecionar um servidor restabelece a conexão automaticamente. Suas alterações de modo, mecanismo, DNS ou regras são aplicadas uma vez após uma breve pausa com reconexão automática; atualizações em segundo plano não reconectam a VPN. Reiniciar o mecanismo pode interromper downloads e chamadas.\n\nA Internet somente por meio de VPN bloqueia o tráfego direto quando um túnel cai. Afeta toda a máquina. Uma desconexão explícita remove as regras do Sora. Se a limpeza não terminar, tente desconectar novamente e abra o log.\n\n## Documentação do projeto\n\n- [sing-box-lx: configuração e suporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentação sing-box](https://sing-box.sagernet.org/)\n- [Documentação Xray](https://xtls.github.io/)\n- [Documentação mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: funcionamento e limitações](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC transporta TCP através de uma videochamada no Jitsi, Yandex Telemost ou WB Stream. Importe uma ligação olcrtc:// ou um código QR. Funciona com sing-box, Xray e mihomo nos modos proxy e TUN; UDP não é suportado. As duas extremidades precisam de versões OLC2 compatíveis. O projeto original está arquivado.\n';

  @override
  String get probeServers => 'Pingar';

  @override
  String get extensions => 'Extensões';

  @override
  String extRatingLabel(String rating) {
    return 'Classificação $rating de 5';
  }

  @override
  String extByAuthor(String author) {
    return 'por $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Instalações: $count';
  }

  @override
  String get extInstallOne => '1 instalação';

  @override
  String get extSideloadWarning => 'Chave autoassinada';

  @override
  String get extPermissionsWidened => 'A atualização pede novas permissões:';

  @override
  String get extInstall => 'Instalar';

  @override
  String get extUpdate => 'Atualizar';

  @override
  String get extCancel => 'Cancelar';

  @override
  String get extConfirm => 'Confirmar';

  @override
  String get extCatalog => 'Catálogo';

  @override
  String get extInstalled => 'Extensões instaladas';

  @override
  String get extSearchHint => 'Pesquisar extensões';

  @override
  String get extCatAll => 'Todos';

  @override
  String get extCatTools => 'Ferramentas';

  @override
  String get extCatThemes => 'Temas';

  @override
  String get extCatAutomation => 'Automação';

  @override
  String get extCatStats => 'Estatísticas';

  @override
  String get extCatNetwork => 'Rede';

  @override
  String get extSortBy => 'Classificar por';

  @override
  String get extSortPopular => 'Mais populares';

  @override
  String get extSortRating => 'Melhor classificação';

  @override
  String get extSortName => 'Nome';

  @override
  String get extCatalogError => 'Não foi possível carregar o catálogo';

  @override
  String get extRetry => 'Tentar novamente';

  @override
  String get extEmptySearch => 'Nada encontrado';

  @override
  String get extEmptyInstalled => 'Nenhuma extensão instalada ainda';

  @override
  String get extInstallFromFile => 'Instalar a partir do arquivo';

  @override
  String get extInstallFromUrl => 'Instalar a partir de URL';

  @override
  String get extDownload => 'Baixar';

  @override
  String get extDownloading => 'Baixando…';

  @override
  String get extVerifying => 'Verificando…';

  @override
  String get extInstalling => 'Instalando…';

  @override
  String get extErrSignature => 'A verificação de assinatura falhou';

  @override
  String get extErrManifest => 'O manifesto da extensão é inválido.';

  @override
  String get extErrNetwork => 'Erro de rede';

  @override
  String get extErrHash => 'O download não corresponde ao catálogo';

  @override
  String extErrMinApp(String version) {
    return 'Esta extensão precisa da versão do aplicativo $version ou mais recente.';
  }

  @override
  String get extErrHttpsOnly => 'Apenas links https:// são permitidos';

  @override
  String get extErrGeneric => 'Algo deu errado';

  @override
  String get extErrAuthorKeyChanged =>
      'Esta atualização está assinada com uma chave de autor diferente da versão instalada, por isso foi bloqueada';

  @override
  String get extDisabled => 'Desativado';

  @override
  String extToggleEnabled(String name) {
    return 'Habilitar $name';
  }

  @override
  String get extSearchInstalled => 'Pesquisar extensões instaladas';

  @override
  String get extUpdateAll => 'Atualizar tudo';

  @override
  String extUpdatesAvailable(int count) {
    return '$count atualizações disponíveis';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count atualizado';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Sensível';

  @override
  String get extRiskDangerous => 'Alto risco';

  @override
  String get extPermissionsRemoved => 'Não é mais solicitado:';

  @override
  String get extUpdateFailedKept => 'A versão anterior ainda está instalada.';

  @override
  String get extConflictsTitle => 'Conflitos de extensão';

  @override
  String get extConflictTheme => 'Tema do aplicativo';

  @override
  String get extConflictNetHooks => 'Ganchos de rede';

  @override
  String extConflictWinner(String name) {
    return '$name vence Os conflitos de';
  }

  @override
  String extConflictsCount(int count) {
    return 'Conflitos de extensão: $count';
  }

  @override
  String get extConflictsResolve => 'Resolver conflitos';

  @override
  String extVersionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get extPermissionsTitle => 'Permissões';

  @override
  String get extNoPermissions => 'Sem permissões especiais.';

  @override
  String get extSettings => 'Configurações';

  @override
  String get extSaveSettings => 'Salvar configurações';

  @override
  String extUpdateTo(String version) {
    return 'Atualizar para $version';
  }

  @override
  String get extEnabled => 'Ativado';

  @override
  String extRollbackTo(String version) {
    return 'Reverter para $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Reverter para a versão $version?';
  }

  @override
  String get extUninstall => 'Desinstalar';

  @override
  String extUninstallConfirm(String name) {
    return 'Remover “$name” e suas configurações?';
  }

  @override
  String get extPanelUnavailable => 'O painel da extensão está indisponível.';

  @override
  String get extPermConnectionsRead => 'Veja lista de conexões ativas';

  @override
  String get extPermServersRead => 'Veja uma lista de seus servidores';

  @override
  String get extPermSettingsRead => 'Leia as configurações do aplicativo';

  @override
  String get extPermSettingsWrite => 'Alterar configurações do aplicativo';

  @override
  String get extPermNotifications => 'Mostrar notificações';

  @override
  String get extPermTray => 'Adicionar itens ao menu da bandeja';

  @override
  String get extPermUiPanel => 'Mostrar painéis dentro do aplicativo';

  @override
  String get extPermThemeApply => 'Aplicar temas';

  @override
  String get extPermRoutingRules => 'Adicionar regras de roteamento';

  @override
  String get extPermNetHooks => 'Integrar ao caminho da rede';

  @override
  String get extPermNetFetch => 'Solicitação URL da lista permitida';

  @override
  String get extPermBackground => 'Executar tarefas em segundo plano';

  @override
  String get extPermNotYetActive => 'Desativado';

  @override
  String get extCapBackground => 'é executado em segundo plano';

  @override
  String get extCapNetHook => 'Contorno de bloqueios e hooks de rede';

  @override
  String get extCapPanel => 'Painéis de interface';

  @override
  String get extCapRouting => 'Regras de roteamento';

  @override
  String get extCapTheme => 'Temas';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Registro de alterações';

  @override
  String get extImageFailed => 'Não foi possível carregar a imagem';

  @override
  String get extScreenshots => 'Capturas de tela';

  @override
  String get extSortRelevance => 'Relevância';

  @override
  String get extBgTitle => 'Tarefa em segundo plano';

  @override
  String get extBgEnabled => 'Executar em segundo plano';

  @override
  String get extBgInterval => 'Executar a cada';

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
  String get extCapNetwork => 'Acesso à rede';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Rede: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Em $name';
  }

  @override
  String get diagnosticHttp => 'Diagnóstico HTTP';

  @override
  String get diagnosticNoData => 'Nenhuma solicitação registrada ainda';

  @override
  String get qrShareTitle => 'Compartilhe o código QR';

  @override
  String get qrScanTitle => 'Digitalize o código QR';

  @override
  String get qrCopyLink => 'Copiar link';

  @override
  String get qrWarning => 'Compartilhe o código apenas com pessoas de confiança.';

  @override
  String get qrFromClipboard => 'Colar da área de transferência';

  @override
  String get qrNoCode => 'Nenhum código QR encontrado nesta imagem.';

  @override
  String get qrInvalid => 'Este código QR não contém um link válido.';

  @override
  String get qrScan => 'Digitalizar QR Lista';

  @override
  String get qrFromImage => 'Abrir imagem';

  @override
  String get connGroupByProcess => 'Agrupar por processo';

  @override
  String get connListView => 'Em lista';

  @override
  String get connCopyHost => 'Copiar host';

  @override
  String get connAddRule => 'Adicionar regra';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count conexões', one: '$count conexão');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Predefinição';

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
  String get dnsCheck => 'Verifique se há vazamentos de dados';

  @override
  String get dnsChecking => 'Verificando...';

  @override
  String get dnsNoLeak => 'Nenhum vazamento encontrado';

  @override
  String get dnsLeakFound => 'Vazamento detectado';

  @override
  String get dnsLastCheck => 'Última verificação';

  @override
  String get dnsNeverChecked => 'Ainda não testado';

  @override
  String get dnsLeakCheckTunnelDns => 'Resolvedores DNS do túnel';

  @override
  String get dnsLeakCheckSystemResolvers => 'Resolvedores do sistema';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Proteção DNS do bloqueio de rede';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Configure DNS para o túnel nas configurações de DNS acima.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Verifique quais resolvedores seu sistema usaria fora do túnel.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Ative o bloqueio de rede para manter o tráfego DNS dentro do túnel.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS cifrado do sistema operativo';

  @override
  String get dnsLeakCheckDnsSpoof => 'Respostas DNS forjadas';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Verifique quais endpoints DNS criptografados seu sistema usa fora do túnel.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Use DNS (DoT ou DoH) criptografado para o túnel para que os resolvedores não possam forjar respostas.';

  @override
  String get dnsCheckNeedsConnection => 'Conecte primeiro ao VPN e depois verifique se há vazamentos.';

  @override
  String get dnsExpected => 'esperado';

  @override
  String get dnsActual => 'Observado';

  @override
  String get measureSpeed => 'Medir velocidade';

  @override
  String get benchmarkStale => 'desatualizado';

  @override
  String get autoSelectMode => 'Servidor de seleção automática';

  @override
  String get autoSelectPing => 'Ping mais rápido';

  @override
  String get autoSelectSpeed => 'Velocidade mais rápida';

  @override
  String get autoSelectSmart => 'Escolha inteligente';

  @override
  String get coreWatchUnstable => 'A conexão com o núcleo está instável';

  @override
  String get watchReconnect => 'Reconectar';

  @override
  String get crashRestoreTitle => 'A última sessão foi interrompida';

  @override
  String get restoreOnCrash => 'Restaurar sessão após uma falha';

  @override
  String get crashRestore => 'Restaurar';

  @override
  String get crashDismiss => 'Agora não';

  @override
  String get overrideTitle => 'Minhas edições';

  @override
  String get overrideEdit => 'Editar servidores';

  @override
  String get overrideHide => 'Ocultar';

  @override
  String get overrideUnhide => 'Mostrar';

  @override
  String get overrideClear => 'Redefinir edições';

  @override
  String get overrideEmpty => 'Nenhuma edição ainda';

  @override
  String get overrideCustomRules => 'Regras próprias';

  @override
  String get errBenchmarkUnsupported => 'A medição de velocidade exige um núcleo mais recente';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Medição de $done de $total…';
  }

  @override
  String get profiles => 'Perfis de rede';

  @override
  String get profilesEmpty => 'Nenhum perfil ainda';

  @override
  String get profileAdd => 'Adicionar perfil';

  @override
  String get profileName => 'Nome do perfil';

  @override
  String get profileSsids => 'Wi-Fi (SSID)';

  @override
  String get profileGateways => 'Gateways de rede';

  @override
  String get profileAsns => 'AS números';

  @override
  String get profileAutoApply => 'Aplicar automaticamente';

  @override
  String get profileSnapshot => 'Lembrar configurações atuais';

  @override
  String get profileSnapshotDone => 'Configurações atuais salvas no perfil';

  @override
  String get profileDelete => 'Excluir perfil';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Excluir perfil \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Aplicar perfil \"$name\"?';
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
  String get profileActive => 'Ativo';

  @override
  String networkNow(Object info) {
    return 'Agora: $info';
  }

  @override
  String get networkUnknown => 'Informações de rede indisponíveis';

  @override
  String get profileNoTriggers => 'Sem condições de perfil';

  @override
  String get chains => 'Cadeias de proxy';

  @override
  String get chainsEmpty => 'Ainda não há correntes';

  @override
  String get chainAdd => 'Nova cadeia';

  @override
  String get chainName => 'Nome da cadeia';

  @override
  String get chainTooFew => 'Uma cadeia precisa de pelo menos dois servidores';

  @override
  String get chainTooMany => 'Uma cadeia pode ter no máximo três servidores';

  @override
  String get chainEstimate => 'Latência estimada';

  @override
  String get chainSave => 'Salvar cadeia';

  @override
  String get chainDelete => 'Excluir cadeia';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Excluir cadeia \"$name\"?';
  }

  @override
  String get chainUnsupported => 'O mecanismo selecionado não suporta cadeias';

  @override
  String get chainHopMissing => 'Um servidor da cadeia não está mais disponível';

  @override
  String chainHop(Object n) {
    return 'Salto $n';
  }

  @override
  String get chainEntry => 'Entrada';

  @override
  String get chainExit => 'Saída';

  @override
  String get sync => 'Sincronização de dispositivos';

  @override
  String get syncDevices => 'Meus dispositivos';

  @override
  String get syncEmpty => 'Nenhum dispositivo emparelhado';

  @override
  String get syncPair => 'Emparelhar dispositivo';

  @override
  String get syncShowCode => 'Mostrar meu código';

  @override
  String get syncScanCode => 'Digitalizar código';

  @override
  String get syncRevoke => 'Retirar';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Revogar \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Última sincronização: $time';
  }

  @override
  String get syncNever => 'Nunca';

  @override
  String get syncPaired => 'Dispositivo emparelhado';

  @override
  String get syncPairingTitle => 'Parear com este dispositivo';

  @override
  String get syncWaiting => 'Aguardando o outro dispositivo…';

  @override
  String get zapretWithVpn => 'Ignorar filtragem DPI para tráfego direto de rede';

  @override
  String get chainDuplicate => 'Um servidor aparece mais de uma vez na cadeia';

  @override
  String get edit => 'Editar';

  @override
  String get remove => 'Remover';

  @override
  String get autoSwitchOnDegrade => 'Ativação automática na degradação';

  @override
  String get tunStackMixed => 'Misto';

  @override
  String get tunStackSystem => 'Sistema';

  @override
  String get customServerAdd => 'Adicionar servidor personalizado';

  @override
  String get customServers => 'Meus servidores';

  @override
  String get customServerName => 'Nome';

  @override
  String get customServerNameRequired => 'Nome não informado';

  @override
  String get customServerAddress => 'Endereço';

  @override
  String get customServerAddressRequired => 'Endereço não informado';

  @override
  String get customServerAddressInvalid => 'Endereço inválido';

  @override
  String get customServerPort => 'Porta';

  @override
  String get customServerPortInvalid => 'Porta inválida';

  @override
  String get customServerProtocol => 'Protocolo';

  @override
  String get customServerCredentials => 'Informações de login';

  @override
  String get customServerShowSecret => 'Mostrar segredo';

  @override
  String get customServerHideSecret => 'Ocultar segredo';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Excluir servidor “$name”?';
  }

  @override
  String get leakTestTitle => 'Teste para vazamento de dados';

  @override
  String get leakTestRun => 'Verifique';

  @override
  String get leakTestCancel => 'Cancelar';

  @override
  String get leakTestNeedsConnection => 'Conecte-se ao VPN para testar vazamentos de dados.';

  @override
  String leakTestProgress(int count) {
    return 'Testes concluídos: $count';
  }

  @override
  String get leakTestAllClear => 'Nenhum vazamento encontrado';

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
  String get leakTestFix => 'Correção';

  @override
  String get leakTestFixedNote => 'O bloqueio de rede está ativo. Repita o teste para verificar.';

  @override
  String get leakTestCheckDirectDns => 'Direto DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP eco';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Resolvedores do sistema';

  @override
  String get leakTestCheckTunnelConnectivity => 'Conectividade de túnel';

  @override
  String get leakTestCheckTunnelDns => 'DNS através do túnel';

  @override
  String get noticeDegraded =>
      'O servidor ficou lento. Sora mudou para o melhor servidor encontrado durante a medição.';

  @override
  String get obfs => 'Ofuscação do tráfego';

  @override
  String get syncCodeExpired => 'O código expirou';

  @override
  String get syncDaemonFailed => 'Não foi possível iniciar o serviço de sincronização';

  @override
  String get syncDaemonMissing => 'O componente sora-sync não foi encontrado';

  @override
  String get syncDaemonStarting => 'Iniciando o serviço de sincronização…';

  @override
  String get syncErrAuth => 'O serviço de sincronização rejeitou o token de acesso';

  @override
  String get syncErrNotFound => 'O dispositivo não está mais emparelhado';

  @override
  String get syncErrPairingActive => 'Uma sessão de emparelhamento já está aberta';

  @override
  String get syncErrUnreachable => 'O outro dispositivo não respondeu';

  @override
  String get syncError => 'Erro de sincronização';

  @override
  String syncExpiresIn(String duration) {
    return 'O código expira em $duration';
  }

  @override
  String get syncJoining => 'Emparelhando com o dispositivo…';

  @override
  String get syncNewCode => 'Novo código';

  @override
  String syncPairedWith(String name) {
    return 'Emparelhado com $name';
  }

  @override
  String get syncRetry => 'Repetir';

  @override
  String get syncStopShowing => 'Ocultar código';

  @override
  String get syncSyncNow => 'Sincronizar agora';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Recebido $pulled, enviado $pushed';
  }

  @override
  String get syncResultTitle => 'Resultado da sincronização';

  @override
  String get syncPulled => 'Recebido';

  @override
  String get syncPushed => 'Enviado';

  @override
  String get syncNoChanges => 'Nenhuma alteração detectada';

  @override
  String get syncDocKindSubscriptions => 'Subscrições';

  @override
  String get syncDocKindSettings => 'Configurações do aplicativo';

  @override
  String get syncDocKindOverrides => 'Personalizações das subscrições';

  @override
  String get syncDocKindProfiles => 'Perfis de rede';

  @override
  String get syncDocKindChains => 'Cadeias de proxy';

  @override
  String syncFrom(String name) {
    return 'de $name';
  }

  @override
  String get syncThisDevice => 'Este dispositivo';

  @override
  String get syncUnavailableAndroid => 'Sincronização indisponível no Android';

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
  String get extErrRevocationsExpired => 'A instalação está bloqueada até a atualização da lista de revogações.';

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
  String get customServerWgKeyInvalid => 'Chave WireGuard inválida';

  @override
  String get customServerWgCidrInvalid => 'Prefixo CIDR inválido';

  @override
  String get customServerWgKeepaliveInvalid => 'Intervalo keepalive inválido';

  @override
  String get strictKillSwitch => 'Bloqueio de rede estrito';

  @override
  String get strictKillSwitchWarning => 'Bloquear tráfego fora da VPN após sair?';

  @override
  String get extWorkerFailed => 'A tarefa em segundo plano da extensão falhou';

  @override
  String get extAssetRejected => 'O arquivo da extensão contém cores ilegíveis ou regras inválidas';

  @override
  String get extVerifiedSora => 'Verificado pela Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Abrir';

  @override
  String get customServerOwn => 'Servidor próprio';

  @override
  String get customServerPaste => 'Colar um link';

  @override
  String get customServerUser => 'Usuário';

  @override
  String get customServerPassword => 'Senha';

  @override
  String get customServerSecretRequired => 'Valor não informado';

  @override
  String get customServerLinkInvalid => 'Link do servidor inválido';

  @override
  String get errInternal => 'Erro interno do Sora';

  @override
  String get errTls => 'Certificado do servidor rejeitado';

  @override
  String get errFileAccess => 'Não foi possível acessar o arquivo';

  @override
  String get errDataLimit => 'Dados demais';

  @override
  String get errCredentials => 'Credenciais salvas ausentes';

  @override
  String subscriptionStale(String time) {
    return 'Última atualização: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Ainda não atualizado';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'O servidor retornou o código HTTP $status',
      zero: 'O servidor recusou a solicitação',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Configuração do servidor incompleta ou incompatível';

  @override
  String get errServerIds => 'Dois servidores têm o mesmo identificador';

  @override
  String get errRoutingGroup => 'A rota aponta para servidores ausentes ou um grupo danificado';

  @override
  String get errConnections => 'Lista de conexões indisponível';

  @override
  String get errLogs => 'Este serviço não mantém registros';

  @override
  String get errDiagnostics => 'Não foi possível coletar o diagnóstico';

  @override
  String get errMissingItem => 'O item solicitado não existe mais';

  @override
  String get errInvalidRequest => 'A solicitação contém valores inválidos';

  @override
  String get errProxyLogin => 'O proxy do sistema não aceita este acesso';

  @override
  String get errLogFilter => 'Filtro de registro inválido';

  @override
  String get errSubRedirect => 'O servidor redirecionou para um endereço inseguro';

  @override
  String get errProxySetup => 'Não foi possível configurar o proxy do sistema';

  @override
  String get notificationsToday => 'Hoje';

  @override
  String get notificationsYesterday => 'Ontem';

  @override
  String get notificationsMarkRead => 'Marcar tudo como lido';

  @override
  String get notificationsUnread => 'Não lida';

  @override
  String get desktopNotifications => 'Notificações da área de trabalho';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'O intervalo de atualização da assinatura é inválido';

  @override
  String get errRule => 'Uma regra de roteamento é inválida';

  @override
  String get errDns => 'As configurações de DNS são inválidas';

  @override
  String get errEndpoint => 'O endereço do servidor a ser testado é inválido';

  @override
  String get errCancelled => 'A solicitação foi cancelada';

  @override
  String get customServerOptions => 'Configurações de conexão';

  @override
  String get customServerTransport => 'Transporte';

  @override
  String get customServerSecurity => 'Segurança';

  @override
  String get customServerCipher => 'Cifra';

  @override
  String get customServerWgInterface => 'Interface';

  @override
  String get customServerWgPeer => 'Par';

  @override
  String extAvailableOn(String platforms) {
    return 'Disponível em: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Alterar o tráfego TCP de todos os aplicativos?';

  @override
  String get winwsRequirements => 'Este modo VPN não está disponível';

  @override
  String get emptyServersTitle => 'Adicione um servidor ou uma assinatura';

  @override
  String get emptyServersBody =>
      'Cole o link de assinatura do seu serviço de VPN, adicione seu próprio servidor ou escaneie um código QR.';

  @override
  String get qrShort => 'Código QR';

  @override
  String get extAboutHello => 'Painel de exemplo: mostra as conexões ativas e envia uma notificação de teste.';

  @override
  String get extAboutZapret =>
      'Contorna bloqueios sem VPN, mudando o início das conexões para que o provedor não reconheça o site. Funciona no modo Sem servidor.';

  @override
  String get extAboutByedpi => 'Contorna bloqueios sem VPN pelo proxy local ByeDPI. Funciona no modo Sem servidor.';

  @override
  String get modeTunHint => 'Todo o tráfego do computador passa pela VPN';

  @override
  String get modeProxyHint => 'Apenas navegadores e apps que usam o proxy do sistema';

  @override
  String get modeBypassHint => 'Contornar bloqueios sem servidor VPN';

  @override
  String get modeExtensionHint => 'Contorno de bloqueios de uma extensão';

  @override
  String get engineInfo =>
      'O núcleo faz a conexão com o servidor.\n\nAuto: o Sora escolhe um núcleo compatível com o protocolo do servidor.\nsing-box: rápido e versátil.\nXray: o melhor para VLESS com REALITY e XHTTP.\nmihomo: assinaturas Clash e regras flexíveis.\n\nTroque o núcleo só se um servidor não conectar no Auto.';

  @override
  String get tunStackInfo =>
      'Como o tráfego vai do sistema para a VPN.\n\nSistema: o mais rápido, usa a pilha de rede do sistema.\ngVisor: pilha própria, compatível com a maioria dos apps.\nMista: TCP pelo sistema, UDP pelo gVisor.\n\nSe sites ou jogos falharem, experimente outra pilha.';

  @override
  String get protection => 'Proteção';

  @override
  String get killSwitchInfo =>
      'Se a VPN cair, o Sora bloqueia a internet para que nenhum tráfego saia fora do túnel. O acesso volta quando a VPN reconecta ou é desligada.';

  @override
  String get strictKillSwitchInfo =>
      'O bloqueio continua depois de sair do Sora e depois de reiniciar, até você desligá-lo aqui.';

  @override
  String get zapretWithVpnInfo =>
      'Sites que suas regras mandam por fora da VPN recebem o contorno de bloqueios do Zapret.';

  @override
  String get failoverInfo => 'Se um servidor parar de responder, o Sora troca sozinho para o próximo que funciona.';

  @override
  String get ipv6Info => 'Enviar IPv6 pela VPN. Desligue se o servidor não tiver IPv6 e os sites carregarem devagar.';

  @override
  String get fragmentInfo =>
      'Divide o início de uma conexão TLS em pedaços para que o filtro do provedor não veja o nome do site. Ajuda quando um servidor é bloqueado por SNI.';

  @override
  String get splitPosInfo =>
      'Onde cortar o primeiro pacote: um número de byte ou uma marca como midsld (meio do domínio). Separe vários valores com vírgulas.';

  @override
  String get disorderInfo =>
      'Envia as partes de um pacote em ordem inversa para confundir filtros que o remontam em sequência.';

  @override
  String get tlsRecordInfo =>
      'Divide o hello TLS em vários registros para que o nome do site nunca fique inteiro em um só.';

  @override
  String get hostCaseInfo =>
      'Muda maiúsculas e minúsculas do cabeçalho Host em pedidos HTTP (Host → hoSt) para que filtros antigos não os reconheçam.';

  @override
  String get probeMethodInfo =>
      'Pelo núcleo: atraso real até um site através do servidor, o mais preciso.\nSó conexão: apenas uma conexão TCP com o servidor, rápido mas não testa a VPN.\nHandshake TLS: TCP e TLS com o servidor.\nICMP: ping comum; alguns servidores não respondem.\nAuto: pelo núcleo e, quando não dá, uma conexão.';

  @override
  String get autoSelectInfo =>
      'Como «O mais rápido» escolhe o servidor: por ping, por velocidade medida ou pelos dois.';

  @override
  String get autoSwitchInfo => 'Se o servidor atual ficar visivelmente mais lento, o Sora troca para um mais rápido.';

  @override
  String get probeTls => 'Handshake TLS';

  @override
  String get probeIcmp => 'ICMP (ping)';
}
