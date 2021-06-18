import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dive_core/dive_core.dart';

void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(AppWidget());
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
  DiveCoreElements _elements;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    _elements = widget.elements;
    DiveScene.create('Scene 1').then((scene) => setup(scene));

    _initialized = true;
  }

  void setup(DiveScene scene) {
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

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
