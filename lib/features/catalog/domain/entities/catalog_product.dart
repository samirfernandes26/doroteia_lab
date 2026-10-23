import 'package:equatable/equatable.dart';

class ProductDimensions extends Equatable {
  const ProductDimensions({
    required this.height,
    required this.width,
    required this.length,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      height: _readPositiveDouble(json, 'height'),
      width: _readPositiveDouble(json, 'width'),
      length: _readPositiveDouble(json, 'length'),
    );
  }

  final double height;
  final double width;
  final double length;

  Map<String, dynamic> toJson() => {
    'height': height,
    'width': width,
    'length': length,
  };

  @override
  List<Object?> get props => [height, width, length];
}

class CatalogProduct extends Equatable {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.dimensions,
    required this.bedCapacity,
    required this.singleUnitPrice,
    required this.singleUnitTimeMinutes,
    required this.fullBedUnitPrice,
    required this.fullBedTotalTimeMinutes,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final dimensions = json['dimensions'];
    final bedCapacity = json['bedCapacity'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Identificador do produto inválido.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Nome do produto inválido.');
    }
    if (dimensions is! Map<String, dynamic>) {
      throw const FormatException('Dimensões do produto inválidas.');
    }
    if (bedCapacity is! num || bedCapacity < 1 || bedCapacity % 1 != 0) {
      throw const FormatException('Capacidade da mesa inválida.');
    }

    return CatalogProduct(
      id: id,
      name: name.trim(),
      dimensions: ProductDimensions.fromJson(dimensions),
      bedCapacity: bedCapacity.toInt(),
      singleUnitPrice: _readPositiveDouble(json, 'singleUnitPrice'),
      singleUnitTimeMinutes: _readPositiveDouble(json, 'singleUnitTimeMinutes'),
      fullBedUnitPrice: _readPositiveDouble(json, 'fullBedUnitPrice'),
      fullBedTotalTimeMinutes: _readPositiveDouble(
        json,
        'fullBedTotalTimeMinutes',
      ),
    );
  }

  final String id;
  final String name;
  final ProductDimensions dimensions;
  final int bedCapacity;
  final double singleUnitPrice;
  final double singleUnitTimeMinutes;
  final double fullBedUnitPrice;
  final double fullBedTotalTimeMinutes;

  int normalizeQuantity(int quantity) => quantity.clamp(1, bedCapacity);

  double unitPriceFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    if (bedCapacity == 1) return singleUnitPrice;

    return singleUnitPrice -
        ((singleUnitPrice - fullBedUnitPrice) * (normalizedQuantity - 1)) /
            (bedCapacity - 1);
  }

  double totalPriceFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    return unitPriceFor(normalizedQuantity) * normalizedQuantity;
  }

  double totalTimeMinutesFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    if (bedCapacity == 1) return singleUnitTimeMinutes;

    return singleUnitTimeMinutes +
        ((fullBedTotalTimeMinutes - singleUnitTimeMinutes) *
                (normalizedQuantity - 1)) /
            (bedCapacity - 1);
  }

  double discountPercentageFor(int quantity) {
    if (singleUnitPrice == 0) return 0;
    return ((singleUnitPrice - unitPriceFor(quantity)) / singleUnitPrice) * 100;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dimensions': dimensions.toJson(),
    'bedCapacity': bedCapacity,
    'singleUnitPrice': singleUnitPrice,
    'singleUnitTimeMinutes': singleUnitTimeMinutes,
    'fullBedUnitPrice': fullBedUnitPrice,
    'fullBedTotalTimeMinutes': fullBedTotalTimeMinutes,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    dimensions,
    bedCapacity,
    singleUnitPrice,
    singleUnitTimeMinutes,
    fullBedUnitPrice,
    fullBedTotalTimeMinutes,
  ];
}

double _readPositiveDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite || value <= 0) {
    throw FormatException('$key inválido.');
  }
  return value.toDouble();
}
