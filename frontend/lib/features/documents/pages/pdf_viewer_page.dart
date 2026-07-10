import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';

/// Viewer PDF embarqué (in-app) — affiche un document depuis ses bytes.
/// Utilisé sur mobile/desktop pour rester dans l'application.
class PdfViewerPage extends StatefulWidget {
  final Uint8List bytes;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.bytes,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfControllerPinch _controller;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _controller,
        onDocumentLoaded: (doc) {
          if (mounted) setState(() => _totalPages = doc.pagesCount);
        },
        onPageChanged: (page) {
          if (mounted) setState(() => _currentPage = page);
        },
      ),
    );
  }
}
