import 'package:dragonchain_sdk/dragonchain_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

final logger = new Logger();

void main() {
  test('returns proper hmac string', () async {
    final client = await DragonchainClient.createClient(dragonchainId: 'kRkjXtchnRGkqbXUhRvjZLKNr4XB7fYWcMWZ6fdGxCjE', authKeyId: 'VYFFYTTSPKES', authKey: 'SSjCVEXUtj58vFbUf9274MnX9aFtJ5KFnB5jXdJfYbm', endpoint: 'https://45414ed2-b72c-42fb-8264-296df2600b4f.api.dragonchain.com');
    logger.d(await client.getStatus());
  });
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  //   expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  // });
}
