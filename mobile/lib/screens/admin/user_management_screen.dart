import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, _) {
              final blockedCount = adminProvider.allUsers
                  .where((u) => u['isActive'] == false)
                  .length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$blockedCount Blocked',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter users
          var users = adminProvider.allUsers.where((user) {
            // Search filter
            final matchesSearch = _searchQuery.isEmpty ||
                (user['fullName'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (user['email'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

            // Role filter
            final matchesRole =
                _roleFilter == 'All' || user['role'] == _roleFilter;

            // Status filter
            final matchesStatus = _statusFilter == 'All' ||
                (_statusFilter == 'Active' && user['isActive'] == true) ||
                (_statusFilter == 'Blocked' && user['isActive'] == false);

            return matchesSearch && matchesRole && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Search + filter bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),

                    // ✅ Combined filter row - Role and Status side by side
                    Row(
                      children: [
                        // Role filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _roleFilter,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'All', child: Text('All Roles')),
                                    DropdownMenuItem(
                                        value: 'PLAYER', child: Text('Player')),
                                    DropdownMenuItem(
                                        value: 'OWNER', child: Text('Owner')),
                                    DropdownMenuItem(
                                        value: 'ADMIN', child: Text('Admin')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _roleFilter = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _statusFilter,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All Status')),
                                    DropdownMenuItem(
                                        value: 'Active', child: Text('Active')),
                                    DropdownMenuItem(
                                        value: 'Blocked',
                                        child: Text('Blocked')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _statusFilter = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Clear filters button (only show when filters are active)
                    if (_roleFilter != 'All' ||
                        _statusFilter != 'All' ||
                        _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _roleFilter = 'All';
                                _statusFilter = 'All';
                              });
                            },
                            child: const Text('Clear All Filters'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // User count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${users.length} users',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // User list
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _statusFilter == 'Blocked'
                                  ? Icons.block
                                  : Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _statusFilter == 'Blocked'
                                  ? 'No blocked users found'
                                  : 'No users found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => adminProvider.loadAllUsers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: users.length,
                          itemBuilder: (_, index) {
                            final user = users[index];
                            final isOwner = user['role'] == 'OWNER';
                            final isAdmin = user['role'] == 'ADMIN';
                            final isApproved = user['isApproved'] ?? false;
                            final isActive = user['isActive'] ?? true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: !isActive
                                          ? Colors.grey.shade300
                                          : isAdmin
                                              ? Colors.red.shade100
                                              : isOwner
                                                  ? Colors.orange.shade100
                                                  : Colors.green.shade100,
                                      child: Text(
                                        (user['fullName'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: !isActive
                                              ? Colors.grey.shade600
                                              : isAdmin
                                                  ? Colors.red
                                                  : isOwner
                                                      ? Colors.orange
                                                      : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                user['fullName'] ?? 'User',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: !isActive
                                                      ? Colors.grey.shade600
                                                      : null,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: !isActive
                                                      ? Colors.grey.shade200
                                                      : isAdmin
                                                          ? Colors.red.shade50
                                                          : isOwner
                                                              ? Colors.orange
                                                                  .shade50
                                                              : Colors.green
                                                                  .shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  user['role'] ?? 'PLAYER',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: !isActive
                                                        ? Colors.grey.shade600
                                                        : isAdmin
                                                            ? Colors.red
                                                            : isOwner
                                                                ? Colors.orange
                                                                : Colors.green,
                                                  ),
                                                ),
                                              ),
                                              if (isOwner && !isApproved)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Pending',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors
                                                          .orange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              if (!isActive)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Blocked',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.red.shade700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: !isActive
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    if (!isAdmin)
                                      Column(
                                        children: [
                                          if (isOwner && !isApproved)
                                            IconButton(
                                              icon: const Icon(Icons.check,
                                                  color: Colors.green,
                                                  size: 20),
                                              tooltip: 'Approve Owner',
                                              onPressed: () async {
                                                final result =
                                                    await adminProvider
                                                        .approveOwner(
                                                            user['id']);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content:
                                                        Text(result['message']),
                                                    backgroundColor:
                                                        result['status'] ==
                                                                'success'
                                                            ? Colors.green
                                                            : Colors.red,
                                                  ));
                                                }
                                              },
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              isActive
                                                  ? Icons.block
                                                  : Icons.check_circle,
                                              color: isActive
                                                  ? Colors.red
                                                  : Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: isActive
                                                ? 'Block User'
                                                : 'Unblock User',
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    isActive
                                                        ? 'Block User'
                                                        : 'Unblock User',
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? Colors.red
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    isActive
                                                        ? 'Are you sure you want to block ${user['fullName']}?\n\nThey will not be able to login to the app.'
                                                        : 'Are you sure you want to unblock ${user['fullName']}?\n\nThey will regain access to the app.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child:
                                                          const Text('CANCEL'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            isActive
                                                                ? Colors.red
                                                                : Colors.green,
                                                      ),
                                                      child: Text(isActive
                                                          ? 'BLOCK'
                                                          : 'UNBLOCK'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                final result =
                                                    await adminProvider
                                                        .toggleUserStatus(
                                                            user['id'],
                                                            !isActive);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          result['message']),
                                                      backgroundColor:
                                                          result['status'] ==
                                                                  'success'
                                                              ? Colors.green
                                                              : Colors.red,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
