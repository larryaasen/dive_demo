import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive_core/dive_core.dart';

void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // // Configure globally for all Equatable instances via EquatableConfig
  // EquatableConfig.stringify = true;

  runApp(ProviderScope(child: AppWidget()));
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive UI Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Media Player Example'),
          ),
          body: BodyWidget(elements: _elements),
        ));
  }
}

class BodyWidget extends StatefulWidget {
  BodyWidget({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  DiveCore _diveCore;
  DiveCoreElements _elements;
  bool _initialized = false;

  static const bool _enableOBS = true; // Set to false for debugging

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    _elements = widget.elements;
    _diveCore = DiveCore();
    if (_enableOBS) {
      DiveScene.create('Scene 1').then((scene) => setup(scene));
    }

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveCore.providerContainer = ProviderScope.containerOf(context);

    _initialized = true;
  }

  void setup(DiveScene scene) {
    // _elements.currentScene = scene;

    DiveVideoMix.create().then((mix) {
      setState(() {
        _elements.videoMixes.add(mix);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_elements.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final videoMix = DivePreview(
      _elements.videoMixes[0].controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );
    print("videoMix=$videoMix");

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
