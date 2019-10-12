library dragonchain_sdk;

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
      // call getCredentials function
      authKeyId = 'banana';
      authKey = 'banana';
    }
    var creds = new CredentialService(dragonchainId, { authKeyId: authKeyId, authKey: authKey }, hmacAlgo);
    return creds;
  }

  static Future<Map<String, String>> getCredentialsFromEnvironment() async {
    return {};
  }
}