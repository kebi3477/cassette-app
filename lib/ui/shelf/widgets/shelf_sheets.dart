import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/report.dart';
import '../../../domain/models/shelf.dart';
import '../../../domain/models/tape_item.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/buttons.dart';
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
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _save() {
    final g = widget.group;
    Navigator.of(context).pop();
    if (g == null) {
      widget.viewModel.addGroup(_draft.text);
    } else {
      widget.viewModel.renameGroup(g.id, _draft.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    const underline = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.ink, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('칸 이름', style: AppText.suit(600, 13, color: AppColors.textMuted)),
        SizedBox(
          height: 52,
          child: TextField(
            controller: _draft,
            style: AppText.suit(800, 22),
            cursorColor: AppColors.ink,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                ShelfViewModel.groupNameMax,
                maxLengthEnforcement:
                    MaxLengthEnforcement.truncateAfterCompositionEnds,
              ),
            ],
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              enabledBorder: underline,
              focusedBorder: underline,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(label: g == null ? '칸 추가' : '저장', onTap: _save),
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
