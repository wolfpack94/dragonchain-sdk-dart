library dragonchain_sdk;
import 'package:logger/logger.dart';
import 'package:dragonchain_sdk/services/config_service.dart';
import 'package:dragonchain_sdk/services/credential_service.dart';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

final httpMethods = {
  "GET": new HttpClient().getUrl,
  "POST": new HttpClient().postUrl,
  "PUT": new HttpClient().putUrl,
  "DELETE": new HttpClient().deleteUrl
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
    var headers = this.getHttpHeaders(path, method, body: body, contentType: contentType);
    String url = '${this.endpoint}$path';
    var request = await httpMethods[method](Uri.parse(url));
    headers.forEach((key, value) => request.headers.set(key, value));
    if (['PUT','POST','DELETE'].contains(method)) request.write(body);
    var response = await request.close();
    var responseBody;
    await for (var contents in response.transform(Utf8Decoder())) {
      responseBody = jsonDecode(contents);
    }
    return responseBody;
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
