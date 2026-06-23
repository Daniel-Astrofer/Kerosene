import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../usecases/create_payment_link_usecase.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    show transactionRepositoryProvider;

final createPaymentLinkUseCaseProvider = Provider<CreatePaymentLinkUseCase>((
  ref,
) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CreatePaymentLinkUseCase(repository);
});
