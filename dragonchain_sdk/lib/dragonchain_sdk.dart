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

  get(String path) async {
    return this.makeRequest(path, 'GET');
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
    if (contentType != '' || contentType != null) headers["contentType"] = contentType;
    return headers;
  }

  makeRequest(
    String path,
    String method,
    [String body= '']
  ) async {
    String contentType = '';
    if (body != '') contentType = 'application/json';
    var headers = this.getHttpHeaders(path, method, contentType: contentType);
    String url = '${this.endpoint}$path';
    logger.d(headers);
    logger.d("URL: $url");
    var response = await httpMethods[method](url, headers: headers);
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      logger.d(responseBody);
      return responseBody;
    }
    var responseBody = json.decode(response.body);
    logger.d(responseBody);
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
