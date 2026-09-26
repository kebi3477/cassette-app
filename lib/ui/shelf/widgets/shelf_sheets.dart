import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/report.dart';
import '../../../domain/models/shelf.dart';
import '../../../domain/models/tape_item.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/choice_chip.dart';
import '../../../utils/format.dart';
import '../../report/widgets/report_sheet.dart';
import '../view_model/shelf_view_model.dart';

/// 받은 테이프 신고 — 보낸 사람을 차단 대상으로 (`report({target: 'tape'})`)
TapeReport tapeReportOf(TapeItem item) => TapeReport(
  deliveryId: item.id,
  name: item.from,
  userId: item.senderId,
  date: formatMonthDay(item.date),
);

/// ⋯ 메뉴 (`shItem`): 답장 녹음하기 / 다른 칸으로 옮기기 / 신고하기 / 지우기.
Future<void> showItemSheet(
  BuildContext context, {
  required ShelfViewModel viewModel,
  required TapeItem item,
  required VoidCallback? onReply,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheet) {
      void close() => Navigator.of(sheet).pop();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.from, style: AppText.sheetTitle),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              viewModel.sheetSub(item),
              style: AppText.suit(500, 13.5, color: AppColors.textMuted),
            ),
          ),
          // 보낸 사람이 탈퇴했으면(senderId 없음) 답장할 수 없다.
          if (onReply != null)
            SheetRow(
              label: '답장 녹음하기',
              onTap: () {
                close();
                onReply();
              },
            ),
          // 안 뜯은 소포는 옮길 수 없다 (계약서 409).
          if (viewModel.canMove(item))
            SheetRow(
              label: '다른 칸으로 옮기기',
              onTap: () {
                close();
                showMoveSheet(context, viewModel: viewModel, item: item);
              },
            ),
          SheetRow(
            label: '신고하기',
            onTap: () {
              close();
              showReportSheet(context, target: tapeReportOf(item));
            },
          ),
          SheetRow(
            label: '지우기',
            danger: true,
            divider: false,
            onTap: () {
              close();
              viewModel.deleteItem(item.id);
            },
          ),
        ],
      );
    },
  );
}

/// 재생 화면 ⋯ (`vMore` → `shItem`, `itemFull: false`): 답장 녹음하기 / 신고하기만.
Future<void> showViewerItemSheet(
  BuildContext context, {
  required TapeItem item,
  required VoidCallback? onReply,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheet) {
      void close() => Navigator.of(sheet).pop();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.from, style: AppText.sheetTitle),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            // itemSub = [date, where] — 재생 화면에서는 where가 비어 날짜만
            child: Text(
              formatMonthDay(item.date),
              style: AppText.suit(500, 13.5, color: AppColors.textMuted),
            ),
          ),
          if (onReply != null)
            SheetRow(
              label: '답장 녹음하기',
              onTap: () {
                close();
                onReply();
              },
            ),
          SheetRow(
            label: '신고하기',
            onTap: () {
              close();
              showReportSheet(context, target: tapeReportOf(item));
            },
          ),
        ],
      );
    },
  );
}

