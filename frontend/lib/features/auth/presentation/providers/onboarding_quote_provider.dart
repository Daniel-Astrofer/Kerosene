import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/voucher/presentation/providers/voucher_providers.dart';

class OnboardingQuote {
  final double amountBtc;
  final String? depositAddress;
  final String? pendingVoucherId;

  const OnboardingQuote({
    required this.amountBtc,
    this.depositAddress,
    this.pendingVoucherId,
  });
}

class OnboardingQuoteNotifier extends AsyncNotifier<OnboardingQuote?> {
  @override
  Future<OnboardingQuote?> build() async {
    return _fetchQuote();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchQuote);
  }

  Future<OnboardingQuote?> _fetchQuote() async {
    final repository = ref.read(voucherRepositoryProvider);
    final result = await repository.requestVoucher();

    return result.fold((failure) => null, (payload) {
      final data = payload['data'] is Map<String, dynamic>
          ? payload['data'] as Map<String, dynamic>
          : payload;

      final amountSats = (data['amountSats'] as num?)?.toDouble();
      final amountBtc = (data['amountBtc'] as num?)?.toDouble() ??
          (amountSats != null ? amountSats / 100000000 : 0.0);

      if (amountBtc <= 0) {
        return null;
      }

      return OnboardingQuote(
        amountBtc: amountBtc,
        depositAddress: data['depositAddress']?.toString(),
        pendingVoucherId: data['pendingVoucherId']?.toString(),
      );
    });
  }
}

final onboardingQuoteProvider =
    AsyncNotifierProvider<OnboardingQuoteNotifier, OnboardingQuote?>(
  OnboardingQuoteNotifier.new,
);
