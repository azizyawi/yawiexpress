class OrderModel {
  final String orderId;
  final String userId;
  final LocationPoint pickup;
  final LocationPoint delivery;
  final ContactPerson sender;
  final ContactPerson receiver;
  final PackageDetails package;
  final OrderPins pins;
  final RiderDetails rider;
  final PricingDetails pricing;
  final PaymentDetails payment;
  final String status;
  final OrderTimestamps timestamps;
  final OrderMeta meta;
  final String? paymentReference;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.pickup,
    required this.delivery,
    required this.sender,
    required this.receiver,
    required this.package,
    required this.pins,
    required this.rider,
    required this.pricing,
    required this.payment,
    required this.status,
    required this.timestamps,
    required this.meta,
    required this.paymentReference,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: (json['orderId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      pickup: LocationPoint.fromJson(json['pickup'] ?? {}),
      delivery: LocationPoint.fromJson(json['delivery'] ?? {}),
      sender: ContactPerson.fromJson(json['sender'] ?? {}),
      receiver: ContactPerson.fromJson(json['receiver'] ?? {}),
      package: PackageDetails.fromJson(json['package'] ?? {}),
      pins: OrderPins.fromJson(json['pins'] ?? {}),
      rider: RiderDetails.fromJson(json['rider'] ?? {}),
      pricing: PricingDetails.fromJson(json['pricing'] ?? {}),
      payment: PaymentDetails.fromJson(json['payment'] ?? {}),
      status: (json['status'] ?? '').toString(),
      timestamps: OrderTimestamps.fromJson(json['timestamps'] ?? {}),
      meta: OrderMeta.fromJson(json['meta'] ?? {}),
      paymentReference: json['paymentReference']?.toString(),
    );
  }
}

class LocationPoint {
  final String address;
  final double lat;
  final double lng;
  final String instructions;

  LocationPoint({
    required this.address,
    required this.lat,
    required this.lng,
    required this.instructions,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      address: (json['address'] ?? '').toString(),
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? 0) as num).toDouble(),
      instructions: (json['instructions'] ?? '').toString(),
    );
  }
}

class ContactPerson {
  final String name;
  final String phone;
  final String email;

  ContactPerson({required this.name, required this.phone, required this.email});

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class PackageDetails {
  final String type;
  final String description;
  final double weightKg;
  final int quantity;
  final bool isFragile;

  PackageDetails({
    required this.type,
    required this.description,
    required this.weightKg,
    required this.quantity,
    required this.isFragile,
  });

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      weightKg: ((json['weightKg'] ?? 0) as num).toDouble(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      isFragile: (json['isFragile'] ?? false) as bool,
    );
  }
}

class OrderPins {
  final String pickupPin;
  final String deliveryPin;
  final bool deliveryPinVisible;

  OrderPins({
    required this.pickupPin,
    required this.deliveryPin,
    required this.deliveryPinVisible,
  });

  factory OrderPins.fromJson(Map<String, dynamic> json) {
    return OrderPins(
      pickupPin: (json['pickupPin'] ?? '').toString(),
      deliveryPin: (json['deliveryPin'] ?? '').toString(),
      deliveryPinVisible: (json['deliveryPinVisible'] ?? false) as bool,
    );
  }
}

class RiderDetails {
  final String? riderId;
  final String? name;
  final String? phone;
  final double? lat;
  final double? lng;
  final double? heading;

  RiderDetails({
    required this.riderId,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.heading,
  });

  factory RiderDetails.fromJson(Map<String, dynamic> json) {
    return RiderDetails(
      riderId: json['riderId']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
    );
  }
}

class PricingDetails {
  final double distanceKm;
  final int estimatedTimeMin;
  final double deliveryFee;
  final double serviceFee;
  final double amount;
  final String currency;

  PricingDetails({
    required this.distanceKm,
    required this.estimatedTimeMin,
    required this.deliveryFee,
    required this.serviceFee,
    required this.amount,
    required this.currency,
  });

  factory PricingDetails.fromJson(Map<String, dynamic> json) {
    return PricingDetails(
      distanceKm: ((json['distanceKm'] ?? 0) as num).toDouble(),
      estimatedTimeMin: ((json['estimatedTimeMin'] ?? 0) as num).toInt(),
      deliveryFee: ((json['deliveryFee'] ?? 0) as num).toDouble(),
      serviceFee: ((json['serviceFee'] ?? 0) as num).toDouble(),
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'NGN').toString(),
    );
  }
}

class PaymentDetails {
  final String method;
  final String status;
  final String? reference;
  final String? accessCode;
  final String? authorizationUrl;
  final String? paidAt;
  final String? initializedAt;
  final String? verificationChannel;
  final String gatewayResponse;

  PaymentDetails({
    required this.method,
    required this.status,
    required this.reference,
    required this.accessCode,
    required this.authorizationUrl,
    required this.paidAt,
    required this.initializedAt,
    required this.verificationChannel,
    required this.gatewayResponse,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      method: (json['method'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reference: json['reference']?.toString(),
      accessCode: json['accessCode']?.toString(),
      authorizationUrl: json['authorizationUrl']?.toString(),
      paidAt: json['paidAt']?.toString(),
      initializedAt: json['initializedAt']?.toString(),
      verificationChannel: json['verificationChannel']?.toString(),
      gatewayResponse: (json['gatewayResponse'] ?? '').toString(),
    );
  }
}

class OrderTimestamps {
  final String createdAt;
  final String? acceptedAt;
  final String? arrivedPickupAt;
  final String? pickedUpAt;
  final String? arrivedDeliveryAt;
  final String? deliveredAt;
  final String? cancelledAt;

  OrderTimestamps({
    required this.createdAt,
    required this.acceptedAt,
    required this.arrivedPickupAt,
    required this.pickedUpAt,
    required this.arrivedDeliveryAt,
    required this.deliveredAt,
    required this.cancelledAt,
  });

  factory OrderTimestamps.fromJson(Map<String, dynamic> json) {
    return OrderTimestamps(
      createdAt: (json['createdAt'] ?? '').toString(),
      acceptedAt: json['acceptedAt']?.toString(),
      arrivedPickupAt: json['arrivedPickupAt']?.toString(),
      pickedUpAt: json['pickedUpAt']?.toString(),
      arrivedDeliveryAt: json['arrivedDeliveryAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      cancelledAt: json['cancelledAt']?.toString(),
    );
  }
}

class OrderMeta {
  final String createdDate;
  final String updatedAt;

  OrderMeta({required this.createdDate, required this.updatedAt});

  factory OrderMeta.fromJson(Map<String, dynamic> json) {
    return OrderMeta(
      createdDate: (json['createdDate'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}
