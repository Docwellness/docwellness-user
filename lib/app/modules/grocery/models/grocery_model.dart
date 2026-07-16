class RecipeUsedIn {
  final String recipeId;
  final String recipeName;
  final String? recipeImage;
  final String? servingTime;
  final double quantity;
  // This entry's OWN original unit (e.g. "tbsp") - a single canonical
  // grocery item can legitimately mix units across the recipes it appears
  // in (that's the whole point of converting to a base unit before
  // summing), so this can differ from the parent GroceryItem's aggregate
  // unit and must be used when displaying this specific entry.
  final String? unit;

  RecipeUsedIn({
    required this.recipeId,
    required this.recipeName,
    this.recipeImage,
    this.servingTime,
    required this.quantity,
    this.unit,
  });

  factory RecipeUsedIn.fromJson(Map<String, dynamic> json) {
    return RecipeUsedIn(
      recipeId: json['recipeId']?.toString() ?? '',
      recipeName: json['recipeName']?.toString() ?? '',
      recipeImage: json['recipeImage']?.toString(),
      servingTime: json['servingTime']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString(),
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
  // Pre-formatted quantity string from the backend (e.g. "330g (~3 medium
  // onion)") - now that totalQuantity/unit are always the base unit
  // (grams/ml), this is what should actually be shown to the patient;
  // totalQuantity/unit stay available as a fallback when this is null (e.g.
  // an ingredient with no natural "friendly" conversion, or a supplement).
  final String? displayQuantity;
  // True for a supplement's own self-contained line item (e.g. "Multivitamin
  // Tablet") - never merged with food ingredients.
  final bool isSupplement;

  GroceryItem({
    required this.name,
    this.unit,
    required this.totalQuantity,
    this.category,
    this.priceLevel,
    this.image,
    required this.purchased,
    required this.recipesUsedIn,
    this.displayQuantity,
    this.isSupplement = false,
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
      displayQuantity: json['displayQuantity']?.toString(),
      isSupplement: json['isSupplement'] == true,
    );
  }
}
