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
  bool isSortedByDate = true;
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
  bool showOpeningHours = false; // State to toggle opening hours visibility

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
      List<dynamic> response =
          await apiService.fetchReviewsByPlaceId(widget.place.id.toString(), 0);

      List<Review> newReviews =
          response.map((e) => Review.fromJson(e)).toList();

      // Pour chaque avis, récupérez les informations de profil
      for (var review in newReviews) {
        var userId = review.userId;
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
      });
    } catch (e) {
      print('Erreur lors de la récupération des avis : $e');
    }
  }

  void selectRating(int rating) {
    setState(() {
      newReviewRating = rating;
      ratingError = ""; // Efface l'erreur si une note est choisie
    });
  }

  void toggleLike(Review review) {
    setState(() {
      if (review.isLiked) {
        _apiService.unlikeAvis(review.id);
        review.likes--;
      } else {
        _apiService.likeAvis(review.id);
        review.likes++;
      }
      review.isLiked = !review.isLiked;
    });
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107));
        } else {
          return const Icon(Icons.star_border_rounded, color: Colors.grey);
        }
      }),
    );
  }

  void toggleSortOrder() {
    setState(() {
      isSortedByDate = !isSortedByDate;
      if (isSortedByDate) {
        reviews.sort((a, b) =>
            b.date.compareTo(a.date)); // Trier par date, du plus récent
      } else {
        reviews.sort((a, b) =>
            b.likes.compareTo(a.likes)); // Trier par likes, du plus grand
      }
    });
  }

  void postReview(String text, {int? rating, int? parentId}) async {
    if (rating != null) {
      try {
        ApiService apiService = ApiService();
        File? imageFile;
        if (reviewPhotos.isNotEmpty) {
          imageFile = reviewPhotos.first;
          try {
            final uploadResponse = await apiService.uploadImage(
                imageFile, widget.place.id.toString());
            if (uploadResponse['success']) {
              print('Image uploaded successfully');
            } else {
              print('Error uploading image: ${uploadResponse['error']}');
            }
          } catch (e) {
            print('Error during image upload: $e');
          }
        }
        final response = await apiService.postReview(
          placeId: widget.place.id.toString(),
          placeTable: widget.place.placeTable,
          comment: text,
          rating: rating,
        );

        if (response['success']) {
          print('Avis posté avec succès');
          await fetchReviews();
        } else {
          print(
              'Erreur lors de la publication de l\'avis : ${response['error']}');
        }
      } catch (e) {
        print('Erreur du try de apiservice avec note: $e');
      }
    } else {
      setState(() {
        replySent = true;
      });
      try {
        ApiService apiService = ApiService();
        final response = await apiService.postReview(
          placeId: widget.place.id.toString(),
          placeTable: widget.place.placeTable,
          comment: text,
          parentId: parentId,
        );

        if (response['success']) {
          print('Réponse postée avec succès');
          await fetchReviews();
        } else {
          print(
              'Erreur lors de la publication de l\'avis : ${response['error']}');
        }
      } catch (e) {
        print('Erreur du try de apiservice sans note: $e');
      }
    }
  }

  void updateLikes(String reviewId) {
    setState(() {
      for (var review in reviews) {
        if (review.id == reviewId) {
          review.likes += 1;
        }
      }
    });
  }

  Future<void> pickImage(ImageSource source, {bool? isReview}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        requestFullMetadata: false,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();

        if (!mounted) return;

        if (isReview == true) {
          // Add the photo to reviewPhotos without tag selection
          setState(() {
            reviewPhotos.add(File(image.path));
          });
        } else {
          String? tag = await showDialog<String>(
            context: context,
            builder: (context) => TagSelectionDialog(existingTags: allTags),
          );

          if (!mounted) return;

          if (tag != null) {
            // Appeler la fonction uploadImage après avoir sélectionné le tag
            try {
              ApiService apiService = ApiService();
              File imageFile = File(image.path); // Convertir XFile en File
              String placeId =
                  widget.place.id.toString(); // Convert int to String

              Map<String, dynamic> response =
                  await apiService.uploadImage(imageFile, placeId);

              print('Image upload response: $response');
              if (response['message'] == "Photo enregistrée") {
                await fetchPhotos();
                print('Image uploaded successfully with tag: $tag');
              } else {
                print('Error uploading image with tag: ${response['error']}');
              }
            } catch (e) {
              print('Erreur lors de l\'upload de l\'image : $e');
            }
          }
        }
      }
    } catch (e) {
      print("Erreur lors de la prise de photo : $e");
    }
  }

