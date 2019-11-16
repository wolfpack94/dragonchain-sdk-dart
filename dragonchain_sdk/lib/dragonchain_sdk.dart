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

  generateQueryString(Map<String, String> queryObject) {
    String path = '';
    if (queryObject.length > 0) {
      path = '?';
      queryObject.forEach((String key, dynamic value) => path += "$key=$value&");
    }
    if (path.endsWith("&")) path = path.substring(0, path.length - 1);
    return path;
  }

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

  createBulkTransaction(
    List<dynamic> transactionList,
  ) async {
    List<Map<String, String>> bulkTransactionBody = [];
    for (var transaction in transactionList) {
      Map<String, String> singleBody = {
        "version": "1",
        "txn_type": transaction["transactionType"],
        "payload": transaction["payload"] ? transaction["payload"] : ""
      };
      if (transaction["tag"] != null || transaction["tag"] != "") singleBody["tag"] = transaction["tag"];
      bulkTransactionBody.add(singleBody);
    }
    return await this.post("/v1/transaction_bulk", bulkTransactionBody);
  }

  queryTransactions(
    String transactionType,
    String redisearchQuery,
    {bool verbatim, int offset, int limit, String sortBy, bool sortAscending, bool idsOnly}
  ) async {
    Map<String, dynamic> queryParams = {
      "transaction_type": transactionType,
      "q": redisearchQuery,
      "offset": (offset != null) ? offset : 0,
      "limit": (limit != null) ? limit : 10
    };
    if (verbatim != null) queryParams["verbatim"] = verbatim;
    if (idsOnly != null) queryParams["id_only"] = idsOnly;
    if (sortBy != null) {
      queryParams["sort_by"] = sortBy;
      if (sortAscending != null) queryParams["sort_asc"] = sortAscending;
    }
    return await this.get("/v1/transaction${this.generateQueryString(queryParams)}");
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

  getTransaction(String transactionId) async {
    if (transactionId != null || transactionId != '') throw Exception("Parameter 'transactionId' is required");
    return await this.get("/v1/transaction/$transactionId");
  }

  createApiKey([String nickname]) async {
    Map<String, String> body = {};
    if (nickname != null || nickname != '') body['nickname'] = nickname;
    return await this.post("/v1/api-key", body);
  }

  listApiKeys() async {
    return await this.get("/v1/api-key");
  }

  getApiKey(String keyId) async {
    if (keyId != null || keyId != '') throw Exception("Parameter 'keyId' is required");
    return await this.get("/v1/api-key/$keyId");
  }

  deleteApiKey(String keyId) async {
    return await this.delete("/v1/api-key/$keyId");
  }

  updateApiKey(String keyId, String nickname) async {
    if (nickname != null || nickname != '') throw Exception("Parameter 'nickname' is required");
    return await this.put("/v1/api-key/$keyId", { "nickname": nickname });
  }

  get(String path) async {
    return await this.makeRequest(path, 'GET');
  }

  delete(String path) async {
    return await this.makeRequest(path, 'DELETE');
  }

  put(String path, dynamic body) async {
    String bodyString = body is String ? body : jsonEncode(body);
    return this.makeRequest(path, 'PUT', bodyString);
  }

  post(String path, dynamic body, {String callbackURL}) async {
    String bodyString = body is String ? body : jsonEncode(body);
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
      responseBody = (method != 'DELETE') ? jsonDecode(contents) : contents;
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
