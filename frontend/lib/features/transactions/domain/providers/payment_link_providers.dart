import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../usecases/create_payment_link_usecase.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart'; // Import this

final createPaymentLinkUseCaseProvider = Provider<CreatePaymentLinkUseCase>((
  ref,
) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return CreatePaymentLinkUseCase(repository);
});
