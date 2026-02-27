class SingUpDto {
  String email, password, role, phone;
  String? firstName;
  String? lastName;
  String? kitchenName;
  String? weigth;
  String? height;
  String? age;
  SingUpDto({
    required this.firstName,
    required this.lastName,
    required this.kitchenName,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
  });
}
