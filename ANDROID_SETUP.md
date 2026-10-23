# Configuração Android necessária

No projeto Flutter criado por `flutter create`, edite `android/app/src/main/AndroidManifest.xml`:

- Adicione `<uses-permission android:name="android.permission.INTERNET" />` antes de `<application>`.
- Dentro de `<application>`, defina `android:label="Next"` e `android:usesCleartextTraffic="true"` (necessário porque o servidor fornecido usa HTTP).

O `usesCleartextTraffic=true` reduz a segurança da conexão. O ideal é usar HTTPS.

O projeto de referência foi compilado em Flutter, mas o APK original não inclui o código Dart fonte. Este projeto é uma nova implementação inicial e não preserva automaticamente todos os recursos internos do Lotus.
