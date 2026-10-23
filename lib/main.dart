import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

const String serverBase = 'http://agenciacinepoa.top';
const Color bg = Color(0xFF100D18);
const Color panel = Color(0xFF211A2C);
const Color accent = Color(0xFF9B5CFF);

void main() => runApp(const NextApp());

class NextApp extends StatelessWidget {
  const NextApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Next', debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: accent))),
    ), home: const LoginPage());
}

class XtreamService {
  final String username, password;
  const XtreamService(this.username, this.password);
  Uri endpoint(String action, [Map<String, String> extra = const {}]) => Uri.parse('$serverBase/player_api.php').replace(queryParameters: {
    'username': username, 'password': password, if (action.isNotEmpty) 'action': action, ...extra,
  });
  Future<Map<String, dynamic>> login() async {
    final r = await http.get(endpoint('')).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('Servidor respondeu HTTP ${r.statusCode}.');
    final data = jsonDecode(r.body);
    if (data is! Map<String, dynamic>) throw Exception('Resposta inválida do servidor.');
    final info = data['user_info'];
    if (info is Map && (info['auth'] == 1 || info['auth'] == '1')) return data;
    throw Exception('Usuário ou senha inválidos, ou conta sem autorização.');
  }
  Future<List<dynamic>> list(String action) async {
    final r = await http.get(endpoint(action)).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Falha ao carregar catálogo.');
    final d = jsonDecode(r.body);
    return d is List ? d : <dynamic>[];
  }
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController(), pass = TextEditingController(); bool busy = false, obscure = true; String? error;
  Future<void> submit() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) { setState(() => error = 'Informe usuário e senha.'); return; }
    setState(() { busy = true; error = null; });
    try { final svc = XtreamService(user.text.trim(), pass.text); final info = await svc.login(); if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(service: svc, account: info)));
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override void dispose() { user.dispose(); pass.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(26), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 100, height: 100, decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(28), border: Border.all(color: accent.withOpacity(.4))), child: const Icon(Icons.play_arrow_rounded, color: accent, size: 72)),
    const SizedBox(height: 18), const Text('NEXT', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 5)), const SizedBox(height: 6), const Text('Entre para continuar', style: TextStyle(color: Colors.white60)), const SizedBox(height: 34),
    TextField(controller: user, textInputAction: TextInputAction.next, autocorrect: false, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Usuário')),
    const SizedBox(height: 14), TextField(controller: pass, obscureText: obscure, onSubmitted: (_) => submit(), decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), labelText: 'Senha', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: const TextStyle(color: Colors.redAccent))), const SizedBox(height: 22),
    SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)))),
    const SizedBox(height: 20), const Text('Servidor configurado automaticamente', style: TextStyle(fontSize: 12, color: Colors.white38)),
  ]))))));
}

class HomePage extends StatefulWidget { final XtreamService service; final Map<String,dynamic> account; const HomePage({super.key, required this.service, required this.account}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  int selected = 0; final titles = const ['TV ao vivo', 'Filmes', 'Séries']; final actions = const ['get_live_streams', 'get_vod_streams', 'get_series'];
  late Future<List<dynamic>> items = widget.service.list(actions[0]);
  void change(int i) => setState(() { selected = i; items = widget.service.list(actions[i]); });
  @override Widget build(BuildContext context) { final name = (widget.account['user_info'] is Map ? widget.account['user_info']['username'] : null) ?? 'Cliente';
    return Scaffold(appBar: AppBar(title: const Text('NEXT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)), actions: [IconButton(onPressed: () => change(selected), icon: const Icon(Icons.refresh))]),
      body: Column(children: [Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 8, 16, 14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF39215C), panel]), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Olá, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5), const Text('Escolha o que deseja assistir', style: TextStyle(color: Colors.white70))])),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: List.generate(3, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(titles[i]), selected: selected == i, onSelected: (_) => change(i), selectedColor: accent)))),
      Expanded(child: FutureBuilder<List<dynamic>>(future: items, builder: (context, snap) { if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snap.hasError) return Center(child: Text('Não foi possível carregar.\n${snap.error}', textAlign: TextAlign.center)); final list = snap.data ?? []; if (list.isEmpty) return const Center(child: Text('Nenhum conteúdo disponível.')); return GridView.builder(padding: const EdgeInsets.all(14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .72, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: list.length, itemBuilder: (context, i) { final item = list[i] as Map; final title = (item['name'] ?? item['title'] ?? 'Conteúdo').toString(); final image = (item['stream_icon'] ?? item['cover'] ?? '').toString(); return InkWell(onTap: () { final id = item['stream_id'] ?? item['series_id']; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title — ID: ${id ?? 'não disponível'}'))); }, child: Container(decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: image.startsWith('http') ? Image.network(image, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.movie, size: 48, color: accent))) : const Center(child: Icon(Icons.movie, size: 48, color: accent))), Padding(padding: const EdgeInsets.all(10), child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))]))); }); }))]),
      bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: change, destinations: const [NavigationDestination(icon: Icon(Icons.live_tv), label: 'TV'), NavigationDestination(icon: Icon(Icons.movie_outlined), label: 'Filmes'), NavigationDestination(icon: Icon(Icons.video_library_outlined), label: 'Séries')]),
    );
  }
}