// Fonction pour afficher le dialogue de choix
  void showImageSourceDialog({bool? isReview}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery,
                      isReview: isReview == true ? true : false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera,
                      isReview: isReview == true ? true : false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fonction récursive pour afficher les réponses
  Widget _buildReplies(List<Review> replies, bool isLastReply) {
    return Column(
      children: replies.asMap().entries.map((entry) {
        int index = entry.key;
        Review reply = entry.value;

        // Récupérer les réponses imbriquées (niveaux inférieurs)
        List<Review> nestedReplies =
            reviews.where((r) => r.parentId == reply.id).toList();

        return Column(
          children: [
            // Afficher la réponse actuelle avec un décalage si elle est imbriquée
            Padding(
              padding:
                  EdgeInsets.only(left: reply.parentId != null ? 20.0 : 0.0),
              // Décalage uniquement pour les réponses imbriquées
              child: _buildReviewItem(reply),
            ),

            // Si la réponse a des réponses imbriquées, les afficher
            if (nestedReplies.isNotEmpty) ...[
              _buildReplies(nestedReplies, false),
              // Affichage récursif des réponses imbriquées
            ],

            // Ajouter le bouton "Répondre" seulement après la dernière réponse d'un avis principal
            if (index == replies.length - 1 && isLastReply)
              TextButton(
                onPressed: () => setState(() {
                  replyingTo = reply
                      .id; // On définit quel avis on est en train de répondre
                }),
                child: const Text("Répondre"),
              ),
          ],
        );
      }).toList(),
    );
  }

  void deleteReview(String reviewId) async {
    try {
      ApiService apiService = ApiService();
      final response = await apiService.deleteReview(reviewId);

      if (response['success']) {
        print('Avis supprimé avec succès');
        await fetchReviews();
      } else {
        print(
            'Erreur lors de la suppression de l\'avis : ${response['error']}');
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'avis : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) =>
            widget.onDragUpdate?.call(details.delta.dy),
        onVerticalDragEnd: (_) => widget.onDragEnd?.call(),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: widget.height - MediaQuery.of(context).viewInsets.bottom,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12, // Updated shadow color
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              // Wrap le Column dans un SingleChildScrollView
              child: SingleChildScrollView(
                child: SizedBox(
                  height:
                      widget.height - MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40.0,
                        height: 6.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.place.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                                maxLines: 2, // Limite à 2 lignes
                                overflow: TextOverflow
                                    .ellipsis, // Ajoute "..." si le texte dépasse
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                    widget.place.avgStars.toString(),
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStars(widget.place.avgStars),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${widget.place.numReviews})',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.place.amenity ?? '',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ),
                            // New code to display open/close status
                            if (widget.place.tags['opening_hours'] != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final now = DateTime.now();
                                        final openingHours = _parseOpeningHours(
                                            widget
                                                .place.tags['opening_hours']!);
                                        final today = _dayToFrench(
                                            DateFormat('E', 'en_US')
                                                .format(now)
                                                .substring(0, 2));
                                        final currentDayHours =
                                            openingHours.firstWhere(
                                          (entry) => entry['day'] == today,
                                          orElse: () =>
                                              {'day': today, 'hours': 'fermé'},
                                        );

                                        if (currentDayHours['hours'] ==
                                            'fermé') {
                                          // Check if it opens tomorrow
                                          final tomorrow = _dayToFrench(
                                              DateFormat('E', 'en_US')
                                                  .format(now
                                                      .add(Duration(days: 1)))
                                                  .substring(0, 2));
                                          final tomorrowHours =
                                              openingHours.firstWhere(
                                            (entry) => entry['day'] == tomorrow,
                                            orElse: () => {
                                              'day': tomorrow,
                                              'hours': 'fermé'
                                            },
                                          );

                                          if (tomorrowHours['hours'] !=
                                              'fermé') {
                                            final openingTime =
                                                tomorrowHours['hours']!
                                                    .split('-')
                                                    .first
                                                    .trim();
                                            return Text(
                                              'Fermé (ouvre demain à $openingTime)',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red),
                                            );
                                          }

                                          for (int i = 2; i <= 7; i++) {
                                            final nextDay = _dayToFrench(
                                                DateFormat('E', 'en_US')
                                                    .format(now
                                                        .add(Duration(days: i)))
                                                    .substring(0, 2));
                                            final nextDayHours =
                                                openingHours.firstWhere(
                                              (entry) =>
                                                  entry['day'] == nextDay,
                                              orElse: () => {
                                                'day': nextDay,
                                                'hours': 'fermé'
                                              },
                                            );
                                            if (nextDayHours['hours'] !=
                                                'fermé') {
                                              final openingTime =
                                                  nextDayHours['hours']!
                                                      .split('-')
                                                      .first
                                                      .trim();
                                              return Text(
                                                'Fermé (ouvre $nextDay à $openingTime)',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red),
                                              );
                                            }
                                          }
                                          return const Text(
                                            'Fermé',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.red),
                                          );
                                        } else {
                                          final hours =
                                              currentDayHours['hours']!
                                                  .split('-');
                                          final openingTime =
                                              DateFormat('HH:mm')
                                                  .parse(hours.first.trim());
                                          final closingTime =
                                              DateFormat('HH:mm')
                                                  .parse(hours.last.trim());

                                          final openingDateTime = DateTime(
                                              now.year,
                                              now.month,
                                              now.day,
                                              openingTime.hour,
                                              openingTime.minute);
                                          final closingDateTime = DateTime(
                                              now.year,
                                              now.month,
                                              now.day,
                                              closingTime.hour,
                                              closingTime.minute);

                                          if (now.isAfter(openingDateTime) &&
                                              now.isBefore(closingDateTime)) {
                                            return Text(
                                              'Ouvert (ferme à ${hours.last.trim()})',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.green),
                                            );
                                          } else if (now
                                              .isBefore(openingDateTime)) {
                                            return Text(
                                              'Fermé (ouvre à ${hours.first.trim()})',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red),
                                            );
                                          }
                                        }

                                        return const Text(
                                          'Fermé',
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.red),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        showOpeningHours
                                            ? Icons.expand_more_rounded
                                            : Icons.chevron_right_rounded,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showOpeningHours = !showOpeningHours;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            // New code to display opening hours
                            if (widget.place.tags['opening_hours'] != null &&
                                showOpeningHours)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _parseOpeningHours(
                                          widget.place.tags['opening_hours']!)
                                      .map((entry) => Text(
                                            '${entry['day']}: ${entry['hours']}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600]),
                                          ))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Action buttons
                      buildActionButtons(),

                      const Divider(
                          thickness: 1, height: 1, color: Colors.grey),

                      // Toggle buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => showReviews = true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      showReviews ? Colors.white : Colors.black,
                                  backgroundColor: showReviews
                                      ? Colors.blue
                                      : Colors.transparent,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text("Avis"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => showReviews = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      showReviews ? Colors.black : Colors.white,
                                  backgroundColor: showReviews
                                      ? Colors.transparent
                                      : Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text("Photos"),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content section
                      Expanded(
                        child: showReviews
                            ? FutureBuilder<void>(
                                future: _fetchReviewsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Erreur: ${snapshot.error}'));
                                  } else {
                                    return buildReviewsSection();
                                  }
                                },
                              )
                            : FutureBuilder<void>(
                                future: _fetchPhotosFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Erreur: ${snapshot.error}'));
                                  } else {
                                    return buildPhotosSection();
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isFavorite ? Color(0xFF147FD6) : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  const SizedBox(
                      width:
                          0), // Augmenter ou réduire la valeur pour ajuster l'espacement
                  GestureDetector(
                    onTap: () => widget.onClose!(),
                    child: const Icon(Icons.close_rounded, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButtons() {
    int nbPossibleActions = 1; // Default actions: Itinéraire and Infos
    if (widget.place.tags['phone'] != null) nbPossibleActions++;
    if (widget.place.tags['website'] != null) nbPossibleActions++;

    double horizontalPadding = 20.0 / nbPossibleActions;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton(
            onPressed: widget.onItineraryTap,
            style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF147FD6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                side: BorderSide.none,
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 5.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Itinéraire"),
                const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 24),
              ],
            ),
          ),
          if (widget.place.tags['phone'] != null)
            OutlinedButton(
              onPressed: widget.onCallTap,
              style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEBEBEB),
                  foregroundColor: const Color(0xFF147FD6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  side: BorderSide.none,
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 5.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Appeler"),
                  const Icon(Icons.call_rounded,
                      color: Color(0xFF147FD6), size: 24),
                ],
              ),
            ),
          if (widget.place.tags['website'] != null)
            OutlinedButton(
              onPressed: widget.onWebsiteTap,
              style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEBEBEB),
                  foregroundColor: const Color(0xFF147FD6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  side: BorderSide.none,
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 5.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Site Web"),
                  const Icon(Icons.language_rounded,
                      color: Color(0xFF147FD6), size: 24),
                ],
              ),
            ),
          OutlinedButton(
            onPressed: () {
              widget.onInfosTap!();
            },
            style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFEBEBEB),
                foregroundColor: const Color(0xFF147FD6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                side: BorderSide.none,
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 5.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Infos"),
                const Icon(Icons.info_rounded,
                    color: Color(0xFF147FD6), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReviewsSection() {
    List<Review> mainReviews =
        reviews.where((r) => r.parentId == null).toList();
    if (isSortedByDate) {
      mainReviews.sort((a, b) => b.date.compareTo(a.date));
    } else {
      mainReviews.sort((a, b) => b.likes.compareTo(a.likes));
    }

    return Column(
      children: [
        // Review input section
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reviewController,
                onChanged: (value) => setState(() => newReviewText = value),
                decoration: InputDecoration(
                  hintText: "Écrire un avis...",
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_rounded),
                        onPressed: () {
                          showImageSourceDialog(isReview: true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: newReviewText.isEmpty
                            ? null
                            : () {
                                if (newReviewRating == 0) {
                                  setState(() => ratingError =
                                      "Veuillez attribuer au moins une étoile.");
                                } else {
                                  postReview(newReviewText,
                                      rating: newReviewRating, parentId: null);
                                  setState(() {
                                    newReviewText = "";
                                    newReviewRating = 0;
                                    ratingError = "";
                                    reviewPhotos.clear();
                                    _reviewController.clear();
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < newReviewRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color:
                          index < newReviewRating ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => setState(() {
                      newReviewRating = index + 1;
                      ratingError = "";
                    }),
                  );
                }),
              ),
              if (ratingError.isNotEmpty)
                Text(
                  ratingError,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              if (reviewPhotos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(reviewPhotos.length, (index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.memory(
                                File(reviewPhotos[index].path)
                                    .readAsBytesSync(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: -10,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    reviewPhotos.removeAt(index);
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Avis",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: toggleSortOrder,
                      icon: const Icon(Icons.sort_rounded),
                      label: Text(isSortedByDate
                          ? "Trier par likes"
                          : "Trier par date"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: mainReviews.length,
                  itemBuilder: (context, index) {
                    Review review = mainReviews[index];
                    List<Review> replies =
                        reviews.where((r) => r.parentId == review.id).toList();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReviewItem(review),
                          if (replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: _buildReplies(replies, true),
                            ),
                          if (replies.isEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  newReviewText = "";
                                  replyingTo = review.id;
                                  replySent = false;
                                });
                              },
                              child: const Text("Répondre"),
                            ),
                          if (replyingTo == review.id && !replySent)
                            TextField(
                              onChanged: (value) =>
                                  setState(() => replyText = value),
                              decoration: InputDecoration(
                                hintText: "Votre réponse...",
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send_rounded),
                                  onPressed: replyText.isEmpty
                                      ? null
                                      : () => postReview(replyText,
                                          rating: null,
                                          parentId: int.tryParse(review.id)),
                                ),
                              ),
                            ),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[300], // Fond gris si pas d'image
        child: review.profilePicBytes == null
            ? const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 30,
              ) // Icône grisée
            : null,
        backgroundImage: review.profilePicBytes != null
            ? MemoryImage(review.profilePicBytes!) // Affichage de l'image
            : null, // Si pas d'image, on ne met pas de backgroundImage
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (review.parentId == null) _buildStars(review.rating.toDouble()),
          // Afficher étoiles si avis principal
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(review.comment),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up_rounded,
                  color: review.isLiked ? Colors.blue : Colors.grey,
                ),
                onPressed: () => toggleLike(review),
              ),
              Text('${review.likes}'),
              const SizedBox(width: 10), // Espacement
              Text(
                DateFormat('dd/MM/yyyy').format(review.date),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPhotosSection() {
    List<Photo> filteredPhotos = selectedTag == null
        ? photos // Use widget.photos instead of photos
        : photos.where((photo) => photo.tag == selectedTag).toList();

    return Stack(
      children: [
        Column(
          children: [
            // Section des tags
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      backgroundColor:
                          selectedTag == null ? Colors.blue : Colors.white,
                      label: Text(
                        'Tous',
                        style: TextStyle(
                            color: selectedTag == null
                                ? Colors.white
                                : Colors.black),
                      ),
                      onSelected: (_) => setState(() => selectedTag = null),
                      selected: selectedTag == null,
                    ),
                  ),
                  ...allTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          backgroundColor:
                              selectedTag == tag ? Colors.blue : Colors.white,
                          label: Text(
                            tag,
                            style: TextStyle(
                                color: selectedTag == tag
                                    ? Colors.white
                                    : Colors.black),
                          ),
                          onSelected: (_) => setState(() => selectedTag = tag),
                          selected: selectedTag == tag,
                        ),
                      )),
                ],
              ),
            ),

            // Grille de photos
            Expanded(
              child: filteredPhotos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_rounded,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            "Aucune photo${selectedTag != null ? ' avec ce tag' : ' ajoutée'}",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: filteredPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = filteredPhotos[index];
                        return GestureDetector(
                          onTap: () {
                            int voteCount = 0; // Initialize vote counter
                            int initialVote = 0; // Track initial state
                            bool hasUpvoted = false;
                            bool hasDownvoted = false;

                            showDialog(
                              context: context,
                              builder: (dialogContext) => StatefulBuilder(
                                builder: (context, setDialogState) {
                                  // Initialize vote state based on photo.vote
                                  if (voteCount == 0) {
                                    if (photo.vote != null) {
                                      voteCount = photo.vote!;
                                      initialVote = voteCount;
                                      // Correctly set up/down vote state based on the vote value
                                      hasUpvoted = photo.vote == 1;
                                      hasDownvoted = photo.vote == -1;
                                      // photo.vote == 0 means no vote (neither up nor down)
                                    } else {
                                      // If photo.vote is null, assume no vote (set to 0)
                                      voteCount = 0;
                                      initialVote = 0;
                                      hasUpvoted = false;
                                      hasDownvoted = false;
                                    }
                                  }

                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Image with InteractiveViewer
                                        GestureDetector(
                                          onTap: () {
                                            // Send the vote before closing
                                            if (initialVote != voteCount) {
                                              // Only call if vote changed
                                              upOrDownvote(voteCount, photo.id);
                                            }
                                            Navigator.pop(dialogContext);
                                          },
                                          child: InteractiveViewer(
                                            child: Image.memory(photo.imageData,
                                                fit: BoxFit.contain),
                                          ),
                                        ),

                                        // Vote UI in top right
                                        Positioned(
                                          top: 20,
                                          right: 20,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.arrow_upward_rounded,
                                                    color: hasUpvoted
                                                        ? Colors.blue
                                                        : Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      print(
                                                          "hasUpvoted : $hasUpvoted, hasDownvoted : $hasDownvoted");
                                                      if (hasUpvoted) {
                                                        // Cancel upvote
                                                        voteCount--;
                                                        hasUpvoted = false;
                                                        print(
                                                            "vote cancelled, vote count : $voteCount, hasUpvoted : $hasUpvoted");
                                                      } else {
                                                        // Add upvote
                                                        print("Upvote");
                                                        voteCount++;
                                                        // If was downvoted before, remove that too
                                                        if (hasDownvoted) {
                                                          voteCount++;
                                                          hasDownvoted = false;
                                                        }
                                                        hasUpvoted = true;
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  '$voteCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .arrow_downward_rounded,
                                                    color: hasDownvoted
                                                        ? Colors.red
                                                        : Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      if (hasDownvoted) {
                                                        // Cancel downvote
                                                        voteCount++;
                                                        hasDownvoted = false;
                                                      } else {
                                                        // Add downvote
                                                        voteCount--;
                                                        // If was upvoted before, remove that too
                                                        if (hasUpvoted) {
                                                          voteCount--;
                                                          hasUpvoted = false;
                                                        }
                                                        hasDownvoted = true;
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Close button
                                        Positioned(
                                          top: 20,
                                          left: 20,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.white),
                                            onPressed: () {
                                              // Check if we need to delete the vote
                                              if (photo.vote != 0 &&
                                                  voteCount == 0) {
                                                // User had a vote that was canceled
                                                deleteVote(photo.id);
                                              } else if (initialVote !=
                                                  voteCount) {
                                                // User changed their vote
                                                upOrDownvote(
                                                    voteCount, photo.id);
                                              }
                                              Navigator.pop(dialogContext);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  photo.imageData,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (photo.tag != null)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      photo.tag!,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: showImageSourceDialog,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void upOrDownvote(int voteType, int idImage) async {
    try {
      // Log the vote action for debugging
      logger.d('Submitting vote: $voteType for image ID: $idImage');
      await _apiService.voteForImage(idImage, voteType);
    } catch (e) {
      logger.e('Exception when submitting vote: $e');
    }
  }

  // New function to delete a vote for an image
  Future<void> deleteVote(int idImage) async {
    try {
      logger.d('Deleting vote for image ID: $idImage');
      final result = await _apiService.deletePhotoVote(idImage);
      if (result['success']) {
        logger.d('Vote deleted successfully');
      } else {
        logger.e('Failed to delete vote: ${result['error']}');
      }
    } catch (e) {
      logger.e('Exception when deleting vote: $e');
    }
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
