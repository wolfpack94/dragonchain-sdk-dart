library dragonchain_sdk;
import 'dart:core';
import 'dart:convert';
import 'package:dragonchain_sdk/services/config_service.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

final logger = new Logger();

class CredentialService {
  String dragonchainId;
  Map<String, String> credentials;
  String hmacAlgo;

  CredentialService(this.dragonchainId, this.credentials, this.hmacAlgo);

  static Future<CredentialService> createCredentials(
    String dragonchainId,
    {String authKeyId= '', String authKey= '', String hmacAlgo= 'SHA256'}
  ) async {
    if (authKeyId == '' || authKey == '') {
      var credentials = await ConfigService.getDragonchainCredentials(dragonchainId);
      authKeyId = credentials['authKeyId'];
      authKey = credentials['authKey'];
    }
    return new CredentialService(dragonchainId, { authKeyId: authKeyId, authKey: authKey }, hmacAlgo);
  }

  getAuthorizationHeader(
    String method,
    String path,
    String timestamp,
    String contentType,
    String body
  ) {
    var message = CredentialService.getHmacMessageString(method, path, this.dragonchainId, timestamp, contentType, this.hmacAlgo, body);
    var bytes = utf8.encode(message);
    var encodedAuthKey = utf8.encode(this.credentials['authKey']);
    var hmacSha256 = new Hmac(sha256, encodedAuthKey);
    var signature = base64.encode(hmacSha256.convert(bytes).bytes);
    return 'DC1-HMAC-${this.hmacAlgo} ${this.credentials['authKeyId']}:$signature';
  }

  static getHmacMessageString(
    String method,
    String path,
    String dragonchainId,
    String timestamp,
    String contentType,
    String hmacAlgo,
    [String body= '']
  ) {
    var binaryBody = utf8.encode(body);
    var hashedBase64Content = base64.encode(sha256.convert(binaryBody).bytes);
    return [method.toUpperCase(), path, dragonchainId, timestamp, contentType, hashedBase64Content].join('\n');
  }
}