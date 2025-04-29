import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/Photo.dart';
import '../services/ApiService.dart'; // Importer ApiService
import 'dart:io'; // Importer dart:io pour utiliser File
import '../models/Place.dart'; // Importer Place
import 'package:logger/logger.dart'; // Importer le package logger

Logger logger = Logger();

class Review {
  final String id;
  final String? parentId;
  String username;
  Uint8List? profilePicBytes;
  final String comment;
  int likes;
  bool isLiked;
  final DateTime date;
  int rating;
  final String placeTable;
  final String userId;
  final bool user_has_liked;
  final bool user_is_author;

  Review({
    required this.id,
    this.parentId,
    required this.username,
    required this.profilePicBytes,
    required this.comment,
    required this.likes,
    this.isLiked = false,
    required this.date,
    this.rating = 0,
    required this.placeTable,
    this.userId = '',
    required this.user_has_liked,
    required this.user_is_author,
  });

  void updateProfileInfo(String newUsername, Uint8List? newProfilePic) {
    username = newUsername;
    profilePicBytes = newProfilePic;
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['avis_id'].toString(),
      parentId: json['avis_parent']?.toString(),
      username:
          'toto', // Remplacer par le nom de l'utilisateur quand on fera avec les tokens
      profilePicBytes: json['profilePicBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['profilePicBytes']))
          : null, // Convertir en Uint8List si non null
      comment: json['lavis'],
      likes: int.tryParse(json['like_count'].toString()) ?? 0,
      isLiked: json['user_has_liked'] == true,
      date: DateTime.parse(json['created_at']),
      rating: json['nb_etoiles'] ?? 0,
      placeTable: json['place_table'],
      userId: json['user_id']?.toString() ?? '',
      user_has_liked: json['user_has_liked'],
      user_is_author: json['user_is_author'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Review{id: $id, parentId: $parentId, username: $username, profilePicBytes: $profilePicBytes, comment: $comment, likes: $likes, isLiked: $isLiked, date: $date, rating: $rating, placeTable: $placeTable, userId: $userId}';
  }
}

class PlacePresentationSheet extends StatefulWidget {
  final double height;
  final Function(double)? onDragUpdate;
  final Function()? onDragEnd;
  final Place place;
  final Function()? onItineraryTap;
  final Function()? onCallTap;
  final Function()? onWebsiteTap;
  final Function()? onInfosTap;
  final Function()? onClose;

  const PlacePresentationSheet({
    Key? key,
    this.height = 400,
    this.onDragUpdate,
    this.onDragEnd,
    required this.place,
    this.onItineraryTap,
    this.onCallTap,
    this.onWebsiteTap,
    this.onInfosTap,
    this.onClose,
  }) : super(key: key);

  @override
  _PlacePresentationSheetState createState() => _PlacePresentationSheetState();
}

class _PlacePresentationSheetState extends State<PlacePresentationSheet> {
  List<File> reviewPhotos = [];
  List<Review> reviews = [];
  bool isFavorite = false;
  bool isSortedByDate = true; // Par défaut, tri par date
  String newReviewText = '';
  String replyText = '';
  String? replyingTo;
  int newReviewRating = 0;
  String ratingError = "";
  bool showReviews = true;
  List<Uint8List> images = [];
  Set<String> allTags = {};
  String? selectedTag;
  bool replySent = false;
  List<Photo> photos = [];
  final ApiService _apiService = ApiService();
  bool showOpeningHours = false;
  bool hasAlreadyPostedReview = false;

  final TextEditingController _reviewController = TextEditingController();

  late Future<void> _fetchReviewsFuture;
  late Future<void> _fetchPhotosFuture;

  @override
  void initState() {
    super.initState();
    _fetchReviewsFuture = fetchReviews();
    _fetchPhotosFuture = fetchPhotos();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    bool favoriteStatus = await _apiService.estFavoris(osmId: widget.place.id);
    setState(() {
      isFavorite = favoriteStatus;
    });
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) {
      bool confirm = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: const Text("Retirer des favoris"),
                    content: const Text(
                        "Êtes-vous sûr de vouloir retirer cet endroit de vos favoris ?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Annuler"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Oui",
                            style: TextStyle(color: Colors.red)),
                      )
                    ]);
              }) ??
          false;

      if (!confirm) return;

      await _apiService.deleteFavoris(osmId: widget.place.id);
    } else {
      await _apiService.addFavoris(osmId: widget.place.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Center(
            child: Text("Ajouté aux favoris",
                style: TextStyle(color: Colors.white))),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> fetchPhotos() async {
    ApiService apiService = ApiService();
    List<Photo> response =
        await apiService.fetchImagesByPlaceId(widget.place.id.toString());

    setState(() {
      photos = response;
    });
  }

  Future<void> fetchReviews() async {
    try {
      ApiService apiService = ApiService();
      List<dynamic> response = await apiService.fetchReviewsByPlaceId(
        widget.place.id.toString(),
        0,
        !isSortedByDate, // Utiliser l'inverse de isSortedByDate pour likeOrDate
      );

      List<Review> newReviews =
          response.map((e) => Review.fromJson(e)).toList();

      bool alreadyPosted = false;
      for (var review in newReviews) {
        var userId = review.userId;
        if (review.user_is_author == true && review.parentId == null) {
          alreadyPosted = true;
        }
        if (userId.isNotEmpty) {
          var profileData = await apiService.getProfile(userId: userId);

          if (profileData['success'] == true) {
            review.updateProfileInfo(profileData['pseudo'] ?? 'Utilisateur',
                profileData['profile_image']);
          }
        }
      }

      setState(() {
        reviews = newReviews;
        hasAlreadyPostedReview = alreadyPosted;
      });
    } catch (e) {
      print('Erreur lors de la récupération des avis : $e');
    }
  }

  void toggleSortOrder() {
    setState(() {
      isSortedByDate = !isSortedByDate; // Basculer entre tri par date et par likes
      fetchReviews(); // Recharger les avis avec le nouveau tri
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          IconButton(
            icon: Icon(isSortedByDate ? Icons.date_range : Icons.thumb_up),
            onPressed: toggleSortOrder, // Basculer le tri
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _fetchReviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ListTile(
                  title: Text(review.comment),
                  subtitle: Text(
                      'Likes: ${review.likes}, Date: ${review.date.toLocal()}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class TagSelectionDialog extends StatefulWidget {
  final Set<String> existingTags;

  const TagSelectionDialog({Key? key, required this.existingTags})
      : super(key: key);

  @override
  _TagSelectionDialogState createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  final TextEditingController _controller = TextEditingController();
  String? selectedTag;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un tag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.existingTags.map((tag) => ListTile(
                  title: Text(tag),
                  onTap: () => Navigator.of(context).pop(tag),
                )),
            const Divider(),
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nouveau tag',
                hintText: 'Entrez un nouveau tag',
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Voici le bouton à remplacer
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop("NO_TAG"), // Au lieu de null
          child: const Text('Sans tag'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Créer'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Add this helper function to parse opening hours
List<Map<String, String>> _parseOpeningHours(String openingHours) {
  const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  final result = <Map<String, String>>[];

  // Split the opening_hours string into individual segments
  final segments = openingHours.split(';');
  final dayHoursMap = <String, String>{};

  for (final segment in segments) {
    final regex = RegExp(r'([A-Za-z]{2})(?:-([A-Za-z]{2}))?\s([\d:, -]+|off)');
    final match = regex.firstMatch(segment.trim());

    if (match != null) {
      final startDay = match.group(1);
      final endDay = match.group(2);
      final hours = match.group(3);

      if (hours == 'off') {
        if (endDay != null) {
          final startIndex = days.indexOf(startDay!);
          final endIndex = days.indexOf(endDay);

          for (int i = startIndex; i <= endIndex; i++) {
            dayHoursMap[days[i]] = 'fermé';
          }
        } else {
          dayHoursMap[startDay!] = 'fermé';
        }
      } else {
        if (endDay != null) {
          final startIndex = days.indexOf(startDay!);
          final endIndex = days.indexOf(endDay);

          for (int i = startIndex; i <= endIndex; i++) {
            dayHoursMap[days[i]] = hours!;
          }
        } else {
          dayHoursMap[startDay!] = hours!;
        }
      }
    } else {
      logger.d('No match for segment: $segment');
    }
  }

  // Populate result for all days
  for (final day in days) {
    result.add({
      'day': _dayToFrench(day),
      'hours': dayHoursMap[day] ?? 'fermé',
    });
  }
  return result;
}

// Add this helper function to translate days to French
String _dayToFrench(String day) {
  switch (day) {
    case 'Mo':
      return 'Lundi';
    case 'Tu':
      return 'Mardi';
    case 'We':
      return 'Mercredi';
    case 'Th':
      return 'Jeudi';
    case 'Fr':
      return 'Vendredi';
    case 'Sa':
      return 'Samedi';
    case 'Su':
      return 'Dimanche';
    default:
      return day;
  }
}
