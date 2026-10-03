import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PhotoAction { camera, gallery, remove }

/// Bottom sheet: Take photo / Choose from gallery / (Remove photo).
Future<PhotoAction?> showPhotoSourceSheet(
  BuildContext context, {
  bool allowRemove = false,
}) {
  return showModalBottomSheet<PhotoAction>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      Widget tile(
        IconData icon,
        String label,
        PhotoAction action, {
        Color color = Colors.white,
      }) {
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color, fontSize: 15)),
          onTap: () => Navigator.of(context).pop(action),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(
                Icons.photo_camera_outlined,
                'Take photo',
                PhotoAction.camera,
              ),
              tile(
                Icons.photo_library_outlined,
                'Choose from gallery',
                PhotoAction.gallery,
              ),
              if (allowRemove)
                tile(
                  Icons.delete_outline,
                  'Remove photo',
                  PhotoAction.remove,
                  color: AppColors.coralDark,
                ),
            ],
          ),
        ),
      );
    },
  );
}
