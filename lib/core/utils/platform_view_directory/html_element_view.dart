import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';


class HtmlElementView extends StatelessWidget {
  /// Creates a platform view for Flutter Web.
  ///
  /// `viewType` identifies the type of platform view to create.
  const HtmlElementView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
  });

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// Callback to invoke after the platform view has been created.
  ///
  /// May be null.
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _createHtmlElementView,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const {},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  /// Creates the controller and kicks off its initialization.
  _HtmlElementViewController _createHtmlElementView(PlatformViewCreationParams params) {
    final _HtmlElementViewController controller = _HtmlElementViewController(params.id, viewType);
    controller._initialize().then((_) {
      params.onPlatformViewCreated(params.id);
      onPlatformViewCreated?.call(params.id);
    });
    return controller;
  }
}

class _HtmlElementViewController extends PlatformViewController {
  _HtmlElementViewController(
      this.viewId,
      this.viewType,
      );

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  bool _initialized = false;

  Future<void> _initialize() async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}