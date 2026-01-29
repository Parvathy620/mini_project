import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/verification_model.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_container.dart';
import 'verification_review_screen.dart';

class AdminVerificationDashboard extends StatefulWidget {
  const AdminVerificationDashboard({super.key});

  @override
  State<AdminVerificationDashboard> createState() => _AdminVerificationDashboardState();
}

class _AdminVerificationDashboardState extends State<AdminVerificationDashboard> {
  final VerificationService _service = VerificationService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ProviderVerification> _pendingRequests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.checkAndProcessExpirations(); 
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _service.getPendingRequests();
      setState(() => _pendingRequests = requests);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Client-side filtering
    final filteredRequests = _pendingRequests.where((req) {
      if (_searchQuery.isEmpty) return true;
      return req.providerId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             req.documentType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Verification Requests',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Search Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: LuxuryGlass(
                  height: 50,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(16),
                  opacity: 0.1,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by ID or Type...',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: filteredRequests.isEmpty
                          ? Center(
                              child: GlassContainer(
                                padding: const EdgeInsets.all(24),
                                borderRadius: BorderRadius.circular(16),
                                child: Text(
                                  _searchQuery.isEmpty 
                                    ? 'No pending requests' 
                                    : 'No matching requests',
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: filteredRequests.length,
                              itemBuilder: (context, index) {
                                final req = filteredRequests[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: LuxuryGlass(
                                    opacity: 0.1,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VerificationReviewScreen(verification: req),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadData(); 
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF66BB6A).withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.assignment_ind, color: Color(0xFF66BB6A)),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Provider ID: ${req.providerId.substring(0, 5)}...',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${req.documentType} • ${req.submittedAt.toString().split(' ')[0]}',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
