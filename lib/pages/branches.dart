// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:apploook/widget/branch_locations.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:async';

class Branches extends StatefulWidget {
  const Branches({super.key});

  @override
  State<Branches> createState() => _BranchesState();
}

class _BranchesState extends State<Branches> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Completer<YandexMapController> _mapController = Completer();
  List<PlacemarkMapObject> _placemarks = [];
  // Static branch data
  final List<Map<String, dynamic>> branches = [
    {
      'name': 'Loook Yunusobod',
      'address': 'Ahmad Donish ko\'chasi, 1A, Yunusobod metro bekati',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook Beruniy',
      'address': 'Toshkent, O\'zbekiston yo\'nalishi, Beruniy metro bekati, `Korzinka` binosi, 3-qavat',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook Chilanzar',
      'address': 'Toshkent, Chilonzor tumani, Chilonzor dahasi, M-mavze, Gulbozor yonida',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook Maksim Gorkiy',
      'address': 'Toshkent, Buyuk Ipak Yo\'li ko\'chasi, 3',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook Boulevard',
      'address': 'Toshkent, O\'qchi ko\'chasi, 3A, `Boulevard` resident kompleks',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook YangiYo\'l',
      'address': 'Yangiyol shahri, Markaziy ko\'cha',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
    {
      'name': 'Loook High Town',
      'address': 'Toshkent, High Town majmuasi',
      'hours': '09:00 - 00:00',
      'isOpen': false,
      'phone': '+998712070070',
    },
    {
      'name': 'Ava Pizza',
      'address': 'Toshkent, Ava Pizza filiali',
      'hours': '09:00 - 00:00',
      'isOpen': true,
      'phone': '+998712070070',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePlacemarks();
  }

  void _initializePlacemarks() {
    _placemarks = [];
    
    // Add placemarks for branches with coordinates
    for (var branch in branches) {
      final coordinates = BranchLocations.getBranchCoordinates(branch['name']);
      if (coordinates != null) {
        final latLng = coordinates.split(', ');
        if (latLng.length == 2) {
          final lat = double.tryParse(latLng[0].trim());
          final lng = double.tryParse(latLng[1].trim());
          
          if (lat != null && lng != null) {
            _placemarks.add(
              PlacemarkMapObject(
                mapId: MapObjectId('branch_${branch['name']}'),
                point: Point(latitude: lat, longitude: lng),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('images/point.png'),
                    scale: 0.5,
                  ),
                ),
                onTap: (PlacemarkMapObject placemark, Point point) {
                  _showBranchInfoFromMap(branch);
                },
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F2F7),
      appBar: AppBar(
        title: Text(
          'Branches',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFFFEC700),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFFFEC700),
          tabs: [
            Tab(
              icon: Icon(Icons.list),
              text: 'List',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Map',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          _buildMapView(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildBranchesList(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header for map view
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFEC700),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFEC700).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.map,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Branch Locations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Find us on the map',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Yandex Map
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: YandexMap(
                  onMapCreated: (YandexMapController controller) {
                    _mapController.complete(controller);
                    _moveToTashkent();
                  },
                  mapObjects: _placemarks,
                  onCameraPositionChanged: (CameraPosition position, CameraUpdateReason reason, bool finished) {
                    // Handle camera position changes if needed
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToTashkent() async {
    final controller = await _mapController.future;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: 41.3137916, longitude: 69.242771), // Tashkent center
          zoom: 10.5, // Adjusted zoom to show more of Tashkent city with branch markers
        ),
      ),
      animation: MapAnimation(type: MapAnimationType.smooth, duration: 1.5),
    );
  }

  void _showBranchInfoFromMap(Map<String, dynamic> branch) {
    _showBranchInfo(branch['name'].toString().split(' ').last);
  }

  void _showBranchInfo(String branchName) {
    // Find the branch data
    final branch = branches.firstWhere(
      (b) => b['name'].toString().contains(branchName),
      orElse: () => {},
    );
    
    if (branch.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(branch['isOpen']),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, branch['address']),
                SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, branch['hours']),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: () {
                          Navigator.pop(context);
                          _openMap(branch);
                        },
                        isPrimary: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        onTap: () {
                          Navigator.pop(context);
                          _callBranch(branch);
                        },
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFEC700),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFEC700).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Our Locations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${branches.length} branches available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        return _buildBranchCard(branches[index]);
      },
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Branch Header
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          _buildStatusBadge(branch['isOpen']),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFEC700).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
                        color: Color(0xFFFEC700),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildInfoRow(Icons.location_on_outlined, branch['address']),
                SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, branch['hours']),
              ],
            ),
          ),
          // Action Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFFF1F2F7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions,
                    label: 'Directions',
                    onTap: () => _openMap(branch),
                    isPrimary: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    onTap: () => _callBranch(branch),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    Color statusColor = isOpen ? Colors.green : Colors.orange;
    String statusText = isOpen ? 'Open Now' : 'Closed';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Color(0xFFFEC700) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.black : Color(0xFFFEC700),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Color(0xFFFEC700),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMap(Map<String, dynamic> branch) async {
    // Get coordinates from BranchLocations
    final coordinates = BranchLocations.getBranchCoordinates(branch['name']);
    if (coordinates != null) {
      final url = "https://www.google.com/maps/search/?api=1&query=$coordinates";
      final uri = Uri.parse(url);
      
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showSnackBar('Could not open map', Colors.orange);
        }
      } catch (e) {
        _showSnackBar('Could not open map', Colors.orange);
      }
    } else {
      _showSnackBar('Location not available for this branch', Colors.orange);
    }
  }

  void _callBranch(Map<String, dynamic> branch) async {
    const phoneNumber = '712072070';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar('Could not make phone call', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Could not make phone call', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}