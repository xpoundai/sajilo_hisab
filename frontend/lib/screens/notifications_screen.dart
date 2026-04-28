import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

// Tab metadata
const _tabs = ['All', 'Unread', 'Transactions', 'Payments', 'Inventory'];
const _tabTypes = [null, null, 'transaction', 'payment', 'inventory'];
// tab 0 = all, tab 1 = unread-only, tab 2+ = by type

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationItem> _filtered(List<NotificationItem> all, int tabIndex) {
    if (tabIndex == 1) return all.where((n) => !n.isRead).toList();
    final type = _tabTypes[tabIndex];
    if (type == null) return all;
    return all.where((n) => n.type == type).toList();
  }

  // Label shown in the confirm dialog
  String _tabLabel(int tabIndex) {
    if (tabIndex == 0) return 'all notifications';
    if (tabIndex == 1) return 'all unread notifications';
    return 'all ${_tabs[tabIndex].toLowerCase()} notifications';
  }

  Future<void> _sweepTab(NotificationProvider provider, int tabIndex) async {
    final label = _tabLabel(tabIndex);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear notifications'),
        content: Text('Delete $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bool unreadOnly = tabIndex == 1;
    final String? type = tabIndex >= 2 ? _tabTypes[tabIndex] : null;

    await provider.deleteByFilter(unreadOnly: unreadOnly, type: type);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared ${_tabs[tabIndex].toLowerCase()} notifications'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markAllRead(NotificationProvider provider) async {
    await provider.markAllRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final visibleItems = _filtered(provider.notifications, _currentTab);
    final hasItems = visibleItems.isNotEmpty;
    final hasUnread = provider.unreadCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.unreadCount}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Mark all read — only when there are unread items
          if (hasUnread)
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllRead(provider),
            ),
          // Sweep / clear current tab — only when tab has items
          if (hasItems)
            IconButton(
              tooltip: 'Clear ${_tabs[_currentTab].toLowerCase()}',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _sweepTab(provider, _currentTab),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: List.generate(_tabs.length, (i) {
            final count = _filtered(provider.notifications, i).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tabs[i]),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (i) {
                  final items = _filtered(provider.notifications, i);
                  if (items.isEmpty) {
                    return const EmptyWidget(
                      message: 'No notifications here',
                      icon: Icons.notifications_none_rounded,
                    );
                  }
                  return _NotificationList(items: items);
                }),
              ),
            ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<NotificationItem> items;
  const _NotificationList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => _NotificationTile(item: items[index]),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorRed,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => provider.deleteNotification(item.id),
      child: InkWell(
        onTap: () {
          if (!item.isRead) provider.markRead(item.id);
        },
        child: Container(
          color: item.isRead
              ? Colors.transparent
              : AppTheme.primaryBlue.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(item.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(item.type),
                    color: _typeColor(item.type), size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PriorityDot(priority: item.priority),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTime(item.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight),
                        ),
                        const Spacer(),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'transaction':
        return Icons.swap_horiz_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'user':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'transaction':
        return AppTheme.primaryBlue;
      case 'payment':
        return AppTheme.accentGreen;
      case 'inventory':
        return AppTheme.warningYellow;
      case 'user':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Priority dot ─────────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'high':
        color = AppTheme.errorRed;
        break;
      case 'medium':
        color = AppTheme.warningYellow;
        break;
      default:
        color = AppTheme.textLight;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
