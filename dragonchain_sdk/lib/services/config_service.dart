library dragonnchain_sdk;
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ConfigService {

  static Future<Map<String, String>> setDragonchainCredentials(String dragonchainId, String authKeyId, String authKey) async {
    final storage = new FlutterSecureStorage();
    await storage.write(key: "authKeyId:$dragonchainId", value: authKeyId);
    await storage.write(key: "authKey:$dragonchainId", value: authKey);
    return { authKeyId: authKeyId, authKey: authKey };
  }

  static Future<Map<String, String>> getDragonchainCredentials(String dragonchainId) async {
    final storage = new FlutterSecureStorage();
    String authKeyId = await storage.read(key: "authKeyId:$dragonchainId");
    String authKey = await storage.read(key: "authKey:$dragonchainId");
    if (authKeyId == null || authKey == null) {
      throw Exception("Failed to find saved credentials for $dragonchainId");
    }
    return { authKeyId: authKeyId, authKey: authKey };
  }

  static Future<String> getDragonchainEndpoint(String dragonchainId) async {
    final response = await http.get("https://matchmaking.api.dragonchain.com/registration/$dragonchainId");
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
    } else {
      throw Exception('Failed to get dragocnhain endpoint with matchmaking');
    }
  }
}