import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../db/bars_dao.dart';
import '../services/places_service.dart';

import 'package:uuid/uuid.dart';


class AddBarPage extends StatefulWidget {
  const AddBarPage({super.key});

  @override
  State<AddBarPage> createState() => _AddBarPageState();
}

class _AddBarPageState extends State<AddBarPage> {
  final _dao = BarsDao();
  final _places = PlacesService();

  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  static const LatLng _amsterdam = LatLng(52.3676, 4.9041);

  LatLng? _pickedLatLng;
  Marker? _pickedMarker;

  // Places UI state
  List<PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _loadingDetails = false;
  String? _errorText;

  // Debounce typing so we don’t call Google on every keystroke
  Timer? _debounce;

  // Session token links autocomplete -> details (better billing behavior)
  String _sessionToken = const Uuid().v4();

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setPickedLocation(LatLng latLng) {
    setState(() {
      _pickedLatLng = latLng;
      _pickedMarker = Marker(
        markerId: const MarkerId('picked'),
        position: latLng,
      );
    });
  }

  Future<void> _onSearchChanged(String input) async {
    _debounce?.cancel();
    setState(() {
      _errorText = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = input.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _loadingSuggestions = true);

      try {
        final res = await _places.autocomplete(
          input: q,
          sessionToken: _sessionToken,
        );
        if (!mounted) return;
        setState(() => _suggestions = res);
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorText = e.toString());
      } finally {
        if (!mounted) return;
        setState(() => _loadingSuggestions = false);
      }
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion s) async {
    setState(() {
      _loadingDetails = true;
      _errorText = null;
    });

    try {
      final details = await _places.details(
        placeId: s.placeId,
        sessionToken: _sessionToken,
      );

      if (!mounted) return;

      // Fill name + drop pin
      _nameController.text = details.name;
      _setPickedLocation(LatLng(details.lat, details.lng));

      // Clear suggestion list
      setState(() {
        _suggestions = [];
        _searchController.text = s.description;
      });

      // New session for next search session
      _sessionToken = const Uuid().v4();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loadingDetails = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bar name')),
      );
      return;
    }
    if (_pickedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick from search or long-press the map')),
      );
      return;
    }

    await _dao.insertBar(
      name,
      _pickedLatLng!.latitude,
      _pickedLatLng!.longitude,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final coordsText = _pickedLatLng == null
        ? 'No pin yet'
        : '${_pickedLatLng!.latitude.toStringAsFixed(5)}, '
          '${_pickedLatLng!.longitude.toStringAsFixed(5)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add bar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search (Google Places)',
                suffixIcon: _loadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _suggestions = [];
                                _errorText = null;
                              });
                            },
                          )),
              ),
              onChanged: _onSearchChanged,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        title: Text(
                          s.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _pickSuggestion(s),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bar name (manual / override)',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              Text('Pin: $coordsText'),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: _amsterdam,
                          zoom: 13,
                        ),
                        onLongPress: _setPickedLocation,
                        markers: _pickedMarker == null ? {} : {_pickedMarker!},
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                    if (_loadingDetails)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
