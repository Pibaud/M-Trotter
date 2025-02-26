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
  final String username;
  final Uint8List? profilePicBytes;
  final String comment;
  int likes;
  bool isLiked;
  final DateTime date;
  int rating;
  final String placeTable;

  Review(
      {required this.id,
      this.parentId,
      required this.username,
      required this.profilePicBytes,
      required this.comment,
      required this.likes,
      this.isLiked = false,
      required this.date,
      this.rating = 0,
      required this.placeTable});

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
        date: DateTime.parse(json['created_at']),
        rating: json['nb_etoiles'] ?? 0,
        placeTable: json['place_table']);
  }

  @override
  String toString() {
    return 'Review{id: $id, parentId: $parentId, username: $username, profilePicBytes: $profilePicBytes, comment: $comment, likes: $likes, isLiked: $isLiked, date: $date, rating: $rating, placeTable: $placeTable}';
  }
}

class PlaceInfoSheet extends StatefulWidget {
  final double height;
  final Function(double)? onDragUpdate;
  final Function()? onDragEnd;
  final Place place;
  final Function()? onItineraryTap;
  final Function()? onCallTap;
  final Function()? onWebsiteTap;
  final Function()? onClose;
  final List<Photo> photos; // Add this line

  const PlaceInfoSheet({
    Key? key,
    this.height = 400,
    this.onDragUpdate,
    this.onDragEnd,
    required this.place,
    this.onItineraryTap,
    this.onCallTap,
    this.onWebsiteTap,
    this.onClose,
    required this.photos, // Add this line
  }) : super(key: key);

  @override
  _PlaceInfoSheetState createState() => _PlaceInfoSheetState();
}

class _PlaceInfoSheetState extends State<PlaceInfoSheet> {
  List<Review> reviews = [];
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

  late Future<void> _fetchReviewsFuture;

  @override
  void initState() {
    super.initState();
    _fetchReviewsFuture = fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      ApiService apiService = ApiService();
      List<dynamic> response = await apiService.fetchReviewsByPlaceId(
          widget.place.id.toString(),
          0); //incrémenter le startid pour obtenir les avis suivants

      setState(() {
        reviews = // Convertir la liste de Map en liste de Review
            response.map((e) => Review.fromJson(e)).toList();
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
        review.likes--;
      } else {
        review.likes++;
      }
      review.isLiked = !review.isLiked;
    });
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey);
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

  void addReview(String text, int rating) {
    setState(() {});
  }

  void addReply(String text, String parentId) {}

  void updateLikes(String reviewId) {
    setState(() {
      for (var review in reviews) {
        if (review.id == reviewId) {
          review.likes += 1;
        }
      }
    });
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        requestFullMetadata: false,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();

        if (!mounted) return;

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

            // Ajouter la photo à la liste après l'upload réussi
            setState(() {
              widget.photos.add(Photo(
                imageData: imageBytes,
                tag: tag == "NO_TAG" ? null : tag,
              ));
              if (tag != "NO_TAG") allTags.add(tag);
            });
          } catch (e) {
            print('Erreur lors de l\'upload de l\'image : $e');
          }
        }
      }
    } catch (e) {
      print("Erreur lors de la prise de photo : $e");
    }
  }

// Fonction pour afficher le dialogue de choix
  void showImageSourceDialog() {
    showDialog(
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
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
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

            // Afficher le champ de texte pour répondre si on répond à cette réponse (replyingTo)
            if (replyingTo == reply.id)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: TextField(
                  onChanged: (value) => setState(() => replyText = value),
                  decoration: InputDecoration(
                    hintText: "Votre réponse...",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: replyText.isEmpty
                          ? null
                          : () {
                              addReply(replyText, reply.id);
                              setState(() {
                                replyText =
                                    ''; // Réinitialiser le texte après envoi
                              });
                            },
                    ),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
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
                              child: Row(
                                children: [
                                  Text(
                                    widget.place.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.place.avgStars
                                        .toString(), // Display avgStars
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStars(widget
                                      .place.avgStars), // Star rating indicator
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${widget.place.numReviews})', // Number of reviews
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
                          ],
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: widget.onItineraryTap,
                              child: const Text('Itinéraire'),
                            ),
                            TextButton(
                              onPressed: widget.onCallTap,
                              child: const Text('Appeler'),
                            ),
                            TextButton(
                              onPressed: widget.onWebsiteTap,
                              child: const Text('Site Web'),
                            ),
                          ],
                        ),
                      ),

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
                            : buildPhotosSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => widget.onClose!(),
                child: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ],
        ),
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
                onChanged: (value) => setState(() => newReviewText = value),
                decoration: InputDecoration(
                  hintText: "Écrire un avis...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: newReviewText.isEmpty
                        ? null
                        : () {
                            if (newReviewRating == 0) {
                              setState(() => ratingError =
                                  "Veuillez attribuer au moins une étoile.");
                            } else {
                              addReview(newReviewText, newReviewRating);
                              setState(() {
                                newReviewText = "";
                                newReviewRating = 0;
                                ratingError = "";
                              });
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < newReviewRating ? Icons.star : Icons.star_border,
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
                      icon: const Icon(Icons.sort),
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
                              onPressed: () =>
                                  setState(() => replyingTo = review.id),
                              child: const Text("Répondre"),
                            ),
                          if (replyingTo == review.id)
                            TextField(
                              onChanged: (value) =>
                                  setState(() => replyText = value),
                              decoration: InputDecoration(
                                hintText: "Votre réponse...",
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: replyText.isEmpty
                                      ? null
                                      : () => addReply(replyText, review.id),
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
        backgroundColor: Colors.grey[300], // Fond gris si pas d'image
        child: review.profilePicBytes == null
            ? const Icon(Icons.person, color: Colors.white) // Icône grisée
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
                  Icons.thumb_up,
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
        ? widget.photos // Use widget.photos instead of photos
        : widget.photos.where((photo) => photo.tag == selectedTag).toList();

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
                          Icon(Icons.photo_library_outlined,
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
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: InteractiveViewer(
                                    child: Image.memory(photo.imageData,
                                        fit: BoxFit.contain),
                                  ),
                                ),
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
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ],
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
