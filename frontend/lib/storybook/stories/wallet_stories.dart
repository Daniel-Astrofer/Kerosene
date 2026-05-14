// Kerosene Storybook — Wallet & Transaction Screen Stories
// Contains home, wallet, deposit, send/receive, and transaction history screens.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/home/presentation/screens/home_loading_screen.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:teste/features/wallet/presentation/screens/create_wallet_screen.dart';
import 'package:teste/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:teste/features/transactions/presentation/screens/withdraw_screen.dart'
    as tx_withdraw;
import 'package:teste/features/wallet/presentation/screens/wallet_details_screen.dart';
import 'package:teste/features/wallet/presentation/screens/wallet_config_screen.dart';
import 'package:teste/features/wallet/presentation/screens/unified_transaction_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_qr_screen.dart';
import 'package:teste/features/wallet/presentation/screens/nfc_interaction_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit_instructions_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_amount_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_method_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_provider_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_onchain_invoice_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_lightning_invoice_screen.dart';

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

/// Returns all wallet and transaction-related stories.
List<Story> walletStories() {
  return [
    // ─── Home & Dashboard ───────────────────────────────
    Story(
      name: 'Wallet/Home Dashboard',
      description: 'Main dashboard with balance, wallets, and recent transactions.',
      builder: (context) => const HomeScreen(),
    ),
    Story(
      name: 'Wallet/Home Loading',
      description: 'Skeleton loading state for the home dashboard.',
      builder: (context) => const HomeLoadingScreen(),
    ),

    // ─── Wallet Management ──────────────────────────────
    Story(
      name: 'Wallet/Create Wallet',
      description: 'New wallet creation form.',
      builder: (context) => const CreateWalletScreen(),
    ),
    Story(
      name: 'Wallet/Details',
      description: 'Individual wallet detail view with balance and transactions.',
      builder: (context) => WalletDetailsScreen(wallet: _mockWallet),
    ),
    Story(
      name: 'Wallet/Config',
      description: 'Wallet settings and configuration.',
      builder: (context) => WalletConfigScreen(wallet: _mockWallet),
    ),

    // ─── Send & Withdraw ────────────────────────────────
    Story(
      name: 'Wallet/Send Money',
      description: 'Send BTC screen with keypad and address input.',
      builder: (context) => SendMoneyScreen(walletId: _mockWallet.name),
    ),
    Story(
      name: 'Wallet/Withdraw (External BTC)',
      description: 'External BTC withdraw with fees and TOTP.',
      builder: (context) => tx_withdraw.WithdrawScreen(wallet: _mockWallet),
    ),

    // ─── Receive ────────────────────────────────────────
    Story(
      name: 'Wallet/Receive',
      description: 'Receive BTC landing screen.',
      builder: (context) => const ReceiveScreen(),
    ),
    Story(
      name: 'Wallet/Receive QR',
      description: 'Generated QR code for receiving payment.',
      builder: (context) => const ReceiveQrScreen(
        amountDisplay: '0.002 BTC',
        paymentUri: 'bitcoin:bc1qstorybook...',
      ),
    ),

    // ─── Deposit Flow ───────────────────────────────────
    Story(
      name: 'Wallet/Deposit — Amount',
      description: 'Enter BRL amount to convert to BTC.',
      builder: (context) => DepositAmountScreen(wallet: _mockWallet),
    ),
    Story(
      name: 'Wallet/Deposit — Method',
      description: 'Choose deposit method (Pix, Card, Wire).',
      builder: (context) =>
          DepositMethodScreen(wallet: _mockWallet, amountFiat: 1000.0),
    ),
    Story(
      name: 'Wallet/Deposit — Provider',
      description: 'Select onramp provider for the deposit.',
      builder: (context) => DepositProviderScreen(
        wallet: _mockWallet,
        amountFiat: 1000.0,
        method: 'Pix',
      ),
    ),
    Story(
      name: 'Wallet/Deposit — Onchain Invoice',
      description: 'On-chain BTC invoice with address and QR.',
      builder: (context) => DepositOnchainInvoiceScreen(
        wallet: _mockWallet,
        amountFiat: 1000.0,
        providerName: 'Kerosene',
      ),
    ),
    Story(
      name: 'Wallet/Deposit — Lightning Invoice',
      description: 'Lightning Network invoice with BOLT11 QR.',
      builder: (context) => DepositLightningInvoiceScreen(
        wallet: _mockWallet,
        amountFiat: 1000.0,
        providerName: 'Kerosene',
      ),
    ),
    Story(
      name: 'Wallet/Deposit — Instructions',
      description: 'Step-by-step deposit instructions.',
      builder: (context) => const DepositInstructionsScreen(),
    ),

    // ─── Transaction History ────────────────────────────
    Story(
      name: 'Wallet/Transaction History',
      description: 'Unified transaction history (send & receive).',
      builder: (context) {
        final isSend = context.knobs.boolean(
          label: 'Show Send Mode',
          initial: false,
        );
        return UnifiedTransactionScreen(isSend: isSend);
      },
    ),

    // ─── Scanning & NFC ─────────────────────────────────
    Story(
      name: 'Wallet/QR Scanner',
      description: 'Camera-based QR code scanner.',
      builder: (context) => const QrScannerScreen(),
    ),
    Story(
      name: 'Wallet/NFC Interaction',
      description: 'NFC tap-to-pay interaction screen.',
      builder: (context) =>
          const NfcInteractionScreen(amountDisplay: '0.001 BTC'),
    ),
  ];
}
