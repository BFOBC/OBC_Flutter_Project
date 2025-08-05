class CountryDialCode {
  final String dialCode;
  final String isoCode;
  final int maxLength;

  const CountryDialCode({
    required this.dialCode,
    required this.isoCode,
    required this.maxLength,
  });
}

class CountryDialCodeData {
  static const List<CountryDialCode> countryList = [
    // Middle East & Asia
    CountryDialCode(dialCode: '+971', isoCode: 'AE', maxLength: 9),
    CountryDialCode(dialCode: '+93', isoCode: 'AF', maxLength: 9),
    CountryDialCode(dialCode: '+91', isoCode: 'IN', maxLength: 10),
    CountryDialCode(dialCode: '+92', isoCode: 'PK', maxLength: 10),
    CountryDialCode(dialCode: '+880', isoCode: 'BD', maxLength: 10),
    CountryDialCode(dialCode: '+977', isoCode: 'NP', maxLength: 10),
    CountryDialCode(dialCode: '+966', isoCode: 'SA', maxLength: 9),
    CountryDialCode(dialCode: '+964', isoCode: 'IQ', maxLength: 10),
    CountryDialCode(dialCode: '+98', isoCode: 'IR', maxLength: 10),

    // Europe
    CountryDialCode(dialCode: '+44', isoCode: 'GB', maxLength: 10), // UK
    CountryDialCode(dialCode: '+49', isoCode: 'DE', maxLength: 11), // Germany
    CountryDialCode(dialCode: '+33', isoCode: 'FR', maxLength: 9),  // France
    CountryDialCode(dialCode: '+39', isoCode: 'IT', maxLength: 10), // Italy
    CountryDialCode(dialCode: '+34', isoCode: 'ES', maxLength: 9),  // Spain
    CountryDialCode(dialCode: '+31', isoCode: 'NL', maxLength: 9),  // Netherlands
    CountryDialCode(dialCode: '+32', isoCode: 'BE', maxLength: 9),  // Belgium
    CountryDialCode(dialCode: '+46', isoCode: 'SE', maxLength: 9),  // Sweden
    CountryDialCode(dialCode: '+47', isoCode: 'NO', maxLength: 8),  // Norway
    CountryDialCode(dialCode: '+358', isoCode: 'FI', maxLength: 10),// Finland
    CountryDialCode(dialCode: '+43', isoCode: 'AT', maxLength: 10), // Austria
    CountryDialCode(dialCode: '+420', isoCode: 'CZ', maxLength: 9), // Czech
    CountryDialCode(dialCode: '+48', isoCode: 'PL', maxLength: 9),  // Poland
    CountryDialCode(dialCode: '+36', isoCode: 'HU', maxLength: 9),  // Hungary
    CountryDialCode(dialCode: '+353', isoCode: 'IE', maxLength: 9), // Ireland
    CountryDialCode(dialCode: '+351', isoCode: 'PT', maxLength: 9), // Portugal
    CountryDialCode(dialCode: '+41', isoCode: 'CH', maxLength: 9),  // Switzerland
    CountryDialCode(dialCode: '+45', isoCode: 'DK', maxLength: 8),  // Denmark
    CountryDialCode(dialCode: '+421', isoCode: 'SK', maxLength: 9), // Slovakia

    // North America
    CountryDialCode(dialCode: '+1', isoCode: 'US', maxLength: 10),
    CountryDialCode(dialCode: '+1', isoCode: 'CA', maxLength: 10),

    // Oceania
    CountryDialCode(dialCode: '+61', isoCode: 'AU', maxLength: 9),  // Australia
    CountryDialCode(dialCode: '+64', isoCode: 'NZ', maxLength: 9),  // New Zealand

    // Africa
    CountryDialCode(dialCode: '+20', isoCode: 'EG', maxLength: 10), // Egypt
    CountryDialCode(dialCode: '+234', isoCode: 'NG', maxLength: 10),// Nigeria
    CountryDialCode(dialCode: '+27', isoCode: 'ZA', maxLength: 9),  // South Africa
    CountryDialCode(dialCode: '+212', isoCode: 'MA', maxLength: 9), // Morocco
  ];

  static String? getIsoCode(String dialCode) {
    return countryList
        .firstWhere(
          (country) => country.dialCode == dialCode,
      orElse: () => const CountryDialCode(dialCode: '', isoCode: '', maxLength: 0),
    )
        .isoCode
        .isNotEmpty
        ? countryList
        .firstWhere((country) => country.dialCode == dialCode)
        .isoCode
        : null;
  }

  static int? getMaxLength(String dialCode) {
    return countryList
        .firstWhere(
          (country) => country.dialCode == dialCode,
      orElse: () => const CountryDialCode(dialCode: '', isoCode: '', maxLength: 0),
    )
        .maxLength;
  }
}
