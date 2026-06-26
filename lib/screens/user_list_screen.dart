import 'package:clinic_web_dashboard/constants/app_constants.dart';
// Importing necessary Flutter and third-party packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rxdart/rxdart.dart';

// UserListScreen widget definition
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

// State class for UserListScreen with TickerProviderStateMixin for animations
class _UserListScreenState extends State<UserListScreen> with TickerProviderStateMixin {
  // Animation controllers and animations for fade and slide effects
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables for pagination, search, and filtering
  int _currentPage = 0;
  int _itemsPerPage = 12; // Increased to show more users per page
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  // State variables for tracking online users
  Map<String, bool> _onlineUsers = {};
  ValueNotifier<int> _onlineCountNotifier = ValueNotifier(0);
  bool _isLoadingPresence = true;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _initializePresence();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    // Clean up controllers and notifiers
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _onlineCountNotifier.dispose();
    super.dispose();
  }

  // Initialize presence tracking for users
  void _initializePresence() async {
    setState(() => _isLoadingPresence = true);
    final userSnapshot = await FirebaseFirestore.instance.collection(Collections.users).get();
    final doctorSnapshot = await FirebaseFirestore.instance.collection(Collections.doctors).get();
    final users = [...userSnapshot.docs, ...doctorSnapshot.docs];
    _onlineUsers = {for (var user in users) user.id: false};

    // Listen to presence changes
    final presenceStream = FirebaseFirestore.instance.collection(Collections.presence).snapshots();
    presenceStream.listen((snapshot) {
      snapshot.docs.forEach((doc) {
        final userId = doc.id;
        final isOnline = doc.data()['online'] ?? false;
        if (_onlineUsers.containsKey(userId)) {
          _onlineUsers[userId] = isOnline;
        }
      });
      _onlineCountNotifier.value = _onlineUsers.values.where((online) => online).length;
      if (mounted) setState(() => _isLoadingPresence = false);
    });
  }

  // Filter users based on search query, role, and status
  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
      final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
      final fullName = '$firstName $lastName';
      final role = userData['role']?.toString().toLowerCase() ?? (user.reference.parent.id == 'doctors' ? 'doctor' : 'user');
      final userId = user.id;
      final isOnline = _onlineUsers[userId] ?? false;

      if (_searchQuery.isNotEmpty && !fullName.contains(_searchQuery.toLowerCase())) return false;
      if (_selectedRole != 'All' && role != _selectedRole.toLowerCase()) return false;
      if (_statusFilter == 'Online' && !isOnline) return false;
      if (_statusFilter == 'Offline' && isOnline) return false;
      return true;
    }).toList();
  }

  // Refresh user presence stats
  void _refreshStats() {
    setState(() => _isLoadingPresence = true);
    _initializePresence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('User Management', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Compact stats and filter section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Stats display
                    StreamBuilder<List<QuerySnapshot>>(
                      stream: Rx.combineLatest2(
                        FirebaseFirestore.instance.collection(Collections.users).snapshots(),
                        FirebaseFirestore.instance.collection(Collections.doctors).snapshots(),
                        (QuerySnapshot users, QuerySnapshot doctors) => [users, doctors],
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return _buildStatsShimmer();
                        final users = [...snapshot.data![0].docs, ...snapshot.data![1].docs];
                        return ValueListenableBuilder<int>(
                          valueListenable: _onlineCountNotifier,
                          builder: (context, onlineCount, child) {
                            if (_isLoadingPresence) return _buildStatsShimmer();
                            final totalUsers = users.length;
                            final offlineCount = totalUsers - onlineCount;
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard('Total', totalUsers.toString(), Icons.people, size: 16),
                                  _buildStatCard('Online', onlineCount.toString(), Icons.circle, color: const Color(0xFF4CAF50), size: 16),
                                  _buildStatCard('Offline', offlineCount.toString(), Icons.circle_outlined, color: Colors.white70, size: 16),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Compact filter section
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                hintStyle: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 12),
                                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              style: GoogleFonts.roboto(fontSize: 12),
                              onChanged: (value) => setState(() {
                                _searchQuery = value;
                                _currentPage = 0;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                hint: Text('Role', style: GoogleFonts.roboto(fontSize: 12)),
                                isExpanded: true,
                                items: ['All', 'Admin', 'Doctor', 'Patient']
                                    .map((role) => DropdownMenuItem(value: role, child: Text(role, style: GoogleFonts.roboto(fontSize: 12))))
                                    .toList(),
                                onChanged: (value) => setState(() {
                                  _selectedRole = value!;
                                  _currentPage = 0;
                                }),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _statusFilter,
                                hint: Text('Status', style: GoogleFonts.roboto(fontSize: 12)),
                                isExpanded: true,
                                items: ['All', 'Online', 'Offline']
                                    .map((status) => DropdownMenuItem(value: status, child: Text(status, style: GoogleFonts.roboto(fontSize: 12))))
                                    .toList(),
                                onChanged: (value) => setState(() {
                                  _statusFilter = value!;
                                  _currentPage = 0;
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Expanded user list section
              Expanded(
                child: StreamBuilder<List<QuerySnapshot>>(
                  stream: Rx.combineLatest2(
                    FirebaseFirestore.instance.collection(Collections.users).snapshots(),
                    FirebaseFirestore.instance.collection(Collections.doctors).snapshots(),
                    (QuerySnapshot users, QuerySnapshot doctors) => [users, doctors],
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                    if (snapshot.hasError) {
                      debugPrint('Error fetching users: ${snapshot.error}');
                      return _buildErrorState();
                    }
                    if (!snapshot.hasData || (snapshot.data![0].docs.isEmpty && snapshot.data![1].docs.isEmpty)) return _buildEmptyState();

                    final allUsers = [...snapshot.data![0].docs, ...snapshot.data![1].docs];
                    final filteredUsers = _filterUsers(allUsers);
                    final totalPages = (filteredUsers.length / _itemsPerPage).ceil();
                    final startIndex = _currentPage * _itemsPerPage;
                    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredUsers.length);
                    final currentPageUsers = filteredUsers.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Showing ${startIndex + 1}-${endIndex} of ${filteredUsers.length}',
                                  style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 12)),
                              Text('Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                                  style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: currentPageUsers.length,
                            itemBuilder: (context, index) {
                              final userDoc = currentPageUsers[index];
                              return AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                                child: _buildUserCard(userDoc, key: ValueKey(userDoc.id)),
                              );
                            },
                          ),
                        ),
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _currentPage > 0 ? AppColors.primary : Colors.grey[300],
                                    foregroundColor: _currentPage > 0 ? Colors.white : Colors.grey[600],
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(totalPages.clamp(0, 5), (index) {
                                  final pageNumber = index;
                                  final isCurrentPage = pageNumber == _currentPage;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => setState(() => _currentPage = pageNumber),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCurrentPage ? AppColors.primary : Colors.grey[200],
                                        foregroundColor: isCurrentPage ? Colors.white : Colors.grey[700],
                                        minimumSize: const Size(36, 36),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        elevation: isCurrentPage ? 2 : 0,
                                      ),
                                      child: Text('${pageNumber + 1}', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _currentPage < totalPages - 1 ? AppColors.primary : Colors.grey[300],
                                    foregroundColor: _currentPage < totalPages - 1 ? Colors.white : Colors.grey[600],
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

  // Build compact stat card
  Widget _buildStatCard(String title, String value, IconData icon, {Color? color, double size = 20}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: size),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
          child: Text(value, key: ValueKey(value), style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Text(title, style: GoogleFonts.roboto(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Build shimmer effect for stats loading
  Widget _buildStatsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildShimmerStatCard(Icons.people),
            _buildShimmerStatCard(Icons.circle),
            _buildShimmerStatCard(Icons.circle_outlined),
          ],
        ),
      ),
    );
  }

  // Build shimmer stat card
  Widget _buildShimmerStatCard(IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // Build user card for grid layout
  Widget _buildUserCard(QueryDocumentSnapshot userDoc, {Key? key}) {
    final user = userDoc.data() as Map<String, dynamic>;
    final userId = userDoc.id;
    final isDoctor = userDoc.reference.parent.id == 'doctors';
    final displayName = (user['firstName'] != null && user['lastName'] != null)
        ? '${user['firstName']} ${user['lastName']}'
        : user['name'] ?? 'Unnamed User';

    return StreamBuilder<Map<String, dynamic>?>(
      key: key,
      stream: FirebaseFirestore.instance.collection(Collections.presence).doc(userId).snapshots().map((doc) => doc.data()),
      builder: (context, presenceSnapshot) {
        if (!presenceSnapshot.hasData) return const SizedBox.shrink();
        final presence = presenceSnapshot.data!;
        final isOnline = presence['online'] ?? false;
        final lastSeenTimestamp = presence['lastSeen'];
        // Handle Timestamp conversion safely
        final lastSeen = lastSeenTimestamp != null
            ? _formatLastSeen(lastSeenTimestamp is Timestamp
                ? lastSeenTimestamp.toDate()
                : DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp as int))
            : 'Never';

        if (_onlineUsers[userId] != isOnline) {
          _onlineUsers[userId] = isOnline;
          _onlineCountNotifier.value = _onlineUsers.values.where((online) => online).length;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isOnline ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.grey.withOpacity(0.2), width: 1),
            boxShadow: [BoxShadow(color: isOnline ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_getAvatarColor(displayName), _getAvatarColor(displayName).withOpacity(0.7)]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _getAvatarColor(displayName).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Center(child: Text(displayName[0].toUpperCase(), style: GoogleFonts.roboto(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 4, spreadRadius: 1)],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF808080), size: 20),
                          onSelected: (value) {},
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('View Profile', style: GoogleFonts.roboto(fontSize: 12))])),
                            PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('Edit User', style: GoogleFonts.roboto(fontSize: 12))])),
                            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 14, color: Colors.red), SizedBox(width: 6), Text('Delete User', style: GoogleFonts.roboto(fontSize: 12))])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2C2C2C)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(isDoctor ? 'doctor' : user['role']).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _getRoleColor(isDoctor ? 'doctor' : user['role']).withOpacity(0.3)),
                          ),
                          child: Text(isDoctor ? 'Doctor' : user['role'] ?? 'User', style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w600, color: _getRoleColor(isDoctor ? 'doctor' : user['role']))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF808080), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isOnline ? 'Online' : lastSeen,
                            style: GoogleFonts.roboto(fontSize: 10, color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF808080), fontWeight: isOnline ? FontWeight.w500 : FontWeight.w400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  // Loading state widget
  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            SizedBox(height: 12),
            Text('Loading users...', style: GoogleFonts.roboto(color: const Color(0xFF808080), fontSize: 14)),
          ],
        ),
      );

  // Error state widget
  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFE57373)),
            SizedBox(height: 12),
            Text('Error loading users', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2C2C2C))),
            SizedBox(height: 6),
            Text('Please try again later', style: GoogleFonts.roboto(color: const Color(0xFF808080), fontSize: 12)),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Retry', style: GoogleFonts.roboto(fontSize: 12)),
            ),
          ],
        ),
      );

  // Empty state widget
  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Color(0xFF808080)),
            SizedBox(height: 12),
            Text('No users found', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2C2C2C))),
            SizedBox(height: 6),
            Text('Users will appear here once registered', style: GoogleFonts.roboto(color: const Color(0xFF808080), fontSize: 12)),
          ],
        ),
      );

  // Generate avatar color based on name
  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      Color(0xFF9ACD32),
      Color(0xFF6B8E23),
      Color(0xFF8FBC8F),
      Color(0xFF90EE90),
      Color(0xFF228B22),
      Color(0xFF32CD32),
      Color(0xFF00FF00),
    ];
    return colors[name.hashCode % colors.length];
  }

  // Get color based on user role
  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Color(0xFFE57373);
      case 'doctor':
        return Color(0xFF64B5F6);
      case 'patient':
        return Color(0xFFBA68C8);
      default:
        return Color(0xFF808080);
    }
  }

  // Format last seen timestamp
  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}


