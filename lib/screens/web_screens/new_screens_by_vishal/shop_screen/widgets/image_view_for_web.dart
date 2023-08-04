import 'package:absolute_app/core/utils/app_export.dart';

class ImageWidgetPlaceholder extends StatelessWidget {
  const ImageWidgetPlaceholder({
    Key?key,
    required this.image,
    required this.placeholder,
  }) : super(key: key);
  final ImageProvider image;
  final Widget placeholder;
  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      frameBuilder: (BuildContext context, Widget child, int? frame,
          bool? wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded == true) {
          return child;
        } else {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: frame != null ? child : placeholder,
          );
        }
      },
    );
  }
}