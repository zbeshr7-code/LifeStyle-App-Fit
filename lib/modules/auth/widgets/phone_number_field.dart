import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/core/utils/phone_utils.dart';
import 'package:soccer_sys/modules/auth/models/phone_country.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.textInputAction,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const country = PhoneCountry.ksa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'phone'.tr,
          textAlign: TextAlign.start,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountrySelector(country: country),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                textInputAction: textInputAction,
                inputFormatters: [SaudiPhoneInputFormatter()],
                maxLength: PhoneUtils.ksaLocalLength,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'phone_hint'.tr,
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppColors.iconMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.country});

  final PhoneCountry country;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PhoneCountry>(
          value: country,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.iconMuted),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          dropdownColor: AppColors.surfaceSolid,
          items: PhoneCountry.supported
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.dialCode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => PhoneCountry.supported
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      item.dialCode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
}
