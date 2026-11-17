# NetQueue - Versão Teste Funcional (Flutter)

App que monitora o tempo offline e, quando a internet volta depois de um período longo, mostra um overlay real com fila de apps e barra de progresso animada.

## O que está funcional agora

- Monitoramento real de conectividade (`connectivity_plus`)
- Contagem de tempo offline salva em `SharedPreferences`
- Tela de configurações com valores padrão editáveis e persistidos
- Overlay de controle em tela cheia (não é mock)
- Lista real de apps instalados no aparelho (`device_apps`)
- Barra de progresso animada de verdade (Timer)
- Espaço reservado para anúncio
- Botão para forçar o controle (útil para teste)

## Como rodar

```bash
flutter pub get
flutter run
```

### Permissões necessárias (Android)

No `android/app/src/main/AndroidManifest.xml` adicione:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
```

## Próximos passos para ficar mais completo

- Integrar VpnService real para bloquear/liberar tráfego de verdade
- Detectar app em primeiro plano e priorizar automaticamente
- AdMob real no espaço de anúncio
- Foreground service para monitoramento em background

## Valores padrão

- Tempo offline: 2 horas
- Apps simultâneos: 1
- Tempo máximo de controle: 3 minutos
- Priorizar primeiro plano: ligado

Essa é uma versão teste **funcional** (não usa telas falsas). O overlay, a fila e a barra de progresso são reais.
