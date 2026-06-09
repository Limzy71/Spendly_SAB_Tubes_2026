import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';

class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (!context.mounted) return;
      Navigator.pop(context, {'action': 'upload', 'path': image.path});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> funnyAvatars = [
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Milo',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Lola',
      'https://api.dicebear.com/7.x/bottts/png?seed=Zoe',
      'https://api.dicebear.com/7.x/bottts/png?seed=Felix',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Buster',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Missy',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Bear',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Oliver',
      'https://api.dicebear.com/7.x/bottts/png?seed=Jasper',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Daisy',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Ubah Foto Profil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Pilih Avatar Lucu",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: funnyAvatars.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, {'action': 'avatar', 'url': funnyAvatars[index]});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      backgroundImage: NetworkImage(funnyAvatars[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Atau Unggah Foto",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
            ),
            title: Text("Ambil dari Kamera", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
            ),
            title: Text("Pilih dari Galeri", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            title: const Text("Hapus Foto Profil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context, {'action': 'delete'});
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}