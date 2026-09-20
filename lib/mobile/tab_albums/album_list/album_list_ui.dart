import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_albums/album_card/album_card_bloc.dart';
import 'package:mockingbird/mobile/tab_albums/album_card/album_card_event.dart';
import 'package:mockingbird/mobile/tab_albums/album_card/album_card_ui.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_bloc.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_event.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumListUI extends StatelessWidget {
  const AlbumListUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlbumListBloc()..add(const AlbumListInitEvent()),
      child: Builder(
        builder: (context) {
          final stateType = context.select<AlbumListBloc, Type>(
            (bloc) => bloc.state.runtimeType,
          );
          switch (stateType) {
            case AlbumListInitState:
              return _pageForInit();
            case AlbumListNotYetRequestedState:
              return _pageForRequestPermissions(context);
            case AlbumListPermissionDeniedState:
              return _pageForGrantPermissionsViaSetting(context);
            case AlbumListEmptyState:
              return _pageForEmpty(context);
            case AlbumListDataState:
              return _pageForData();
            default:
              assert(false, 'stateType $stateType missed');
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _pageForInit() {
    return Scaffold(appBar: _appBar());
  }

  Widget _pageForEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.collections_bookmark_rounded,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No Albums Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Organize your audio and video clips into albums for better shadowing practice.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageForRequestPermissions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Permission Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mockingbird needs access to your media library to find and organize your audio and video clips.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.read<AlbumListBloc>().add(
                  const AlbumListRequestPermissionEvent(),
                ),
                icon: const Icon(Icons.settings_suggest_rounded),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageForGrantPermissionsViaSetting(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_applications_rounded,
                  size: 80,
                  color: colorScheme.error.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Settings Access Needed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Permission was denied. Please go to system settings to manually allow Mockingbird access to your media.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  await PhotoManager.openSetting();
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageForData() {
    return Scaffold(appBar: _appBar(), body: _grid());
  }

  AppBar _appBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Albums'),
          Builder(
            builder: (context) {
              final albumCount = context.select<AlbumListBloc, int?>(
                (bloc) => bloc.state.as<AlbumListDataState>()?.albumList.length,
              );
              if (albumCount == null) return const SizedBox.shrink();
              return Text(
                '$albumCount albums',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: false,
      actions: const [],
    );
  }

  Widget _grid() {
    return Builder(
      builder: (context) {
        //watch all, albumCount may not change but the album inside list already change
        //etc. album order updated
        final albumList =
            context.select<AlbumListBloc, List<AssetPathEntity>?>(
              (bloc) => bloc.state.as<AlbumListDataState>()?.albumList,
            ) ??
            [];
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: albumList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, i) {
            return AlbumCardUI(
              AlbumCardBloc(albumList[i])..add(const AlbumCardInitEvent()),
            );
          },
        );
      },
    );
  }
}
