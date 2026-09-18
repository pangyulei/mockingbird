import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/mobile/tab_albums/album_detail/album_detail_bloc.dart';
import 'package:mockingbird/mobile/tab_albums/album_detail/album_detail_ui.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_ui.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_ui.dart';
import 'package:mockingbird/mobile/tab_settings/about/about_ui.dart';
import 'package:mockingbird/mobile/tab_settings/settings_ui.dart';

typedef OnClickTab = void Function(int index, StatefulNavigationShell shell);

class MobileAppRoute {
  static GoRouter? _router;
  static GoRouter init(OnClickTab callback) {
    var router = _router;
    router ??= GoRouter(
      initialLocation: albumList,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              _indexesStackScaffold(context, shell, callback),
          branches: [
            StatefulShellBranch(routes: [_albumRoute()]),
            StatefulShellBranch(routes: [_playerRoute()]),
            StatefulShellBranch(routes: [_settingsRoute()]),
          ],
        ),
      ],
    );
    _router = router;
    return router;
  }

  static String get albumList => '/albums';

  // static String get addAlbum => '$albums/new';
  static String albumById(String id) => '$albumList/$id';

  // static String editAlbum(int id) => '$albums/$id/edit';

  static String get player => '/player';
  static String playerById(String mediaId) => '$player?mediaId=$mediaId';

  static String get settings => '/settings';

  static String get about => '$settings/about';

  static GoRoute _albumRoute() => GoRoute(
    path: albumList,
    builder: (context, state) => const AlbumListUI(),
    routes: [
      GoRoute(
        path: ':albumId',
        builder: (BuildContext context, GoRouterState state) {
          final albumId = state.pathParameters['albumId'];
          i('albumdetail go-router create instance $albumId');
          return AlbumDetailUI(AlbumDetailBloc(albumId));
        },
      ),
    ],
  );

  static GoRoute _playerRoute() => GoRoute(
    path: player,
    builder: (BuildContext context, GoRouterState state) {
      // final mediaId = state.pathParameters['mediaId'];
      final mediaId = state.uri.queryParameters['mediaId'];
      i('player go-router create mediaId($mediaId)');
      final playerBloc = SharedMobilePlayerBloc.instance;
      return MobilePlayerUI(playerBloc..add(MobilePlayerInitEvent(mediaId)));
    },
  );

  static GoRoute _settingsRoute() => GoRoute(
    path: settings,
    builder: (BuildContext context, GoRouterState state) {
      return const SettingsUI();
    },
    routes: [
      GoRoute(path: 'about', builder: (context, state) => const AboutUI()),
    ],
  );

  static Widget _indexesStackScaffold(
    BuildContext context,
    StatefulNavigationShell shell,
    OnClickTab onClickTab,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
              // width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: shell.currentIndex,
          onTap: (index) {
            onClickTab(index, shell);
          },
          elevation: 0,
          backgroundColor: const Color(0xFF17212B),
          selectedItemColor: const Color(0xFF5288C1),
          unselectedItemColor: const Color(0xFF7F91A4),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_rounded),
              activeIcon: Icon(Icons.folder_rounded),
              label: 'Albums',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_rounded),
              activeIcon: Icon(Icons.play_circle_rounded),
              label: 'Player',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
