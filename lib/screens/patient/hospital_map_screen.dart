// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicore/providers/hospital_provider.dart';
import 'package:medicore/models/hospital_model.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  Hospital? _selectedHospital;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().fetchNearbyHospitals();
    });
  }

  void _focusOn(Hospital h) {
    setState(() => _selectedHospital = h);
    if (_mapReady) {
      _mapController.move(LatLng(h.latitude, h.longitude), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HospitalProvider>(
        builder: (context, provider, _) {
          final myPos = provider.currentPosition;
          final myLatLng = myPos != null
              ? LatLng(myPos.latitude, myPos.longitude)
              : const LatLng(23.8103, 90.4125);

          return Column(
            children: [
              _AppBar(onRefresh: provider.fetchNearbyHospitals),
              if (provider.isLoading)
                const LinearProgressIndicator(minHeight: 3),
              // Location permission / service error banners
              if (provider.locationError == 'location_service_disabled')
                _LocationBanner(
                  icon: Icons.location_disabled_rounded,
                  message: 'Location service is off. Showing results for Dhaka.',
                  actionLabel: 'Turn On',
                  onAction: () async {
                    await Geolocator.openLocationSettings();
                    provider.fetchNearbyHospitals();
                  },
                ),
              if (provider.locationError == 'permission_denied_forever')
                _LocationBanner(
                  icon: Icons.location_off_rounded,
                  message: 'Location permission blocked. Enable it in app settings.',
                  actionLabel: 'Settings',
                  onAction: () async {
                    await Geolocator.openAppSettings();
                    provider.fetchNearbyHospitals();
                  },
                ),
              if (provider.locationError == 'permission_denied')
                _LocationBanner(
                  icon: Icons.location_off_rounded,
                  message: 'Location access denied. Tap retry to allow.',
                  actionLabel: 'Retry',
                  onAction: provider.fetchNearbyHospitals,
                ),
              if (provider.locationError == 'location_unavailable')
                _LocationBanner(
                  icon: Icons.gps_off_rounded,
                  message: 'Could not get your location. Showing results for Dhaka.',
                  actionLabel: 'Retry',
                  onAction: provider.fetchNearbyHospitals,
                ),
              if (provider.errorMessage != null)
                _ErrorBanner(provider.errorMessage!,
                    onRetry: provider.fetchNearbyHospitals),
              // Map — top 55%
              Expanded(
                flex: 55,
                child: _buildMap(provider, myLatLng),
              ),
              // Hospital list — bottom 45%
              Expanded(
                flex: 45,
                child: _buildList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(HospitalProvider provider, LatLng myLatLng) {
    final hospitals = provider.hospitals;

    // zoom 10 shows roughly 60 km in each direction on mobile screens
    const double defaultZoom = 10.0;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: myLatLng,
        initialZoom: defaultZoom,
        onMapReady: () => setState(() => _mapReady = true),
      ),
      children: [
        // OpenStreetMap tiles — free, no API key
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.medicore.app',
        ),
        // Hospital markers
        MarkerLayer(
          markers: [
            // Current location marker
            Marker(
              point: myLatLng,
              width: 40,
              height: 40,
              child: _MyLocationMarker(),
            ),
            // Hospital markers
            ...hospitals.map((h) {
              final isSelected = _selectedHospital?.id == h.id;
              return Marker(
                point: LatLng(h.latitude, h.longitude),
                width: isSelected ? 48 : 36,
                height: isSelected ? 48 : 36,
                child: GestureDetector(
                  onTap: () => _focusOn(h),
                  child: _HospitalMarker(isSelected: isSelected),
                ),
              );
            }),
          ],
        ),
        // Attribution required by OSM tile usage policy
        SimpleAttributionWidget(
          source: const Text('© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildList(HospitalProvider provider) {
    final hospitals = provider.hospitals;

    if (!provider.isLoading && hospitals.isEmpty && provider.errorMessage == null) {
      return _EmptyState(onRetry: provider.fetchNearbyHospitals);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                const Text('Nearby Hospitals',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Text('${hospitals.length} found',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: hospitals.length,
              itemBuilder: (context, i) =>
                  _HospitalTile(
                    hospital: hospitals[i],
                    isSelected: _selectedHospital?.id == hospitals[i].id,
                    onTap: () => _focusOn(hospitals[i]),
                    onDirections: () => _openDirections(hospitals[i], provider),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(
      Hospital h, HospitalProvider provider) async {
    final pos = provider.currentPosition;
    final origin =
        pos != null ? '${pos.latitude},${pos.longitude}' : '';
    final dest = '${h.latitude},${h.longitude}';
    final params = <String, String>{
      'api': '1',
      'destination': dest,
      'travelmode': 'driving',
      if (origin.isNotEmpty) 'origin': origin,
    };
    final uri = Uri.https('www.google.com', '/maps/dir/', params);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AppBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nearby Hospitals',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('OpenStreetMap • real-time data',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: const Icon(Icons.my_location_rounded,
          color: Colors.white, size: 18),
    );
  }
}

class _HospitalMarker extends StatelessWidget {
  final bool isSelected;
  const _HospitalMarker({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade600 : Colors.red.shade400,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: isSelected ? 10 : 4,
              spreadRadius: isSelected ? 2 : 0),
        ],
      ),
      child: Icon(Icons.local_hospital_rounded,
          color: Colors.white, size: isSelected ? 26 : 18),
    );
  }
}

class _HospitalTile extends StatelessWidget {
  final Hospital hospital;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _HospitalTile({
    required this.hospital,
    required this.isSelected,
    required this.onTap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: Colors.red.shade50, shape: BoxShape.circle),
          child: Icon(Icons.local_hospital_rounded,
              color: Colors.red.shade600, size: 22),
        ),
        title: Text(hospital.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(hospital.address,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_rounded,
                  size: 12, color: Colors.blue.shade600),
              const SizedBox(width: 3),
              Text(hospital.formattedDistance,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 10),
              if (hospital.hasEmergency)
                _Badge('Emergency', Colors.red),
              if (hospital.isOpen && !hospital.hasEmergency)
                _Badge('Open', Colors.green),
            ]),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.directions_rounded,
              color: Colors.blue.shade600),
          onPressed: onDirections,
          tooltip: 'Get directions',
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.shade700 ?? color)),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _LocationBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800))),
        TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner(this.message, {required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            size: 16, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12, color: Colors.orange.shade800))),
        TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.local_hospital_outlined,
            size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No hospitals found nearby',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 6),
        Text('Try refreshing or check location permissions',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry')),
      ]),
    );
  }
}

extension on Color {
  Color? get shade700 {
    if (this == Colors.red) return Colors.red.shade700;
    if (this == Colors.green) return Colors.green.shade700;
    return null;
  }
}
