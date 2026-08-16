import 'package:flutter/material.dart';
import '../../../../data/services/cache_service.dart';
import '../../../../core/error_handling/error_handler.dart';

class ConnectivityStatus extends StatefulWidget {
  const ConnectivityStatus({super.key});

  @override
  State<ConnectivityStatus> createState() => _ConnectivityStatusState();
}

class _ConnectivityStatusState extends State<ConnectivityStatus> {
  bool _isOnline = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isChecking = true);
    
    try {
      final isOnline = await CacheService.isOnline();
      setState(() {
        _isOnline = isOnline;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() => _isChecking = true);
    
    try {
      await CacheService.syncData();
      await _checkConnectivity();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne - Certaines fonctionnalités peuvent être limitées',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isChecking)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              onPressed: _syncData,
              tooltip: 'Synchroniser',
            ),
        ],
      ),
    );
  }
}

// Widget pour afficher le statut de connectivité dans une app bar
class ConnectivityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const ConnectivityAppBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const ConnectivityStatus(),
      ],
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(
      child.preferredSize.height + 40, // Hauteur du statut de connectivité
    );
  }
}
