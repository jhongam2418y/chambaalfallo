enum UserRole { admin, waiter, kitchen }

enum MenuSection {
  marineFood, // Platos Marinos
  creoleFood, // Platos Criollos
  soda,       // Gaseosas
  water,      // Agua
  chicha,     // Chicha / Limonadas
  extra,      // Extra / Manual
}

extension MenuSectionX on MenuSection {
  bool get isFood =>
      this == MenuSection.marineFood || this == MenuSection.creoleFood;

  String get label {
    switch (this) {
      case MenuSection.marineFood: return 'Platos Marinos';
      case MenuSection.creoleFood: return 'Platos Criollos';
      case MenuSection.soda:       return 'Gaseosas';
      case MenuSection.water:      return 'Agua';
      case MenuSection.chicha:     return 'Chicha / Limonadas';
      case MenuSection.extra:      return 'Extra / Manual';
    }
  }
}

enum OrderStatus { pending, inProgress, ready, delivered }

enum PaymentStatus { none, paid, notPaid }

class MenuItem {
  final String id;
  String name;
  MenuSection section;
  double price;
  bool isAvailable;
  int? stock; // null = sin límite

  MenuItem({
    required this.id,
    required this.name,
    required this.section,
    required this.price,
    this.isAvailable = true,
    this.stock,
  });

  bool get isFood => section.isFood;
}

class OrderItem {
  final String menuItemId;
  final String menuItemName;
  int quantity;
  final double price;
  final bool isExtra;
  final String? notes;

  OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.price,
    this.isExtra = false,
    this.notes,
  });

  double get subtotal => price * quantity;
}

class Order {
  final String id;
  int tableNumber;
  final List<OrderItem> items;
  OrderStatus status;
  PaymentStatus paymentStatus;
  final DateTime createdAt;
  double? customTotal;
  final String waiterName;
  final int orderNumber;
  final bool isDirectSale;
  final bool isTakeaway;
  final bool isDelivery;
  String? deliveryPhone;
  bool isTableCompleted;
  bool isArchived;
  String? invoiceType;  // 'boleta_electronica' | 'factura'
  String? invoiceRuc;
  String? invoiceName;
  String? invoiceConcept; // 'consumo' | 'especifico'
  String? invoicePhone;  // teléfono del cliente en boleta
  String? yapeScreenshot; // ruta local de foto del pago yape
  double? paidAmount;    // cuánto entregó el cliente
  double? changeAmount;  // vuelto recibido
  bool hasKitchenAlert;  // se agregaron ítems después de entregado
  DateTime? extraAddedAt; // cuándo se agregó el extra

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.none,
    required this.createdAt,
    this.customTotal,
    required this.waiterName,
    required this.orderNumber,
    this.isDirectSale = false,
    this.isTakeaway = false,
    this.isDelivery = false,
    this.deliveryPhone,
    this.isTableCompleted = false,
    this.isArchived = false,
    this.invoiceType,
    this.invoiceRuc,
    this.invoiceName,
    this.invoiceConcept,
    this.invoicePhone,
    this.yapeScreenshot,
    this.paidAmount,
    this.changeAmount,
    this.hasKitchenAlert = false,
    this.extraAddedAt,
  });

  double get calculatedTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);
}

class InventoryItem {
  final String id;
  String name;
  int quantity;
  String notes;

  InventoryItem({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.notes = '',
  });
}

// ─── Trabajador registrado ────────────────────────────────────────────────────

class RegisteredWorker {
  String name;
  UserRole role;
  bool isExpelled;
  DateTime? lastLogin;

  RegisteredWorker({
    required this.name,
    required this.role,
    this.isExpelled = false,
    this.lastLogin,
  });
}
