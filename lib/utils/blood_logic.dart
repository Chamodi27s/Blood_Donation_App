class BloodLogic {
  // Donor ගේ ලේ වර්ගය අනුව එයාට ලේ දිය හැකි වර්ග මොනවාදැයි පරීක්ෂා කිරීම
  static List<String> getCompatibleGroups(String donorGroup) {
    Map<String, List<String>> compatibility = {
      'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], // ඕනෑම කෙනෙකුට දිය හැක
      'O+': ['A+', 'B+', 'AB+', 'O+'],
      'A-': ['A+', 'A-', 'AB+', 'AB-'],
      'A+': ['A+', 'AB+'],
      'B-': ['B+', 'B-', 'AB+', 'AB-'],
      'B+': ['B+', 'AB+'],
      'AB-': ['AB+', 'AB-'],
      'AB+': ['AB+'],
    };
    return compatibility[donorGroup] ?? [];
  }
}