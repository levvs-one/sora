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
      'Escolha Automático se não tiver certeza de qual mecanismo seu servidor precisa. Sora verifica o perfil e as configurações antes de conectar. Um mecanismo não pode aumentar a largura de banda do seu plano: o desempenho depende do servidor, da rota, do protocolo e da rede.\n\n## Modos\n\n### Todo o tráfego (TUN)\n\nSora cria uma interface de rede virtual e roteia o tráfego de aplicativos por meio dela, incluindo TCP e UDP. Use este modo para Telegram, jogos e voz Discord. As regras podem enviar sites ou programas específicos diretamente ou bloqueá-los. O serviço de rede precisa de permissão e de um servidor que suporte o protocolo necessário.\n\n###Proxy System\n\nSora configura um proxy HTTP/SOCKS local. Aplicativos que respeitam as configurações de proxy do sistema o utilizam. Aplicativos com sua própria pilha de rede podem se conectar diretamente; As chamadas UDP e de voz geralmente precisam de TUN. Este modo é adequado para navegadores e aplicativos com suporte a proxy.\n\n### Nenhum servidor\n\nEm Linux, Sora usa [zapret](https://github.com/bol-van/zapret) para dividir e remodelar solicitações HTTP/TLS e ignorar algumas verificações de DPI. Seu IP permanece o mesmo e as conexões vão diretamente para o site. Os resultados dependem do seu provedor e do método de bloqueio.\n\nA integração atual usa tpws para HTTP e TLS sobre TCP. Ele não ignora o bloqueio de IP nem retransmite UDP e não pode garantir as conexões MTProto do Telegram. Use um servidor VPN com TUN para voz Discord, chamadas Telegram e esses tipos de restrições.\n\n## Motores\n\n### Automático\n\nSora seleciona um mecanismo instalado que suporta todo o plano de conexão: protocolos de servidor, transportes, grupos, fragmentação e modo. Uma escolha manual incompatível é rejeitada antes de interromper a conexão atual. Escolha Automático ou outro mecanismo e aplique as configurações novamente.\n\n### sing-box\n\nOs novos pacotes Sora incluem [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), um fork de [sing-box](https://github.com/SagerNet/sing-box), adicionando XHTTP e VLESS Encryption do lado do cliente. Sora reconhece a construção e seus recursos. Uma compilação upstream sem XHTTP não obtém esse recurso apenas pelo seu nome.\n\nOs protocolos suportados incluem VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard e os parâmetros AmneziaWG 1.x/2.x Sora pode importar. Perfis JSON Xray completos requerem Xray. Novos campos AWG 3.x ainda não podem ser importados. sing-box usa uma porta de controle local protegida por senha, que outros aplicativos no computador podem detectar.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) suporta fragmentação VLESS, REALITY, XHTTP, VLESS Encryption e TLS. Ele também executa perfis completos do provedor Xray, preservando seu roteamento e grupos. Esses perfis não podem ser convertidos automaticamente para outro mecanismo sem alterar seu comportamento.\n\nO Xray incluído removeu a configuração que desativa a verificação do certificado TLS (`allowInsecure`). Seleciona automaticamente sing-box ou mihomo para servidores comuns que exigem essa configuração. Selecionar Xray reporta manualmente a incompatibilidade antes de interromper a conexão atual. Perfis JSON completos mais antigos precisam de um perfil de provedor atualizado com um certificado verificável ou PIN de certificado.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) oferece suporte a grupos de fallback e balanceamento de carga ordenados, XHTTP e AmneziaWG. Escolha-o quando o failover automático para um servidor de backup for importante. A configuração de fragmentação TLS do Sora não está disponível com este mecanismo.\n\n## Compatibilidade em Sora\n\n| Recurso | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux TUN e TCP/UDP | Sim | Sim | Sim |\n| XHTTP | Sim | Sim | Sim |\n| VLESS Encryption | Sim | Sim | Sim |\n| Perfil Xray completo | Não | Sim | Não |\n| TUIC/AnyTLS | Ambos | Não | TUIC |\n| Fragmentação TLS | Sim | Sim | Não |\n| AmneziaWG 1.x/2.x | Sim¹ | Não | Sim |\n| Grupo substituto ordenado | Não | Não² | Sim |\n\n¹ Perfis com J1/J2/J3/Itime utilizam mihomo; esses campos nunca devem ser descartados silenciosamente. ² Para um grupo de perfis Xray completos, o aplicativo seleciona um perfil de backup. O suporte depende da versão instalada; verifique sua versão em Sobre.\n\n## Pilha TUN\n\nA pilha lida com TCP e UDP dentro da interface virtual. No painel de modos, Xray e mihomo oferecem gVisor, System, Mixed e MIPS. Cada mecanismo salva sua própria preferência. Os modos proxy System e sem servidor não usam essa preferência.\n\n- **Mixed** — TCP usa a pilha do sistema, enquanto gVisor lida com UDP. Este é o padrão para mihomo.\n- **System** — usa a pilha do sistema. Tente outra opção se os aplicativos de rede encontrarem problemas.\n- **gVisor** — lida com o tráfego no espaço do usuário.\n- **MIPS** — pilha IP própria do mihomo, disponível na versão 1.19.32 do pacote.\n\nNo Linux, o Xray usa seu gVisor integrado por padrão. System, Mixed e MIPS em Linux usam mihomo como mecanismo TUN, encaminhando TCP e UDP para Xray por meio de um link SOCKS local autenticado. Xray mantém o protocolo, perfil do provedor e roteamento. Essas três opções requerem um mihomo instalado. Em Windows, TUN usa atualmente sing-box ou mihomo; Xray é executado no modo proxy do sistema.\n\nA ponte executa um segundo processo. Em três medições ociosas no Linux, ele usou cerca de 32–36 MiB a mais de memória física do que o Xray TUN nativo. Isso não mede a carga de download: os custos de CPU e memória dependem das conexões. Mantenha gVisor, a menos que precise de outra pilha. sing-box não possui seletor de pilha. Nenhuma pilha garante melhor desempenho em todas as redes. Escolha uma pilha e selecione Aplicar e reconecte para experimentá-la em sua rede.\n\n## Aplicando configurações\n\nSelecionar um servidor reconecta automaticamente. As configurações de modo, mecanismo, DNS e regras são salvas imediatamente; durante uma conexão ativa, clique em Aplicar e reconecte para usá-los. Reiniciar um mecanismo pode interromper downloads e chamadas. Cliques repetidos não iniciam conexões paralelas; a desconexão encerra a transição e libera a conexão.\n\nA Internet somente por meio de VPN bloqueia o tráfego direto quando um túnel cai. Afeta toda a máquina. Uma desconexão explícita remove as regras do Sora. Se a limpeza não terminar, tente desconectar novamente e abra o log.\n\n## Documentação do projeto\n\n- [sing-box-lx: configuração e suporte](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Documentação sing-box](https://sing-box.sagernet.org/)\n- [Documentação Xray](https://xtls.github.io/)\n- [Documentação mihomo](https://wiki.metacubex.one/)\n- [zapret: funcionamento e limitações](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Verifique servidores';

  @override
  String get extensions => 'Extensões';

  @override
  String get extensionsSoon => 'Em breve';

  @override
  String exportLogFile(String name) {
    return 'Em $name';
  }

  @override
  String get diagnosticHttp => 'Diagnóstico HTTP';

  @override
  String get diagnosticPackets => 'Captura de pacotes';

  @override
  String get diagnosticEvents => 'Eventos do Windows';

  @override
  String get diagnosticCapture => 'Capture por 10 segundos';

  @override
  String get diagnosticNoData => 'Nenhuma solicitação registrada ainda. Abra primeiro um site de teste de velocidade.';

  @override
  String get diagnosticRequiresTun => 'A captura de pacotes precisa de uma conexão Sora TUN ativa.';

  @override
  String get diagnosticUnavailable => 'Este diagnóstico não está disponível nesta plataforma.';
}
