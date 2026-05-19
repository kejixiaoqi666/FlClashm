import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'net77_config.dart';

class Net77ApiException implements Exception {
  final String message;
  final int? code;
  Net77ApiException(this.message, [this.code]);
  @override
  String toString() => message;
}

class Net77Api {
  Net77Api._()
      : _dio = Dio(BaseOptions(
          baseUrl: _normalizeBaseUrl(Net77Config.apiBaseUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
        ));

  static final Net77Api instance = Net77Api._();
  static const _authDataKey = 'net77.auth_data';
  static const _subscribeUrlKey = 'net77.subscribe_url';
  final Dio _dio;

  static String _normalizeBaseUrl(String value) {
    var url = value.trim();
    while (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  Future<String?> get authData async => (await SharedPreferences.getInstance()).getString(_authDataKey);

  Future<void> saveAuthData(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_authDataKey);
    } else {
      await prefs.setString(_authDataKey, value);
    }
  }

  Future<void> saveSubscribeUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscribeUrlKey, value);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final info = await PackageInfo.fromPlatform();
    final headers = <String, String>{
      'X-App-Name': Net77Config.appName,
      'X-App-Version': info.version,
      'X-App-Platform': Platform.operatingSystem,
    };
    if (auth) {
      final token = await authData;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = token.startsWith('Bearer ') ? token : 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _unwrap(Response<dynamic> response) {
    final body = response.data;
    if (body is Map) {
      final status = body['status'];
      final message = body['message']?.toString() ?? '请求失败';
      final code = body['code'] is int ? body['code'] as int : response.statusCode;
      if (status == false || status == 'fail' || status == 'error') {
        throw Net77ApiException(message, code);
      }
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Net77ApiException(message, response.statusCode);
      }
      return body.containsKey('data') ? body['data'] : body;
    }
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Net77ApiException('请求失败', response.statusCode);
    }
    return body;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        queryParameters: queryParameters,
        data: data,
        options: Options(method: method, headers: await _headers(auth: auth)),
      );
      return _unwrap(response);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw Net77ApiException(body['message'].toString(), e.response?.statusCode);
      }
      throw Net77ApiException(e.message ?? '网络请求失败', e.response?.statusCode);
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  Future<void> verifyEntryCode(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      throw Net77ApiException('请输入识别码');
    }
    final data = _map(await _request(
      'POST',
      '/api/v1/app/entry/verify',
      data: {'code': normalized},
      auth: false,
    ));
    if (data['valid'] != true) {
      throw Net77ApiException('识别码错误');
    }
  }

  Future<Map<String, dynamic>> config() async => _map(await _request('GET', '/api/v1/app/config', auth: false));
  Future<Map<String, dynamic>> notice() async => _map(await _request('GET', '/api/v1/app/notice', auth: false));
  Future<Map<String, dynamic>> version() async => _map(await _request('GET', '/api/v1/app/version', auth: false));

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final data = _map(await _request('POST', '/api/v1/app/auth/login', data: {
      'email': email,
      'password': password,
    }, auth: false));
    await saveAuthData((data['auth_data'] ?? data['token'])?.toString());
    return data;
  }

  Future<Map<String, dynamic>> register({required String email, required String password, String? inviteCode}) async {
    final data = _map(await _request('POST', '/api/v1/app/auth/register', data: {
      'email': email,
      'password': password,
      if (inviteCode != null && inviteCode.isNotEmpty) 'invite_code': inviteCode,
    }, auth: false));
    await saveAuthData((data['auth_data'] ?? data['token'])?.toString());
    return data;
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/api/v1/app/auth/logout');
    } finally {
      await saveAuthData(null);
    }
  }

  Future<Map<String, dynamic>> dashboard() async => _map(await _request('GET', '/api/v1/app/user/dashboard'));

  Future<Map<String, dynamic>> subscribe() async {
    final data = _map(await _request('GET', '/api/v1/app/subscribe'));
    final url = data['subscribe_url']?.toString();
    if (url != null && url.isNotEmpty) await saveSubscribeUrl(url);
    return data;
  }

  Future<Map<String, dynamic>> resetSubscribe() async {
    final data = _map(await _request('POST', '/api/v1/app/subscribe/reset'));
    final url = data['subscribe_url']?.toString();
    if (url != null && url.isNotEmpty) await saveSubscribeUrl(url);
    return data;
  }

  Future<List<dynamic>> plans() async => _list(await _request('GET', '/api/v1/app/plan/list'));
  Future<List<dynamic>> paymentMethods() async => _list(await _request('GET', '/api/v1/app/order/payment-methods'));

  Future<Map<String, dynamic>> createOrder({required int planId, required String period, String? couponCode}) async =>
      _map(await _request('POST', '/api/v1/app/order/create', data: {
        'plan_id': planId,
        'period': period,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      }));

  Future<Map<String, dynamic>> checkoutOrder({required String tradeNo, required int method}) async =>
      _map(await _request('POST', '/api/v1/app/order/checkout', data: {
        'trade_no': tradeNo,
        'method': method,
      }));

  Future<Map<String, dynamic>> orderStatus(String tradeNo) async =>
      _map(await _request('GET', '/api/v1/app/order/status', queryParameters: {'trade_no': tradeNo}));

  Future<List<dynamic>> orders({int limit = 50}) async =>
      _list(await _request('GET', '/api/v1/app/order/list', queryParameters: {'limit': limit}));

  Future<Map<String, dynamic>> orderDetail(String tradeNo) async =>
      _map(await _request('GET', '/api/v1/app/order/detail', queryParameters: {'trade_no': tradeNo}));

  Future<void> cancelOrder(String tradeNo) async {
    await _request('POST', '/api/v1/app/order/cancel', data: {'trade_no': tradeNo});
  }

  Future<List<dynamic>> nodeStatus({int limit = 200}) async =>
      _list(await _request('GET', '/api/v1/app/node/status', queryParameters: {'limit': limit}));

  Future<List<dynamic>> trafficLogs({int limit = 120}) async =>
      _list(await _request('GET', '/api/v1/app/traffic/logs', queryParameters: {'limit': limit}));

  Future<List<dynamic>> tickets({int limit = 50}) async =>
      _list(await _request('GET', '/api/v1/app/ticket/list', queryParameters: {'limit': limit}));
}
