import 'package:tapeletter_app/data/model/api_error.dart';
import 'package:tapeletter_app/data/model/recording_dto.dart';
import 'package:tapeletter_app/data/repositories/recording_repository_remote.dart';
import 'package:tapeletter_app/data/services/api/api_client.dart';
import 'package:tapeletter_app/data/services/upload_service.dart';
import 'package:tapeletter_app/domain/models/recording.dart';
import 'package:tapeletter_app/domain/models/tape_type.dart';
import 'package:tapeletter_app/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /recordings/{id}` 응답을 차례로 돌려주는 서버. 항목이 [ApiException]이면 던진다.
class _PollApi implements ApiClient {
  _PollApi(this.polls, {this.completes = const []});

  final List<Object> polls;
  final List<Object> completes;
  int completeCalls = 0;
  int pollCalls = 0;

  @override
  String? accessToken;

  static RecordingDto rec(String status) => RecordingDto(
    id: 'r1',
    tapeType: 15,
    durationMs: 20000,
    status: status,
    preview: status == 'ready'
        ? PreviewDto(
            url: 'https://storage.test/r1',
            expiresAt: DateTime.utc(2026, 9, 26),
          )
        : null,
  );

  static const network = ApiException(
    status: 0,
    code: ApiErrorCode.networkError,
    message: '인터넷에 연결되어 있지 않아요',
  );
  static const badGateway = ApiException(
    status: 502,
    code: ApiErrorCode.internalError,
    message: '잠시 문제가 생겼어요',
  );

  RecordingDto _next(List<Object> list, int i, String fallback) {
    final x = i < list.length ? list[i] : rec(fallback);
    if (x is ApiException) throw x;
    return x as RecordingDto;
  }

  @override
  Future<RecordingDto> getRecording(String id) async =>
      _next(polls, pollCalls++, 'ready');

  @override
  Future<RecordingDto> completeRecording(String id) async =>
      _next(completes, completeCalls++, 'processing');

  @override
  Future<RecordingUploadDto> createRecording(
    CreateRecordingRequest body,
  ) async => RecordingUploadDto(
    recording: rec('uploading'),
    upload: UploadTicketDto(
      url: 'https://storage.test/put',
      method: 'PUT',
      headers: const {'Content-Type': 'audio/mp4'},
      expiresAt: DateTime.utc(2026, 9, 26),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Uploads implements UploadService {
  @override
  Future<void> upload(UploadTicketDto ticket, String filePath) async {}
}

Result<Recording>? _run(RecordingRepositoryRemote repo, String id) {
  Result<Recording>? out;
  fakeAsync((async) {
    repo.convert(id).then((r) => out = r);
    async.elapse(const Duration(seconds: 30));
  });
  return out;
}

void main() {
  test('서버가 failed라고 할 때만 실패', () {
    final api = _PollApi([_PollApi.rec('processing'), _PollApi.rec('failed')]);
    final r = _run(RecordingRepositoryRemote(api, _Uploads()), 'r1');
    expect(r, isA<Error<Recording>>());
  });

  test('폴링 중 네트워크 오류·5xx는 실패가 아니라 계속 기다린다', () {
    final api = _PollApi([
      _PollApi.rec('processing'),
      _PollApi.network,
      _PollApi.badGateway,
      _PollApi.rec('processing'),
      _PollApi.rec('ready'),
    ]);
    final r = _run(RecordingRepositoryRemote(api, _Uploads()), 'r1');
    expect(r, isA<Ok<Recording>>());
    expect((r as Ok<Recording>).value.status, RecordingStatus.ready);
    expect(api.pollCalls, 5);
  });

  test('complete 직후 아직 uploading이면 complete를 다시 알리고 기다린다', () {
    final api = _PollApi([
      _PollApi.rec('uploading'),
      _PollApi.rec('processing'),
      _PollApi.rec('ready'),
    ]);
    final r = _run(RecordingRepositoryRemote(api, _Uploads()), 'r1');
    expect(r, isA<Ok<Recording>>());
    expect(api.completeCalls, 1);
  });

  test('complete가 일시적으로 실패하면 다시 보낸다', () {
    final api = _PollApi(
      [_PollApi.rec('ready')],
      completes: [_PollApi.network, _PollApi.rec('processing')],
    );
    Result<Recording>? out;
    fakeAsync((async) {
      RecordingRepositoryRemote(api, _Uploads())
          .upload(
            filePath: '/tmp/a.m4a',
            type: TapeType.s15,
            duration: const Duration(seconds: 20),
          )
          .then((r) => out = r);
      async.elapse(const Duration(seconds: 10));
    });
    expect(out, isA<Ok<Recording>>());
    expect(api.completeCalls, 2);
  });

  test('끝까지 일시적 오류만 나면 시간 초과로 실패', () {
    final api = _PollApi(List.filled(500, _PollApi.network));
    Result<Recording>? out;
    fakeAsync((async) {
      RecordingRepositoryRemote(
        api,
        _Uploads(),
        timeout: const Duration(seconds: 20),
      ).convert('r1').then((r) => out = r);
      async.elapse(const Duration(minutes: 1));
    });
    expect(out, isA<Error<Recording>>());
  });
}
