import 'dart:math';

class UuidUtils {
  static final Random _random = Random.secure();

  /// Generates a RFC-compliant UUID v4 string
  static String generateV4() {
    final List<int> values = List<int>.generate(16, (i) => _random.nextInt(256));

    // Set version 4 (bits 12-15 of time_hi_and_version)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant 2 (bits 6-7 of clock_seq_hi_and_reserved)
    values[8] = (values[8] & 0x3f) | 0x80;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
