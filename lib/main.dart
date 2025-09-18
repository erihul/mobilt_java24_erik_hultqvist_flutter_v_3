import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'SecondPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFavorite Picture',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentSeed = '';
  List<String> _likedSeeds = [];
  final Random _random = Random();
  bool _hoveringFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadLikedSeeds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRandomSeed();
    });
  }

  void _loadRandomSeed() {
    final seed = _random.nextInt(100000).toString();
    setState(() {
      _currentSeed = seed;
    });
  }

  Future<void> _loadLikedSeeds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _likedSeeds = prefs.getStringList('liked_seeds') ?? [];
    });
  }

  Future<void> _saveLikedSeeds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('liked_seeds', _likedSeeds);
  }

  void _likeImage() {
    if (!_likedSeeds.contains(_currentSeed)) {
      _likedSeeds.add(_currentSeed);
      _saveLikedSeeds();
    }
    _loadRandomSeed();
  }

  void _dislikeImage() {
    _loadRandomSeed();
  }

  void _goToSecondPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(
          likedSeeds: _likedSeeds,
          onUpdateLikedSeeds: (updatedList) {
            setState(() {
              _likedSeeds = updatedList;
            });
            _saveLikedSeeds();
          },
        ),
      ),
    );
  }

  String _buildImageUrl(String seed, double width) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imageWidth = (width * dpr).round();
    final imageHeight = (width * 0.75 * dpr).round(); // 4:3 ratio
    return 'https://picsum.photos/seed/$seed/$imageWidth/$imageHeight';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        elevation: kIsWeb ? 0 : 4,
        toolbarHeight: kIsWeb ? 80 : kToolbarHeight,
        centerTitle: true,
        title: Text(
          'My pICS',
          style: GoogleFonts.playfairDisplay(
            fontSize: kIsWeb ? 40 : 26,
            letterSpacing: kIsWeb ? 5 : 1.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                hoverColor: Colors.red.withOpacity(0.1),
                onTap: _goToSecondPage,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.favorite,
                    size: kIsWeb ? 36 : 30,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final imageUrl = _currentSeed.isNotEmpty
                    ? _buildImageUrl(_currentSeed, availableWidth)
                    : '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SquareButton(
                              icon: Icons.thumb_down,
                              iconColor: Colors.red,
                              onPressed: _dislikeImage,
                            ),
                            const SizedBox(width: 20),
                            _SquareButton(
                              icon: Icons.thumb_up,
                              iconColor: Colors.green,
                              onPressed: _likeImage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable square button widget for thumbs up/down
class _SquareButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _SquareButton({
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 32,
        ),
      ),
    );
  }
}
