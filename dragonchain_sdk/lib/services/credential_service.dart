library dragonchain_sdk;
import 'package:dragonchain_sdk/services/config_service.dart';

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
      Map<String, String> credentials = await ConfigService.getDragonchainCredentials(dragonchainId);
      authKeyId = credentials['authKeyId'];
      authKey = credentials['authKey'];
    }
    var creds = new CredentialService(dragonchainId, { authKeyId: authKeyId, authKey: authKey }, hmacAlgo);
    return creds;
  }
}