class CompleteProfileData {
  String? _uuid;
  int? _age;
  int? _weight;
  String? _address;
  double? _height;
  List<String>? _selectedAllergies;

  CompleteProfileData(
      {required String uuid,
      required int age,
      required int weight,
      required double height,
      required String address,
      required List<String> commonAlergies}) {
    _uuid = uuid;
    _age = age;
    _weight = weight;
    _height = height;
    _address = address;
    _selectedAllergies = commonAlergies;
  }

  String? get getUuid => _uuid;
  int? get getAge => _age;
  int? get getWeight => _weight;
  double? get getHeight => _height;
  List<String>? get getSelectedAllergies => _selectedAllergies;
  String? get getAddress => _address;
}
