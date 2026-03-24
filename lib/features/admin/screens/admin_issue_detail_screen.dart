import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/issue_model.dart';
import '../../../core/services/issue_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/drive_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminIssueDetailScreen extends StatefulWidget {
  final IssueModel issue;
  const AdminIssueDetailScreen({super.key, required this.issue});

  @override
  State<AdminIssueDetailScreen> createState() => _AdminIssueDetailScreenState();
}

class _AdminIssueDetailScreenState extends State<AdminIssueDetailScreen> {
  late IssueStatus _currentStatus;
  late IssuePriority _currentPriority;
  final TextEditingController _noteController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.issue.status;
    _currentPriority = widget.issue.priority;
    _noteController.text = widget.issue.adminNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);
    try {
      final service = Provider.of<IssueService>(context, listen: false);
      await service.updateIssueStatus(
        widget.issue.id, 
        _currentStatus, 
        adminNote: _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Issue Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildDescriptionCard(),
                const SizedBox(height: 20),
                if (widget.issue.location != null) _buildLocationCard(),
                const SizedBox(height: 20),
                if (widget.issue.mediaUrls.isNotEmpty) _buildMediaCard(),
                const SizedBox(height: 20),
                _buildAdminControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${widget.issue.id}', style: GoogleFonts.ibmPlexMono(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
              Text(
                DateFormat('MMM d, yyyy').format(widget.issue.createdAt),
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.issue.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(widget.issue.category, Colors.blueGrey),
              const SizedBox(width: 8),
              _buildBadge(widget.issue.priority.name.toUpperCase(), _getPriorityColor(widget.issue.priority)),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white54)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.issue.reporterName ?? 'Anonymous User', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Reporter ID: ${widget.issue.reporterId.substring(0, 8)}...', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESCRIPTION', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(
            widget.issue.description,
            style: GoogleFonts.inter(color: Colors.white, height: 1.6, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final loc = widget.issue.location!;
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOCATION', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(loc.address ?? 'Coordinates Provided', style: GoogleFonts.inter(color: Colors.white)),
          if (loc.latitude != null && loc.longitude != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(loc.latitude!, loc.longitude!),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('issue_loc'),
                      position: LatLng(loc.latitude!, loc.longitude!),
                    ),
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  liteModeEnabled: false, 
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(' EVIDENCE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.issue.mediaUrls.length,
            itemBuilder: (context, index) {
              final rawUrl = widget.issue.mediaUrls[index];
              final imageUrl = DriveService.getDirectLinkFromUrl(rawUrl) ?? rawUrl;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(rawUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.white10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.white38, size: 32),
                              const SizedBox(height: 8),
                              Text('Open Link', style: GoogleFonts.inter(color: const Color(0xFF69F0AE), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminControls() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADMIN ACTIONS', style: GoogleFonts.inter(color: const Color(0xFF69F0AE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildStatusDropdown(),
          const SizedBox(height: 20),
          _buildAdminNoteField(),
          const SizedBox(height: 24),
          _isUpdating
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)))
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF69F0AE),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('UPDATE STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Update Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<IssueStatus>(
              value: _currentStatus,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              items: IssueStatus.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _currentStatus = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Note (Visible to User)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add a note for the reporter...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getPriorityColor(IssuePriority p) {
    switch (p) {
      case IssuePriority.low: return Colors.blue;
      case IssuePriority.medium: return Colors.greenAccent;
      case IssuePriority.high: return Colors.orange;
      case IssuePriority.urgent: return Colors.redAccent;
    }
  }
}