/// 옮기기 (`shMove`): 어느 칸으로 옮길까요?
Future<void> showMoveSheet(
  BuildContext context, {
  required ShelfViewModel viewModel,
  required TapeItem item,
}) {
  final s = viewModel.shelf;
  return showAppSheet<void>(
    context,
    builder: (sheet) {
      void go(String? groupId) {
        Navigator.of(sheet).pop();
        viewModel.moveTo(item.id, groupId);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('어느 칸으로 옮길까요?', style: AppText.sheetTitle),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetRow(
                    label: ShelfViewModel.unsortedName,
                    trailing: '${s.unsorted.length}개',
                    onTap: () => go(null),
                  ),
                  for (final g in s.groups)
                    SheetRow(
                      label: g.name,
                      trailing: '${g.items.length}개',
                      onTap: () => go(g.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 칸 추가·수정 (`shGroup`). [group]이 있으면 이름 바꾸기 + 칸 삭제.
Future<void> showGroupSheet(
  BuildContext context, {
  required ShelfViewModel viewModel,
  ShelfGroup? group,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheet) => _GroupForm(viewModel: viewModel, group: group),
  );
}

class _GroupForm extends StatefulWidget {
  const _GroupForm({required this.viewModel, this.group});

  final ShelfViewModel viewModel;
  final ShelfGroup? group;

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  late final TextEditingController _draft = TextEditingController(
    text: widget.group?.name ?? '',
  )..addListener(() => setState(() {}));
  final FocusNode _focus = FocusNode();

  /// 고른 카테고리 (`sh.cat`)
  String? _cat;

  /// 카테고리 칩 → 예시 이름 (`CAT_EX`). "직접 입력"은 비우고 입력칸에 포커스.
  static const categories = {
    '사람': '엄마 목소리',
    '기념일': '2026 생일',
    '여행': '제주 여행',
    '일상': '출근길 인사',
    '가족': '우리 가족',
    '연인': '우리의 100일',
    '직접 입력': '',
  };

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _pickCategory(String c) {
    setState(() => _cat = c);
    final text = categories[c]!;
    _draft.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (c == '직접 입력') _focus.requestFocus();
  }

  void _save() {
    final name = _draft.text.trim();
    if (name.isEmpty) {
      widget.viewModel.toast('칸 이름을 적어 주세요');
      return;
    }
    final g = widget.group;
    Navigator.of(context).pop();
    if (g == null) {
      widget.viewModel.addGroup(name);
    } else {
      widget.viewModel.renameGroup(g.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final n = _draft.text.characters.length;
    final max = ShelfViewModel.groupNameMax;
    const underline = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.ink, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 칸 만들기 (`groupNew`): 카테고리 칩
        if (g == null) ...[
          Text(
            '이 칸에 어떤 목소리를 모을까요?',
            style: AppText.suit(800, 20, letterSpacingEm: -.01),
          ),
          const SizedBox(height: 6),
          Text(
            '사람, 순간, 주제별로 모아 두면 오래 간직할 수 있어요',
            style: AppText.suit(500, 14, color: AppColors.textSub),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in categories.keys)
                AppChoiceChip(
                  label: c,
                  selected: _cat == c,
                  onTap: () => _pickCategory(c),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        Text('칸 이름', style: AppText.suit(600, 13, color: AppColors.textMuted)),
        SizedBox(
          height: 52,
          child: TextField(
            controller: _draft,
            focusNode: _focus,
            style: AppText.suit(800, 22),
            cursorColor: AppColors.ink,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                max,
                maxLengthEnforcement:
                    MaxLengthEnforcement.truncateAfterCompositionEnds,
              ),
            ],
            decoration: InputDecoration(
              hintText: '칸 이름을 적어 주세요',
              hintStyle: AppText.suit(800, 22, color: AppColors.textFaint),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: underline,
              focusedBorder: underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '예) 2026 생일, 제주 여행, 엄마 목소리, 힘들 때 듣기',
                style: AppText.suit(
                  500,
                  12.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$n/$max',
              style: AppText.suit(
                600,
                12.5,
                height: 1.5,
                tabularNums: true,
                color: n >= max ? AppColors.red : AppColors.textFaint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 이름이 없으면 비활성 (`groupBg` #CFCFCC, background .2s)
        AppButton(
          label: g == null ? '칸 만들기' : '저장',
          background: _draft.text.trim().isEmpty
              ? AppColors.disabled
              : AppColors.ink,
          onTap: _save,
        ),
        if (g != null)
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop();
                widget.viewModel.deleteGroup(g.id);
              },
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    '칸 삭제',
                    style: AppText.suit(600, 14, color: AppColors.red),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
