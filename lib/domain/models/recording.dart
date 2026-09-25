import 'tape_type.dart';

enum RecordingStatus { uploading, converting, ready, failed }

/// 서버에 올린 녹음 — 원본 업로드 → "테이프 소리" 변환 → 미리 듣기.
class Recording {
  const Recording({
    required this.id,
    required this.type,
    required this.duration,
    required this.status,
    this.previewUrl,
  });

  final String id;
  final TapeType type;
  final Duration duration;
  final RecordingStatus status;

  /// 변환이 끝난 파일을 들을 수 있는 주소 (로컬 파일 경로일 수도 있다)
  final String? previewUrl;

  Recording copyWith({RecordingStatus? status, String? previewUrl}) =>
      Recording(
        id: id,
        type: type,
        duration: duration,
        status: status ?? this.status,
        previewUrl: previewUrl ?? this.previewUrl,
      );
}
