import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';
import 'package:smart_travel/presentation/blocs/admin_host_approval/host_approval_bloc.dart';
import 'package:smart_travel/presentation/blocs/admin_host_approval/host_approval_event.dart';
import 'package:smart_travel/presentation/blocs/admin_host_approval/host_approval_state.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class AdminHostApprovalScreen extends StatefulWidget {
  const AdminHostApprovalScreen({super.key});

  @override
  State<AdminHostApprovalScreen> createState() => _AdminHostApprovalScreenState();
}

class _AdminHostApprovalScreenState extends State<AdminHostApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HostApprovalBloc>().add(const LoadPendingHosts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HostApprovalBloc, HostApprovalState>(
      listener: (context, state) {
        if (state is HostApprovalActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is HostApprovalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final hosts = state is HostApprovalLoaded ? state.hosts : <HostApprovalResponseModel>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Duyệt Chủ Homestay'),
            centerTitle: true,
            elevation: 2,
            actions: [
              IconButton(
                onPressed: () => context.read<HostApprovalBloc>().add(const LoadPendingHosts()),
                icon: const Icon(Icons.refresh),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(gradient: AppColors.mainGradient),
            ),
          ),
          body: _buildBody(context, state, hosts),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HostApprovalState state, List<HostApprovalResponseModel> hosts) {
    if (state is HostApprovalLoading || state is HostApprovalInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HostApprovalError && hosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<HostApprovalBloc>().add(const LoadPendingHosts()),
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    if (hosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Không có chủ homestay chờ duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HostApprovalBloc>().add(const LoadPendingHosts());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: hosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildHostCard(context, hosts[index]),
      ),
    );
  }

  Widget _buildHostCard(BuildContext context, HostApprovalResponseModel host) {
    final initial = host.fullName.isNotEmpty ? host.fullName[0].toUpperCase() : '?';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(host.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(host.email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Số điện thoại', host.phone ?? 'Chưa có'),
            _infoRow('Số CCCD', host.idCardNumber ?? 'Chưa có'),
            _infoRow('Ngày đăng ký', host.createdAt?.toString().split('.').first ?? 'N/A'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context, host),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(context, host),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showViewDocumentsDialog(context, host),
                icon: const Icon(Icons.image),
                label: const Text('Xem Tài Liệu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, HostApprovalResponseModel host) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc chắn muốn duyệt hồ sơ của ${host.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<HostApprovalBloc>().add(ApproveHostRequested(host.userId));
            },
            child: const Text('Duyệt', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, HostApprovalResponseModel host) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối hồ sơ của ${host.fullName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<HostApprovalBloc>().add(
                    RejectHostRequested(
                      userId: host.userId,
                      reason: reasonController.text.trim().isEmpty ? 'Không đủ điều kiện' : reasonController.text.trim(),
                    ),
                  );
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  void _showViewDocumentsDialog(BuildContext context, HostApprovalResponseModel host) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tài liệu xác thực'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _documentPreview('Ảnh chân dung', host.portraitUrl),
              const SizedBox(height: 12),
              _documentPreview('Ảnh CCCD', host.idCardImageUrl),
              const SizedBox(height: 12),
              _documentPreview('Giấy tờ sở hữu', host.ownershipDocumentUrl),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng'))],
      ),
    );
  }

  Widget _documentPreview(String title, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: url == null || url.isEmpty
              ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
        ),
      ],
    );
  }
}

