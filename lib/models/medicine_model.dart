// models/medicine_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String brand;
  final String description;
  final String category;
  final double price;
  final double discountPrice;
  final int discount;
  final String? manufacturer;
  final String? imageUrl;
  final int stockQuantity;
  final String? dosage;
  final String? expiryDate;
  final String? composition;
  final String? sideEffects;
  final String? storageInstructions;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool prescriptionRequired;

  Medicine({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPrice,
    required this.discount,
    this.manufacturer,
    this.imageUrl,
    required this.stockQuantity,
    this.dosage,
    this.expiryDate,
    this.composition,
    this.sideEffects,
    this.storageInstructions,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.prescriptionRequired,
  });

  // Calculate discount percentage
  double get discountPercentage {
    if (discount == 0 || price == 0) return 0.0;
    return discount.toDouble();
  }

  // Check if medicine is on discount
  bool get hasDiscount => discount > 0;

  // Get final price after discount
  double get finalPrice => discountPrice;

  // Check if stock is low
  bool get isLowStock => stockQuantity < 10;

  // Check if out of stock
  bool get isOutOfStock => stockQuantity == 0;

  // Check if in stock
  bool get inStock => stockQuantity > 0;

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Medicine(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      brand: data['brand']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Tablet',
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] ?? data['price'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0).toInt(),
      manufacturer: data['manufacturer']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
      dosage: data['dosage']?.toString(),
      expiryDate: data['expiryDate']?.toString(),
      composition: data['composition']?.toString(),
      sideEffects: data['sideEffects']?.toString(),
      storageInstructions: data['storageInstructions']?.toString(),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      prescriptionRequired: data['prescriptionRequired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'description': description,
      'category': category,
      'price': price,
      'discountPrice': discountPrice,
      'discount': discount,
      'manufacturer': manufacturer,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
      'dosage': dosage,
      'expiryDate': expiryDate,
      'composition': composition,
      'sideEffects': sideEffects,
      'storageInstructions': storageInstructions,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'prescriptionRequired': prescriptionRequired,
    };
  }

  // Copy with method for updates
  Medicine copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    String? category,
    double? price,
    double? discountPrice,
    int? discount,
    String? manufacturer,
    String? imageUrl,
    int? stockQuantity,
    String? dosage,
    String? expiryDate,
    String? composition,
    String? sideEffects,
    String? storageInstructions,
    List<String>? tags,
    bool? isActive,
    bool? prescriptionRequired,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      discount: discount ?? this.discount,
      manufacturer: manufacturer ?? this.manufacturer,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      dosage: dosage ?? this.dosage,
      expiryDate: expiryDate ?? this.expiryDate,
      composition: composition ?? this.composition,
      sideEffects: sideEffects ?? this.sideEffects,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
    );
  }

  // Empty medicine factory
  factory Medicine.empty() {
    return Medicine(
      id: '',
      name: '',
      brand: '',
      description: '',
      category: 'Tablet',
      price: 0.0,
      discountPrice: 0.0,
      discount: 0,
      stockQuantity: 0,
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      prescriptionRequired: false,
    );
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, brand: $brand, category: $category, price: $price, stock: $stockQuantity)';
  }

  // Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medicine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
