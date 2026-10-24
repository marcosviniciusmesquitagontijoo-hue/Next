
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


const Color bg = Color(0xFF100D18);
const Color panel = Color(0xFF211A2C);
const Color accent = Color(0xFF9B5CFF);

void main() {
  runApp(const NextApp());
}

class NextApp extends StatelessWidget {
  const NextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

String normalizeServerUrl(String input) {
  var value = input.trim();
  if (value.isEmpty) {
    throw const FormatException('Informe a URL do servidor.');
  }
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'http://$value';
  }

  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException(
      'URL inválida. Informe, por exemplo, http://servidor:porta.',
    );
  }

  var path = uri.path;
  if (path.endsWith('/player_api.php')) {
    path = path.substring(0, path.length - '/player_api.php'.length);
  }
  path = path.replaceFirst(RegExp(r'/+$'), '');
  return uri.replace(path: path, query: null, fragment: null).toString()
      .replaceFirst(RegExp(r'/+$'), '');
}

class XtreamService {
  final String serverBase;
  final String username;
  final String password;

  XtreamService({
    required String serverUrl,
    required this.username,
    required this.password,
  }) : serverBase = normalizeServerUrl(serverUrl);

  Uri endpoint(String action, [Map<String, String> extra = const {}]) {
    return Uri.parse('$serverBase/player_api.php').replace(
      queryParameters: {
        'username': username,
        'password': password,
        if (action.isNotEmpty) 'action': action,
        ...extra,
      },
    );
  }

  Future<Map<String, dynamic>> login() async {
    final response = await http
        .get(endpoint(''))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'O servidor respondeu HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    final userInfo = decoded['user_info'];

    if (userInfo is Map) {
      final auth = userInfo['auth'];
      if (auth == 1 || auth == '1') {
        return decoded;
      }
    }

    throw Exception(
      'Usuário ou senha inválidos, ou conta sem autorização.',
    );
  }

  Future<List<dynamic>> list(String action) async {
    final response = await http
        .get(endpoint(action))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar o catálogo.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded;
    }

    return <dynamic>[];
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController server = TextEditingController();
  final TextEditingController user = TextEditingController();
  final TextEditingController pass = TextEditingController();

  bool busy = false;
  bool obscure = true;
  String? error;

  Future<void> submit() async {
    if (server.text.trim().isEmpty || user.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() {
        error = 'Informe URL do servidor, usuário e senha.';
      });
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final service = XtreamService(
        serverUrl: server.text,
        username: user.text.trim(),
        password: pass.text,
      );

      final account = await service.login();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            service: service,
            account: account,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          final message = e.toString().replaceFirst('Exception: ', '');
          error = message.contains('SocketException') ||
                  message.contains('Failed host lookup') ||
                  message.contains('SocketFailed')
              ? 'Não foi possível localizar o domínio do servidor (DNS). Confira a URL e tente outra conexão.'
              : message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    server.dispose();
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accent.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: accent,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Entre para continuar',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 34),
                  TextField(
                    controller: server,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link),
                      labelText: 'URL do servidor',
                      hintText: 'http://servidor:porta',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: user,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      labelText: 'Usuário',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pass,
                    obscureText: obscure,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(
                          obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: busy ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Informe a URL, o usuário e a senha fornecidos pelo serviço.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final XtreamService service;
  final Map<String, dynamic> account;

  const HomePage({
    super.key,
    required this.service,
    required this.account,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;

  final List<String> titles = const [
    'TV ao vivo',
    'Filmes',
    'Séries',
  ];

  final List<String> actions = const [
    'get_live_streams',
    'get_vod_streams',
    'get_series',
  ];

  late Future<List<dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = widget.service.list(actions[0]);
  }

  void change(int index) {
    setState(() {
      selected = index;
      items = widget.service.list(actions[index]);
    });
  }

  String get displayName {
    final info = widget.account['user_info'];

    if (info is Map) {
      return (info['username'] ?? 'Cliente').toString();
    }

    return 'Cliente';
  }

  Widget buildContentCard(Map item) {
    final title = (
      item['name'] ??
      item['title'] ??
      'Conteúdo'
    ).toString();

    final image = (
      item['stream_icon'] ??
      item['cover'] ??
      ''
    ).toString();

    final id = item['stream_id'] ?? item['series_id'];

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title — ID: ${id ?? 'não disponível'}',
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: image.startsWith('http')
                  ? Image.network(
                      image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.movie,
                            size: 48,
                            color: accent,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.movie,
                        size: 48,
                        color: accent,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEXT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => change(selected),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar catálogo',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF39215C),
                  panel,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $displayName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Escolha o que deseja assistir',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(
                titles.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(titles[index]),
                    selected: selected == index,
                    onSelected: (_) => change(index),
                    selectedColor: accent,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: items,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Não foi possível carregar o catálogo.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final list = snapshot.data ?? <dynamic>[];

                if (list.isEmpty) {
                  return const Center(
                    child: Text('Nenhum conteúdo disponível.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width >= 900
                        ? 5
                        : MediaQuery.sizeOf(context).width >= 600
                            ? 4
                            : 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final entry = list[index];

                    if (entry is Map) {
                      return buildContentCard(entry);
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: change,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv),
            label: 'TV',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            label: 'Filmes',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            label: 'Séries',
          ),
        ],
      ),
    );
  }
}
