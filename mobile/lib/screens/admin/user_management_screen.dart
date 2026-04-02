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
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter users
          var users = adminProvider.allUsers.where((user) {
            final matchesSearch = _searchQuery.isEmpty ||
                (user['fullName'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (user['email'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            final matchesRole =
                _roleFilter == 'All' || user['role'] == _roleFilter;
            return matchesSearch && matchesRole;
          }).toList();

          return Column(
            children: [
              // Search + filter bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
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
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    // Replace Row with Wrap for role filters
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ['All', 'PLAYER', 'OWNER', 'ADMIN']
                          .map((role) => FilterChip(
                                label: Text(role),
                                selected: _roleFilter == role,
                                onSelected: (_) =>
                                    setState(() => _roleFilter = role),
                                selectedColor: Colors.green.shade100,
                                checkmarkColor: Colors.green,
                              ))
                          .toList(),
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
                    ? const Center(child: Text('No users found'))
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
                                      backgroundColor: isAdmin
                                          ? Colors.red.shade100
                                          : isOwner
                                              ? Colors.orange.shade100
                                              : Colors.green.shade100,
                                      child: Text(
                                        (user['fullName'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
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
                                          // Replace Row(children: [name, role badge, pending badge]) with
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                user['fullName'] ?? 'User',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAdmin
                                                      ? Colors.red.shade50
                                                      : isOwner
                                                          ? Colors
                                                              .orange.shade50
                                                          : Colors
                                                              .green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  user['role'] ?? 'PLAYER',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAdmin
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
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (!isActive)
                                            Text(
                                              'Blocked',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.w500,
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
                                              final result = await adminProvider
                                                  .toggleUserStatus(
                                                      user['id'], !isActive);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content:
                                                      Text(result['message']),
                                                ));
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
