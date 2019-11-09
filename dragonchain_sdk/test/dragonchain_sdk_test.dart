import 'package:dragonchain_sdk/dragonchain_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

final logger = new Logger();

void main() {
  // test('returns proper hmac string', () async {
  //   final DragonchainClient client = await DragonchainClient.createClient(dragonchainId: '24tSbKkPrMByxRCS3zbGHQgNsyhbj2eGq3vpniX7TpinZ', authKeyId: 'BPQGNWNGCGFE', authKey: 'Jv01qfKV4GIIQQl3foinSmJY8dEru5q5XY987DRKbOE', endpoint: 'https://2fb1b96e-d78b-463b-9a53-13e1b35f46a2.api.dragonchain.com');
  //   var response = await client.getStatus();
  //   expect(response['id'], '24tSbKkPrMByxRCS3zbGHQgNsyhbj2eGq3vpniX7TpinZ');
  // });

  test('create transaction type', () async {
    final DragonchainClient client = await DragonchainClient.createClient(dragonchainId: '24tSbKkPrMByxRCS3zbGHQgNsyhbj2eGq3vpniX7TpinZ', authKeyId: 'BPQGNWNGCGFE', authKey: 'Jv01qfKV4GIIQQl3foinSmJY8dEru5q5XY987DRKbOE', endpoint: 'https://2fb1b96e-d78b-463b-9a53-13e1b35f46a2.api.dragonchain.com');
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
