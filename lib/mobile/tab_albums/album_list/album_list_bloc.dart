import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_event.dart';
import 'package:mockingbird/mobile/tab_albums/album_list/album_list_state.dart';
import 'package:mockingbird/tool/event_hub.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../db/mobile_db.dart';


class AlbumListBloc extends Bloc<AlbumListEvent, AlbumListState> {
  final _subscriptionList = <StreamSubscription>[];

  AlbumListBloc() : super(const AlbumListInitState()) {
    on<AlbumListInitEvent>(_onInit);
    on<AlbumListRequestPermissionEvent>(_onRequestPermission);
    on<AlbumListResumeEvent>(_onResume);
    _subscriptionList.addAll([
      EventHub.on<HubAppResumeEvent>((event) => add(const AlbumListResumeEvent())),
    ]);
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptionList) {
      sub.cancel();
    }
    return super.close();
  }

  void _onInit(AlbumListInitEvent event, Emitter<AlbumListState> emit) async {
    EasyLoading.show(maskType: .clear);
    emit(await _reload());
    EasyLoading.dismiss();
  }

  void _onResume(AlbumListResumeEvent event, Emitter<AlbumListState> emit) async {
    EasyLoading.show(maskType: .clear);
    emit(await _reload());
    EasyLoading.dismiss();
  }

  Future<AlbumListState> _reload() async {
    final metadata = await MobileDB.loadMetadata();
    if (!metadata.permissionRequested) {
      return const AlbumListNotYetRequestedState();
    }
    //mediaLocation is for media's GPS info, I dont need that.
    //first time state is denied, only allow selected, is limited, allow-all is limited
    final option = PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.video | RequestType.audio,
        mediaLocation: false,
      ),
    );
    PermissionState permissionState = await PhotoManager.getPermissionState(requestOption: option);
    if (!permissionState.granted) {
      return const AlbumListPermissionDeniedState();
    }
    final albumList = await PhotoManager.getAssetPathList(
      type: RequestType.audio | RequestType.video,
    );
    if (albumList.isEmpty) {
      return const AlbumListEmptyState();
    }
    return AlbumListDataState(albumList);
  }

  void _onRequestPermission(
    AlbumListRequestPermissionEvent event,
    Emitter<AlbumListState> emit,
  ) async {
    await PhotoManager.requestPermissionExtend();
    var metadata = await MobileDB.loadMetadata();
    metadata = metadata.copyWith(permissionRequested: true);
    await MobileDB.updateMetadata(metadata);
    emit(await _reload());
  }
}

extension on PermissionState {
  bool get granted => {PermissionState.limited, PermissionState.authorized}.contains(this);
}
