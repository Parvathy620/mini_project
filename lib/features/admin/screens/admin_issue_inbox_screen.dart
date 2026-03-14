import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/issue_model.dart';
import '../../../core/services/issue_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import 'admin_issue_detail_screen.dart';

class AdminIssueInboxScreen extends StatefulWidget {
  const AdminIssueInboxScreen({super.key});

  @override
  State<AdminIssueInboxScreen> createState() => _AdminIssueInboxScreenState();
}

class _AdminIssueInboxScreenState extends State<AdminIssueInboxScreen> {
  IssueStatus? _statusFilter;
  IssuePriority? _priorityFilter;
  String _categoryFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final issueService = Provider.of<IssueService>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Issue Management', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterSection(),
              Expanded(
                child: StreamBuilder<List<IssueModel>>(
                  stream: issueService.getIssues(
                    status: _statusFilter,
                    priority: _priorityFilter,
                    category: _categoryFilter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }

                    var issues = snapshot.data ?? [];
                    
                    if (_searchQuery.isNotEmpty) {
                      issues = issues.where((i) => 
                        i.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        i.title.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                    }

                    if (issues.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text('No issues found', style: GoogleFonts.inter(color: Colors.white54)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: issues.length,
                      itemBuilder: (context, index) {
                        final issue = issues[index];
                        return _buildIssueCard(issue);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          LuxuryGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(16),
            opacity: 0.1,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by ID or Title...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Status', _statusFilter == null, () => setState(() => _statusFilter = null)),
                ...IssueStatus.values.map((s) => _buildFilterChip(
                  s.name.toUpperCase(), 
                  _statusFilter == s, 
                  () => setState(() => _statusFilter = s)
                )),
                const SizedBox(width: 8),
                Container(width: 1, height: 20, color: Colors.white24),
                const SizedBox(width: 8),
                _buildFilterChip('All Priority', _priorityFilter == null, () => setState(() => _priorityFilter = null)),
                 ...IssuePriority.values.map((p) => _buildFilterChip(
                  p.name.toUpperCase(), 
                  _priorityFilter == p, 
                  () => setState(() => _priorityFilter = p)
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF69F0AE).withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF69F0AE) : Colors.white10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isSelected ? const Color(0xFF69F0AE) : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    Color priorityColor = _getPriorityColor(issue.priority);
    Color statusColor = _getStatusColor(issue.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminIssueDetailScreen(issue: issue)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: LuxuryGlass(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          opacity: 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '#${issue.id}',
                      style: GoogleFonts.ibmPlexMono(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.status.name.toUpperCase(),
                      style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                issue.description,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(issue.reporterName ?? 'User', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  Text(
                    DateFormat('MMM d, hh:mm a').format(issue.createdAt),
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Color _getStatusColor(IssueStatus s) {
    switch (s) {
      case IssueStatus.pending: return Colors.orangeAccent;
      case IssueStatus.inProgress: return Colors.blueAccent;
      case IssueStatus.resolved: return const Color(0xFF69F0AE);
      case IssueStatus.rejected: return Colors.redAccent;
    }
  }
}
