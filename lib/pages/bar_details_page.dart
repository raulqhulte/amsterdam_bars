import 'package:flutter/material.dart';

import '../db/reviews_dao.dart';
import '../db/visits_dao.dart';
import '../models/bar.dart';

class BarDetailsPage extends StatefulWidget {
  final Bar bar;

  const BarDetailsPage({super.key, required this.bar});

  @override
  State<BarDetailsPage> createState() => _BarDetailsPageState();
}

class _BarDetailsPageState extends State<BarDetailsPage> {
  final _visitsDao = VisitsDao();
  final _reviewsDao = ReviewsDao();

  final _notesController = TextEditingController();

  List<DateTime> _visits = [];
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _loadVisits();
    _loadReview();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    final visits = await _visitsDao.getVisitsForBar(widget.bar.id);
    if (!mounted) return;
    setState(() => _visits = visits);
  }

  Future<void> _loadReview() async {
    final review = await _reviewsDao.getReview(widget.bar.id);
    if (!mounted) return;

    setState(() {
      _rating = review?.rating ?? 0;
      _notesController.text = review?.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.bar;

    return Scaffold(
      appBar: AppBar(title: Text(bar.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _visitsDao.addVisit(bar.id);
          if (!mounted) return;
          await _loadVisits();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit logged 🍻')),
          );
        },
        icon: const Icon(Icons.check),
        label: const Text('Visited'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: ${bar.latitude.toStringAsFixed(4)}, ${bar.longitude.toStringAsFixed(4)}',
            ),

            // ─── Review section ────────────────────────────────────────────────
            const SizedBox(height: 16),
            Text(
              'Your rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final filled = starIndex <= _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                  ),
                );
              }),
            ),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _reviewsDao.upsertReview(
                      bar.id,
                      _rating,
                      _notesController.text.trim(),
                    );
                    if (!mounted) return;

                    // ✅ confirm persistence
                    await _loadReview();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review saved ✅')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save review'),
              ),
            ),

            // ─── Visit history section ────────────────────────────────────────
            const SizedBox(height: 16),
            Text(
              'Visit history (${_visits.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _visits.isEmpty
                  ? const Center(child: Text('No visits yet.'))
                  : ListView.builder(
                      itemCount: _visits.length,
                      itemBuilder: (_, i) {
                        final v = _visits[i];
                        final text =
                            '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')} '
                            '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(text),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
