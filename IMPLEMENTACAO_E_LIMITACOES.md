# FluxNet — implementação e limitações

Base: FluxNet_auditoria_corrigida.zip. Não foi executado Flutter/Android build neste ambiente (SDK ausente).

## Implementado neste pacote
- Planejador de lotes (2–20 apps) com no máximo um app classificado como pesado por lote e listas de exclusão/prioridade via SharedPreferences.
- Overlay passa a mostrar lotes; histórico local de conclusão de filas; encerramento libera VPN.
- Política persistente de parada geral manual, nível de bateria 5%, retorno elegível a partir de 15%, avaliação também quando estiver em 30% ou mais.
- WorkManager periódico de 30 min e receiver de boot para reagendar; verificações nativas de segurança antes de iniciar VPN.
- Preflight de CI e extração de erros do build para diagnóstico.

## Limitações / itens ainda não completos
- WorkManager não consegue garantir reiniciar serviço em primeiro plano em segundo plano, nem recuperar force-stop; worker atual é verificador seguro, NÃO reinicia o serviço Flutter.
- A parada em 5% é verificada enquanto o serviço está ativo e no worker; não é um alarme exato com todos os serviços desligados.
- Ativação preditiva da VPN por desbloqueio, tela e horário ainda não está implementada.
- Lotes usam heurística de tipo de conexão e carregador, não throughput/latência real; detecção de app em primeiro plano e medição real de economia de bateria ainda não implementados.
- As categorias pesadas são heurísticas por package name; não medem tráfego. O filtro é configurável por lista de IDs, ainda sem editor gráfico.
- A VPN atual usa TUN que descarta pacotes dos apps não liberados; não é uma VPN de encaminhamento de tráfego. A troca de TUN pode interromper conexões. Testar em Android real.
- A tela chamada overlay é uma rota Flutter; não é uma janela SYSTEM_ALERT_WINDOW sobre outros apps.
- A recuperação do serviço após boot depende do plugin foreground_task e de restrições Android.
- A detecção de conectividade por connectivity_plus não comprova acesso real à internet.
- Não há telemetria remota nem dados enviados a servidor.
- Otimização básica durante carregamento, lista gráfica de apps e registro local de erros Flutter estão presentes; deduplicação avançada de erros e classificação real de tráfego permanecem pendentes.

## Política de falhas Codemagic
1. Preflight: arquivos Gradle duplicados, versões, dependências, análise Dart.
2. Build: guardar log integral, destacar classe e linha do erro (não corrigir somente avisos).
3. Classificação: resolução de dependências, plugin/AGP/Kotlin, Manifest, código Kotlin, código Dart, assinatura.
4. Nunca fazer atualização simultânea cega de Flutter, AGP, Gradle, Kotlin e plugins.
5. Repetir build após cada correção e validar em aparelho real antes de chamar release estável.
