# 🧪 [SUGESTÕES DE TESTES] - Feature Wallet

## 📋 Estratégia de Testes

### **Pirâmide de Testes**
```
        /\
       /  \      10% - E2E Tests
      /____\
     /      \    30% - Integration Tests
    /________\
   /          \  60% - Unit Tests
  /__________  \
```

---

## 1️⃣ Testes Unitários (Domain Layer)

### **Entities**

#### `wallet_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';

void main() {
  group('Wallet Entity', () {
    test('should convert satoshis to BTC correctly', () {
      // Arrange
      const wallet = Wallet(
        id: '1',
        name: 'Test Wallet',
        address: 'bc1qtest',
        balanceSatoshis: 100000000, // 1 BTC
        derivationPath: "m/84'/0'/0'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      // Act
      final balanceBTC = wallet.balanceBTC;

      // Assert
      expect(balanceBTC, 1.0);
    });

    test('should format balance in USD correctly', () {
      // Arrange
      const wallet = Wallet(
        id: '1',
        name: 'Test Wallet',
        address: 'bc1qtest',
        balanceSatoshis: 100000000, // 1 BTC
        derivationPath: "m/84'/0'/0'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      const btcToUsdRate = 50000.0;

      // Act
      final balanceUSD = wallet.balanceInUSD(btcToUsdRate);

      // Assert
      expect(balanceUSD, '\$50000.00');
    });

    test('should return correct derivation path for each wallet type', () {
      // Assert
      expect(WalletType.legacy.basePath, "m/44'/0'/0'");
      expect(WalletType.segwit.basePath, "m/49'/0'/0'");
      expect(WalletType.nativeSegwit.basePath, "m/84'/0'/0'");
      expect(WalletType.taproot.basePath, "m/86'/0'/0'");
    });
  });
}
```

### **UseCases**

#### `send_bitcoin_usecase_test.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([WalletRepository])
void main() {
  late SendBitcoinUseCase useCase;
  late MockWalletRepository mockRepository;

  setUp(() {
    mockRepository = MockWalletRepository();
    useCase = SendBitcoinUseCase(mockRepository);
  });

  group('SendBitcoinUseCase', () {
    const tWalletId = 'wallet-1';
    const tToAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';
    const tAmountSatoshis = 100000; // 0.001 BTC
    const tFeeSatoshis = 1000;

    final tWallet = Wallet(
      id: tWalletId,
      name: 'Test Wallet',
      address: 'bc1qtest',
      balanceSatoshis: 200000, // Saldo suficiente
      derivationPath: "m/84'/0'/0'/0/0",
      type: WalletType.nativeSegwit,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    final tTransaction = Transaction(
      id: 'tx-1',
      fromAddress: tWallet.address,
      toAddress: tToAddress,
      amountSatoshis: tAmountSatoshis,
      feeSatoshis: tFeeSatoshis,
      status: TransactionStatus.pending,
      type: TransactionType.send,
      confirmations: 0,
      timestamp: DateTime.now(),
    );

    test('should return failure when amount is below dust limit', () async {
      // Act
      final result = await useCase(
        fromWalletId: tWalletId,
        toAddress: tToAddress,
        amountSatoshis: 500, // Abaixo de 546
        feeSatoshis: tFeeSatoshis,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure.message,
          contains('dust limit'),
        ),
        (_) => fail('Should return failure'),
      );
    });

    test('should return failure when amount exceeds maximum', () async {
      // Act
      final result = await useCase(
        fromWalletId: tWalletId,
        toAddress: tToAddress,
        amountSatoshis: 2100000000000001, // Acima do máximo
        feeSatoshis: tFeeSatoshis,
      );

      // Assert
      expect(result.isLeft(), true);
    });

    test('should return failure when address is invalid', () async {
      // Arrange
      when(mockRepository.validateAddress(any))
          .thenAnswer((_) async => const Right(false));

      // Act
      final result = await useCase(
        fromWalletId: tWalletId,
        toAddress: 'invalid-address',
        amountSatoshis: tAmountSatoshis,
        feeSatoshis: tFeeSatoshis,
      );

      // Assert
      expect(result.isLeft(), true);
      verify(mockRepository.validateAddress('invalid-address'));
    });

    test('should return failure when balance is insufficient', () async {
      // Arrange
      when(mockRepository.validateAddress(any))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.getWalletById(tWalletId))
          .thenAnswer((_) async => Right(tWallet.copyWith(
                balanceSatoshis: 50000, // Saldo insuficiente
              )));

      // Act
      final result = await useCase(
        fromWalletId: tWalletId,
        toAddress: tToAddress,
        amountSatoshis: tAmountSatoshis,
        feeSatoshis: tFeeSatoshis,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure.message,
          contains('Saldo insuficiente'),
        ),
        (_) => fail('Should return failure'),
      );
    });

    test('should send bitcoin successfully when all validations pass', () async {
      // Arrange
      when(mockRepository.validateAddress(tToAddress))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.getWalletById(tWalletId))
          .thenAnswer((_) async => Right(tWallet));
      when(mockRepository.sendBitcoin(
        fromWalletId: anyNamed('fromWalletId'),
        toAddress: anyNamed('toAddress'),
        amountSatoshis: anyNamed('amountSatoshis'),
        feeSatoshis: anyNamed('feeSatoshis'),
        description: anyNamed('description'),
      )).thenAnswer((_) async => Right(tTransaction));

      // Act
      final result = await useCase(
        fromWalletId: tWalletId,
        toAddress: tToAddress,
        amountSatoshis: tAmountSatoshis,
        feeSatoshis: tFeeSatoshis,
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.sendBitcoin(
        fromWalletId: tWalletId,
        toAddress: tToAddress,
        amountSatoshis: tAmountSatoshis,
        feeSatoshis: tFeeSatoshis,
      ));
    });
  });
}
```

---

## 2️⃣ Testes de Integração (Data Layer)

### **Repository Implementation**

#### `wallet_repository_impl_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([WalletRemoteDataSource, WalletLocalDataSource])
void main() {
  late WalletRepositoryImpl repository;
  late MockWalletRemoteDataSource mockRemoteDataSource;
  late MockWalletLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockWalletRemoteDataSource();
    mockLocalDataSource = MockWalletLocalDataSource();
    repository = WalletRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('getWallets', () {
    final tWalletModels = [
      WalletModel(
        id: '1',
        name: 'Wallet 1',
        address: 'bc1q1',
        balanceSatoshis: 100000,
        derivationPath: "m/84'/0'/0'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ];

    test('should return wallets from remote when call is successful', () async {
      // Arrange
      when(mockRemoteDataSource.getWallets())
          .thenAnswer((_) async => tWalletModels);
      when(mockLocalDataSource.cacheWallets(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.getWallets();

      // Assert
      expect(result.isRight(), true);
      verify(mockRemoteDataSource.getWallets());
      verify(mockLocalDataSource.cacheWallets(tWalletModels));
    });

    test('should return cached wallets when remote fails', () async {
      // Arrange
      when(mockRemoteDataSource.getWallets())
          .thenThrow(const NetworkException());
      when(mockLocalDataSource.getCachedWallets())
          .thenAnswer((_) async => tWalletModels);

      // Act
      final result = await repository.getWallets();

      // Assert
      expect(result.isRight(), true);
      verify(mockLocalDataSource.getCachedWallets());
    });
  });
}
```

---

## 3️⃣ Testes de Widget (Presentation Layer)

### **Screens**

#### `wallet_home_screen_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('should show loading indicator when state is loading', (tester) async {
    // Arrange
    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith((ref) => MockWalletNotifier(
              const WalletLoading(),
            )),
      ],
    );

    // Act
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WalletHomeScreen(),
        ),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should show error message when state is error', (tester) async {
    // Arrange
    const errorMessage = 'Network error';
    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith((ref) => MockWalletNotifier(
              const WalletError(errorMessage),
            )),
      ],
    );

    // Act
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WalletHomeScreen(),
        ),
      ),
    );

    // Assert
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.text('Tentar Novamente'), findsOneWidget);
  });

  testWidgets('should show wallet balance when state is loaded', (tester) async {
    // Arrange
    final tWallet = Wallet(
      id: '1',
      name: 'Test Wallet',
      address: 'bc1qtest',
      balanceSatoshis: 100000000,
      derivationPath: "m/84'/0'/0'/0/0",
      type: WalletType.nativeSegwit,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith((ref) => MockWalletNotifier(
              WalletLoaded(
                wallets: [tWallet],
                selectedWallet: tWallet,
                btcToUsdRate: 50000.0,
              ),
            )),
      ],
    );

    // Act
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WalletHomeScreen(),
        ),
      ),
    );

    // Assert
    expect(find.byType(WalletBalanceCard), findsOneWidget);
    expect(find.text('\$50000.00'), findsOneWidget);
  });
}
```

---

## 4️⃣ Testes de Performance

### **Isolates Test**

#### `bitcoin_crypto_performance_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'dart:isolate';

