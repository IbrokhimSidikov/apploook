// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — kept in sync with the rest of the app.
/// ---------------------------------------------------------------------------
const Color _kAccent = Color(0xFFFEC700);
const Color _kBackground = Color(0xFFF1F2F7);
const String _kFont = 'Poppins';
const String _kPhone = '+998712070070';

/// ---------------------------------------------------------------------------
/// Type-safe branch model. Coordinates are parsed once, up front, instead of
/// repeatedly splitting strings while the map is interactive.
/// ---------------------------------------------------------------------------
class Branch {
  final String name;
  final String address;
  final String hours;
  final bool isOpen;
  final double lat;
  final double lng;

  const Branch({
    required this.name,
    required this.address,
    required this.hours,
    required this.isOpen,
    required this.lat,
    required this.lng,
  });

  LatLng get point => LatLng(lat, lng);
}

const List<Branch> _kBranches = [
  Branch(
    name: 'Loook Yunusobod',
    address: "Ahmad Donish ko'chasi, 1A, Yunusobod metro bekati",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.366780,
    lng: 69.293222,
  ),
  Branch(
    name: 'Loook Beruniy',
    address:
        "Toshkent, O'zbekiston yo'nalishi, Beruniy metro bekati, `Korzinka` binosi, 3-qavat",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.346379,
    lng: 69.206030,
  ),
  Branch(
    name: 'Loook Chilanzar',
    address:
        "Toshkent, Chilonzor tumani, Chilonzor dahasi, M-mavze, Gulbozor yonida",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.276810,
    lng: 69.201880,
  ),
  Branch(
    name: 'Loook Maksim Gorkiy',
    address: "Toshkent, Buyuk Ipak Yo'li ko'chasi, 3",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.326421,
    lng: 69.327426,
  ),
  Branch(
    name: 'Loook Boulevard',
    address: "Toshkent, O'qchi ko'chasi, 3A, `Boulevard` resident kompleks",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.313691,
    lng: 69.244055,
  ),
  Branch(
    name: "Loook YangiYo'l",
    address: "Yangiyol shahri, Markaziy ko'cha",
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.120050,
    lng: 69.060309,
  ),
  Branch(
    name: 'Chicken by Loook High Town',
    address: 'Toshkent, High Town majmuasi',
    hours: '10:00 - 22:00',
    isOpen: true,
    lat: 41.356380,
    lng: 69.310698,
  ),
  Branch(
    name: 'Chicken by Loook Ava',
    address: 'Toshkent, Ava Pizza filiali',
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.276810,
    lng: 69.201880,
  ),
  Branch(
    name: 'Chicken by Loook GANGA',
    address: 'Toshkent, Abdulla Qodiriy 11D',
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.328603,
    lng: 69.249466,
  ),
  Branch(
    name: 'Chicken by Loook SERGELI',
    address: 'Toshkent, Sergeli Metro bekati',
    hours: '09:00 - 00:00',
    isOpen: true,
    lat: 41.22274,
    lng: 69.207342,
  ),
];

/// Tashkent overview camera position (shows all branches at once).
final LatLng _kTashkentCenter = LatLng(41.3137916, 69.242771);

/// ---------------------------------------------------------------------------
/// Shared actions — pure functions so both the list and the map reuse them.
/// ---------------------------------------------------------------------------
Future<void> _openDirections(BuildContext context, Branch branch) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${branch.lat},${branch.lng}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    _showSnack(context, AppLocalizations.of(context).couldNotOpenMap,
        Colors.orange);
  }
}

Future<void> _callBranch(BuildContext context, Branch branch) async {
  final uri = Uri(scheme: 'tel', path: _kPhone);
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    _showSnack(context, AppLocalizations.of(context).couldNotCall, Colors.red);
  }
}

void _showSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: color),
  );
}

/// ---------------------------------------------------------------------------
/// Top-level page: a thin shell around two independent tabs. Keeping this
/// widget light means switching tabs never rebuilds the heavy map view.
/// ---------------------------------------------------------------------------
class Branches extends StatefulWidget {
  const Branches({super.key});

  @override
  State<Branches> createState() => _BranchesState();
}

