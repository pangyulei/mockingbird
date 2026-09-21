import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mockingbird/desktop/main_window/desktop_main_window_bloc.dart';
import 'package:mockingbird/desktop/main_window/desktop_main_window_event.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../tool/extensions.dart';
import 'desktop_main_window_state.dart';

class DesktopMainWindowUI extends StatefulWidget {
  const DesktopMainWindowUI({super.key});

  @override
  State<StatefulWidget> createState() => _DesktopMainWindowUIState();
}

class _DesktopMainWindowUIState extends State<DesktopMainWindowUI> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DesktopMainWindowBloc()..add(const DesktopMainWindowInitEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: EasyLoading.init(),
        home: _home(),
      ),
    );
  }

  Widget _home() {
    //Theme.of(context).scaffoldBackgroundColor
    return Scaffold(
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: kDesktopMainWindowDividerThickness,
          dividerPainter: DividerPainters.grooved1(),
        ),
        child: imageContainer(
          Image.asset('assets/desktop/main_window_background.jpg').image,
          child: Builder(
            builder: (context) {
              final splitter = context
                  .select<DesktopMainWindowBloc, MultiSplitViewController?>(
                    (bloc) =>
                        bloc.state.as<DesktopMainWindowDataState>()?.splitter,
                  );
              if (splitter == null) return const SizedBox.shrink();
              return MultiSplitView(
                controller: splitter,
                axis: Axis.horizontal,
              );
            },
          ),
        ),
      ),
    );
  }
}
