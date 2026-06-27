import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransferStatus { uploading, downloading, completed, failed, retrying }

class FileTransferState {
  final String id;
  final String name;
  final double progress; // 0.0 to 1.0
  final TransferStatus status;
  final String? errorMessage;

  FileTransferState({
    required this.id,
    required this.name,
    required this.progress,
    required this.status,
    this.errorMessage,
  });

  FileTransferState copyWith({
    String? id,
    String? name,
    double? progress,
    TransferStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileTransferState(
      id: id ?? this.id,
      name: name ?? this.name,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TransferRegistry {
  static final List<Function(String id, double progress)> _listeners = [];
  static final List<Function(String id, String name, TransferStatus status, {String? error})> _statusListeners = [];
  
  static void addListener(Function(String id, double progress) listener) {
    _listeners.add(listener);
  }
  static void addStatusListener(Function(String id, String name, TransferStatus status, {String? error}) listener) {
    _statusListeners.add(listener);
  }
  static void removeListener(Function(String id, double progress) listener) {
    _listeners.remove(listener);
  }
  static void removeStatusListener(Function(String id, String name, TransferStatus status, {String? error}) listener) {
    _statusListeners.remove(listener);
  }
  
  static void updateProgress(String id, double progress) {
    for (final l in List.from(_listeners)) {
      try { l(id, progress); } catch (_) {}
    }
  }
  static void updateStatus(String id, String name, TransferStatus status, {String? error}) {
    for (final l in List.from(_statusListeners)) {
      try { l(id, name, status, error: error); } catch (_) {}
    }
  }
}

class TransferNotifier extends StateNotifier<Map<String, FileTransferState>> {
  TransferNotifier() : super({}) {
    TransferRegistry.addListener(_onProgress);
    TransferRegistry.addStatusListener(_onStatus);
  }

  void _onProgress(String id, double progress) {
    updateProgress(id, progress);
  }

  void _onStatus(String id, String name, TransferStatus status, {String? error}) {
    if (status == TransferStatus.completed) {
      completeTransfer(id);
    } else if (status == TransferStatus.failed) {
      failTransfer(id, error ?? 'Failed');
    } else {
      startTransfer(id, name, status);
    }
  }

  @override
  void dispose() {
    TransferRegistry.removeListener(_onProgress);
    TransferRegistry.removeStatusListener(_onStatus);
    super.dispose();
  }

  void startTransfer(String id, String name, TransferStatus status) {
    state = {
      ...state,
      id: FileTransferState(
        id: id,
        name: name,
        progress: 0.0,
        status: status,
      ),
    };
  }

  void updateProgress(String id, double progress) {
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(progress: progress),
      };
    }
  }

  void completeTransfer(String id) {
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(progress: 1.0, status: TransferStatus.completed),
      };
      // Keep completed state for 2 seconds before removing from active UI list
      Future.delayed(const Duration(seconds: 2), () {
        removeTransfer(id);
      });
    }
  }

  void failTransfer(String id, String errorMessage) {
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(status: TransferStatus.failed, errorMessage: errorMessage),
      };
    }
  }

  void removeTransfer(String id) {
    final current = Map<String, FileTransferState>.from(state);
    current.remove(id);
    state = current;
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, Map<String, FileTransferState>>((ref) {
  return TransferNotifier();
});
