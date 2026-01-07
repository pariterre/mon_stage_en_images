String emailToPath(String email) {
  var reducedEmail = email.replaceAll('@', '__at__');
  reducedEmail = reducedEmail.replaceAll('.', '__dot__');
  return reducedEmail;
}

String pathToEmail(String reducedEmail) {
  var email = reducedEmail.replaceAll('__at__', '@');
  email = email.replaceAll('__dot__', '.');
  return email;
}

// We need this because before septembre 2025, this field did not exist
final defaultCreationDate = DateTime(2024, 9, 1).toIso8601String();
final _today = DateTime.now();
final DateTime isActiveLimitDate =
    DateTime(_today.month < 7 ? _today.year - 1 : _today.year)
        .add(const Duration(days: 30 * 7));
