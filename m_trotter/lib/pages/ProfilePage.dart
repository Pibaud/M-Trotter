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
/*
  Future<void> _fetchProfileData() async {
    await Future.delayed(Duration(seconds: 1)); // Simule un délai réseau

    setState(() {
      _pseudoController.text = "UtilisateurTest"; // Simule un pseudo reçu du serveur
      _ageController.text = ""; // Simule un âge reçu
      _profileImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sosXVTvbc6RHirr2reNy1OXd6pJsQ+gqjk8VWFYmHrwBzW/n+uMPFiRwHB2I7ih8ciHFxIkd/3Omk5tCDV1t+2nNu5sxxpDFNx+huNhVT3/zMDz8usXC3ddaHBj1GHj/As08fwTS7Kt1HBTmyN29vdwAw+/wbwLVOJ3uAD1wi/dUH7Qei66PfyuRj4Ik9is+hglfbkbfR3cnZm7chlUWLdwmprtCohX4HUtlOcQjLYCu+fzGJH2QRKvP3UNz8bWk1qMxjGTOMThZ3kvgLI5AzFfo379UAAAAASUVORK5CYII=";
      _profileImageBytes = base64Decode(_profileImageBase64!);
      _isLoading = false;
    });
  }
*/
  //  Choisir et recadrer une image
  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.storage.request();

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedImage = await _cropImage(File(pickedFile.path));
      if (croppedImage != null) {
        setState(() {
          _profileImage = croppedImage;
        });
      }
    }
  }

  //  Recadrer l’image
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

    if (pseudo.isEmpty) {
      setState(() {
        _errorMessage = "Le nom d'utilisateur est obligatoire.";
      });
      return;
    }

    var response = await _apiService.updateProfile(
      pseudo: pseudo,
      age: age.isNotEmpty ? age : null,
      profileImage: _profileImage,
    );

    if (response.containsKey('success') && response['success']) {
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
