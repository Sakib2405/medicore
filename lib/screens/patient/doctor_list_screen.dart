// E:\Flutter project\medicore\lib\screens\patient\doctor_list_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/doctor_provider.dart';
// THIS IS THE SINGLE SOURCE OF TRUTH FOR THE DOCTOR MODEL
import 'package:medicore/models/doctor_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Import the profile screen; it should not declare its own Doctor class to avoid conflicts.
import 'package:medicore/screens/patient/doctor_profile_screen.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<DoctorProvider>(context, listen: false).loadMoreDoctors();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Find Your Doctor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade50,
            ),
            child: IconButton(
              icon:
                  Icon(Icons.filter_list_rounded, color: Colors.blue.shade700),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, specialty, or service...',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(Icons.search, color: Colors.blue.shade700),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        VoiceSuffixButton(
                          controller: _searchController,
                          append: false,
                          onResult: (t) =>
                              setState(() => _searchQuery = t.toLowerCase()),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.blue.shade400, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
            // Filter Chips
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<DoctorProvider>(
                builder: (context, doctorProvider, child) {
                  if (doctorProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading Doctors...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (doctorProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              doctorProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => doctorProvider.loadDoctors(),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final doctors = _filterDoctors(doctorProvider.doctors);

                  if (doctors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Doctors Found',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search terms or filters to find what you\'re looking for.'
                                  : 'No doctors match your current filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_searchQuery.isNotEmpty ||
                              _selectedFilter != 'All')
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedFilter = 'All';
                                  _searchController.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.blue.shade200),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Clear All Filters'),
                            ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: doctors.length +
                        (doctorProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == doctors.length) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }
                      final doctor = doctors[index];
                      return _buildDoctorTile(doctor, context)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0, duration: 300.ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorTile(Doctor doctor, BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDoctorProfile(doctor, context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.max, // Fill available height from Grid tile
            children: [
              // Doctor Image with overlay
              Stack(
                children: [
                  Container(
                    height: 100, // Further reduced height
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Colors.blue.shade50,
                    ),
                    child: doctor.hasImage
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              doctor.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderAvatar(),
                            ),
                          )
                        : _buildPlaceholderAvatar(),
                  ),
                  // Verified badge
                  if (doctor.isVerified)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  // Availability indicator
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: doctor.isAvailable
                            ? Colors.green.shade600
                            : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doctor.isAvailable ? 'Available' : 'Busy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Doctor Info - Completely restructured to avoid overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8), // Minimal padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and Specialty - More compact
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doctor.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              doctor.specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rating and Fee - More compact
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Rating
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      color: Colors.amber.shade600, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    doctor.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Fee
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    doctor.consultationFeeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Experience - Only show if there's space
                          if (doctor.experienceYears != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${doctor.experienceYears!}+ yrs exp',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: Colors.blue.shade400,
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Available',
      'Verified',
      'Highly Rated',
      'Experienced'
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade700 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Doctor> _filterDoctors(List<Doctor> doctors) {
    List<Doctor> filtered = doctors.where((doctor) {
      final query = _searchQuery;
      return doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query) ||
          doctor.email.toLowerCase().contains(query) ||
          doctor.services
              .any((service) => service.toLowerCase().contains(query)) ||
          doctor.languages
              .any((language) => language.toLowerCase().contains(query));
    }).toList();

    switch (_selectedFilter) {
      case 'Available':
        return filtered.where((doctor) => doctor.isAvailable).toList();
      case 'Verified':
        return filtered.where((doctor) => doctor.isVerified).toList();
      case 'Highly Rated':
        return filtered.where((doctor) => doctor.rating >= 4.5).toList();
      case 'Experienced':
        return filtered
            .where((doctor) =>
                doctor.experienceYears != null && doctor.experienceYears! >= 5)
            .toList();
      case 'All':
      default:
        return filtered;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Doctors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All Doctors', 'All'),
              _buildFilterOption('Available Now', 'Available'),
              _buildFilterOption('Verified Doctors', 'Verified'),
              _buildFilterOption('Highly Rated (4.5+ stars)', 'Highly Rated'),
              _buildFilterOption('Experienced (5+ years)', 'Experienced'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Apply'),
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

  Widget _buildFilterOption(String title, String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedFilter == value
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: _selectedFilter == value
                      ? Colors.blue.shade700
                      : Colors.transparent,
                ),
                child: _selectedFilter == value
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  fontWeight: _selectedFilter == value
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDoctorProfile(Doctor doctor, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(doctor: doctor),
      ),
    );
  }
}
