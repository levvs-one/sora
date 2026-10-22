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
  String get programsEmpty => 'Nenhum aplicativo encontrado. Tente outro nome.';

  @override
  String get selectExe => 'Escolha um arquivo .exe';

  @override
  String get speedtest => 'Velocidade';

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
      'Os arquivos de atualização são conferidos com os checksums publicados com a versão.';

  @override
  String get updateManualSigWarning =>
      'Os arquivos abaixo correspondem aos checksums da versão. Execute o comando se você os baixou da versão oficial.';

  @override
  String get updateVersionRevoked => 'O desenvolvedor retirou esta versão. Aguarde uma versão corrigida.';

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
  String get updateRollbackError =>
      'Falha na reversão automática. Se a nova versão não funcionar, reinstale manualmente a versão anterior.';

  @override
  String get updateRollbackCacheError =>
      'Não foi possível preparar uma cópia de reversão verificada da versão atual, portanto a atualização não foi instalada.';

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
      'Escolha Automático se não tiver certeza de qual mecanismo seu servidor precisa. Sora verifica o perfil e as configurações antes de conectar. Um mecanismo não pode aumentar a largura de banda do seu plano: o desempenho depende do servidor, da rota, do protocolo e da rede.\n\n## Modos\n\n### Todo o tráfego (TUN)\n\nSora cria uma interface de rede virtual e roteia o tráfego de aplicativos por meio dela, incluindo TCP e UDP. Use este modo para Telegram, jogos e voz Discord. As regras podem enviar sites ou programas específicos diretamente ou bloqueá-los. O serviço de rede precisa de permissão e de um servidor que suporte o protocolo necessário.\n\n###Proxy System\n\nSora configura um proxy HTTP/SOCKS local. Aplicativos que respeitam as configurações de proxy do sistema o utilizam. Aplicativos com sua própria pilha de rede podem se conectar diretamente; As chamadas UDP e de voz geralmente precisam de TUN. Este modo é adequado para navegadores e aplicativos com suporte a proxy.\n\n### Nenhum servidor\n\nEm Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir e remodelar solicitações HTTP/TLS e ignorar algumas verificações de DPI. Seu IP permanece o mesmo e as conexões vão diretamente para o site. Os resultados dependem do seu provedor e do método de bloqueio.\n\nA integração atual usa tpws para HTTP e TLS sobre TCP. Ele não ignora o bloqueio de IP nem retransmite UDP e não pode garantir as conexões MTProto do Telegram. Use um servidor VPN com TUN para voz Discord, chamadas Telegram e esses tipos de restrições.\n\n## Motores\n\n### Automático\n\nSora seleciona um mecanismo instalado que suporta todo o plano de conexão: protocolos de servidor, transportes, grupos, fragmentação e modo. Uma escolha manual incompatível é rejeitada antes de interromper a conexão atual. Escolha Automático ou outro mecanismo e aplique as configurações novamente.\n\n### sing-box\n\nOs novos pacotes Sora incluem [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), um fork de [sing-box](https://github.com/SagerNet/sing-box), adicionando XHTTP e VLESS Encryption do lado do cliente. Sora reconhece a construção e seus recursos. Uma compilação upstream sem XHTTP não obtém esse recurso apenas pelo seu nome.\n\nOs protocolos suportados incluem VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard e os parâmetros AmneziaWG 1.x/2.x Sora pode importar. Perfis JSON Xray completos requerem Xray. Novos campos AWG 3.x ainda não podem ser importados. sing-box usa uma porta de controle local protegida por senha, que outros aplicativos no computador podem detectar.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) suporta fragmentação VLESS, REALITY, XHTTP, VLESS Encryption e TLS. Ele também executa perfis completos do provedor Xray, preservando seu roteamento e grupos. Esses perfis não podem ser convertidos automaticamente para outro mecanismo sem alterar seu comportamento.\n\nO Xray incluído removeu a configuração que desativa a verificação do certificado TLS (`allowInsecure`). Seleciona automaticamente sing-box ou mihomo para servidores comuns que exigem essa configuração. Selecionar Xray reporta manualmente a incompatibilidade antes de interromper a conexão atual. Perfis JSON completos mais antigos precisam de um perfil de provedor atualizado com um certificado verificável ou PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) oferece suporte a grupos de fallback e balanceamento de carga ordenados, XHTTP e AmneziaWG. Escolha-o quando o failover automático para um servidor de backup for importante. A configuração de fragmentação TLS do Sora não está disponível com este mecanismo.\n\n## Compatibilidade em Sora\n\n| Recurso | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN e TCP/UDP | Sim | Sim | Sim |\n| XHTTP | Sim | Sim | Sim |\n| VLESS Encryption | Sim | Sim | Sim |\n| Perfil Xray completo | Não | Sim | Não |\n| TUIC/AnyTLS | Ambos | Não | TUIC |\n| Fragmentação TLS | Sim | Sim | Não |\n| AmneziaWG 1.x/2.x | Sim¹ | Não | Sim |\n| Grupo substituto ordenado | Não | Não² | Sim |\n\n¹ Perfis com J1/J2/J3/Itime utilizam mihomo; esses campos nunca devem ser descartados silenciosamente. ² Para um grupo de perfis Xray completos, o aplicativo seleciona um perfil de backup. O suporte depende da versão instalada; verifique sua versão em Sobre.\n\n## Pilha TUN\n\nA pilha lida com TCP e UDP dentro da interface virtual. No painel de modos, Xray e mihomo oferecem gVisor, System, Mixed e MIPS. Cada mecanismo salva sua própria preferência. Os modos proxy System e sem servidor não usam essa preferência.\n\n- **Mixed**: TCP usa a pilha do sistema, enquanto gVisor lida com UDP. Este é o padrão do mihomo no Linux. No Windows, Xray e mihomo usam MIPS por padrão.\n- **System**: usa a pilha do sistema. Tente outra opção se os aplicativos de rede encontrarem problemas.\n- **gVisor**: lida com o tráfego no espaço do usuário.\n- **MIPS**: pilha IP própria do mihomo, disponível na versão 1.19.32 do pacote.\n\nNo Linux, o Xray usa seu gVisor integrado por padrão. System, Mixed e MIPS em Linux usam mihomo como mecanismo TUN, encaminhando TCP e UDP para Xray por meio de um link SOCKS local autenticado. Xray mantém o protocolo, perfil do provedor e roteamento. Essas três opções requerem um mihomo instalado. Em Windows, Xray usa mihomo 1.19.32 ou posterior para as quatro pilhas TUN. Os protocolos e o roteamento permanecem no Xray. As regras de aplicativos nessa combinação permitem apenas conexões diretas e bloqueio; no Linux, elas exigem o gVisor integrado do Xray.\n\nA ponte executa um segundo processo. Em três medições ociosas no Linux, ele usou cerca de 32–36 MiB a mais de memória física do que o Xray TUN nativo. Isso não mede a carga de download: os custos de CPU e memória dependem das conexões. sing-box não possui seletor de pilha. Nenhuma pilha garante melhor desempenho em todas as redes. Escolha uma pilha e selecione Aplicar e reconecte para experimentá-la em sua rede.\n\n## Aplicando configurações\n\nSelecionar um servidor reconecta automaticamente. As configurações de modo, mecanismo, DNS e regras são salvas imediatamente; durante uma conexão ativa, clique em Aplicar e reconecte para usá-los. Reiniciar um mecanismo pode interromper downloads e chamadas. Cliques repetidos não iniciam conexões paralelas; a desconexão encerra a transição e libera a conexão.\n\nA Internet somente por meio de VPN bloqueia o tráfego direto quando um túnel cai. Afeta toda a máquina. Uma desconexão explícita remove as regras do Sora. Se a limpeza não terminar, tente desconectar novamente e abra o log.\n\n## Documentação do projeto\n\n- [sing-box-lx: configuração e suporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentação sing-box](https://sing-box.sagernet.org/)\n- [Documentação Xray](https://xtls.github.io/)\n- [Documentação mihomo](https://wiki.metacubex.one/)\n- [zapret: funcionamento e limitações](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Verifique servidores';

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
  String get extBadgeVerified => 'Verificado';

  @override
  String get extBadgeTop => 'Mais popular esta semana';

  @override
  String get extBadgeNew => 'Novo';

  @override
  String get extBadgeStaff => 'A equipe Sora';

  @override
  String get extSideloadShort => 'Não é do catálogo';

  @override
  String get extSideloadWarning =>
      'Esta extensão não faz parte do catálogo da equipe. Somente o autor garantiu sua chave: instale-a somente se você confiar no autor.';

  @override
  String extInstallTitle(String name) {
    return 'Instalar «$name»';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Atualizar «$name»';
  }

  @override
  String get extPermissionsIntro => 'Esta extensão será capaz de:';

  @override
  String get extPermissionsWidened => 'A atualização pede novas permissões:';

  @override
  String get extDangerousAck => 'Entendo que essas permissões são sérias';

  @override
  String get extInstall => 'Instalar';

  @override
  String get extUpdate => 'Atualizar';

  @override
  String get extCancel => 'Cancelar';

  @override
  String get extConfirm => 'Confirmar';

  @override
  String get extOk => 'OK';

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
  String get extEmptyInstalled =>
      'Nenhuma extensão instalada ainda.\nEncontre um no catálogo ou instale a partir de um arquivo.';

  @override
  String get extInstallFromFile => 'Instalar a partir do arquivo';

  @override
  String get extInstallFromUrl => 'Instalar a partir de URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Baixar';

  @override
  String get extDownloading => 'Baixando…';

  @override
  String get extVerifying => 'Verificando…';

  @override
  String get extInstalling => 'Instalando…';

  @override
  String get extInstallFailed => 'Falha na instalação';

  @override
  String get extErrSignature => 'A verificação de assinatura falhou. O arquivo pode estar danificado ou adulterado.';

  @override
  String get extErrManifest => 'O manifesto da extensão é inválido.';

  @override
  String get extErrNetwork => 'Erro de rede. Verifique sua conexão e tente novamente.';

  @override
  String get extErrHash => 'O download não corresponde ao catálogo. Pode ter sido adulterado.';

  @override
  String extErrMinApp(String version) {
    return 'Esta extensão precisa da versão do aplicativo $version ou mais recente.';
  }

  @override
  String get extErrHttpsOnly => 'Apenas links https:// são permitidos';

  @override
  String get extErrGeneric => 'Algo deu errado. Por favor, tente novamente.';

  @override
  String get extErrAuthorKeyChanged =>
      'Esta atualização está assinada com uma chave de autor diferente da versão instalada, por isso foi bloqueada. Se você confia na nova chave, desinstale a extensão e instale-a novamente explicitamente.';

  @override
  String get extUpdateAvailable => 'Atualização disponível';

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
  String get extConflictsIntro =>
      'Estas extensões querem a mesma coisa. Escolha qual funciona; a outra continua instalada.';

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
    return '$count precisam de sua decisão';
  }

  @override
  String get extConflictsResolve => 'Resolver conflitos';

  @override
  String get extConflictNote =>
      'Sua escolha fica salva neste dispositivo. O tema muda na hora; os hooks de rede não são executados nesta versão.';

  @override
  String extVersionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get extAuthor => 'Autor';

  @override
  String get extRating => 'Avaliação';

  @override
  String get extInstalls => 'Instalações';

  @override
  String get extVersion => 'Versão';

  @override
  String get extAbout => 'Sobre esta extensão';

  @override
  String get extPermissionsTitle => 'Permissões';

  @override
  String get extNoPermissions => 'Sem permissões especiais.';

  @override
  String get extSettings => 'Configurações';

  @override
  String get extSaveSettings => 'Salvar configurações';

  @override
  String get extSaving => 'Salvando…';

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
  String get extPanelUnavailable => 'O painel não está disponível. A extensão pode ter sido desativada ou removida.';

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
  String get extPermRoutingRules => 'Adicionar regras de roteamento (afeta para onde vai o tráfego de rede)';

  @override
  String get extPermNetHooks => 'Integrar ao caminho da rede (módulos de bypass DPI)';

  @override
  String get extPermNetFetch => 'Solicitação URL da lista permitida';

  @override
  String get extPermBackground => 'Executar tarefas em segundo plano';

  @override
  String get extPermBackgroundDetail =>
      'Executa tarefas agendadas mesmo quando o painel está fechado. Você pode pausá-lo ou alterar a frequência de execução nas configurações da extensão.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

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
  String get extRatingHow => 'Como funcionam as classificações';

  @override
  String get extRatingHowBody =>
      'As classificações usam uma média bayesiana: uma extensão com poucas avaliações permanece próxima do meio até que mais pessoas votem, portanto, uma única avaliação de 5 estrelas não pode levar uma nova extensão ao topo. As classificações recentes pesam mais do que as antigas e apenas uma classificação por conta conta.';

  @override
  String get extScreenshots => 'Capturas de tela';

  @override
  String get extSortRelevance => 'Relevância';

  @override
  String get extPermNetworkDetail =>
      'Busca dados da internet pela VPN. Só os hosts abaixo são permitidos; todo o resto é bloqueado.';

  @override
  String get extBgTitle => 'Tarefa em segundo plano';

  @override
  String get extBgEnabled => 'Executar em segundo plano';

  @override
  String get extBgInterval => 'Executar a cada';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minutos', one: '# minuto');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# horas', one: '# hora');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'A tarefa roda conforme o agendamento enquanto o Sora está aberto, inclusive na bandeja. O intervalo mínimo é de 15 minutos.';

  @override
  String get extBgDisabledNote => 'Habilite a extensão para gerenciar sua tarefa em segundo plano.';

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
  String get diagnosticNoData => 'Nenhuma solicitação registrada ainda. Abra primeiro um site de teste de velocidade.';

  @override
  String get qrShareTitle => 'Compartilhe o código QR';

  @override
  String get qrScanTitle => 'Digitalize o código QR';

  @override
  String get qrCopyLink => 'Copiar link';

  @override
  String get qrWarning => 'Compartilhe o código apenas com pessoas de confiança.';

  @override
  String get qrScanHint => 'Escolha uma captura ou foto com um código QR, ou cole um link';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# conexões', one: '# conexão');
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
  String get sortBy => 'Classificar por';

  @override
  String get sortSubscription => 'Na ordem da assinatura';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Velocidade';

  @override
  String get sortName => 'Nome';

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
  String get coreWatchUnstable => 'A conexão com o núcleo Sora está instável';

  @override
  String get watchReconnect => 'Reconectar';

  @override
  String get coreRestoringLink => 'Restaurando a conexão com o núcleo Sora…';

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
  String get errBenchmarkUnsupported => 'A medição de velocidade precisa de um núcleo mais novo';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Medição de $done de $total…';
  }

  @override
  String get profiles => 'Perfis de rede';

  @override
  String get profilesEmpty =>
      'Nenhum perfil ainda. Crie um para aplicar configurações automaticamente em redes conhecidas.';

  @override
  String get profileAdd => 'Adicionar perfil';

  @override
  String get profileName => 'Nome do perfil';

  @override
  String get profileSsids => 'Wi-Fi (SSID)';

  @override
  String get profileSsidsHint => 'Casa, Escritório separados por vírgulas';

  @override
  String get profileGateways => 'Gateways de rede';

  @override
  String get profileAsns => 'AS números';

  @override
  String get profileAutoApply => 'Aplicar automaticamente';

  @override
  String get profileAutoApplyHint => 'Se desativado, pedir confirmação antes de aplicar o perfil.';

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
  String get profileNoTriggers => 'Adicione pelo menos um gatilho: SSID, gateway ou ASN';

  @override
  String get chains => 'Cadeias de proxy';

  @override
  String get chainsEmpty =>
      'Ainda não há correntes. Vincule 2 a 3 servidores para que o tráfego passe por cada um deles.';

  @override
  String get chainAdd => 'Nova cadeia';

  @override
  String get chainName => 'Nome da cadeia';

  @override
  String get chainPickServers => 'Escolha 2–3 servidores';

  @override
  String get chainOrderHint => 'Arraste para reordenar: o tráfego entra na parte superior e sai na parte inferior.';

  @override
  String get chainTooFew => 'Escolha pelo menos 2 servidores';

  @override
  String get chainTooMany => 'Uma cadeia contém no máximo 3 servidores';

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
  String get chainUnsupported => 'O motor atual não permite criar cadeias';

  @override
  String get chainHopMissing => 'Um dos servidores da cadeia não está mais disponível';

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
  String get syncEmpty => 'Nenhum dispositivo emparelhado. Emparelhe outro dispositivo pela rede local.';

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
  String get syncNoLan => 'Os dispositivos devem estar na mesma rede local';

  @override
  String get syncPaired => 'Dispositivo emparelhado';

  @override
  String get syncPairingTitle => 'Parear com este dispositivo';

  @override
  String get syncWaiting => 'Aguardando o outro dispositivo…';

  @override
  String get syncSecureNote => 'Canal criptografado de ponta a ponta. Sem contas, sem servidores em nuvem.';

  @override
  String get zapretWithVpn => 'Ignorar filtragem DPI para tráfego direto de rede';

  @override
  String get zapretWithVpnHint =>
      'Executa zapret em paralelo com o túnel VPN: o tráfego do túnel usa a VPN e o tráfego direto passa pelo mecanismo de contorno.';

  @override
  String get chainDuplicate => 'Cada servidor pode aparecer apenas uma vez';

  @override
  String get edit => 'Editar';

  @override
  String get remove => 'Remover';

  @override
  String get autoSwitchOnDegrade => 'Ativação automática na degradação';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Se o servidor selecionado ficar muito lento ou deixar de responder, o Sora muda para o melhor segundo as medições, no máximo uma vez a cada 10 minutos.';

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
  String get customServerNameHint => 'Por exemplo: meu VPS';

  @override
  String get customServerNameRequired => 'Insira o nome';

  @override
  String get customServerAddress => 'Endereço';

  @override
  String get customServerAddressHint => 'example.com ou 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Digite o endereço do servidor';

  @override
  String get customServerAddressInvalid => 'Endereço inválido';

  @override
  String get customServerPort => 'Porta';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'A porta deve ser um número entre 1 e 65535';

  @override
  String get customServerProtocol => 'Protocolo';

  @override
  String get customServerCredentials => 'Informações de login';

  @override
  String get customServerOptional => 'Opcional';

  @override
  String get customServerShowSecret => 'Mostrar segredo';

  @override
  String get customServerHideSecret => 'Ocultar segredo';

  @override
  String get customServerBadge => 'personalizado';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Excluir servidor “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Adicione um servidor manualmente: endereço, porta e protocolo';

  @override
  String get customServerTest => 'Testar';

  @override
  String get leakTestTitle => 'Teste para vazamento de dados';

  @override
  String get leakTestIntro =>
      'Verifica se o tráfego pode sair do dispositivo fora do túnel: pedidos diretos de DNS e ICMP, saída IPv6 e resolvedores do sistema. Execute o teste com a ligação ativa.';

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
      other: '# fugas encontradas',
      one: '# fuga encontrada',
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
  String get syncDaemonMissing =>
      'O componente sora-sync não foi encontrado. Reinstale o aplicativo para ativar a sincronização do dispositivo.';

  @override
  String get syncDaemonStarting => 'Iniciando o serviço de sincronização…';

  @override
  String get syncErrAuth =>
      'O serviço de sincronização rejeitou o token de acesso. Reinicie o aplicativo e tente novamente.';

  @override
  String get syncErrNotFound => 'O dispositivo não está mais emparelhado';

  @override
  String get syncErrPairingActive => 'Uma sessão de emparelhamento já está aberta';

  @override
  String get syncErrUnreachable =>
      'O outro dispositivo não respondeu. Certifique-se de que esteja na mesma rede e mostrando seu código.';

  @override
  String get syncError => 'Erro de sincronização';

  @override
  String syncExpiresIn(String duration) {
    return 'O código expira em $duration';
  }

  @override
  String get syncJoining => 'Emparelhando com o dispositivo…';

  @override
  String get syncLegacyCleared =>
      'A lista de dispositivos antiga nunca foi realmente emparelhada, por isso foi limpa. Emparelhe seus dispositivos novamente, desta vez de verdade.';

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
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

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

  @override
  String get strictKillSwitch => 'Bloqueio de rede estrito';

  @override
  String get strictKillSwitchWarning =>
      'Após a conexão, bloqueia o tráfego fora da VPN mesmo após uma falha, reinício ou saída do aplicativo. Apenas desconectar ou desativar esta opção restaura o acesso. Após reiniciar o sistema, o bloqueio só retorna se a conexão ao iniciar estiver ativada.';

  @override
  String get extWorkerFailed => 'A tarefa em segundo plano da extensão falhou. Verifique o registo da extensão.';

  @override
  String get extAssetRejected => 'Ficheiro da extensão rejeitado: cores ilegíveis ou regras inválidas.';
}
