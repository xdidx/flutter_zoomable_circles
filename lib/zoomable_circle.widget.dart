import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CircleButton extends StatelessWidget {
  final IconData? iconData;
  final double diameter;

  const CircleButton({Key? key, this.iconData, this.diameter = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.black,
      ),
    );
  }
}

class ZoomableCircleWidget extends StatefulWidget {
  final List<CircleButton> children;

  const ZoomableCircleWidget({Key? key, this.children = const []}) : super(key: key);

  @override
  State<ZoomableCircleWidget> createState() => _ZoomableCircleWidgetState();
}

const double _radiansPerDegree = pi / 180;
const double _startAngle = -90.0 * _radiansPerDegree;

const double _margin = 10;
const int _animationDuration = 500;

class _ZoomableCircleWidgetState extends State<ZoomableCircleWidget>
    with
        SingleTickerProviderStateMixin,
        AfterLayoutMixin<ZoomableCircleWidget> {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;

  double _initialContainerCircleSize = 500;
  double _containerCircleSize = 500;
  double _itemSpacing = 0;
  bool _zoomed = false;
  GlobalKey containerKey = GlobalKey();
  final List<Widget> _positionedChildren = [];

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: _animationDuration),
        vsync: this);

    _itemSpacing = 360.0 / widget.children.length;


    for (var child in widget.children) {
      if (child.diameter * 2 > _initialContainerCircleSize) {
        _initialContainerCircleSize = child.diameter * 2;
      }
    }
    _containerCircleSize = _initialContainerCircleSize;

    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _containerCircleSize = _initialContainerCircleSize;
    drawChildren();
  }

  void drawChildren() {
    _positionedChildren.clear();

    double radius = _containerCircleSize / 2;
    widget.children.asMap().forEach((i, child) {
      double childSize = child.diameter;
      final double itemAngle =
          _startAngle + i * _itemSpacing * _radiansPerDegree;
      double shiftValue = (radius -
          childSize / 2 -
          _margin * (_containerCircleSize / _initialContainerCircleSize));
      double left = ((radius - childSize / 2) + shiftValue * cos(itemAngle));
      double top = ((radius - childSize / 2) + shiftValue * sin(itemAngle));

      GlobalKey currentKey = GlobalKey();
      _positionedChildren.add(Positioned(
        key: currentKey,
        child: GestureDetector(
          onTap: () => setState(() {
            final keyContext = containerKey.currentContext;
            if (keyContext != null) {
              // widget is visible
              final interactiveViewerBox =
              keyContext.findRenderObject() as RenderBox;
              double viewerWidth = interactiveViewerBox.size.width;

              final buttonKeyContext = currentKey.currentContext;
              if (buttonKeyContext != null) {
                Positioned? widget = currentKey.currentWidget as Positioned?;
                double? top = widget?.top;
                double? left = widget?.left;

                final box = buttonKeyContext.findRenderObject() as RenderBox;

                double scale = viewerWidth / (box.size.width + _margin * 2);

                launchAnimation(
                    x: (-(left ?? 0) + _margin),
                    y: (-(top ?? 0) + _margin),
                    scale: scale);
              }
            }
          }),
          child: child,
        ),
        top: top,
        left: left,
      ));
    });
    setState(() {});
  }

  updateContainerCircleSize() {
    double screenWidth = MediaQuery.of(context).size.width - _margin * 2;
    double maxWidth =
    _initialContainerCircleSize > screenWidth ? screenWidth : _initialContainerCircleSize;
    _containerCircleSize = maxWidth;

    double screenHeight = MediaQuery.of(context).size.height - _margin * 2;
    double maxHeight =
    _initialContainerCircleSize > screenHeight ? screenHeight : _initialContainerCircleSize;
    _containerCircleSize = maxHeight;

    if (maxWidth > maxHeight) {
      _containerCircleSize = maxHeight;
    } else {
      _containerCircleSize = maxWidth;
    }
  }

  void launchAnimation({x, y, scale = 1}) {
    double currentScale = _transformationController.value.getMaxScaleOnAxis();
    double currentX = _transformationController.value.getTranslation().x;
    double currentY = _transformationController.value.getTranslation().y;
    var start = Matrix4.identity()
      ..translate(currentX, currentY)
      ..scale(currentScale, currentScale);
    var end = Matrix4.identity()
      ..translate(x * scale, y * scale)
      ..scale(scale, scale);

    var mapAnimation = Matrix4Tween(begin: start, end: end)
        .animate(_animationController)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _zoomed = _transformationController.value.getMaxScaleOnAxis() > 1;
          });
        }
      });

    mapAnimation.addListener(() {
      setState(() {
        _transformationController.value = mapAnimation.value;
      });
    });
    _animationController.reset();
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    updateContainerCircleSize();
    drawChildren();

    return Material(
      child: SizedBox(
        width: _containerCircleSize,
        height: _containerCircleSize,
        child: InteractiveViewer(
          key: containerKey,
          transformationController: _transformationController,
          // scaleEnabled: false,
          // panEnabled: false,
          maxScale: 10,
          minScale: 0.001,
          // boundaryMargin: const EdgeInsets.all(double.infinity),
          // constrained: false,
          onInteractionEnd: (details) {
            setState(() {
              _zoomed = _transformationController.value.getMaxScaleOnAxis() > 1;
            });
          },
          child: Stack(
            children: <Widget>[
              Positioned(
                child: Text("Zoomed: " + _zoomed.toString()),
                top: 0,
                left: 0,
              ),
              Container(
                width: _initialContainerCircleSize,
                height: _initialContainerCircleSize,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              ..._positionedChildren
            ],
          ),
        ),
      ),
    );
  }
}