void main() {
  group('Bitcoin Crypto Performance', () {
    test('should generate HD wallet in isolate without blocking UI', () async {
      // Arrange
      const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final stopwatch = Stopwatch()..start();

      // Act
      final wallet = await compute(_generateWalletWorker, mnemonic);

      stopwatch.stop();

      // Assert
      expect(wallet, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // < 1s
      print('Wallet generation took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should sign transaction in isolate', () async {
      // Arrange
      final unsignedTx = UnsignedTransaction(...);
      final stopwatch = Stopwatch()..start();

      // Act
      final signedTx = await compute(_signTransactionWorker, unsignedTx);

      stopwatch.stop();

      // Assert
      expect(signedTx, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // < 500ms
      print('Transaction signing took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Worker functions
Wallet _generateWalletWorker(String mnemonic) {
  // Implementação real de geração de carteira
  // Usando bip39, bip32, etc.
}

SignedTransaction _signTransactionWorker(UnsignedTransaction tx) {
  // Implementação real de assinatura
}
```

---

## 5️⃣ Testes de Segurança

### **Validation Tests**

#### `bitcoin_address_validation_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bitcoin Address Validation', () {
    test('should validate Legacy (P2PKH) addresses', () {
      // Valid addresses
      expect(validateBitcoinAddress('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'), true);
      expect(validateBitcoinAddress('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'), true);

      // Invalid addresses
      expect(validateBitcoinAddress('1InvalidAddress'), false);
      expect(validateBitcoinAddress(''), false);
    });

    test('should validate SegWit (P2SH) addresses', () {
      // Valid addresses
      expect(validateBitcoinAddress('3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy'), true);

      // Invalid addresses
      expect(validateBitcoinAddress('3InvalidAddress'), false);
    });

    test('should validate Native SegWit (Bech32) addresses', () {
      // Valid addresses
      expect(validateBitcoinAddress('bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'), true);
      expect(validateBitcoinAddress('bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'), true);

      // Invalid addresses
      expect(validateBitcoinAddress('bc1qinvalidaddress'), false);
    });

    test('should validate Taproot (Bech32m) addresses', () {
      // Valid addresses
      expect(validateBitcoinAddress('bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297'), true);

      // Invalid addresses
      expect(validateBitcoinAddress('bc1pinvalidaddress'), false);
    });
  });
}
```

---

## 📊 Cobertura de Testes Recomendada

| Camada | Cobertura Mínima | Prioridade |
|--------|------------------|------------|
| **Domain** | 100% | 🔴 Crítica |
| **Data** | 90%+ | 🟠 Alta |
| **Presentation** | 70%+ | 🟡 Média |

---

## 🚀 Comandos para Executar Testes

```bash
# Todos os testes
flutter test

# Testes com cobertura
flutter test --coverage

# Testes específicos
flutter test test/features/wallet/domain/usecases/send_bitcoin_usecase_test.dart

# Testes de performance (com profiling)
flutter test --profile

# Gerar relatório de cobertura (HTML)
genhtml coverage/lcov.info -o coverage/html
```

---

## 🎯 Métricas de Sucesso

- ✅ **100% de cobertura** em UseCases críticos (SendBitcoin, CreateWallet)
- ✅ **< 1s** para geração de carteira HD
- ✅ **< 500ms** para assinatura de transação
- ✅ **0 falhas** em validações de endereço
- ✅ **60 FPS** em animações de UI

---

**Conclusão:** Suite de testes completa cobrindo segurança, performance e corretude.
