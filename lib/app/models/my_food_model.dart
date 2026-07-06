class MyFoodModel {
  final String image;
  final int shiftIndex;
  final String foodTitle;
  final String des;
  final String quantity;
  final String portion;

  MyFoodModel({
    required this.image,
    required this.shiftIndex,
    required this.foodTitle,
    required this.des,
    required this.quantity,
    required this.portion,
  });

  factory MyFoodModel.fromJson(Map<String, dynamic> json) {
    return MyFoodModel(
      image: json['image'] ?? '',
      shiftIndex: json['shiftIndex'] ?? 0,
      foodTitle: json['foodTitle'] ?? '',
      des: json['des'] ?? '',
      quantity: json['quantity'] ?? '',
      portion: json['portion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'shiftIndex': shiftIndex,
      'foodTitle': foodTitle,
      'des': des,
      'quantity': quantity,
      'portion': portion,
    };
  }
}
