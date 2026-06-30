class SymptomMapper {
  static const Map<String, String> _symptomMap = {
    'Fever': 'fever',
    'Cough': 'cough',
    'Headache': 'headache',
    'Sore Throat': 'sore_throat',
    // ... add all other mappings
  };

  static String getApiTerm(String friendlyName) {
    return _symptomMap[friendlyName] ?? friendlyName.toLowerCase();
  }

  static List<String> mapSymptomsToApi(List<String> friendlyNames) {
    return friendlyNames.map((name) => getApiTerm(name)).toList();
  }
}
