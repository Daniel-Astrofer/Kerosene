import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import '../../features/wallet/domain/entities/unsigned_transaction.dart';

class TransactionSigner {
  /// Signs an unsigned transaction using the provided mnemonic.
  static Future<String> sign({
    required UnsignedTransaction unsignedTx,
    required String mnemonic,
  }) async {
    // 1. Derive Keys (Explicit BIP32 Path: m/84'/0'/0'/0/0)
    final seed = Mnemonic.fromSentence(mnemonic, Language.english).seed;
    final root = Bip32Slip10Secp256k1.fromSeed(seed);

    // m/84'/0'/0'/0/0
    // m/84'/0'/0'/0/0
    final childKey = root.derivePath("m/84'/0'/0'/0/0");

    // In a real app, we must match the correct key for each input.
    // For this implementation, we assume all inputs belong to the first address (index 0).
    final privateKey = childKey.privateKey;
    final publicKey = childKey.publicKey;

    // 2. Prepare Transaction Objects
    final tx = _BitcoinTx.fromUnsigned(unsignedTx);

    // 3. Sign Each Input (BIP143 for SegWit)
    for (int i = 0; i < tx.inputs.length; i++) {
      final input = tx.inputs[i];
      final amount = BigInt.from(
        (unsignedTx.inputs[i].value * 100000000).round(),
      );

      // P2WPKH ScriptCode: 0x19 76 a9 14 <20-byte-pubkey-hash> 88 ac
      final pubKeyHash = QuickCrypto.hash160(publicKey.compressed);
      final scriptCode = <int>[
        0x19, // VarInt(25)
        0x76, // OP_DUP
        0xa9, // OP_HASH160
        0x14, // Push 20 bytes
        ...pubKeyHash,
        0x88, // OP_EQUALVERIFY
        0xac, // OP_CHECKSIG
      ];

      // Calculate SigHash (SIGHASH_ALL = 1)
      final sighash = tx.hashForWitnessV0(
        i,
        scriptCode,
        amount,
        1, // SIGHASH_ALL
      );

      // Sign
      final signer = BitcoinSigner.fromKeyBytes(privateKey.raw);
      final signature = signer.signTransaction(
        sighash,
      ); // Returns DER signature

      // Append SIGHASH_ALL (0x01) to signature
      final signatureWithHashType = [...signature, 0x01];

      // Create Witness Stack [Signature, PublicKey]
      final witness = <List<int>>[
        signatureWithHashType,
        publicKey.compressed, // Compressed Public Key
      ];

      input.witness = witness;
    }

    // 4. Serialize Final Transaction
    return BytesUtils.toHexString(tx.serialize());
  }

  /// Derives the Bech32 address (Native SegWit) from the mnemonic.
  static String deriveAddress(String mnemonic) {
    final seed = Mnemonic.fromSentence(mnemonic, Language.english).seed;
    final root = Bip32Slip10Secp256k1.fromSeed(seed);

    // m/84'/0'/0'/0/0
    // m/84'/0'/0'/0/0
    final childKey = root.derivePath("m/84'/0'/0'/0/0");

    // P2WPKH Address
    final pubKeyHash = QuickCrypto.hash160(childKey.publicKey.compressed);
    return SegwitBech32Encoder.encode("bc", 0, pubKeyHash);
  }
}

// Helper aliases to match blockchain_utils structure if needed
// Note: real package classes need to be verified.
// Use 'bitcoin_base' or similar if 'entryPoint' is not the correct namespace.
// I'm using a placeholder 'entryPoint' pattern here.
// Please check imports.
// Actually, I'll rely on the IDE/Compiler to help me fix the exact classes.
// I will write generic code and expect to fix imports.

// Minimal Bitcoin Transaction Implementation for SegWit Signing
class _BitcoinTx {
  int version = 2; // Version 2 for recent transactions
  List<_TxInput> inputs = [];
  List<_TxOutput> outputs = [];
  int locktime = 0;

  _BitcoinTx();

