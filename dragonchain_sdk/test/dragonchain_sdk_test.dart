import 'package:dragonchain_sdk/dragonchain_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final logger = new Logger();

void main() {
  test('returns proper hmac string', () async {
    final DragonchainClient client = await DragonchainClient.createClient(dragonchainId: 'kRkjXtchnRGkqbXUhRvjZLKNr4XB7fYWcMWZ6fdGxCjE', authKeyId: '', authKey: '', endpoint: '');
    var response = await client.getStatus();
    expect(response['id'], 'kRkjXtchnRGkqbXUhRvjZLKNr4XB7fYWcMWZ6fdGxCjE');
  });

  test('create transaction type', () async {
    final DragonchainClient client = await DragonchainClient.createClient(dragonchainId: 'kRkjXtchnRGkqbXUhRvjZLKNr4XB7fYWcMWZ6fdGxCjE', authKeyId: '', authKey: '', endpoint: '');
    var response = await client.createTransactionType('test');
    logger.d(response);
  });
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  //   expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  // });
}
