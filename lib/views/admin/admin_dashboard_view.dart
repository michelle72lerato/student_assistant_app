
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/application.dart';
import '../auth/login_view.dart';

// ── ViewModel ──────────────────────────────────────────────
enum AdminState { idle, loading, loaded, error }

class AdminViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  AdminState state = AdminState.idle;
  List<Map<String, dynamic>> applications = [];
  String errorMessage = '';
  String filterStatus = 'all';

  List<Map<String, dynamic>> get filtered {
    if (filterStatus == 'all') return applications;
    return applications.where((a) => a['status'] == filterStatus).toList();
  }

  Future<void> loadApplications() async {
    state = AdminState.loading;
    notifyListeners();

    try {
      final data = await _supabase
          .from('applications')
          .select('*, profiles(full_name, email)')
          .order('created_at', ascending: false);
      applications = List<Map<String, dynamic>>.from(data);
      state = AdminState.loaded;
    } catch (e) {
      state = AdminState.error;
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _supabase
          .from('applications')
          .update({'status': status})
          .eq('id', id);
      await loadApplications();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteApplication(String id) async {
    try {
      await _supabase.from('applications').delete().eq('id', id);
      await loadApplications();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setFilter(String status) {
    filterStatus = status;
    notifyListeners();
  }
}

// ── View ───────────────────────────────────────────────────
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late AdminViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AdminViewModel();
    Future.microtask(() => _vm.loadApplications());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: Colors.indigo.shade50,
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header card
                  Card(
                    color: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Admin Portal',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${vm.applications.length} total application(s)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['all', 'pending', 'approved', 'rejected'].map((f) {
                        final selected = vm.filterStatus == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f[0].toUpperCase() + f.substring(1)),
                            selected: selected,
                            onSelected: (_) => vm.setFilter(f),
                            selectedColor: Colors.indigo,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Content
                  if (vm.state == AdminState.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))

                  else if (vm.state == AdminState.error)
                    Expanded(child: Center(child: Text(vm.errorMessage, style: const TextStyle(color: Colors.red))))

                  else if (vm.filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.indigo.shade200),
                            const SizedBox(height: 16),
                            const Text('No applications found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    )

                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.filtered.length,
                        itemBuilder: (context, index) {
                          final app = vm.filtered[index];
                          final profile = app['profiles'];
                          final status = app['status'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Student info row
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.indigo,
                                        child: Icon(Icons.person, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile?['full_name'] ?? 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              profile?['email'] ?? '',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _statusColor(status)),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  // Module info
                                  Text('Module 1: ${app['module_1_name']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Level: ${app['module_1_level']}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  if (app['module_2_name'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Module 2: ${app['module_2_name']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Level: ${app['module_2_level']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 12),

                                  // Action buttons
                                  Row(
                                    children: [
                                      if (status != 'approved')
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => vm.updateStatus(app['id'], 'approved'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      if (status != 'approved' && status != 'rejected')
                                        const SizedBox(width: 8),
                                      if (status != 'rejected')
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => vm.updateStatus(app['id'], 'rejected'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _confirmDelete(context, vm, app['id']),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Delete',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to remove this application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteApplication(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
