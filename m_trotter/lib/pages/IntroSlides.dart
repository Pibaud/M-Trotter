import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'AuthPage.dart';

class IntroSlides extends StatefulWidget {
  @override
  _IntroSlidesState createState() => _IntroSlidesState();
}

class _IntroSlidesState extends State<IntroSlides>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  int? _firstAnimationMaxFrame;
  bool _isFirstSlideAnimationStopped = false;

  final List<Map<String, dynamic>> slides = [
    {
      "title": "Explorez Montpellier",
      "content":
          "Accédez aux données en temps réel des transports TAM, trouvez les restaurants et points d'intérêt à proximité, et découvrez la ville comme un local.",
      "icon": Icons.explore,
      "animation": "assets/lottie/city_explore.json"
    },
    {
      "title": "Itinéraires simplifiés",
      "content":
          "Planifiez facilement vos trajets grâce à OpenStreetMap. Trouvez le chemin le plus court vers votre destination.",
      "icon": Icons.map,
      "animation": "assets/lottie/map_navigation.json"
    },
    {
      "title": "Participez à la communauté",
      "content":
          "Contribuez à l'amélioration de l'application en ajoutant des notes, photos et avis. Aidez d'autres utilisateurs à découvrir les trésors cachés de Montpellier.",
      "icon": Icons.people,
      "animation": "assets/lottie/community.json"
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Relancer l'animation du premier slide lorsqu'on y revient
    if (page == 0 &&
        _isFirstSlideAnimationStopped &&
        _firstAnimationMaxFrame != null) {
      _animationController.reset();
      _animationController.forward();
      _isFirstSlideAnimationStopped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.from(alpha: 0.2, red: 0.239, green: 0.353, blue: 0.996),
              Color.from(alpha: 0.8, red: 0.239, green: 0.353, blue: 0.996),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return _buildSlide(slide, index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: slides.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: Color.fromARGB(255, 61, 90, 228),
                        dotColor: Colors.white60,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                    SizedBox(height: 32),
                    _buildBottomButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration ou animation
          Container(
            height: 220,
            child: Hero(
              tag: "slide_$index",
              child: slide["animation"] != null
                  ? Lottie.asset(
                      slide["animation"],
                      repeat: index == 2, // Ne répète pas pour le premier slide
                      animate: true,
                      frameRate: FrameRate.max,
                      controller: index == 0 ? _animationController : null,
                      onLoaded: (composition) {
                        if (index == 0) {
                          // Pour le slide d'index 0, configurez l'animation pour s'arrêter à la frame 122
                          _animationController.duration = composition.duration;
                          _firstAnimationMaxFrame = 122;
                          _animationController.forward();

                          // Écoutez l'animation et arrêtez-la à la frame 122
                          _animationController.addListener(() {
                            if (_animationController.value *
                                    composition.durationFrames >=
                                _firstAnimationMaxFrame!) {
                              _animationController.stop();
                              _isFirstSlideAnimationStopped = true;
                            }
                          });
                        }
                      },
                    )
                  : Icon(
                      slide["icon"] as IconData,
                      size: 150,
                      color: Colors.white,
                    ),
            ),
          ),
          SizedBox(height: 24),
          // Titre
          Text(
            slide["title"]!,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Contenu
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              slide["content"]!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    if (_currentPage == slides.length - 1) {
      return ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isFirstLaunch', false);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AuthPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor:
              Color.from(alpha: 1, red: 0.239, green: 0.353, blue: 0.996),
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        child: Text(
          "Commencer",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isFirstLaunch', false);

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AuthPage()),
              );
            },
            child: Text(
              "Passer",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(width: 24),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor:
                  Color.from(alpha: 1, red: 0.239, green: 0.353, blue: 0.996),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: Text(
              "Suivant",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }
  }
}