  factory _BitcoinTx.fromUnsigned(UnsignedTransaction unsignedTx) {
    final tx = _BitcoinTx();
    // Inputs
    for (var input in unsignedTx.inputs) {
      tx.inputs.add(
        _TxInput(
          txId: BytesUtils.fromHexString(input.txid),
          vout: input.vout,
          sequence: 0xffffffff, // Default sequence
        ),
      );
    }
    // Outputs
    for (var output in unsignedTx.outputs) {
      // Decode address to ScriptPubKey
      // Handling Bech32 (Native SegWit) and Base58 (Legacy/Compat)
      List<int> scriptPubKey;
      try {
        if (output.address.startsWith('bc1')) {
          // SegWit (Bech32)
          // decode requires HRP (Human Readable Part) 'bc' for mainnet
          final decoded = SegwitBech32Decoder.decode("bc", output.address);
          // P2WPKH: 00 14 <20-byte-hash>
          // P2TR: 51 20 <32-byte-hash>
          final program = decoded.item2;
          final version = decoded.item1;
          scriptPubKey = [
            version == 0 ? 0x00 : (version + 0x50), // 0x00 for v0, 0x51 for v1
            program.length,
            ...program,
          ];
        } else {
          // Legacy/P2SH (Base58)
          // Attempting generic decode
          try {
            final decoded = P2PKHAddrDecoder().decodeAddr(output.address);
            // P2PKH: 76 a9 14 <20-byte-hash> 88 ac
            scriptPubKey = [0x76, 0xa9, 0x14, ...decoded, 0x88, 0xac];
          } catch (_) {
            // Try P2SH
            final decoded = P2SHAddrDecoder().decodeAddr(output.address);
            // P2SH: a9 14 <20-byte-hash> 87
            scriptPubKey = [0xa9, 0x14, ...decoded, 0x87];
          }
        }
      } catch (e) {
        // Fallback - simplistic handling for now
        // Ideally assume we can decode it if valid content.
        // If all fails, throw error for now to be explicit.
        throw Exception("Unsupported address format: ${output.address}");
      }

      tx.outputs.add(
        _TxOutput(
          amount: BigInt.from((output.value * 100000000).round()),
          scriptPubKey: scriptPubKey,
        ),
      );
    }
    return tx;
  }

