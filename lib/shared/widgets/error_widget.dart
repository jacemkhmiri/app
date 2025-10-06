import 'package:flutter/material.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/failures.dart';

class CustomErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ErrorHandler.getErrorMessage(failure),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (failure.runtimeType) {
      case ServerFailure:
        return Icons.cloud_off;
      case NetworkFailure:
        return Icons.wifi_off;
      case CacheFailure:
        return Icons.storage;
      case P2PFailure:
        return Icons.link_off;
      case ValidationFailure:
        return Icons.warning;
      case AuthenticationFailure:
        return Icons.lock;
      default:
        return Icons.error;
    }
  }

  String _getErrorTitle() {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error';
      case NetworkFailure:
        return 'Connection Error';
      case CacheFailure:
        return 'Storage Error';
      case P2PFailure:
        return 'Connection Error';
      case ValidationFailure:
        return 'Validation Error';
      case AuthenticationFailure:
        return 'Authentication Error';
      default:
        return 'Something went wrong';
    }
  }
}
