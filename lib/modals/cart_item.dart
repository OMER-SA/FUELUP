class CartItem {
  String description;
  String name;
  String recipieId;
  String category;
  String kitchenName;
  String kitchenId;
  int quantity;
  int price;
  String? mealPicture;
  List<Map<String, dynamic>> recipie;

  CartItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.category,
    required this.kitchenName,
    required this.kitchenId,
    required this.recipieId,
    required this.recipie,
    this.mealPicture,
  });

  // Convert CartItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'recipieId': recipieId,
      'category': category,
      'kitchenName': kitchenName,
      'kitchenId': kitchenId,
      'quantity': quantity,
      'price': price,
      'mealPicture': mealPicture,
      'recipie': recipie,
    };
  }

  // Convert JSON to CartItem
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'],
      description: json['description'],
      recipieId: json['recipieId'],
      category: json['category'],
      kitchenName: json['kitchenName'],
      kitchenId: json['kitchenId'],
      quantity: json['quantity'],
      price: json['price'],
      mealPicture: json['mealPicture'],
      recipie: List<Map<String, dynamic>>.from(json['recipie']),
    );
  }
}
