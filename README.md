# Next — projeto Flutter inicial

Este projeto é uma nova implementação inspirada no fluxo geral de um app de streaming, não uma cópia binária do Lotus. Inclui marca Next, servidor Xtream Codes fixo e tela de login somente com usuário e senha, além de navegação inicial por TV ao vivo, filmes e séries.

## Servidor configurado
`http://agenciacinepoa.top`

## Compilar
1. Instale Flutter SDK e Android Studio/Android SDK.
2. Na pasta do projeto execute `flutter pub get`.
3. Execute `flutter run` para testar.
4. Para gerar APK: `flutter build apk --release`.

## Observações
- O endereço é HTTP sem TLS. Credenciais e tráfego podem ser interceptados na rede; idealmente o servidor deve oferecer HTTPS.
- Este projeto não inclui credenciais, lista de canais nem conteúdo. O usuário precisa de uma conta válida autorizada no servidor.
- Para instalar em Android, a compilação e assinatura devem ser feitas com Flutter/Android SDK. O ambiente em que este arquivo foi criado não possui essas ferramentas, portanto não foi gerado um APK instalável aqui.
