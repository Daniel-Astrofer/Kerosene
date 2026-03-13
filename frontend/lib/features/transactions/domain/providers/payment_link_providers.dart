import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../usecases/create_payment_link_usecase.dart';
import '../../presentation/providers/transaction_provider.dart';

final createPaymentLinkUseCaseProvider = Provider<CreatePaymentLinkUseCase>((
  ref,
) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CreatePaymentLinkUseCase(repository);
});
