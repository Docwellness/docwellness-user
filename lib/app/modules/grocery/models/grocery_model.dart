class RecipeUsedIn {
  final String recipeId;
  final String recipeName;
  final String? recipeImage;
  final String? servingTime;
  final double quantity;

  RecipeUsedIn({
    required this.recipeId,
    required this.recipeName,
    this.recipeImage,
    this.servingTime,
    required this.quantity,
  });

  factory RecipeUsedIn.fromJson(Map<String, dynamic> json) {
    return RecipeUsedIn(
      recipeId: json['recipeId']?.toString() ?? '',
      recipeName: json['recipeName']?.toString() ?? '',
      recipeImage: json['recipeImage']?.toString(),
      servingTime: json['servingTime']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GroceryItem {
  final String name;
  final String? unit;
  final double totalQuantity;
  final String? category;
  final String? priceLevel;
  final String? image;
  bool purchased;
  final List<RecipeUsedIn> recipesUsedIn;

  GroceryItem({
    required this.name,
    this.unit,
    required this.totalQuantity,
    this.category,
    this.priceLevel,
    this.image,
    required this.purchased,
    required this.recipesUsedIn,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString(),
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString(),
      priceLevel: json['priceLevel']?.toString(),
      image: json['image']?.toString(),
      purchased: json['purchased'] == true,
      recipesUsedIn: (json['recipesUsedIn'] as List<dynamic>? ?? [])
          .map((e) => RecipeUsedIn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
