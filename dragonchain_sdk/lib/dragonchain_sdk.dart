library dragonchain_sdk;
import 'package:logger/logger.dart';
import 'package:dragonchain_sdk/services/config_service.dart';
import 'package:dragonchain_sdk/services/credential_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';

final httpMethods = {
  "GET": http.get,
  "POST": http.post,
  "PUT": http.put,
  "DELETE": http.delete
};

final logger = new Logger();

class DragonchainClient {
  String endpoint;
  bool verify;
  CredentialService credentialService;

  DragonchainClient(this.endpoint, this.credentialService, this.verify);

  getStatus() async {
    return await this.get('/v1/status');
  }

  createTransaction(
    String transactionType,
    dynamic payload,
    {String tag, String callbackURL}
  ) async {
    if (payload == null) payload = '';
    var transactionBody = {
      "version": '1',
      "txn_type": transactionType,
      "payload": payload
    };
    if (tag != null || tag != '') transactionBody['tag'] = tag;
    return await this.post('/v1/transaction', transactionBody, callbackURL: callbackURL);
  }

  createTransactionType(
    String transactionType,
    [dynamic customIndexedFields]
  ) async {
    if (transactionType == null || transactionType == '') throw Exception('Empty transaction type');
    var body = {
      "version": '2',
      "txn_type": transactionType
    };
    // if (customIndexedFields != null) customIndexedFields
    return await this.post('/v1/transaction-type', body);
  }

  get(String path) async {
    return this.makeRequest(path, 'GET');
  }

  post(String path, dynamic body, {String callbackURL}) async {
    String bodyString = body is String ? body : jsonEncode(body);
    logger.d('BODY STRING: $bodyString');
    return this.makeRequest(path, 'POST', bodyString);
  }

  getHttpHeaders(
    String path,
    String method,
    {String contentType= '', String body=''}
  ) {
    var timestamp = (new DateTime.now().toUtc()).toIso8601String();
    Map<String, String> headers = {
      "dragonchain": this.credentialService.dragonchainId,
      "authorization": this.credentialService.getAuthorizationHeader(method, path, timestamp, contentType, body),
      "timestamp": timestamp
    };
    if (contentType != '' || contentType != null) headers["Content-Type"] = contentType;
    return headers;
  }

  makeRequest(
    String path,
    String method,
    [String body= '']
  ) async {
    String contentType = '';
    if (body != '') contentType = 'application/json';
    var headers = this.getHttpHeaders(path, method, contentType: contentType, body: body);
    String url = '${this.endpoint}$path';
    var response;
    switch (method) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        logger.d(headers);
        response = await http.post(url, headers: headers, body: body);
        break;
      default:
        throw Exception('Http method $method not valid');
    }
    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      logger.d(responseBody);
      return responseBody;
    }
    throw Exception('Failed to connect to dragonchain: ${response.statusCode}');
  }

  static createClient(
    {
      String dragonchainId,
      String authKeyId,
      String authKey,
      String endpoint,
      bool verify= false,
      String algorithm= 'SHA256'
    }
  ) async {
    logger.d(algorithm);
    if (dragonchainId == null || dragonchainId == '') throw Exception('Did not provide dragonchain ID');
    if (endpoint == null || endpoint == '') endpoint = await ConfigService.getDragonchainEndpoint(dragonchainId);
    var credentials = new CredentialService(dragonchainId, { "authKeyId": authKeyId, "authKey": authKey }, algorithm);
    return new DragonchainClient(endpoint, credentials, verify);
  }
}
