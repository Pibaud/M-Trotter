import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

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
  });

  // Factory pour créer un Review depuis un JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      parentId: json['parentId'],
      username: json['username'],
      profilePicBytes: json['profilePicBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['profilePicBytes']))
          : null, // Convertir en Uint8List si non null
      comment: json['comment'],
      likes: json['likes'] ?? 0,
      date: DateTime.parse(json['date']),
      rating: json['rating'] ?? 0,
    );
  }
}

class Photo {
  final Uint8List imageData;
  final String? tag;

  Photo({required this.imageData, this.tag});
}

class PlaceInfoSheet extends StatefulWidget {
  final double height;
  final Function(double)? onDragUpdate;
  final Function()? onDragEnd;
  final String placeName;
  final String placeType;
  final Function()? onItineraryTap;
  final Function()? onCallTap;
  final Function()? onWebsiteTap;
  final Function()? onClose;

  const PlaceInfoSheet({
    Key? key,
    this.height = 400,
    this.onDragUpdate,
    this.onDragEnd,
    required this.placeName,
    required this.placeType,
    this.onItineraryTap,
    this.onCallTap,
    this.onWebsiteTap,
    this.onClose,
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
  List<Photo> photos = [];
  Set<String> allTags = {};
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // Fonction pour récupérer les avis depuis l'API
  void fetchReviews() async {
    try {
      // Simule un appel API (remplace avec un vrai appel HTTP)
      await Future.delayed(const Duration(seconds: 2)); // Simule un délai API
      List<Map<String, dynamic>> response = [
        {
          "id": "1",
          "parentId": null,
          "username": "Alice",
          "profilePicBytes": null,
          "comment": "Super endroit !",
          "likes": 5,
          "date": "2025-02-08T12:30:00",
          "rating": 5
        },
        {
          "id": "2",
          "parentId": "1",
          "username": "Bob",
          "profilePicBytes": null,
          "comment": "Je suis d’accord !",
          "likes": 2,
          "date": "2025-02-09T10:00:00"
        },
        {
          "id": "3",
          "parentId": null,
          "username": "Charlie",
          "profilePicBytes": null,
          "comment": "Moyen...",
          "likes": 1,
          "date": "2025-02-10T09:00:00",
          "rating": 3
        },
        {
          "id": "4",
          "parentId": null,
          "username": "David",
          "profilePicBytes": null,
          "comment": "Lieu très propre et agréable.",
          "likes": 7,
          "date": "2025-02-07T14:15:00",
          "rating": 4
        },
        {
          "id": "5",
          "parentId": "3",
          "username": "Eve",
          "profilePicBytes": null,
          "comment": "J'ai trouvé ça plutôt sympa aussi.",
          "likes": 3,
          "date": "2025-02-10T10:20:00"
        },
        {
          "id": "6",
          "parentId": null,
          "username": "Frank",
          "profilePicBytes": null,
          "comment": "Pas terrible... je ne reviendrai pas.",
          "likes": 0,
          "date": "2025-02-06T18:45:00",
          "rating": 1
        },
        {
          "id": "7",
          "parentId": null,
          "username": "Grace",
          "profilePicBytes": null,
          "comment": "Endroit génial ! Je recommande.",
          "likes": 9,
          "date": "2025-02-05T20:30:00",
          "rating": 5
        },
        {
          "id": "8",
          "parentId": "6",
          "username": "Hugo",
          "profilePicBytes": null,
          "comment": "Je suis d'accord, pas ouf...",
          "likes": 2,
          "date": "2025-02-06T19:00:00"
        },
        {
          "id": "9",
          "parentId": null,
          "username": "Isabelle",
          "profilePicBytes": null,
          "comment": "Mauvais rapport qualité-prix.",
          "likes": 4,
          "date": "2025-02-04T15:10:00",
          "rating": 2
        },
        {
          "id": "10",
          "parentId": null,
          "username": "Jack",
          "profilePicBytes": null,
          "comment": "Très bon accueil, personnel sympa.",
          "likes": 6,
          "date": "2025-02-03T17:50:00",
          "rating": 4
        },
        {
          "id": "11",
          "parentId": "8",
          "username": "Vincent",
          "profilePicBytes": null,
          "comment": "Pas trop d'accord avec vous",
          "likes": 2,
          "date": "2025-02-07T19:00:00"
        },
      ];

      setState(() {
        reviews = response.map((json) => Review.fromJson(json)).toList();
      });
    } catch (e) {
      print("Erreur lors de la récupération des avis : $e");
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

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          // Étoile pleine ou vide
          color: index < rating ? Colors.amber : Colors.grey,
        );
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
    setState(() {
      reviews.add(Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: null,
        username: "Moi",
        profilePicBytes: null,
        comment: text,
        likes: 0,
        date: DateTime.now(),
        rating: rating,
      ));
      newReviewText = '';
      newReviewRating = 0;
    });
  }

  void addReply(String text, String parentId) {
    setState(() {
      reviews.add(Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        username: "Moi",
        profilePicBytes: null,
        comment: text,
        likes: 0,
        date: DateTime.now(),
      ));
      replyingTo = null;
      replyText = '';
    });
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
          setState(() {
            photos.add(Photo(
              imageData: imageBytes,
              tag: tag == "NO_TAG" ? null : tag,
            ));
            if (tag != "NO_TAG") allTags.add(tag);
          });
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          // Ajout du MediaQuery pour gérer le clavier
          height: widget.height - MediaQuery.of(context).viewInsets.bottom,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          // Wrap le Column dans un SingleChildScrollView
          child: SingleChildScrollView(
            child: SizedBox(
              height: widget.height - MediaQuery.of(context).viewInsets.bottom,
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

                  // Place info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.placeName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          widget.placeType,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
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

                  const Divider(thickness: 1, height: 1, color: Colors.grey),

                  // Toggle buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => showReviews = true),
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
                        ? buildReviewsSection()
                        : buildPhotosSection(),
                  ),
                ],
              ),
            ),
          ),
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
                child: mainReviews.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: mainReviews.length,
                        itemBuilder: (context, index) {
                          Review review = mainReviews[index];
                          List<Review> replies = reviews
                              .where((r) => r.parentId == review.id)
                              .toList();

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                            : () =>
                                                addReply(replyText, review.id),
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
          if (review.parentId == null) _buildStars(review.rating),
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
        ? photos
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
