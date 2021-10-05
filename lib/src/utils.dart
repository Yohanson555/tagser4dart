part of tagser;

class TagserUtils {
  static bool isAvailableCharacter(int? charCode) {
    if (charCode != null && charCode == charUnderscore ||
        (charCode! >= 48 && charCode <= 57) ||
        (charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122)) {
      return true;
    }

    return false;
  }
}