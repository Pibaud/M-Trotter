import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/AuthNotifier.dart';
import '../services/ApiService.dart';
import 'SettingsPage.dart';



class ProfilePage extends StatefulWidget {

  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = true;
  //String? _profileImageBase64; // Stocker l'image en Base64
  Uint8List? _profileImageBytes;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchProfileData(); // Récupérer les infos dès l’ouverture
  }

  // Récupérer les infos du profil depuis l’API

  Future<void> _fetchProfileData() async {
    var response = await _apiService.getProfile();
    if (response.containsKey('success') && response['success']) {
      setState(() {
        _pseudoController.text = response['pseudo'] ?? "";
        _ageController.text = response['age'] ?? "";
        _profileImageBytes = response['profile_image'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //  Choisir et recadrer une image
  Future<void> _pickImage() async {
    // Demander les permissions
    await Permission.camera.request();
    await Permission.storage.request();

    // Afficher le dialogue de choix
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    // Si l'utilisateur a choisi une source
    if (source != null) {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compression de l’image à 80% de qualité
      );


      if (pickedFile != null) {
        File? croppedImage = await _cropImage(File(pickedFile.path));
        if (croppedImage != null) {
          setState(() {
            _profileImage = croppedImage;
          });
        }
      }
    }
  }

// Le reste du code reste inchangé
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer la photo',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Recadrer la photo',
          aspectRatioLockEnabled: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  //Sauvegarde des données modifiées
  Future<void> _saveProfile() async {
    final String pseudo = _pseudoController.text.trim();
    final String age = _ageController.text.trim();
    if(_profileImage == null) {
      print("Image non sélectionnée");
    }else{
      print("Image sélectionnée");
    }

    if (pseudo.isEmpty) {
      setState(() {
        _errorMessage = "Le nom d'utilisateur est obligatoire.";
      });
      return;
    }
    try {
      var response = await _apiService.updateProfile(
        pseudo: pseudo,
        age: age.isNotEmpty ? age : null,
        profileImage: _profileImage,
      );
      print("Réponse de l'API : $response");

      if (response.containsKey('success') && response['success'] == true) {
        setState(() {
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profil mis à jour avec succès !"))
        );
      } else if (response['error'] == 'pseudo_taken') {
        setState(() {
          _errorMessage = "Ce nom d'utilisateur est déjà pris.";
        });
      } else {
        setState(() {
          _errorMessage = "Une erreur est survenue, réessayez.";
        });
      }
    }catch (e) {
      // Si une erreur d'appel d'API survient
      setState(() {
        _errorMessage = "Une erreur de connexion est survenue.";
      });
    }
  }

  /*
  Future<void> _saveProfile() async {
    final String pseudo = _pseudoController.text.trim();
    final String age = _ageController.text.trim();

    if (pseudo.isEmpty) {
      setState(() {
        _errorMessage = "Le nom d'utilisateur est obligatoire.";
      });
      return;
    }

    await Future.delayed(Duration(seconds: 1)); // Simule une requête

    if (pseudo == "UtilisateurTest") { // Simule un pseudo déjà pris
      setState(() {
        _errorMessage = "Ce nom d'utilisateur est déjà pris.";
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil mis à jour avec succès !"))
      );
    }
  }
*/

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
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) //  Indicateur de chargement
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!) // Utilisation de MemoryImage pour afficher l'image binaire
                      : null),
                  child: (_profileImage == null && _profileImageBytes == null)
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Champ Pseudo
              TextFormField(
                controller: _pseudoController,
                decoration: InputDecoration(
                  labelText: "Nom d'utilisateur",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 5),

              // Champ Âge (optionnel)
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Âge (optionnel)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Sauvegarder"),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