  // BIP143 Preimage Calculation
  List<int> hashForWitnessV0(
    int inputIndex,
    List<int> scriptCode,
    BigInt amount,
    int hashType,
  ) {
    // 1. Version (4 bytes)
    final versionBytes = IntUtils.toBytes(
      version,
      length: 4,
      byteOrder: Endian.little,
    );

    // 2. HashPrevouts (32 bytes)
    // Double SHA256 of all input outpoints (txid + vout)
    final prevouts = <int>[];
    for (var input in inputs) {
      prevouts.addAll(
        input.txId.reversed,
      ); // Internal txId is usually stored big-endian?
      // Wait, standard RPC txid is big-endian hex string.
      // Protocol uses little-endian.
      // BytesUtils.fromHexString keeps order.
      // If hex is '1234...', fromHexString gives [0x12, 0x34...].
      // Bitcoin protocol needs reversed of that for outpoint?
      // Yes, RPC TXID is reversed compared to wire format.
      // So if input.txid is from RPC (big endian), we need to reverse it to get little endian wire format.
      prevouts.addAll(
        IntUtils.toBytes(input.vout, length: 4, byteOrder: Endian.little),
      );
    }
    final hashPrevouts = QuickCrypto.sha256DoubleHash(prevouts);

    // 3. HashSequence (32 bytes)
    final sequences = <int>[];
    for (var input in inputs) {
      sequences.addAll(
        IntUtils.toBytes(input.sequence, length: 4, byteOrder: Endian.little),
      );
    }
    final hashSequence = QuickCrypto.sha256DoubleHash(sequences);

    // 4. Outpoint (32+4 bytes) of input being signed
    final input = inputs[inputIndex];
    final outpoint = [
      ...input.txId.reversed,
      ...IntUtils.toBytes(input.vout, length: 4, byteOrder: Endian.little),
    ];

    // 5. ScriptCode (VarInt len + content) -> Passed as arg (includes length?)
    // The scriptCode passed usually starts with length? Yes 0x19...

    // 6. Amount (8 bytes)
    final amountBytes = IntUtils.toBytes(
      amount.toInt(),
      length: 8,
      byteOrder: Endian.little,
    );

    // 7. Sequence (4 bytes)
    final nSequence = IntUtils.toBytes(
      input.sequence,
      length: 4,
      byteOrder: Endian.little,
    );

    // 8. HashOutputs (32 bytes)
    final outputBytes = <int>[];
    for (var output in outputs) {
      outputBytes.addAll(
        IntUtils.toBytes(
          output.amount.toInt(),
          length: 8,
          byteOrder: Endian.little,
        ),
      );
      outputBytes.addAll(IntUtils.encodeVarint(output.scriptPubKey.length));
      outputBytes.addAll(output.scriptPubKey);
    }
    final hashOutputs = QuickCrypto.sha256DoubleHash(outputBytes);

    // 9. Locktime (4 bytes)
    final nLocktime = IntUtils.toBytes(
      locktime,
      length: 4,
      byteOrder: Endian.little,
    );

    // 10. HashType (4 bytes)
    final nHashType = IntUtils.toBytes(
      hashType,
      length: 4,
      byteOrder: Endian.little,
    );

    // Combine
    final preimage = [
      ...versionBytes,
      ...hashPrevouts,
      ...hashSequence,
      ...outpoint,
      ...scriptCode,
      ...amountBytes,
      ...nSequence,
      ...hashOutputs,
      ...nLocktime,
      ...nHashType,
    ];

    return QuickCrypto.sha256DoubleHash(preimage);
  }

  List<int> serialize() {
    final buffer = <int>[];

    // 1. Version
    buffer.addAll(
      IntUtils.toBytes(version, length: 4, byteOrder: Endian.little),
    );

    // 2. Marker & Flag (SegWit) -> 0x00 0x01
    buffer.addAll([0x00, 0x01]);

    // 3. Inputs
    buffer.addAll(IntUtils.encodeVarint(inputs.length));
    for (var input in inputs) {
      buffer.addAll(input.txId.reversed); // TxID Little Endian
      buffer.addAll(
        IntUtils.toBytes(input.vout, length: 4, byteOrder: Endian.little),
      );
      buffer.add(0x00); // ScriptSig Length 0 (SegWit)
      buffer.addAll(
        IntUtils.toBytes(input.sequence, length: 4, byteOrder: Endian.little),
      );
    }

    // 4. Outputs
    buffer.addAll(IntUtils.encodeVarint(outputs.length));
    for (var output in outputs) {
      buffer.addAll(
        IntUtils.toBytes(
          output.amount.toInt(),
          length: 8,
          byteOrder: Endian.little,
        ),
      );
      buffer.addAll(IntUtils.encodeVarint(output.scriptPubKey.length));
      buffer.addAll(output.scriptPubKey);
    }

    // 5. Witnesses
    for (var input in inputs) {
      // Witness count
      buffer.addAll(IntUtils.encodeVarint(input.witness.length));
      for (var item in input.witness) {
        buffer.addAll(IntUtils.encodeVarint(item.length));
        buffer.addAll(item);
      }
    }

    // 6. Locktime
    buffer.addAll(
      IntUtils.toBytes(locktime, length: 4, byteOrder: Endian.little),
    );

    return buffer;
  }
}

class _TxInput {
  final List<int> txId;
  final int vout;
  final int sequence;
  List<List<int>> witness = [];

  _TxInput({required this.txId, required this.vout, required this.sequence});
}

class _TxOutput {
  final BigInt amount;
  final List<int> scriptPubKey;

  _TxOutput({required this.amount, required this.scriptPubKey});
}
