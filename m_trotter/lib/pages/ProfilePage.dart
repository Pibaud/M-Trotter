import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Importer permission_handler
import '../providers/AuthNotifier.dart';
import 'SettingsPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  File? _profileImage;

  // Demander les permissions nécessaires pour la caméra et le stockage
  Future<void> _requestPermissions() async {
    var cameraStatus = await Permission.camera.request();
    var storageStatus = await Permission.storage.request();

    if (cameraStatus.isGranted && storageStatus.isGranted) {
      // Permissions accordées, on peut faire ce qu'on veut (prendre une photo, choisir une image)
      print("Permissions accordées !");
    } else {
      // Si une permission est refusée, informer l'utilisateur
      print("Permissions refusées !");
    }
  }

  // Méthode pour choisir une image et la recadrer
  Future<void> _pickImage() async {
    // Demander les permissions avant de choisir une image
    await _requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Recadrer l'image après l'avoir choisie
      File? croppedImage = await _cropImage(File(pickedFile.path));

      if (croppedImage != null) {
        setState(() {
          _profileImage = croppedImage;
        });
      }
    }
  }

  // Méthode pour recadrer l'image en forme de cercle
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,

      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer la photo',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false, // Permet de zoomer et déplacer librement
          cropStyle: CropStyle.circle, // Découpe en rond
        ),
        IOSUiSettings(
          title: 'Recadrer la photo',
          aspectRatioLockEnabled: false, // Permet de bouger et zoomer
          cropStyle: CropStyle.circle, // Découpe en rond
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📸 Photo de profil avec option de recadrage
            GestureDetector(
              onTap: _pickImage, // Lancer le choix d'une image et le recadrage
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // 🔤 Champ Pseudo
            TextFormField(
              decoration: InputDecoration(
                labelText: "Pseudo",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // 🔢 Champ Âge
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Âge",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Bouton Sauvegarder
            ElevatedButton(
              onPressed: () {
                print("Profil mis à jour !");
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}
