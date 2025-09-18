import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' as staggered;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

class SecondPage extends StatefulWidget {
  final List<String> likedSeeds;
  final Function(List<String>) onUpdateLikedSeeds;

  const SecondPage({
    super.key,
    required this.likedSeeds,
    required this.onUpdateLikedSeeds,
  });

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  late List<String> seeds;
  Map<String, String> _comments = {};
  bool _hoveringHome = false;

  @override
  void initState() {
    super.initState();
    seeds = List.from(widget.likedSeeds);
    _loadComments();
  }

  Future<void> _loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    setState(() {
      _comments = {
        for (var key in keys)
          if (key.startsWith('comment_'))
            key.replaceFirst('comment_', ''): prefs.getString(key) ?? ''
      };
    });
  }

  Future<void> _saveComment(String seed, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comment_$seed', comment);
    setState(() {
      _comments[seed] = comment;
    });
  }

  Future<void> _deleteComment(String seed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('comment_$seed');
    setState(() {
      _comments.remove(seed);
    });
  }

  void _removeSeed(String seed) {
    setState(() {
      seeds.remove(seed);
    });
    widget.onUpdateLikedSeeds(seeds);
    _deleteComment(seed);
  }

  String _buildImageUrl(String seed, double itemWidth, double heightRatio) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imageWidth = (itemWidth * dpr).round();
    final imageHeight = (itemWidth * heightRatio * dpr).round();
    return 'https://picsum.photos/seed/$seed/$imageWidth/$imageHeight';
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        elevation: kIsWeb ? 0 : 4,
        toolbarHeight: kIsWeb ? 80 : kToolbarHeight,
        centerTitle: true,
        title: Text(
          'Saved Pictures',
          style: GoogleFonts.playfairDisplay(
            fontSize: kIsWeb ? 40 : 26,
            letterSpacing: kIsWeb ? 2.0 : 1.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: kIsWeb
                ? const EdgeInsets.symmetric(horizontal: 24)
                : const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => Navigator.pop(context),
              onHover: kIsWeb
                  ? (hovering) {
                setState(() {
                  _hoveringHome = hovering;
                });
              }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kIsWeb && _hoveringHome
                      ? Colors.green.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.home,
                  color: Colors.green,
                  size: kIsWeb ? 36 : 30,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const int columns = 2;
              const double gridSpacing = 10;
              final double totalSpacing = gridSpacing * (columns - 1);
              final double itemWidth = (constraints.maxWidth - totalSpacing) / columns;

              return staggered.MasonryGridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                itemCount: seeds.length,
                itemBuilder: (context, index) {
                  final seed = seeds[index];
                  final double heightRatio = 0.6 + random.nextDouble() * 0.6;
                  final imageUrl = _buildImageUrl(seed, itemWidth, heightRatio);
                  final comment = _comments[seed];

                  return _ImageItem(
                    seed: seed,
                    imageUrl: imageUrl,
                    comment: comment,
                    onDelete: () => _removeSeed(seed),
                    onComment: (seed, comment) => _saveComment(seed, comment),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ImageItem extends StatefulWidget {
  final String seed;
  final String imageUrl;
  final String? comment;
  final VoidCallback onDelete;
  final Function(String seed, String comment) onComment;

  const _ImageItem({
    required this.seed,
    required this.imageUrl,
    required this.comment,
    required this.onDelete,
    required this.onComment,
  });

  @override
  State<_ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<_ImageItem> {
  bool _hovering = false;

  void _showMenuAtPosition(Offset globalPosition) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'comment',
          child: Text('Comment Picture'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );

    if (selected == 'delete') {
      _showDeleteDialog();
    } else if (selected == 'comment') {
      _showCommentDialog();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog() {
    final controller = TextEditingController(text: widget.comment ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add/Edit Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter your comment',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final commentText = controller.text.trim();
              widget.onComment(widget.seed, commentText);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (kIsWeb) {
          setState(() => _hovering = true);
        }
      },
      onExit: (_) {
        if (kIsWeb) {
          setState(() => _hovering = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onLongPressStart: (details) {
                  if (!kIsWeb) {
                    _showMenuAtPosition(details.globalPosition);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  ),
                ),
              ),
              if (kIsWeb && _hovering)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTapDown: (details) {
                      _showMenuAtPosition(details.globalPosition);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.comment != null && widget.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                widget.comment!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
