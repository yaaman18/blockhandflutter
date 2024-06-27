import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bs58/bs58.dart';
import 'package:sha3/sha3.dart';

const String errInputLength =
    'Provided code must be at least 16 characters long and password must be at least 8 characters long';
const String errInputFormat =
    'Provided code or password is not in Base58 format';
const String errHashGeneration = 'Failed to generate hash';
const String errMnemonicGeneration = 'Mnemonic generation error';

Uint8List hashAndConcatenate(String providedCode, String passwordString) {
  if (providedCode.length < 16 || passwordString.length < 8) {
    throw Exception(errInputLength);
  }

  try {
    base58.decode(providedCode);
    base58.decode(passwordString);
  } catch (_) {
    throw Exception(errInputFormat);
  }

  final sha3ForCode = SHA3(256, SHA3_PADDING, 256);
  final providedCodeHash =
      sha3ForCode.update(Uint8List.fromList(providedCode.codeUnits)).digest();

  final sha3ForPassword = SHA3(256, SHA3_PADDING, 256);
  final passwordStringHash = sha3ForPassword
      .update(Uint8List.fromList(passwordString.codeUnits))
      .digest();

  return Uint8List.fromList([...providedCodeHash, ...passwordStringHash]);
}

Future<Uint8List> stretchHash(Uint8List concatenatedHash) async {
  try {
    final sha3ForSalt = SHA3(256, SHA3_PADDING, 256);
    final salt = sha3ForSalt.update(concatenatedHash).digest();

    final argon2id = Argon2id(
      memory: 65536, // 64 MB
      parallelism: 4,
      iterations: 3,
      hashLength: 32,
    );

    final secretKey = await argon2id.deriveKey(
      secretKey: SecretKey(concatenatedHash),
      nonce: salt,
    );
    final result = await secretKey.extractBytes();

    // SHA-3ハッシュをArgon2id出力に適用
    final sha3ForFinal = SHA3(256, SHA3_PADDING, 256);
    final finalHash = sha3ForFinal.update(result).digest();

    return Uint8List.fromList(finalHash);
  } catch (e) {
    throw Exception('$errHashGeneration: $e');
  }
}

Future<String> generateMnemonicPhrase(
    String providedCode, String passwordString) async {
  try {
    final concatenatedHash = hashAndConcatenate(providedCode, passwordString);
    final stretchedHash = await stretchHash(concatenatedHash);

    // Use the first 16 bytes of the stretched hash as entropy for mnemonic generation
    final seed = stretchedHash.sublist(0, 16);
    final mnemonic = bip39.entropyToMnemonic(
        seed.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join());

    return mnemonic;
  } catch (e) {
    throw Exception('$errMnemonicGeneration: $e');
  }
}
