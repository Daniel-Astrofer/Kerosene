// Kerosene Storybook — Wallet & Transaction Screen Stories
// Contains home, wallet, deposit, send/receive, and transaction history screens.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/home/presentation/screens/home_loading_screen.dart';
import 'package:teste/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_method.dart';
import 'package:teste/features/wallet/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_request_flow_screen.dart';
import 'package:teste/features/transactions/presentation/screens/deposits_screen.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart'
    show ColdWalletCreationScreen;

/// Shared mock wallet used across wallet stories for constructor requirements.
final Wallet _mockWallet = Wallet(
  id: 'story_wallet_001',
  name: 'Storybook Wallet',
  address: 'bc1qstorybook0mock0address0sovereign0key0',
  balance: 0.042,
  derivationPath: "m/84'/0'/0'/0/0",
  type: WalletType.nativeSegwit,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final Wallet _mockColdWallet = _mockWallet.copyWith(
  id: 'story_wallet_cold',
  name: 'Storybook Cold Vault',
  address: 'bc1qstorybookcoldvault0address0sovereign0key',
  walletMode: 'ONCHAIN',
);

/// Returns all wallet and transaction-related stories.
List<Story> walletStories() {
  return [
    // ─── Home & Dashboard ───────────────────────────────
    Story(
      name: 'Wallet/Home Dashboard',
      description:
          'Main dashboard with balance, wallets, and recent transactions.',
      builder: (context) => const HomeScreen(),
    ),
    Story(
      name: 'Wallet/Home Loading',
      description: 'Skeleton loading state for the home dashboard.',
      builder: (context) => const HomeLoadingScreen(),
    ),

    // ─── Send ───────────────────────────────────────────
    Story(
      name: 'Wallet/Send Money',
      description: 'Send BTC screen with keypad and address input.',
      builder: (context) => SendMoneyScreen(walletId: _mockWallet.name),
    ),
    Story(
      name: 'Wallet/Cold Wallet — Create',
      description:
          'Create a watch-only cold wallet with purpose, seed backup, and verification.',
      builder: (context) => const ColdWalletCreationScreen(),
    ),

    // ─── Receive ────────────────────────────────────────
    Story(
      name: 'Wallet/Receive — Selection',
      description: 'Minimal receive method selection flow.',
      builder: (context) => DepositsScreen(initialWallet: _mockWallet),
    ),
    Story(
      name: 'Wallet/Receive — Provedores',
      description: 'Payment gateway provider selection for receiving funds.',
      builder: (context) => ReceiveGatewayProvidersScreen(wallet: _mockWallet),
    ),
    Story(
      name: 'Wallet/Receive — QR Code e Dados',
      description: 'New receive QR and payment data screen.',
      builder: (context) => ReceiveRequestFlowScreen(
        wallet: _mockWallet,
        onChainWallet: false,
        amountBtc: 0.025,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.qr,
        enableStatusPolling: false,
        initialAddress: _mockWallet.address,
        initialPaymentUri:
            'kerosene:pay?address=${_mockWallet.address}&amount=0.02500000',
      ),
    ),
    Story(
      name: 'Wallet/Receive — Confirmações',
      description: 'New receive network confirmation screen.',
      builder: (context) => ReceiveRequestFlowScreen(
        wallet: _mockColdWallet,
        onChainWallet: true,
        amountBtc: 0.045,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.confirmations,
        enableStatusPolling: false,
        initialAddress: _mockColdWallet.address,
        initialPaymentUri:
            'bitcoin:${_mockColdWallet.address}?amount=0.04500000',
        initialTxid: 'storybook-onchain-txid',
        initialConfirmations: 0,
        requiredConfirmations: 3,
      ),
    ),
    Story(
      name: 'Wallet/Receive — Pagamento Identificado',
      description: 'New receive payment identified success screen.',
      builder: (context) => ReceiveRequestFlowScreen(
        wallet: _mockColdWallet,
        onChainWallet: true,
        amountBtc: 0.045,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.identified,
        enableStatusPolling: false,
        initialAddress: _mockColdWallet.address,
        initialPaymentUri:
            'bitcoin:${_mockColdWallet.address}?amount=0.04500000',
        initialTxid: 'storybook-onchain-txid',
        initialConfirmations: 3,
        requiredConfirmations: 3,
        identifiedAt: DateTime(2023, 10, 24, 14, 32),
      ),
    ),
    Story(
      name: 'Wallet/Receive — NFC Kerosene',
      description:
          'Internal NFC receive flow with searching, detected, and success states.',
      builder: (context) => ReceiveNfcFlowScreen(
        wallet: _mockWallet,
        onChainWallet: false,
        amountBtc: 0.00125,
      ),
    ),
    Story(
      name: 'Wallet/Receive — NFC On-chain',
      description:
          'On-chain NFC receive flow with searching, detected, and success states.',
      builder: (context) => ReceiveNfcFlowScreen(
        wallet: _mockWallet.copyWith(
          name: 'Carteira Fria',
          walletMode: 'ONCHAIN',
        ),
        onChainWallet: true,
        amountBtc: 0.00125,
      ),
    ),
    Story(
      name: 'Wallet/Transactions — Statement',
      description: 'Transaction statement screen used by history.',
      builder: (context) => const TransactionStatementScreen(),
    ),
  ];
}