class _BranchesState extends State<Branches>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).branches,
          style: const TextStyle(
            fontFamily: _kFont,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        foregroundColor: Colors.black87,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SegmentedTabs(controller: _tabController),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // List is built eagerly (cheap); the map mounts only once this tab
        // is first dragged into view, so opening the page stays instant.
        children: const [
          _BranchListView(branches: _kBranches),
          _BranchMapView(branches: _kBranches),
        ],
      ),
    );
  }
}

/// A pill-style segmented control that matches the app's rounded aesthetic
/// while still being driven by the real [TabController].
class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _kAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontFamily: _kFont,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _kFont,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            height: 36,
            child: _TabLabel(icon: Icons.list_rounded, text: l.branchesListTab),
          ),
          Tab(
            height: 36,
            child: _TabLabel(icon: Icons.map_rounded, text: l.branchesMapTab),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TabLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// LIST TAB
/// ---------------------------------------------------------------------------
class _BranchListView extends StatelessWidget {
  final List<Branch> branches;
  const _BranchListView({required this.branches});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 for the header card.
      itemCount: branches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _ListHeader(count: branches.length);
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _BranchCard(branch: branches[index - 1]),
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int count;
  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccent, Color(0xFFFFD740)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.findOurLocations,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.branchesAcrossTashkent(count),
                  style: TextStyle(
                    fontFamily: _kFont,
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final Branch branch;
  const _BranchCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _StatusBadge(isOpen: branch.isOpen),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: _kAccent, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.location_on_outlined, text: branch.address),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.access_time_rounded, text: branch.hours),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.directions_rounded,
                    label: AppLocalizations.of(context).directions,
                    isPrimary: true,
                    onTap: () => _openDirections(context, branch),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_rounded,
                    label: AppLocalizations.of(context).callBranch,
                    isPrimary: false,
                    onTap: () => _callBranch(context, branch),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// MAP TAB
///
/// Uses [FlutterMap] (OpenStreetMap tiles) instead of a native map engine, so
/// there is no platform GL view that can crash. This widget:
///   • is kept alive so swapping tabs preserves the camera + cached tiles;
///   • renders markers as plain Flutter widgets (no SVG→bitmap step), so the
///     first frame is immediate;
///   • drives selection through a [ValueNotifier] so swiping cards or
///     highlighting a marker rebuilds ONLY the affected sub-tree — never the
///     tile layer.
/// ---------------------------------------------------------------------------
class _BranchMapView extends StatefulWidget {
  final List<Branch> branches;
  const _BranchMapView({required this.branches});

  @override
  State<_BranchMapView> createState() => _BranchMapViewState();
}

class _BranchMapViewState extends State<_BranchMapView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final PageController _pageController =
      PageController(viewportFraction: 0.88);

  /// -1 means "no branch selected" → overview, no marker highlighted.
  final ValueNotifier<int> _selected = ValueNotifier<int>(-1);

  /// Drives smooth camera fly-to animations (flutter_map has no built-in one).
  late final AnimationController _camAnim;
  VoidCallback? _camTick;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _camAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _selected.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _selected.removeListener(_onSelectionChanged);
    _selected.dispose();
    if (_camTick != null) _camAnim.removeListener(_camTick!);
    _camAnim.dispose();
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final index = _selected.value;
    if (index < 0) return;
    _flyTo(widget.branches[index].point, 15);
  }

  /// Animates the camera from its current position to [dest]/[zoom] with an
  /// eased tween — the "pro app" smooth glide between branches.
  void _flyTo(LatLng dest, double zoom) {
    final camera = _mapController.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: dest.latitude);
    final lngTween =
        Tween<double>(begin: camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);
    final curved =
        CurvedAnimation(parent: _camAnim, curve: Curves.easeOutCubic);

    if (_camTick != null) _camAnim.removeListener(_camTick!);
    _camTick = () {
      _mapController.move(
        LatLng(latTween.evaluate(curved), lngTween.evaluate(curved)),
        zoomTween.evaluate(curved),
      );
    };
    _camAnim
      ..reset()
      ..addListener(_camTick!)
      ..forward();
  }

  void _showAllBranches() {
    _selected.value = -1;
    _flyTo(_kTashkentCenter, 10.5);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep-alive

    return Stack(
      children: [
        // Pure-Dart map: rendered on Flutter's own canvas, so there is no
        // native GL view to crash and the first frame is immediate.
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kTashkentCenter,
              initialZoom: 10.5,
              minZoom: 4,
              maxZoom: 18,
              backgroundColor: _kBackground,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              // Tapping empty map clears the highlight.
              onTap: (_, __) => _selected.value = -1,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.loook.v1',
              ),
              // Only the marker layer rebuilds on selection — the tile layer
              // underneath is untouched, so panning/zoom stays smooth.
              ValueListenableBuilder<int>(
                valueListenable: _selected,
                builder: (context, selectedIndex, _) {
                  return MarkerLayer(
                    markers: [
                      for (int i = 0; i < widget.branches.length; i++)
                        Marker(
                          point: widget.branches[i].point,
                          width: 56,
                          height: 56,
                          alignment: Alignment.bottomCenter,
                          child: _MapMarker(
                            selected: i == selectedIndex,
                            onTap: () => _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        _MapTopBar(
          count: widget.branches.length,
          onRecenter: _showAllBranches,
        ),

        // Bottom carousel. The PageView itself is built once; each card listens
        // to [_selected] independently for its scale/highlight animation.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 196,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.branches.length,
              onPageChanged: (index) => _selected.value = index,
              itemBuilder: (context, index) => _MapBranchCard(
                branch: widget.branches[index],
                index: index,
                selected: _selected,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapTopBar extends StatelessWidget {
  final int count;
  final VoidCallback onRecenter;
  const _MapTopBar({required this.count, required this.onRecenter});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: _kAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.branchesCountLabel(count),
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    l.tapMarkerHint,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: _kAccent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onRecenter,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.my_location_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A map pin built entirely from Flutter widgets. The tip sits at the bottom
/// center (the marker is anchored with [Alignment.bottomCenter]); selecting it
/// scales it up around that tip so the point stays put.
class _MapMarker extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _MapMarker({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        alignment: Alignment.bottomCenter,
        scale: selected ? 1.0 : 0.78,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.location_on,
              size: 56,
              color: _kAccent,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            Positioned(
              top: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_rounded,
                    size: 13, color: _kAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBranchCard extends StatelessWidget {
  final Branch branch;
  final int index;
  final ValueNotifier<int> selected;
  const _MapBranchCard({
    required this.branch,
    required this.index,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selected,
      builder: (context, selectedIndex, child) {
        final isSelected = selectedIndex == index;
        return AnimatedScale(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          scale: isSelected ? 1.0 : 0.94,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.fromLTRB(6, 12, 6, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? _kAccent.withOpacity(0.35)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: isSelected ? 22 : 12,
                  offset: Offset(0, isSelected ? 8 : 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showBranchSheet(context, branch),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: _kAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _StatusBadge(isOpen: branch.isOpen),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: branch.address,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.directions_rounded,
                        label: AppLocalizations.of(context).directions,
                        isPrimary: true,
                        compact: true,
                        onTap: () => _openDirections(context, branch),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.phone_rounded,
                        label: AppLocalizations.of(context).callBranch,
                        isPrimary: false,
                        compact: true,
                        onTap: () => _callBranch(context, branch),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail sheet shown when a map card is tapped.
void _showBranchSheet(BuildContext context, Branch branch) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusBadge(isOpen: branch.isOpen),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.location_on_outlined, text: branch.address),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.access_time_rounded, text: branch.hours),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.directions_rounded,
                  label: AppLocalizations.of(context).directions,
                  isPrimary: true,
                  onTap: () {
                    Navigator.pop(context);
                    _openDirections(context, branch);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_rounded,
                  label: AppLocalizations.of(context).callBranch,
                  isPrimary: false,
                  onTap: () {
                    Navigator.pop(context);
                    _callBranch(context, branch);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// ---------------------------------------------------------------------------
/// Shared small widgets
/// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen
                ? AppLocalizations.of(context).openNow
                : AppLocalizations.of(context).closedNow,
            style: TextStyle(
              fontFamily: _kFont,
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool compact;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isPrimary ? Colors.black : _kAccent;
    return Material(
      color: isPrimary ? _kAccent : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 9 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: _kAccent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: _kFont,
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12.5 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
