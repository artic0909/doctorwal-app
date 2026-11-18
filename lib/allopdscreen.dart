import 'dart:async';
import 'dart:convert';
import 'package:demoapp/opddetailsscreen.dart';
import 'package:demoapp/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:demoapp/services/location_service.dart';

import 'Models/all_available_opd_model.dart';

class AllAvailableOPDScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AllAvailableOPDScreen({super.key, required this.userData});

  @override
  State<AllAvailableOPDScreen> createState() => _AllAvailableOPDScreenState();
}

class _AllAvailableOPDScreenState extends State<AllAvailableOPDScreen> {
  static List<AllAvailableOPDModel> _cachedClinics = [];
  List<AllAvailableOPDModel> _clinics = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadMoreLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isNearMe = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fast render from cache immediately
    if (_cachedClinics.isNotEmpty) {
      _clinics = List.from(_cachedClinics);
      _isLoading = false;
    }
    _initData();
  }

  Future<void> _initData() async {
    final val = await LocationService.getIsNearMe();
    if (mounted) setState(() => _isNearMe = val);
    _fetchInitialClinics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchInitialClinics();
      }
    });
  }

  Future<void> _fetchInitialClinics() async {
    if (_searchQuery.isEmpty && _cachedClinics.isNotEmpty) {
      if (mounted) {
        setState(() {
          _clinics = List.from(_cachedClinics);
          _isLoading = false;
          _currentPage = 1;
        });
      }
      await _fetchClinics(1);
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _currentPage = 1;
          _clinics = [];
        });
      }
      await _fetchClinics(1);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchClinics(int page) async {
    String queryParam = _searchQuery.isNotEmpty ? '&query=${Uri.encodeComponent(_searchQuery)}' : '';
    if (_isNearMe) {
      final city = await LocationService.getUserCity(context: context);
      if (city != null && city.isNotEmpty) {
        queryParam += '&user_city=${Uri.encodeComponent(city)}';
      }
    }
    final url = Uri.parse(
      "https://doctorwala.info/api/api/all-opd-contacts?page=$page$queryParam",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        final bool isSearch = jsonData['is_search'] ?? false;
        
        final newClinics = data.map((json) => AllAvailableOPDModel.fromJson(json)).toList();
        if (page == 1 && _searchQuery.isEmpty) {
          _cachedClinics = List.from(newClinics);
        }

        if (mounted) {
          setState(() {
            if (page == 1) {
              _clinics = newClinics;
            } else {
              _clinics.addAll(newClinics);
            }
            
            if (isSearch) {
              _currentPage = 1;
              _lastPage = 1;
            } else {
              _currentPage = jsonData['current_page'] ?? 1;
              _lastPage = jsonData['last_page'] ?? 1;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching OPD clinics: $e");
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage || _isLoadMoreLoading) return;

    setState(() => _isLoadMoreLoading = true);
    await _fetchClinics(_currentPage + 1);
    setState(() => _isLoadMoreLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Removed client-side filtering
    final displayClinics = _clinics;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const OpdListSkeleton()
                : RefreshIndicator(
                    onRefresh: _fetchInitialClinics,
                    color: const Color(0xFF1565C0),
                    child: displayClinics.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            MediaQuery.of(context).viewPadding.bottom + 25,
                          ),
                          itemCount: displayClinics.length + (_currentPage < _lastPage ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < displayClinics.length) {
                              return _buildClinicCard(displayClinics[index]);
                            } else {
                              return _buildLoadMoreBtn();
                            }
                          },
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No OPD clinics available" : "No results for \"$_searchQuery\"",
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 18.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Available OPD Clinics",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Book clinical appointments instantly",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Search for clinics or doctors...",
                            hintStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.blueGrey),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final newValue = !_isNearMe;
                  setState(() => _isNearMe = newValue);
                  await LocationService.setIsNearMe(newValue);
                  _fetchInitialClinics();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _isNearMe ? const Color(0xFF2E7D32) : Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isNearMe ? Colors.lightGreenAccent : Colors.white.withAlpha(100),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isNearMe ? Icons.location_on_rounded : Icons.location_off_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isNearMe ? "Near Me" : "Everywhere",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(AllAvailableOPDModel clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withAlpha(8), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(15), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => OPDDetailsScreen(opd: clinic, userData: widget.userData))),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70, height: 70, color: const Color(0xFF1565C0).withAlpha(10),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF1565C0), size: 30),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeWords(clinic.clinicName),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _capitalizeWords(clinic.clinicAddress),
                        style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 12, color: Colors.blueGrey[300]),
                          const SizedBox(width: 6),
                          Text(
                            "${clinic.doctors.length} Specialists Available",
                            style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: _isLoadMoreLoading
            ? const CircularProgressIndicator(color: Color(0xFF1565C0))
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: const Color(0xFF1565C0).withAlpha(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "VIEW MORE CLINICS",
                  style: TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
      ),
    );
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}
