// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/player_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/squad_builder_screen.dart';
import 'screens/history_screen.dart';
import 'models/match_roster_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const BasketStephApp());
}

class BasketStephApp extends StatelessWidget {
  const BasketStephApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basket Steph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFFF97316),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF131B2E),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Avvia sulla Scoreboard
  Widget? _customScoreboard;

  final GlobalKey<PlayersScreenState> _playersKey = GlobalKey<PlayersScreenState>();
  final GlobalKey<TeamsScreenState> _teamsKey = GlobalKey<TeamsScreenState>();
  final GlobalKey<SquadBuilderScreenState> _builderKey = GlobalKey<SquadBuilderScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();

  void _onMatchFinished() {
    setState(() => _currentIndex = 4); // Salta alla scheda Storico
    _historyKey.currentState?.reload();
  }

  void _loadMatchFromExternal(
    List<MatchRosterPlayer> homeRoster,
    List<MatchRosterPlayer> awayRoster,
    String homeName,
    String awayName,
    Color homeColor,
    Color awayColor, [
    String? tournamentId,
  ]) {
    setState(() {
      _customScoreboard = ScoreboardScreen(
        key: UniqueKey(),
        initialHomePlayers: homeRoster,
        initialAwayPlayers: awayRoster,
        initialHomeName: homeName,
        initialAwayName: awayName,
        initialHomeColor: homeColor,
        initialAwayColor: awayColor,
        initialTournamentId: tournamentId,
        onMatchFinished: _onMatchFinished,
      );
      _currentIndex = 2; // Va alla Scoreboard
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        _playersKey.currentState?.reload();
        break;
      case 1:
        _teamsKey.currentState?.reload();
        break;
      case 3:
        _builderKey.currentState?.reload(); // Reload attivo sul Builder
        break;
      case 4:
        _historyKey.currentState?.reload();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      PlayersScreen(
        key: _playersKey,
        onDataChanged: () {
          _historyKey.currentState?.reload();
          _builderKey.currentState?.reload();
          _teamsKey.currentState?.reload();
        },
      ),
      TeamsScreen(
        key: _teamsKey,
        onLoadMatch: (h, a, hn, an, hc, ac) {
          _loadMatchFromExternal(h, a, hn, an, hc, ac);
        },
      ),
      _customScoreboard ??
          ScoreboardScreen(
            key: const PageStorageKey('default_scoreboard'),
            initialHomePlayers: const [],
            initialAwayPlayers: const [],
            onMatchFinished: _onMatchFinished,
          ),
      SquadBuilderScreen(
        key: _builderKey,
        onSendToScoreboard: (h, a) {
          _loadMatchFromExternal(
            h,
            a,
            'CASA',
            'OSPITI',
            const Color(0xFF3B82F6),
            const Color(0xFFEF4444),
          );
        },
      ),
      HistoryScreen(
        key: _historyKey,
        onLoadTournamentMatch: _loadMatchFromExternal,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131B2E),
          border: Border(top: BorderSide(color: Color(0xFF263559), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF131B2E),
          selectedItemColor: const Color(0xFFF97316),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Giocatori'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Squadre'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_basketball), label: 'Scoreboard'),
            BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Builder'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Storico'),
          ],
        ),
      ),
    );
  }
}