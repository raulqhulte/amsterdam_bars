import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../db/bars_dao.dart';
import '../models/bar.dart';
import 'bar_details_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _barsDao = BarsDao();

  GoogleMapController? _controller;

  static const CameraPosition _amsterdamCamera = CameraPosition(
    target: LatLng(52.3676, 4.9041),
    zoom: 12.5,
  );

  Set<Marker> _markers = {};
  List<Bar> _bars = [];
  Map<String, int> _visitCounts = {};

  Position? _me;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadBars();
    await _loadLocation();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadBars() async {
    final bars = await _barsDao.getAllBars();
    final counts = await _barsDao.getVisitCountsByBarId();

    final markers = bars.map((bar) {
      return Marker(
        markerId: MarkerId(bar.id),
        position: LatLng(bar.latitude, bar.longitude),
        infoWindow: InfoWindow(
          title: bar.name,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BarDetailsPage(bar: bar)),
            );
          },
        ),
      );
    }).toSet();

    if (!mounted) return;
    setState(() {
      _bars = bars;
      _visitCounts = counts;
      _markers = markers;
    });
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _locationError = 'Location services are off.');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locationError = 'Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _me = pos;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Location error: $e');
    }
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  String _prettyDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  List<(Bar bar, double meters)> _closestUnvisited() {
    final me = _me;
    if (me == null) return const [];

    final items = <(Bar, double)>[];

    for (final b in _bars) {
      final visited = (_visitCounts[b.id] ?? 0) > 0;
      if (visited) continue;

      final m = _distanceMeters(
        me.latitude,
        me.longitude,
        b.latitude,
        b.longitude,
      );
      items.add((b, m));
    }

    items.sort((a, b) => a.$2.compareTo(b.$2));
    return items;
  }

  Future<void> _centerOnMe() async {
    final me = _me;
    if (me == null || _controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(me.latitude, me.longitude), 15),
    );
  }

  Future<void> _centerOnBar(Bar bar) async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(bar.latitude, bar.longitude), 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closest = _closestUnvisited().take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'My location',
            onPressed: () async {
              await _loadLocation();
              await _centerOnMe();
            },
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _amsterdamCamera,
            markers: _markers,
            myLocationEnabled: _me != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _controller = c,
          ),

          // Bottom sheet list
          DraggableScrollableSheet(
            initialChildSize: 0.20,
            minChildSize: 0.12,
            maxChildSize: 0.55,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Closest unvisited',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (_locationError != null)
                            const Icon(Icons.info_outline, size: 18),
                        ],
                      ),
                    ),
                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: closest.isEmpty
                          ? ListView(
                              controller: scrollController,
                              children: const [
                                SizedBox(height: 16),
                                Center(child: Text('No unvisited bars nearby (or location off).')),
                              ],
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: closest.length,
                              itemBuilder: (_, i) {
                                final bar = closest[i].$1;
                                final meters = closest[i].$2;

                                return ListTile(
                                  title: Text(bar.name),
                                  subtitle: Text(_prettyDistance(meters)),
                                  onTap: () async {
                                    await _centerOnBar(bar);
                                    if (!context.mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BarDetailsPage(bar: bar),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    await _loadBars(); // update visited filtering after you log a visit
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
