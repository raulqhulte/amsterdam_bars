import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'db/bars_dao.dart';
import 'db/reviews_dao.dart';
import 'db/visits_dao.dart';
import 'firebase_options.dart';
import 'models/bar.dart';
import 'pages/add_bar_page.dart';
import 'pages/bar_details_page.dart';
import 'pages/enter_name_page.dart';
import 'pages/map_page.dart';
import 'pages/select_list_page.dart';
import 'services/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AmsterdamBarsApp());
}

class AmsterdamBarsApp extends StatelessWidget {
  const AmsterdamBarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amsterdam Bars',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AppStartupGate(),
    );
  }
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  final _session = UserSession();

  bool _loading = true;
  bool _hasList = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final name = await _session.getUserName();
    final listId = await _session.getCurrentListId();

    if (!mounted) return;

    setState(() {
      _userName = name;
      _hasList = listId != null;
      _loading = false;
    });
  }

  Future<void> _goToEnterName() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EnterNamePage()),
    );
    if (!mounted) return;
    await _checkUser();
  }

  Future<void> _goToSelectList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectListPage()),
    );
    if (!mounted) return;
    await _checkUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userName == null || _userName!.trim().isEmpty) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _goToEnterName,
            child: const Text('Set your name'),
          ),
        ),
      );
    }

    if (!_hasList) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _goToSelectList,
            child: const Text('Create or join a shared list'),
          ),
        ),
      );
    }

    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    MapPage(),
    BarsListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class BarsListPage extends StatefulWidget {
  const BarsListPage({super.key});

  @override
  State<BarsListPage> createState() => _BarsListPageState();
}

class _BarsListPageState extends State<BarsListPage> {
  final _dao = BarsDao();
  final _visitsDao = VisitsDao();
  final _reviewsDao = ReviewsDao();

  List<Bar> _bars = [];
  Map<String, int> _visitCounts = {};
  Map<String, ReviewData> _reviews = {};
  Map<String, DateTime> _lastVisits = {};

  @override
  void initState() {
    super.initState();
    _loadBars();
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
        );
      }),
    );
  }

  Future<void> _loadBars() async {
    final bars = await _dao.getAllBars();
    final counts = await _dao.getVisitCountsByBarId();
    final reviews = await _reviewsDao.getAllReviewsByBarId();
    final lastVisits = await _visitsDao.getLastVisitsByBarId();

    bars.sort((a, b) {
      final aVisited = (counts[a.id] ?? 0) > 0;
      final bVisited = (counts[b.id] ?? 0) > 0;
      if (aVisited != bVisited) return aVisited ? -1 : 1;

      final aRating = reviews[a.id]?.rating ?? 0;
      final bRating = reviews[b.id]?.rating ?? 0;
      if (aRating != bRating) return bRating.compareTo(aRating);

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    if (!mounted) return;
    setState(() {
      _bars = bars;
      _visitCounts = counts;
      _reviews = reviews;
      _lastVisits = lastVisits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bars'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBarPage()),
          );
          if (!mounted) return;
          await _loadBars();
        },
        child: const Icon(Icons.add),
      ),
      body: _bars.isEmpty
          ? const Center(child: Text('No bars yet. Add your first one 🍺'))
          : ListView.builder(
              itemCount: _bars.length,
              itemBuilder: (_, i) {
                final bar = _bars[i];

                final count = _visitCounts[bar.id] ?? 0;
                final visited = count > 0;

                final rating = _reviews[bar.id]?.rating ?? 0;
                final last = _lastVisits[bar.id];

                final subtitleParts = <String>[
                  visited ? 'Visited ($count)' : 'Not visited yet',
                  if (last != null) 'Last: ${_formatDateTime(last)}',
                ];
                final subtitle = subtitleParts.join(' • ');

                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(bar.name)),
                      if (rating > 0) _stars(rating),
                    ],
                  ),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: Icon(
                      visited ? Icons.check_circle : Icons.check_circle_outline,
                    ),
                    onPressed: () async {
                      await _visitsDao.addVisit(bar.id);
                      if (!mounted) return;

                      await _loadBars();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Visit logged for "${bar.name}" 🍻'),
                        ),
                      );
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BarDetailsPage(bar: bar),
                      ),
                    );
                    if (!mounted) return;
                    await _loadBars();
                  },
                );
              },
            ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Later: export/import, about, etc.'),
      ),
    );
  }
}