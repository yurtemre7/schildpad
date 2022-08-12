import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:schildpad/installed_app_widgets/app_widgets_screen.dart';

class ShowAppWidgetsButton extends StatelessWidget {
  const ShowAppWidgetsButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () => context.push(AppWidgetsScreen.routeName),
        icon: const Icon(
          Icons.now_widgets_outlined,
          color: Colors.white,
        ));
  }
}

class DeletePageButton extends StatelessWidget {
  const DeletePageButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white));
  }
}

class AddPageButton extends StatelessWidget {
  const AddPageButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onTap, icon: const Icon(Icons.add, color: Colors.white));
  }
}
