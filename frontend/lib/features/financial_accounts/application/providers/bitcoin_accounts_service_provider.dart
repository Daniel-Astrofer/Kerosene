import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/financial_accounts/data/bitcoin_accounts_service.dart';

final bitcoinAccountsServiceProvider = Provider<BitcoinAccountsService>((ref) {
  return RemoteBitcoinAccountsService(ref.watch(apiClientProvider));
});
