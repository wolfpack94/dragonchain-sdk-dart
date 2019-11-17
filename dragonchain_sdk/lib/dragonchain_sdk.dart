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

  getStatus() async => await this.get('/v1/status');

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

  queryBlocks(
    String redisearchQuery,
    {bool verbatim, int offset, int limit, String sortBy, bool sortAscending, bool idsOnly}
  ) async {
    Map<String, dynamic> queryParams = {
      "q": redisearchQuery,
      "offset": (offset != null) ? offset : 0,
      "limit": (limit != null) ? limit : 10
    };
    if (idsOnly != null) queryParams["id_only"] = idsOnly;
    if (sortBy != null) {
      queryParams["sort_by"] = sortBy;
      if (sortAscending != null) queryParams["sort_asc"] = sortAscending;
    }
    return await this.get("/v1/block${this.generateQueryString(queryParams)}");
  }

  createTransactionType(
    String transactionType,
    [List<Map<String, String>> customIndexedFields]
  ) async {
    if (transactionType == null || transactionType == '') throw Exception('Empty transaction type');
    var body = {
      "version": '2',
      "txn_type": transactionType
    };
    if (customIndexedFields != null) body["customIndexedFields"] = this.validateAndBuildCustomIndexFieldsArray(customIndexedFields);
    return await this.post('/v1/transaction-type', body);
  }

  deleteTransactionType(String transactionType) async => await this.delete("/v1/transaction-type/$transactionType");

  listTransactionTypes() async => await this.get("/v1/transaction-types");

  getTransactionType(String transactionType) async => await this.get("/v1/transaction-type/$transactionType");

  getTransaction(String transactionId) async => await this.get("/v1/transaction/$transactionId");

  createApiKey([String nickname]) async {
    Map<String, String> body = {};
    if (nickname != null || nickname != '') body['nickname'] = nickname;
    return await this.post("/v1/api-key", body);
  }

  listApiKeys() async => await this.get("/v1/api-key");

  getApiKey(String keyId) async => await this.get("/v1/api-key/$keyId");

  deleteApiKey(String keyId) async => await this.delete("/v1/api-key/$keyId");

  updateApiKey(String keyId, String nickname) async => await this.put("/v1/api-key/$keyId", { "nickname": nickname });

  createSmartContract(
    String transactionType,
    String image,
    String cmd,
    {
      List<String> args,
      String executionOrder,
      Map<String, String> environmentVariables,
      Map<String, String> secrets,
      int scheduleIntervalInSeconds,
      String cronExpression,
      String registryCredentials,
      List<Map<String, String>> customIndexedFields
    }
  ) async {
    if (scheduleIntervalInSeconds != null && cronExpression != null) throw Exception("Parameters 'scheduleIntervalInSeconds' AND 'cronExpression' are mutually exclusive");
    Map<String, dynamic> body = {
      "version": "3",
      "txn_type": transactionType,
      "image": image,
      "execution_order": "parallel",
      "cmd": cmd
    };
    if (args != null) body["args"] = args;
    if (executionOrder != null && ["parallel", "serial"].contains(executionOrder)) body["execution_order"] = executionOrder;
    if (environmentVariables != null) body["env"] = environmentVariables;
    if (secrets != null) body["secrets"] = secrets;
    if (scheduleIntervalInSeconds != null) body["seconds"] = scheduleIntervalInSeconds;
    if (cronExpression != null) body["cron"] = cronExpression;
    if (registryCredentials != null) body["auth"] = registryCredentials;
    if (customIndexedFields != null) body["custom_indexes"] = this.validateAndBuildCustomIndexFieldsArray(customIndexedFields);
    return await this.post("/v1/contract", body);  
  }

  updateSmartContract(
    String smartContractId,
    {
      String image,
      String cmd,
      List<String> args,
      String executionOrder,
      bool enabled,
      Map<String, String> environmentVariables,
      Map<String, String> secrets,
      int scheduleIntervalInSeconds,
      String cronExpression,
      String registryCredentials,
      bool disableSchedule
    }
  ) async {
    if (scheduleIntervalInSeconds != null && cronExpression != null) throw Exception("Parameters 'scheduleIntervalInSeconds' AND 'cronExpression' are mutually exclusive");
    Map<String, dynamic> body = {
      "version": "3"
    };
    if (image != null) body["image"] = image;
    if (cmd != null) body["cmd"] = cmd;
    if (args != null) body["args"] = args;
    if (executionOrder != null && ["parallel", "serial"].contains(executionOrder)) body["execution_order"] = executionOrder;
    if (enabled != null && enabled == true) body["desired_state"] = "active";
    if (enabled != null && enabled == false) body["desired_state"] = "inactive";
    if (environmentVariables != null) body["env"] = environmentVariables;
    if (secrets != null) body["secrets"] = secrets;
    if (scheduleIntervalInSeconds != null) body["seconds"] = scheduleIntervalInSeconds;
    if (cronExpression != null) body["cron"] = cronExpression;
    if (registryCredentials != null) body["auth"] = registryCredentials;
    return await this.put("/v1/contract/$smartContractId", body);
  }

  getSmartContract(
    {
      String smartContractId,
      String transactionType
    }
  ) async {
    if (smartContractId != null && transactionType != null) throw Exception("Only one of 'smartContractId' or 'transactionType' can be specified");
    if (smartContractId != null) return await this.get("/v1/contract/$smartContractId");
    if (transactionType != null) return await this.get("/v1/contract/txn_type/$transactionType");
    throw Exception("At least one of 'smartContractId' or 'transactionType' must be specified");
  }

  deleteSmartContract(String smartContractId) async => await this.delete("/v1/contract/$smartContractId");

  getSmartContractLogs(
    String smartContractId,
    {
      int tail,
      String since
    }
  ) async {
    Map<String, dynamic> queryParams = {};
    if (tail != null) queryParams["tail"] = tail;
    if (since != null) queryParams["since"] = since;
    return await this.get("/v1/contract/$smartContractId/logs${this.generateQueryString(queryParams)}");
  }

  listSmartContracts() async => await this.get("/v1/contract");

  getSmartContractObject(String key, String smartContractId) async => this.get("/v1/get/$smartContractId/$key", false);

  listSmartContractObjects(String smartContractId, [String prefixKey]) async {
    String path = "/v1/list/$smartContractId";
    if (prefixKey != null) {
      if (prefixKey.endsWith("/")) throw Exception("Parameter 'prefixKey' cannot end with '/'");
      path += "$prefixKey/";
    }
    return await this.get(path);
  }

  getPendingVerifications(String blockId) async => await this.get("/v1/verifications/pending/$blockId");

  getVerifications(String blockId, [int level]) async {
    if (level != null) return await this.get("/v1/verifications/$blockId?level=$level");
    return await this.get("/v1/verifications/$blockId");
  }

  get(String path, [bool jsonParse=true]) async {
    return await this.makeRequest(path, 'GET', parse: jsonParse);
  }

  delete(String path) async {
    return await this.makeRequest(path, 'DELETE');
  }

  put(String path, dynamic body) async {
    String bodyString = body is String ? body : jsonEncode(body);
    return this.makeRequest(path, 'PUT', body: bodyString);
  }

  post(String path, dynamic body, {String callbackURL}) async {
    String bodyString = body is String ? body : jsonEncode(body);
    return this.makeRequest(path, 'POST', body: bodyString);
  }

  generateQueryString(Map<String, String> queryObject) {
    String path = '';
    if (queryObject.length > 0) {
      path = '?';
      queryObject.forEach((String key, dynamic value) => path += "$key=$value&");
    }
    if (path.endsWith("&")) path = path.substring(0, path.length - 1);
    return path;
  }

  validateAndBuildCustomIndexFieldsArray(List<Map<String, dynamic>> customIndexedFields) {
    List<Map<String, dynamic>> returnList = [];
    customIndexedFields.forEach((customIndexedField) {
      Map<String, dynamic> customTransactionFieldBody = {
        "path": customIndexedField["path"],
        "field_name": customIndexedField["fieldName"],
        "type": customIndexedField["type"]
      };
      if (customIndexedField["options"] != null) {
        Map<String, String> optionsBody = {};
        if (customIndexedField["options"]["noIndex"] != null) optionsBody["no_index"] = customIndexedField["options"]["noIndex"];
        if (customIndexedField["type"] == "tag") {
            if (customIndexedField["options"]["separator"] != null) optionsBody["separator"] = customIndexedField["options"]["separator"];
        } else if (customIndexedField["type"] == "text") {
          if (customIndexedField["options"]["noStem"] != null) optionsBody["no_stem"] = customIndexedField["options"]["noStem"];
          if (customIndexedField["options"]["weight"] != null) optionsBody["weight"] = customIndexedField["options"]["weight"];
          if (customIndexedField["options"]["sortable"] != null) optionsBody["sortable"] = customIndexedField["options"]["sortable"];
        } else if (customIndexedField["type"] == "number") {
          if (customIndexedField["options"]["sortable"] != null) optionsBody["sortable"] = customIndexedField["options"]["sortable"];
        } else {
          throw Exception("Parameter 'customIndexedFields[].type' must be 'tag', 'text' or 'number'");
        }
        customTransactionFieldBody["options"] = optionsBody;
      }
      returnList.add(customTransactionFieldBody);
    });
    return returnList;
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
    {String body='', bool parse=true}
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
      responseBody = (method != 'DELETE' || parse == true) ? jsonDecode(contents) : contents;
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
