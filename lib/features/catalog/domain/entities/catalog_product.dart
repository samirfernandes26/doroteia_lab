import 'package:equatable/equatable.dart';

class ProductDimensions extends Equatable {
  const ProductDimensions({
    required this.height,
    required this.width,
    required this.length,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      height: _readPositiveDouble(json, primaryKey: 'height'),
      width: _readPositiveDouble(json, primaryKey: 'width'),
      length: _readPositiveDouble(json, primaryKey: 'length'),
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
    this.projectUrl = '',
    int? mediumCapacity,
    double? mediumTotalTimeMinutes,
    double? mediumUnitPrice,
  }) : assert(bedCapacity >= 1, 'bedCapacity deve ser maior que zero.'),
       assert(
         mediumCapacity == null ||
             (mediumCapacity >= 1 && mediumCapacity <= bedCapacity),
         'mediumCapacity deve estar entre 1 e bedCapacity.',
       ),
       mediumCapacity = mediumCapacity ?? bedCapacity,
       mediumTotalTimeMinutes =
           mediumTotalTimeMinutes ?? fullBedTotalTimeMinutes,
       mediumUnitPrice = mediumUnitPrice ?? fullBedUnitPrice;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final projectUrl = json['projectUrl'];
    final dimensions = _readDimensions(json);
    final bedCapacity = _readPositiveInt(
      json,
      primaryKey: 'maxCapacity',
      legacyKey: 'bedCapacity',
    );

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Identificador do produto inválido.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Nome do produto inválido.');
    }
    if (projectUrl != null && projectUrl is! String) {
      throw const FormatException('Link do projeto inválido.');
    }

    final hasMediumPoint =
        json.containsKey('mediumCapacity') ||
        json.containsKey('mediumTotalTimeMinutes') ||
        json.containsKey('mediumUnitPrice');

    final fullBedUnitPrice = _readPositiveDouble(
      json,
      primaryKey: 'fullUnitPrice',
      legacyKey: 'fullBedUnitPrice',
    );
    final fullBedTotalTimeMinutes = _readPositiveDouble(
      json,
      primaryKey: 'fullTotalTimeMinutes',
      legacyKey: 'fullBedTotalTimeMinutes',
    );
    final mediumCapacity = hasMediumPoint
        ? _readPositiveInt(json, primaryKey: 'mediumCapacity')
        : bedCapacity;

    if (mediumCapacity > bedCapacity) {
      throw const FormatException(
        'A capacidade da mesa média não pode superar a mesa cheia.',
      );
    }

    return CatalogProduct(
      id: id,
      name: name.trim(),
      projectUrl: (projectUrl as String?)?.trim() ?? '',
      dimensions: dimensions,
      bedCapacity: bedCapacity,
      singleUnitPrice: _readPositiveDouble(json, primaryKey: 'singleUnitPrice'),
      singleUnitTimeMinutes: _readPositiveDouble(
        json,
        primaryKey: 'singleTimeMinutes',
        legacyKey: 'singleUnitTimeMinutes',
      ),
      mediumCapacity: mediumCapacity,
      mediumTotalTimeMinutes: hasMediumPoint
          ? _readPositiveDouble(json, primaryKey: 'mediumTotalTimeMinutes')
          : fullBedTotalTimeMinutes,
      mediumUnitPrice: hasMediumPoint
          ? _readPositiveDouble(json, primaryKey: 'mediumUnitPrice')
          : fullBedUnitPrice,
      fullBedUnitPrice: fullBedUnitPrice,
      fullBedTotalTimeMinutes: fullBedTotalTimeMinutes,
    );
  }

  final String id;
  final String name;
  final String projectUrl;
  final ProductDimensions dimensions;
  final int bedCapacity;
  final double singleUnitPrice;
  final double singleUnitTimeMinutes;
  final int mediumCapacity;
  final double mediumTotalTimeMinutes;
  final double mediumUnitPrice;
  final double fullBedUnitPrice;
  final double fullBedTotalTimeMinutes;

  double get height => dimensions.height;
  double get width => dimensions.width;
  double get length => dimensions.length;
  int get maxCapacity => bedCapacity;
  double get singleTimeMinutes => singleUnitTimeMinutes;
  double get fullUnitPrice => fullBedUnitPrice;
  double get fullTotalTimeMinutes => fullBedTotalTimeMinutes;

  int normalizeQuantity(int quantity) => quantity.clamp(1, bedCapacity);

  double unitPriceFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    if (bedCapacity == 1) return singleUnitPrice;

    if (!_hasIntermediatePoint) {
      return _interpolate(
        startValue: singleUnitPrice,
        endValue: fullBedUnitPrice,
        position: normalizedQuantity,
        startPosition: 1,
        endPosition: bedCapacity,
      );
    }

    if (normalizedQuantity <= mediumCapacity) {
      return _interpolate(
        startValue: singleUnitPrice,
        endValue: mediumUnitPrice,
        position: normalizedQuantity,
        startPosition: 1,
        endPosition: mediumCapacity,
      );
    }

    return _interpolate(
      startValue: mediumUnitPrice,
      endValue: fullBedUnitPrice,
      position: normalizedQuantity,
      startPosition: mediumCapacity,
      endPosition: bedCapacity,
    );
  }

  double totalPriceFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    return unitPriceFor(normalizedQuantity) * normalizedQuantity;
  }

  double totalTimeMinutesFor(int quantity) {
    final normalizedQuantity = normalizeQuantity(quantity);
    if (bedCapacity == 1) return singleUnitTimeMinutes.roundToDouble();

    final interpolatedTime = !_hasIntermediatePoint
        ? _interpolate(
            startValue: singleUnitTimeMinutes,
            endValue: fullBedTotalTimeMinutes,
            position: normalizedQuantity,
            startPosition: 1,
            endPosition: bedCapacity,
          )
        : normalizedQuantity <= mediumCapacity
        ? _interpolate(
            startValue: singleUnitTimeMinutes,
            endValue: mediumTotalTimeMinutes,
            position: normalizedQuantity,
            startPosition: 1,
            endPosition: mediumCapacity,
          )
        : _interpolate(
            startValue: mediumTotalTimeMinutes,
            endValue: fullBedTotalTimeMinutes,
            position: normalizedQuantity,
            startPosition: mediumCapacity,
            endPosition: bedCapacity,
          );

    return interpolatedTime.roundToDouble();
  }

  double discountPercentageFor(int quantity) {
    if (singleUnitPrice == 0) return 0;
    return ((singleUnitPrice - unitPriceFor(quantity)) / singleUnitPrice) * 100;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectUrl': projectUrl,
    'height': height,
    'width': width,
    'length': length,
    'maxCapacity': maxCapacity,
    'singleTimeMinutes': singleTimeMinutes,
    'singleUnitPrice': singleUnitPrice,
    'mediumCapacity': mediumCapacity,
    'mediumTotalTimeMinutes': mediumTotalTimeMinutes,
    'mediumUnitPrice': mediumUnitPrice,
    'fullTotalTimeMinutes': fullTotalTimeMinutes,
    'fullUnitPrice': fullUnitPrice,
  };

  bool get _hasIntermediatePoint =>
      mediumCapacity > 1 && mediumCapacity < bedCapacity;

  @override
  List<Object?> get props => [
    id,
    name,
    projectUrl,
    dimensions,
    bedCapacity,
    singleUnitPrice,
    singleUnitTimeMinutes,
    mediumCapacity,
    mediumTotalTimeMinutes,
    mediumUnitPrice,
    fullBedUnitPrice,
    fullBedTotalTimeMinutes,
  ];
}

ProductDimensions _readDimensions(Map<String, dynamic> json) {
  final dimensions = json['dimensions'];
  if (dimensions is Map<String, dynamic>) {
    return ProductDimensions.fromJson(dimensions);
  }

  return ProductDimensions.fromJson(json);
}

int _readPositiveInt(
  Map<String, dynamic> json, {
  required String primaryKey,
  String? legacyKey,
}) {
  final value =
      json[primaryKey] ?? (legacyKey == null ? null : json[legacyKey]);
  if (value is! num || !value.isFinite || value < 1 || value % 1 != 0) {
    throw FormatException('$primaryKey inválido.');
  }
  return value.toInt();
}

double _readPositiveDouble(
  Map<String, dynamic> json, {
  required String primaryKey,
  String? legacyKey,
}) {
  final value =
      json[primaryKey] ?? (legacyKey == null ? null : json[legacyKey]);
  if (value is! num || !value.isFinite || value <= 0) {
    throw FormatException('$primaryKey inválido.');
  }
  return value.toDouble();
}

double _interpolate({
  required double startValue,
  required double endValue,
  required int position,
  required int startPosition,
  required int endPosition,
}) {
  return startValue +
      ((endValue - startValue) * (position - startPosition)) /
          (endPosition - startPosition);
}
