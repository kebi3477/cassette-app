import 'package:flutter/material.dart';

import '../../../domain/models/tape_type.dart';
import '../view_model/record_view_model.dart';
import 'record_confirm_view.dart';
import 'record_idle_view.dart';
import 'record_label_view.dart';
import 'record_pick_view.dart';
import 'record_sending_view.dart';
import 'record_sent_view.dart';

/// 녹음 탭. phase 하나로 대기 → 확인 → 받는 사람 → 라벨 → 발송 → 완료를 바꾼다.
class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.viewModel,
    required this.onGoShop,
    required this.onBuyTape,
  });

  final RecordViewModel viewModel;

  /// 0개인 테이프를 사러 상점으로 (해당 테이프 행을 강조)
  final ValueChanged<TapeType> onGoShop;

  /// 0개인 테이프의 "+" → 상점에서 강조 + 1개짜리 구매 시트
  final ValueChanged<TapeType> onBuyTape;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 프로토타입의 visibilitychange(hidden) → 녹음 멈춤
    _lifecycle = AppLifecycleListener(
      onHide: widget.viewModel.onAppHidden,
      onResume: widget.viewModel.onAppResumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return switch (vm.phase) {
          RecordPhase.idle ||
          RecordPhase.rec ||
          RecordPhase.paused => RecordIdleView(
            key: const ValueKey('idle'),
            viewModel: vm,
            onGoShop: widget.onGoShop,
            onBuyTape: widget.onBuyTape,
          ),
          RecordPhase.confirm => RecordConfirmView(
            key: const ValueKey('confirm'),
            viewModel: vm,
          ),
          RecordPhase.pick => RecordPickView(
            key: const ValueKey('pick'),
            viewModel: vm,
          ),
          RecordPhase.label => RecordLabelView(
            key: const ValueKey('label'),
            viewModel: vm,
          ),
          RecordPhase.sending => RecordSendingView(
            key: const ValueKey('sending'),
            viewModel: vm,
          ),
          RecordPhase.sent => RecordSentView(
            key: const ValueKey('sent'),
            viewModel: vm,
          ),
        };
      },
    );
  }
}
