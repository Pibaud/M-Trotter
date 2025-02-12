import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      profilePicBytes: json['profilePicBytes'],
      comment: json['comment'],
      likes: json['likes'] ?? 0,
      date: DateTime.parse(json['date']),
      rating: json['rating'] ?? 0,
    );
  }
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
        {"id": "1", "parentId": null, "username": "Alice", "profilePicBytes": null, "comment": "Super endroit !", "likes": 5, "date": "2025-02-08T12:30:00", "rating": 5},
        {"id": "2", "parentId": "1", "username": "Bob", "profilePicBytes": null, "comment": "Je suis d’accord !", "likes": 2, "date": "2025-02-09T10:00:00"},
        {"id": "3", "parentId": null, "username": "Charlie", "profilePicBytes": null, "comment": "Moyen...", "likes": 1, "date": "2025-02-10T09:00:00", "rating": 3},
        {"id": "4", "parentId": null, "username": "David", "profilePicBytes": null, "comment": "Lieu très propre et agréable.", "likes": 7, "date": "2025-02-07T14:15:00", "rating": 4},
        {"id": "5", "parentId": "3", "username": "Eve", "profilePicBytes": null, "comment": "J'ai trouvé ça plutôt sympa aussi.", "likes": 3, "date": "2025-02-10T10:20:00"},
        {"id": "6", "parentId": null, "username": "Frank", "profilePicBytes": null, "comment": "Pas terrible... je ne reviendrai pas.", "likes": 0, "date": "2025-02-06T18:45:00", "rating": 1},
        {"id": "7", "parentId": null, "username": "Grace", "profilePicBytes": null, "comment": "Endroit génial ! Je recommande.", "likes": 9, "date": "2025-02-05T20:30:00", "rating": 5},
        {"id": "8", "parentId": "6", "username": "Hugo", "profilePicBytes": null, "comment": "Je suis d'accord, pas ouf...", "likes": 2, "date": "2025-02-06T19:00:00"},
        {"id": "9", "parentId": null, "username": "Isabelle", "profilePicBytes": null, "comment": "Mauvais rapport qualité-prix.", "likes": 4, "date": "2025-02-04T15:10:00", "rating": 2},
        {"id": "10", "parentId": null, "username": "Jack", "profilePicBytes": null, "comment": "Très bon accueil, personnel sympa.", "likes": 6, "date": "2025-02-03T17:50:00", "rating": 4},
        {"id": "11", "parentId": "8", "username": "Vincent", "profilePicBytes": null, "comment": "Pas trop d'accord avec vous", "likes": 2, "date": "2025-02-07T19:00:00"},
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
          index < rating ? Icons.star : Icons.star_border, // Étoile pleine ou vide
          color: index < rating ? Colors.amber : Colors.grey,
        );
      }),
    );
  }

  void toggleSortOrder() {
    setState(() {
      isSortedByDate = !isSortedByDate;
      if (isSortedByDate) {
        reviews.sort((a, b) => b.date.compareTo(a.date));  // Trier par date, du plus récent
      } else {
        reviews.sort((a, b) => b.likes.compareTo(a.likes));  // Trier par likes, du plus grand
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

  // Fonction récursive pour afficher les réponses
  Widget _buildReplies(List<Review> replies, bool isLastReply) {
    return Column(
      children: replies.asMap().entries.map((entry) {
        int index = entry.key;
        Review reply = entry.value;

        // Récupérer les réponses imbriquées (niveaux inférieurs)
        List<Review> nestedReplies = reviews.where((r) => r.parentId == reply.id).toList();

        return Column(
          children: [
            // Afficher la réponse actuelle avec un décalage si elle est imbriquée
            Padding(
              padding: EdgeInsets.only(left: reply.parentId != null ? 20.0 : 0.0), // Décalage uniquement pour les réponses imbriquées
              child: _buildReviewItem(reply),
            ),

            // Si la réponse a des réponses imbriquées, les afficher
            if (nestedReplies.isNotEmpty) ...[
              _buildReplies(nestedReplies, false), // Affichage récursif des réponses imbriquées
            ],

            // Ajouter le bouton "Répondre" seulement après la dernière réponse d'un avis principal
            if (index == replies.length - 1 && isLastReply)
              TextButton(
                onPressed: () => setState(() {
                  replyingTo = reply.id;  // On définit quel avis on est en train de répondre
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
                      onPressed: replyText.isEmpty ? null : () {
                        addReply(replyText, reply.id);
                        setState(() {
                          replyText = '';  // Réinitialiser le texte après envoi
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
    // Séparer les avis principaux et les réponses
    List<Review> mainReviews = reviews.where((r) => r.parentId == null).toList();

    // Trier **uniquement** les avis principaux
    if (isSortedByDate) {
      mainReviews.sort((a, b) => b.date.compareTo(a.date)); // Trier par date (plus récent en premier)
    } else {
      mainReviews.sort((a, b) => b.likes.compareTo(a.likes)); // Trier par likes (plus liké en premier)
    }


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
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.placeName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            widget.placeType,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 20.0),
                          Row(
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
                          const Divider(),


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
                                      onPressed: newReviewText.isEmpty ? null : () {
                                        if (newReviewRating == 0) { // Vérifie que l'utilisateur a mis une note
                                          setState(() => ratingError = "Veuillez attribuer au moins une étoile.");
                                        } else {
                                          addReview(newReviewText, newReviewRating);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Étoiles sélectionnables
                                Row(
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < newReviewRating ? Icons.star : Icons.star_border,
                                        color: index < newReviewRating ? Colors.amber : Colors.grey,
                                      ),
                                      onPressed: () => selectRating(index + 1), // Permet de choisir la note
                                    );
                                  }),
                                ),

                                // Affichage de l'erreur si l'utilisateur n'a pas mis de note
                                if (ratingError.isNotEmpty)
                                  Text(
                                    ratingError,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Avis",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: toggleSortOrder,
                                icon: const Icon(Icons.sort),
                                label: Text(isSortedByDate ? "Trier par likes" : "Trier par date"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          // Liste des avis
                          Expanded(
                            child: reviews.isEmpty
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                              itemCount: mainReviews.length,
                              itemBuilder: (context, index) {
                                Review review = mainReviews[index];

                                // Récupérer les réponses associées
                                List<Review> replies = reviews.where((r) => r.parentId == review.id).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildReviewItem(review),
                                    if (replies.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 20), // Décalage pour indiquer que ce sont des réponses
                                        child: _buildReplies(replies, true), // Appel à la fonction récursive pour afficher les réponses
                                      ),
                                    ],
                                    // Si aucune réponse n'est présente, afficher un bouton de réponse
                                    if (replies.isEmpty)
                                      TextButton(
                                        onPressed: () => setState(() => replyingTo = review.id),
                                        child: const Text("Répondre"),
                                      ),
                                    if (replyingTo == review.id)
                                      TextField(
                                        onChanged: (value) => setState(() => replyText = value),
                                        decoration: InputDecoration(
                                          hintText: "Votre réponse...",
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.send),
                                            onPressed: replyText.isEmpty ? null : () => addReply(replyText, review.id),
                                          ),
                                        ),
                                      ),
                                    const Divider(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
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
          if (review.parentId == null) _buildStars(review.rating), // Afficher étoiles si avis principal
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
}
