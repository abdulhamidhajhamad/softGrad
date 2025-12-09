// lib/screens/full_image_viewer.dart
import 'dart:io';
import 'package:flutter/material.dart';

class FullImageViewer extends StatefulWidget {
  final List<String> images;

  const FullImageViewer({Key? key, required this.images}) : super(key: key);

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  bool _isNetwork(String path) {
    return path.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (_, index) {
          final img = widget.images[index];

          return Center(
            child: InteractiveViewer(
              child: _isNetwork(img)
                  ? Image.network(
                      img,
                      fit: BoxFit.contain,
                    )
                  : Image.file(
                      File(img),
                      fit: BoxFit.contain,
                    ),
            ),
          );
        },
      ),
    );
  }
}
