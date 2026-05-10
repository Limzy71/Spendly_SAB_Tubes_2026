import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({super.key});

  // Fungsi untuk mengambil gambar
  // Ubah fungsi menjadi mengembalikan File
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // Kirim path gambar kembali ke halaman profil saat sheet ditutup
      Navigator.pop(context, image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Agar tinggi box mengikuti isi
        children: [
          const Text(
            "Ubah Foto Profil",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF00A368)), // Warna hijau Spendly
            title: const Text("Ambil dari Kamera"),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF00A368)),
            title: const Text("Pilih dari Galeri"),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}