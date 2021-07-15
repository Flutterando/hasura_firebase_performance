import 'package:flutter/foundation.dart';
import 'package:hasura_connect/hasura_connect.dart';
import 'package:firebase_performance/firebase_performance.dart';

class HasuraFirebasePerformanceInterceptor extends InterceptorBase {
  HasuraFirebasePerformanceInterceptor();

  final _mapMetric = <int, HttpMetric>{};

  @override
  Future? onRequest(Request request) async {
    try {
      var metric = FirebasePerformance.instance.newHttpMetric('https://${request.query.key}'.replaceAll('_', '-'), HttpMethod.Post);
      metric.requestPayloadSize = request.query.document.length;
      metric.putAttribute('query', request.query.document);
      _mapMetric[request.query.hashCode] = metric;
      await metric.start();
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      debugPrintStack(
        label: e.toString(),
        stackTrace: stackTrace,
      );
    }
    return super.onRequest(request);
  }

  @override
  Future? onResponse(Response data) async {
    try {
      final metric = _mapMetric[data.request.query.hashCode];
      metric?.httpResponseCode = data.statusCode;
      metric?.responsePayloadSize = data.data.toString().length;
      await metric?.stop();
      _mapMetric.remove(data.request.query.hashCode);
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      debugPrintStack(
        label: e.toString(),
        stackTrace: stackTrace,
      );
    }
    return super.onResponse(data);
  }

  @override
  Future? onError(HasuraError error) async {
    try {
      final metric = _mapMetric[error.request.query.hashCode];
      metric?.httpResponseCode = 500;
      await metric?.stop();
      _mapMetric.remove(error.request.query.hashCode);
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      debugPrintStack(
        label: e.toString(),
        stackTrace: stackTrace,
      );
    }
    return super.onError(error);
  }
}
