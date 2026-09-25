import 'json.dart';

/// `POST /recordings` 요청
class CreateRecordingRequest {
  const CreateRecordingRequest({
    required this.tapeType,
    required this.durationMs,
    this.contentType = 'audio/mp4',
  });

  final int tapeType;
  final int durationMs;
  final String contentType;

  Json toJson() => {
    'tapeType': tapeType,
    'durationMs': durationMs,
    'contentType': contentType,
  };
}

/// `POST /recordings` 응답 `{ id, status, upload }`
class RecordingUploadDto {
  const RecordingUploadDto({
    required this.id,
    required this.status,
    required this.upload,
  });

  final String id;
  final String status;
  final UploadTicketDto upload;

  factory RecordingUploadDto.fromJson(Json j) => RecordingUploadDto(
    id: j['id'] as String,
    status: j['status'] as String,
    upload: UploadTicketDto.fromJson(j['upload'] as Json),
  );

  Json toJson() => {'id': id, 'status': status, 'upload': upload.toJson()};
}

/// presigned PUT 정보
class UploadTicketDto {
  const UploadTicketDto({
    required this.url,
    required this.method,
    required this.headers,
    required this.expiresAt,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final DateTime expiresAt;

  factory UploadTicketDto.fromJson(Json j) => UploadTicketDto(
    url: j['url'] as String,
    method: j['method'] as String,
    headers: (j['headers'] as Map).cast<String, String>(),
    expiresAt: parseDate(j['expiresAt']),
  );

  Json toJson() => {
    'url': url,
    'method': method,
    'headers': headers,
    'expiresAt': dateToJson(expiresAt),
  };
}

/// 계약서 §9 Recording. `status`: `uploading | processing | ready | failed`
class RecordingDto {
  const RecordingDto({
    required this.id,
    required this.tapeType,
    required this.durationMs,
    required this.status,
    this.preview,
  });

  final String id;
  final int tapeType;

  /// 변환이 끝나면 서버가 실제 길이로 갱신한다.
  final int durationMs;
  final String status;
  final PreviewDto? preview;

  factory RecordingDto.fromJson(Json j) => RecordingDto(
    id: j['id'] as String,
    tapeType: j['tapeType'] as int,
    durationMs: j['durationMs'] as int,
    status: j['status'] as String,
    preview: j['preview'] == null
        ? null
        : PreviewDto.fromJson(j['preview'] as Json),
  );

  Json toJson() => {
    'id': id,
    'tapeType': tapeType,
    'durationMs': durationMs,
    'status': status,
    'preview': preview?.toJson(),
  };
}

class PreviewDto {
  const PreviewDto({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  factory PreviewDto.fromJson(Json j) =>
      PreviewDto(url: j['url'] as String, expiresAt: parseDate(j['expiresAt']));

  Json toJson() => {'url': url, 'expiresAt': dateToJson(expiresAt)};
}
