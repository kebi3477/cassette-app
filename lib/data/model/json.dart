/// JSON 도우미. 계약서: 키는 camelCase, 날짜는 ISO 8601 UTC.
typedef Json = Map<String, dynamic>;

DateTime parseDate(Object? v) => DateTime.parse(v as String);

DateTime? parseDateOrNull(Object? v) => v == null ? null : parseDate(v);

String dateToJson(DateTime d) => d.toUtc().toIso8601String();

List<T> parseList<T>(Object? v, T Function(Json) f) =>
    (v as List).map((e) => f(e as Json)).toList();
