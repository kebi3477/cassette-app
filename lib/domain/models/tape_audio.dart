/// 재생할 파일 주소 — `GET /deliveries/{id}/audio`. 짧은 만료라 곡마다 새로 받는다.
class TapeAudio {
  const TapeAudio({
    required this.url,
    required this.expiresAt,
    required this.duration,
  });

  final String url;
  final DateTime expiresAt;
  final Duration duration;
}
