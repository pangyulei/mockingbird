import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/mobile/tab_albums/album_detail/album_detail_event.dart';
import 'package:mockingbird/mobile/tab_albums/album_detail/album_detail_state.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../tool/extensions.dart';
import '../media_card/media_card_ui.dart';

abstract interface class AlbumDetailBlocITF {
  MediaCardBlocType mediaCardBlocAtIndex(int index);
}

abstract class AlbumDetailBlocType extends Bloc<AlbumDetailEvent, AlbumDetailState>
    implements AlbumDetailBlocITF {
  AlbumDetailBlocType(super.initialState);
}

class AlbumDetailUI extends StatelessWidget {
  final AlbumDetailBlocType _bloc;

  const AlbumDetailUI(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        i('albumdetail ui blocprovider create called');
        return _bloc..add(const AlbumDetailInitEvent());
      },
      child: Builder(
        builder: (context) {
          final stateType = context.select<AlbumDetailBlocType, Type>(
            (bloc) => bloc.state.runtimeType,
          );
          switch (stateType) {
            case AlbumDetailInitState:
              return _pageForLoading();
            case AlbumDetailNotFoundState:
              return _pageForNotFound();
            case AlbumDetailEmptyState:
              return _pageForEmpty();
            case AlbumDetailDataState:
              return _pageForData(context);
            default:
              assert(false, 'state type $stateType not handled');
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _pageForLoading() {
    return Scaffold(appBar: AppBar());
  }

  Widget _pageForData(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final (name, count) = context.select<AlbumDetailBlocType, (String, int)>((bloc) {
              final data = bloc.state.as<AlbumDetailDataState>();
              return (data?.name ?? 'Album Not Found', data?.mediaList.length ?? 0);
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  '$count medias',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          final mediaList = context.select<AlbumDetailBlocType, List<AssetEntity>>(
            (bloc) => bloc.state.as<AlbumDetailDataState>()?.mediaList ?? [],
          );
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: mediaList.length,
            itemBuilder: (context, i) {
              final mediaCardBloc = context.read<AlbumDetailBlocType>().mediaCardBlocAtIndex(i);
              return MediaCardUI(mediaCardBloc);
            },
          );
        },
      ),
    );
  }

  Widget _pageForNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('?')),
      body: const Center(child: Text('Album not found')),
    );
  }

  Widget _pageForEmpty() {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final name = context.select<AlbumDetailBlocType, String>(
              (bloc) => bloc.state.as<AlbumDetailEmptyState>()?.name ?? '',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  '0 medias',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            );
          },
        ),
      ),
      body: const Center(child: Text('Album is empty')),
    );
  }
}
