library dive_ui;

import 'dart:math';

import 'package:dive_core/dive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'blocs/dive_reference_panels.dart';

export 'blocs/dive_reference_panels.dart';

class DiveUI {
  /// DiveCore and DiveUI must use the same [ProviderContainer], so it needs
  /// to be passed to DiveCore at the start.
  static void setup(BuildContext context) {}
}

class DiveSourceCard extends StatefulWidget {
  DiveSourceCard({this.child, this.elements, this.referencePanels, this.panel});

  final Widget child;
  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;

  @override
  _DiveSourceCardState createState() => _DiveSourceCardState();
}

class _DiveSourceCardState extends State<DiveSourceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // print("SourceCard.build: $this hovering=$_hovering");
    final stack = FocusableActionDetector(
        onShowHoverHighlight: _handleHoverHighlight,
        child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.topCenter,
            child: Stack(
              children: <Widget>[
                widget.child ?? Container(),
                if (_hovering)
                  Positioned(
                      right: 5,
                      top: 5,
                      child: DiveSourceMenu(
                          elements: widget.elements,
                          referencePanels: widget.referencePanels,
                          panel: widget.panel)),
              ],
            )));

    return stack;
  }

  void _handleHoverHighlight(bool value) {
    // print("SourceCard.onShowHoverHighlight: $this hovering=$value");

    // Sometimes the hover state is invokes twice for the same value, so
    // it should be ignored if it did not change.
    if (_hovering == value) return;

    setState(() {
      _hovering = value;
    });
  }
}

@Deprecated(
    'This was helpful for a while, but not needed anymore. keep around for a little while')
class DiveSourcePreview extends StatelessWidget {
  const DiveSourcePreview(this.controller, {Key key}) : super(key: key);

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    final preview =
        DivePreview(controller, aspectRatio: DiveCoreAspectRatio.HD.ratio);
    return preview;
  }
}

/// A widget showing a preview of a video/image frame using a [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview(this.controller, {Key key, this.aspectRatio})
      : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    var texture = controller != null && controller.value.isInitialized
        ? Texture(textureId: controller.textureId)
        : Container(color: Colors.blue);

    final widget = aspectRatio != null
        ? DiveAspectRatio(aspectRatio: aspectRatio, child: texture)
        : texture;

    return widget;
  }
}

/// A Dive gear settings button.
class DiveGearButton extends StatelessWidget {
  const DiveGearButton({Key key, this.iconColor = Colors.white})
      : super(key: key);

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Ink(
          decoration: const ShapeDecoration(
            color: Colors.black12,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(Icons.settings_outlined),
            color: iconColor,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

/// A widget that will size the child to a specific aspect ratio.
class DiveAspectRatio extends StatelessWidget {
  /// Creates a widget with a specific aspect ratio.
  ///
  /// The [aspectRatio] argument must be a finite number greater than zero.
  const DiveAspectRatio({
    Key key,
    @required this.aspectRatio,
    this.child,
  }) : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Wrap the AspectRatio inside an Align widget to make the AspectRatio
    // widget actually work.
    return Align(
        child: AspectRatio(
      aspectRatio: aspectRatio,
      child: child,
    ));
  }
}

class DiveGrid extends StatelessWidget {
  const DiveGrid({
    Key key,
    @required this.aspectRatio,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The widgets to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      crossAxisCount: 3,
      childAspectRatio: aspectRatio,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: children,
      shrinkWrap: true,
      clipBehavior: Clip.hardEdge,
    );
  }
}

class DiveSourceMenu extends StatelessWidget {
  DiveSourceMenu({this.elements, this.referencePanels, this.panel});

  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;

  @override
  Widget build(BuildContext context) {
    // id, menu text, icon, sub menu?
    final _sourceItems = elements.videoSources
        .map((source) => {
              'id': source.trackingUUID,
              'title': source.name,
              'icon': Icons.clear,
              'source': source,
              'subMenu': null,
            })
        .toList();
    final _popupItems = [
      // id, menu text, icon, sub menu?
      {
        'id': 1,
        'title': 'Clear',
        'icon': Icons.clear,
        'subMenu': null,
      },
      {
        'id': 2,
        'title': 'Select source',
        'icon': Icons.select_all,
        'subMenu': _sourceItems,
      },
    ];

    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<int>(
          child: Icon(Icons.settings_outlined,
              color: Theme.of(context).buttonColor),
          tooltip: 'Source menu',
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return _popupItems.map((Map<String, dynamic> item) {
              final child = item['subMenu'] != null
                  ? DiveSubMenu(
                      item['title'],
                      item['subMenu'],
                      onSelected: (item) {
                        if (referencePanels != null) {
                          referencePanels.assignSource(item['source'], panel);
                        }
                      },
                    )
                  : Text(item['title']);
              return PopupMenuItem<int>(
                key: Key('diveSourceMenu_${item['id']}'),
                value: item['id'],
                child: Row(
                  children: <Widget>[
                    Icon(item['icon'], color: Colors.grey),
                    Padding(padding: EdgeInsets.only(left: 6.0), child: child),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (int item) {
            // TODO: this is not being called
            print("onSelected: $item");
            // If `clear` menu item
            if (item == 1) {
              print("onSelected: item 1");
              if (referencePanels != null) {
                print("onSelected: assign");
                referencePanels.assignSource(null, panel);
              }
            }
          },
          onCanceled: () {
            // TODO: this is not being called
            print("onCanceled");
          },
        ));
  }
}

class DiveSubMenu extends StatelessWidget {
  DiveSubMenu(this.title, this.popupItems, {this.onSelected, this.onCanceled});

  final String title;
  final List<Map<String, Object>> popupItems;

  /// Called when the user selects a value from the popup menu created by this
  /// menu.
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final void Function(Map<String, Object> item) onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final void Function() onCanceled;

  @override
  Widget build(BuildContext context) {
    final mainChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title),
        // Spacer(),
        Icon(Icons.arrow_right, size: 30.0),
      ],
    );
    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<Map<String, Object>>(
          child: mainChild,
          tooltip: title,
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return popupItems.map((Map<String, dynamic> item) {
              return PopupMenuItem<Map<String, Object>>(
                  key: Key('diveSubMenu_${item['id']}'),
                  value: item,
                  child: Flexible(
                      child: Row(children: <Widget>[
                    Icon(item['icon'], color: Colors.grey),
                    Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Text(
                          item['title'].toString().substring(
                              0, min(14, item['title'].toString().length)),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ])));
            }).toList();
          },
          onSelected: (item) {
            if (this.onSelected != null) {
              this.onSelected(item);
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          onCanceled: () {
            if (this.onSelected != null) {
              this.onCanceled();
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ));
  }
}
