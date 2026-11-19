# Auditoria inicial FluxNet — 19/11/2026

## Alterações aplicadas
- Restaurado o caminho de saída Gradle esperado pelo Flutter (`build/app/outputs/flutter-apk`).
- Diagnóstico adicional de artefatos no Codemagic.
- Evitada autorização VPN automática na abertura da tela inicial.
- Impedido avanço visual da fila sem autorização VPN.
- Removida seleção aleatória e limite arbitrário de dez aplicativos.
- Tratado retorno nulo/exceção de `VpnService.Builder.establish()` para encerrar o serviço.
- Removida permissão `BIND_VPN_SERVICE` de nível de aplicativo (permanece corretamente no serviço).
- Evitada tentativa repetida de abrir uma Activity automaticamente a partir do serviço de fundo.
- Limpeza de registro offline quando a conexão retorna antes do limite.

## Limitações importantes / próximos testes
1. **Compilação não executada aqui**: Flutter e Dart SDK não estão instalados neste ambiente. Rodar Codemagic e conferir o novo log.
2. O VPN implementado é um *túnel sumidouro*: apps não liberados ficam sem rede; não há encaminhamento de pacotes nem proxy. Requer testes reais de conectividade e política Android.
3. A fila ainda é baseada em tempo, não em consumo real de rede; não se deve afirmar que o percentual representa conclusão do tráfego.
4. A interface `ControlOverlay` é uma Activity Flutter em tela cheia, não uma janela sobreposta a outros apps.
5. Monitoramento de rede com `connectivity_plus` indica tipo de rede, não acesso efetivo à internet.
6. `flutter_foreground_task` e `flutter_vpn_service` ainda usam KGP; futuras versões Flutter podem exigir migração dos plugins.
