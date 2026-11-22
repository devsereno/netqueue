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
7. Android 14+ exige validação das permissões e tipos de foreground service. O serviço `dataSync` possui restrições de duração em versões recentes.
8. `QUERY_ALL_PACKAGES` pode exigir justificativa para publicação na Play Store.
9. Release continua assinada com chave debug: adequado apenas para teste, não distribuição oficial.
10. Ainda falta implementar fila por prioridade, limite configurável de concorrência, tempo máximo, recuperação após morte do processo e testes automatizados.
11. O repositório não inclui `gradlew` nem `gradle-wrapper.jar`; o Flutter/Codemagic pode precisar regenerá-los.
12. As versões AGP 9.1.1, Kotlin 2.4.10 e Gradle 9.5.0 foram mantidas para evitar uma migração sem teste de compatibilidade.

**Status:** correções estáticas aplicadas; build e funcionamento Android não validados. Não é versão certificada para produção.
