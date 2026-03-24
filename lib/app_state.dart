import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  UserRole? currentRole;
  String currentUserName = '';
  int _orderCounter = 0;
  // Para reset diario del contador
  DateTime _counterDate = DateTime.now();

  int _dailyOrderNumber() {
    final now = DateTime.now();
    if (now.year != _counterDate.year ||
        now.month != _counterDate.month ||
        now.day != _counterDate.day) {
      _orderCounter = 0;
      _counterDate = now;
    }
    _orderCounter++;
    _saveDailyCounter();
    return _orderCounter;
  }

  Future<void> _saveDailyCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_order_counter', _orderCounter);
      await prefs.setString('daily_order_date',
          '${_counterDate.year}-${_counterDate.month}-${_counterDate.day}');
    } catch (_) {}
  }

  Future<void> loadDailyCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('daily_order_date');
      if (savedDate != null) {
        final parts = savedDate.split('-');
        if (parts.length == 3) {
          final savedYear = int.tryParse(parts[0]);
          final savedMonth = int.tryParse(parts[1]);
          final savedDay = int.tryParse(parts[2]);
          final now = DateTime.now();
          if (savedYear == now.year &&
              savedMonth == now.month &&
              savedDay == now.day) {
            // Mismo día: restaurar el contador
            _orderCounter = prefs.getInt('daily_order_counter') ?? 0;
            _counterDate = now;
          } else {
            // Día diferente: resetear
            _orderCounter = 0;
            _counterDate = now;
            await prefs.setInt('daily_order_counter', 0);
            await prefs.setString('daily_order_date',
                '${now.year}-${now.month}-${now.day}');
          }
        }
      }
    } catch (_) {}
  }

  // ── Config Yape ────────────────────────────────────────────────────────────
  String? _yapeQrImagePath;
  String _yapePhone = '';

  String? get yapeQrImagePath => _yapeQrImagePath;
  String get yapePhone => _yapePhone;

  void setYapeConfig({String? qrImagePath, String? phone}) {
    if (qrImagePath != null) _yapeQrImagePath = qrImagePath;
    if (phone != null) _yapePhone = phone;
    notifyListeners();
  }

  void setYapeScreenshot(String orderId, String path) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].yapeScreenshot = path;
      notifyListeners();
    }
  }

  // \u2500\u2500 Inventario \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  final List<InventoryItem> _inventory = [];

  final List<MenuItem> _menuItems = [
    // ── Platos Marinos ─────────────────────────────────────────────────────
    MenuItem(id: 'pm1',  name: 'Ceviche de Pescado Clasico',               section: MenuSection.marineFood, price: 25),
    MenuItem(id: 'pm2',  name: 'Ceviche Mixto',                             section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'pm3',  name: 'Ceviche de Langostinos',                    section: MenuSection.marineFood, price: 35),
    // Duos Marinos
    MenuItem(id: 'pm4',  name: 'Duo: Ceviche Pescado + Chicharron de Pota',        section: MenuSection.marineFood, price: 27),
    MenuItem(id: 'pm5',  name: 'Duo: Ceviche Pescado + Chicharron de Pescado',     section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'pm6',  name: 'Duo: Ceviche Pescado + Chicharron de Langostino',  section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'pm7',  name: 'Duo: Ceviche Mixto + Chicharron de Pota',          section: MenuSection.marineFood, price: 33),
    MenuItem(id: 'pm8',  name: 'Duo: Ceviche Mixto + Chicharron de Pescado',       section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'pm9',  name: 'Duo: Ceviche Mixto + Chicharron de Langostino',    section: MenuSection.marineFood, price: 38),
    // Trios Marinos
    MenuItem(id: 'pm10', name: 'Trio: Ceviche + Chicharron Pota + Arroz c. Marisco',        section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'pm11', name: 'Trio: Ceviche + Chicharron Pescado + Arroz c. Marisco',     section: MenuSection.marineFood, price: 38),
    MenuItem(id: 'pm12', name: 'Trio: Ceviche + Chicharron Langostino + Arroz c. Marisco',  section: MenuSection.marineFood, price: 40),
    // Ronda Marina
    MenuItem(id: 'pm13', name: 'Ronda: Ceviche, Arroz, L.Tigre, Causa Atun, Chicharron Langostino', section: MenuSection.marineFood, price: 65),
    MenuItem(id: 'pm14', name: 'Ronda: Ceviche, Arroz/Chaufa Marisco, L.Tigre, Causa, Chicharron Pota', section: MenuSection.marineFood, price: 60),
    MenuItem(id: 'pm15', name: 'Jalea de Pescado (Filete o Cabrilla)',      section: MenuSection.marineFood, price: 45),
    MenuItem(id: 'pm16', name: 'Jalea Mixta (Filete o Cabrilla)',           section: MenuSection.marineFood, price: 45),
    MenuItem(id: 'pm17', name: 'Chicharron de Pescado',                     section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'pm18', name: 'Chicharron de Pota',                        section: MenuSection.marineFood, price: 25),
    MenuItem(id: 'pm19', name: 'Chicharron de Langostino',                  section: MenuSection.marineFood, price: 38),
    // Sudados
    MenuItem(id: 'sd1',  name: 'Concentrado Mixto de la Casa (La Cabana)',  section: MenuSection.marineFood, price: 36),
    MenuItem(id: 'sd2',  name: 'Sudado de Cabrilla',                        section: MenuSection.marineFood, price: 36),
    MenuItem(id: 'sd3',  name: 'Sudado de Filete',                          section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'sd4',  name: 'Sudado de Lenguado',                        section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'sd5',  name: 'Parihuela Clasica (Filete, Cabrilla)',      section: MenuSection.marineFood, price: 40),
    MenuItem(id: 'sd6',  name: 'Chilcano de Pescado',                       section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'sd7',  name: 'Arroz con Mariscos',                        section: MenuSection.marineFood, price: 32),
    MenuItem(id: 'sd8',  name: 'Chaufa de Mariscos',                        section: MenuSection.marineFood, price: 32),
    MenuItem(id: 'sd9',  name: 'Chaufa de Pescado',                         section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'sd10', name: 'Chaufa de Langostino',                      section: MenuSection.marineFood, price: 40),
    MenuItem(id: 'sd11', name: 'Cabrilla Frita con Yuca y Sarsa',           section: MenuSection.marineFood, price: 27),
    MenuItem(id: 'sd12', name: 'Filete de Pescado a la Plancha o Grill',    section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'sd13', name: 'Pescado a lo Macho (Cabrilla o Filete)',    section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'sd14', name: 'Chita Frita con Yuca y Sarsa',              section: MenuSection.marineFood, price: 40),
    // Entradas y Piqueos
    MenuItem(id: 'ep1',  name: 'Causa Acevichada',                          section: MenuSection.marineFood, price: 28),
    MenuItem(id: 'ep2',  name: 'Causa de Atun',                             section: MenuSection.marineFood, price: 15),
    MenuItem(id: 'ep3',  name: 'Causa de Pollo',                            section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep4',  name: 'Causa de Langostino',                       section: MenuSection.marineFood, price: 25),
    MenuItem(id: 'ep5',  name: 'Combo de Causa',                            section: MenuSection.marineFood, price: 30),
    MenuItem(id: 'ep6',  name: '8 Tequenos de Queso c/ Guacamole',          section: MenuSection.marineFood, price: 16),
    MenuItem(id: 'ep7',  name: 'Yuquitas a la Huancaina',                   section: MenuSection.marineFood, price: 15),
    MenuItem(id: 'ep8',  name: 'Leche de Tigre Clasica',                    section: MenuSection.marineFood, price: 20),
    MenuItem(id: 'ep9',  name: 'Leche de Tigre Especial',                   section: MenuSection.marineFood, price: 25),
    MenuItem(id: 'ep10', name: '8 Alitas Orientales',                       section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep11', name: '8 Alitas BBQ (Picante)',                    section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep12', name: '8 Alitas BBQ',                              section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep13', name: '8 Alitas Miel de Maracuya',                 section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep14', name: 'Alitas Super Bravas',                       section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep15', name: 'Alitas Acevichadas',                        section: MenuSection.marineFood, price: 20),
    MenuItem(id: 'ep16', name: 'Alitas Maracumango',                        section: MenuSection.marineFood, price: 20),
    MenuItem(id: 'ep17', name: 'Combo de Alitas',                           section: MenuSection.marineFood, price: 35),
    MenuItem(id: 'ep18', name: 'Alitas Broaster',                           section: MenuSection.marineFood, price: 20),
    MenuItem(id: 'ep19', name: 'Salchipapa Clasica',                        section: MenuSection.marineFood, price: 10),
    MenuItem(id: 'ep20', name: 'Salchipapa Especial a lo Pobre',            section: MenuSection.marineFood, price: 15),
    MenuItem(id: 'ep21', name: 'Broaster Clasica',                          section: MenuSection.marineFood, price: 13),
    MenuItem(id: 'ep22', name: 'Broaster Especial a lo Pobre',              section: MenuSection.marineFood, price: 18),
    MenuItem(id: 'ep23', name: 'Porcion de Chaufa',                         section: MenuSection.marineFood, price: 5),
    MenuItem(id: 'ep24', name: 'Porcion de Yuca',                           section: MenuSection.marineFood, price: 8),
    MenuItem(id: 'ep25', name: 'Porcion de Arroz Blanco',                   section: MenuSection.marineFood, price: 4),
    // ── Platos Criollos ────────────────────────────────────────────────────
    MenuItem(id: 'pc1',  name: 'Milanesa de Carne',                         section: MenuSection.creoleFood, price: 28),
    MenuItem(id: 'pc2',  name: 'Lomo Saltado Clasico',                      section: MenuSection.creoleFood, price: 27),
    MenuItem(id: 'pc3',  name: 'Lomo Saltado a lo Pobre',                   section: MenuSection.creoleFood, price: 32),
    MenuItem(id: 'pc4',  name: 'Pollo Saltado Clasico',                     section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'pc5',  name: 'Pollo Saltado a lo Pobre',                  section: MenuSection.creoleFood, price: 30),
    MenuItem(id: 'pc6',  name: 'Pechuga al Grill a lo Pobre',               section: MenuSection.creoleFood, price: 30),
    MenuItem(id: 'pc7',  name: 'Bistec de Lomo Fino Clasico',               section: MenuSection.creoleFood, price: 30),
    MenuItem(id: 'pc8',  name: 'Bistec a lo Pobre',                         section: MenuSection.creoleFood, price: 35),
    MenuItem(id: 'pc9',  name: 'Milanesa de Pollo',                         section: MenuSection.creoleFood, price: 27),
    MenuItem(id: 'pc10', name: 'Tallarin Saltado de Carne',                 section: MenuSection.creoleFood, price: 28),
    MenuItem(id: 'pc11', name: 'Tallarin Saltado de Pollo',                 section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'pc12', name: 'Chicharron de Pollo',                       section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'pc13', name: 'Tacu Lomo',                                 section: MenuSection.creoleFood, price: 32),
    // Chaufa
    MenuItem(id: 'ch1',  name: 'Chaufa de Pollo',                           section: MenuSection.creoleFood, price: 18),
    MenuItem(id: 'ch2',  name: 'Chaufa de Lomo',                            section: MenuSection.creoleFood, price: 22),
    MenuItem(id: 'ch3',  name: 'Chaufa Mixto (Pollo, Carne y Chancho)',     section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'ch4',  name: 'Chaufa Achorado (Huevo, Platano)',          section: MenuSection.creoleFood, price: 25),
    // Pastas
    MenuItem(id: 'pa1',  name: 'Fetuccini a lo Alfredo',                    section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'pa2',  name: 'Fetuccini a la Huancaina con Lomo Saltado', section: MenuSection.creoleFood, price: 32),
    MenuItem(id: 'pa3',  name: 'Fetuccini al Pesto (Milanesa/Bistec/Pollo)',section: MenuSection.creoleFood, price: 32),
    MenuItem(id: 'pa4',  name: 'Spaguetti a la Bolonesa',                   section: MenuSection.creoleFood, price: 30),
    // Sustancias / Sopas
    MenuItem(id: 'so1',  name: 'Sustancia de Pollo',                        section: MenuSection.creoleFood, price: 13),
    MenuItem(id: 'so2',  name: 'Sustancia de Carne',                        section: MenuSection.creoleFood, price: 16),
    MenuItem(id: 'so3',  name: 'Sopa a la Minuta',                          section: MenuSection.creoleFood, price: 13),
    MenuItem(id: 'so4',  name: 'Sopa Criolla',                              section: MenuSection.creoleFood, price: 18),
    // Platos Tradicionales
    MenuItem(id: 'tr1',  name: 'Pato en Aji',                               section: MenuSection.creoleFood, price: 25),
    MenuItem(id: 'tr2',  name: 'Picante de Cuy 1/2',                        section: MenuSection.creoleFood, price: 32),
    MenuItem(id: 'tr3',  name: 'Cuy Frito 1/2',                             section: MenuSection.creoleFood, price: 32),
    MenuItem(id: 'tr4',  name: 'Chicharron de Trucha',                      section: MenuSection.creoleFood, price: 40),
    MenuItem(id: 'tr5',  name: 'Picante de Langostino',                     section: MenuSection.creoleFood, price: 35),
    MenuItem(id: 'tr6',  name: 'Picante de Camarones',                      section: MenuSection.creoleFood, price: 40),
    MenuItem(id: 'tr7',  name: 'Chupe de Mariscos',                         section: MenuSection.creoleFood, price: 30),
    MenuItem(id: 'tr8',  name: 'Chupe de Pescado',                          section: MenuSection.creoleFood, price: 28),
    MenuItem(id: 'tr9',  name: 'Chupe de Camarones',                        section: MenuSection.creoleFood, price: 40),
    // ── Tragos y Bebidas ───────────────────────────────────────────────────
    MenuItem(id: 'tb1',  name: 'Pisco Sour',                                section: MenuSection.chicha,     price: 15),
    MenuItem(id: 'tb2',  name: 'Pisco Sour de Maracuya',                    section: MenuSection.chicha,     price: 15),
    MenuItem(id: 'tb3',  name: 'Chilcano',                                  section: MenuSection.chicha,     price: 12),
    MenuItem(id: 'tb4',  name: 'Mojito Clasico',                            section: MenuSection.chicha,     price: 12),
    MenuItem(id: 'tb5',  name: 'Mojito de Maracuya',                        section: MenuSection.chicha,     price: 15),
    MenuItem(id: 'tb6',  name: 'Pina Colada',                               section: MenuSection.chicha,     price: 15),
    MenuItem(id: 'tb7',  name: 'Te / Manzanilla / Anis / Cafe',             section: MenuSection.chicha,     price: 4),
    // ── Gaseosas ───────────────────────────────────────────────────────────
    MenuItem(id: 'gs1',  name: 'Agua Mineral',                              section: MenuSection.soda,       price: 9.5),
    MenuItem(id: 'gs2',  name: 'Gaseosa 500ml',                             section: MenuSection.soda,       price: 4),
    MenuItem(id: 'gs3',  name: 'Gaseosa 1.5L',                              section: MenuSection.soda,       price: 10),
    MenuItem(id: 'gs4',  name: 'Gaseosa 3 Litros',                          section: MenuSection.soda,       price: 18),
    MenuItem(id: 'gs5',  name: 'Gaseosa Gordita',                           section: MenuSection.soda,       price: 6),
    // ── Cervezas / Agua ────────────────────────────────────────────────────
    MenuItem(id: 'ce1',  name: 'Cerveza Cusquena',                          section: MenuSection.water,      price: 11),
    MenuItem(id: 'ce2',  name: 'Cerveza Cristal',                           section: MenuSection.water,      price: 10),
    MenuItem(id: 'ce3',  name: 'Cerveza Pilsen',                            section: MenuSection.water,      price: 10),
    MenuItem(id: 'ce4',  name: 'Cerveza Corona',                            section: MenuSection.water,      price: 15),
    MenuItem(id: 'ce5',  name: 'Vinos',                                     section: MenuSection.water,      price: 25),
  ];

  // ─── Queries de menú ─────────────────────────────────────────────────────────

  List<MenuItem> get menuItems => List.from(_menuItems);

  List<MenuItem> get availableFoodItems =>
      _menuItems.where((m) => m.isFood && m.isAvailable).toList();

  List<MenuItem> get availableDrinkItems =>
      _menuItems.where((m) => !m.isFood && m.isAvailable).toList();

  List<MenuItem> get allFoodItems =>
      _menuItems.where((m) => m.isFood).toList();

  List<MenuItem> get allDrinkItems =>
      _menuItems.where((m) => !m.isFood).toList();

  List<MenuItem> availableItemsBySection(MenuSection section) =>
      _menuItems.where((m) => m.section == section && m.isAvailable).toList();

  List<MenuItem> allItemsBySection(MenuSection section) =>
      _menuItems.where((m) => m.section == section).toList();

  MenuItem? getMenuItemById(String id) {
    try {
      return _menuItems.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Pedidos ─────────────────────────────────────────────────────────────────

  final List<Order> _orders = [];

  // Track per-item checks in kitchen: orderId -> Set of item indices
  final Map<String, Set<int>> _kitchenChecks = {};

  Set<int> getKitchenChecks(String orderId) =>
      _kitchenChecks[orderId] ?? {};

  void toggleKitchenItemCheck(String orderId, int itemIndex) {
    _kitchenChecks.putIfAbsent(orderId, () => {});
    if (_kitchenChecks[orderId]!.contains(itemIndex)) {
      _kitchenChecks[orderId]!.remove(itemIndex);
    } else {
      _kitchenChecks[orderId]!.add(itemIndex);
    }
    notifyListeners();
  }

  bool allKitchenItemsChecked(String orderId, int itemCount) {
    final checks = _kitchenChecks[orderId];
    if (checks == null) return false;
    return checks.length >= itemCount;
  }

  List<Order> get orders => List.from(_orders);

  List<Order> get kitchenQueue {
    final list = _orders
        .where((o) =>
            !o.isDirectSale &&
            (o.status == OrderStatus.pending ||
                o.status == OrderStatus.inProgress))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<Order> get activeKitchenOrders => kitchenQueue.take(2).toList();

  int get kitchenQueueSize => kitchenQueue.length;

  int get todayCompletedOrders {
    final today = DateTime.now();
    return _orders.where((o) =>
        o.status == OrderStatus.delivered &&
        o.createdAt.year == today.year &&
        o.createdAt.month == today.month &&
        o.createdAt.day == today.day).length;
  }

  int get todayTotalOrders {
    final today = DateTime.now();
    return _orders.where((o) =>
        o.createdAt.year == today.year &&
        o.createdAt.month == today.month &&
        o.createdAt.day == today.day).length;
  }

  // ── Sistema de autenticación ───────────────────────────────────────────────

  String _adminPassword = 'AMANDA123';
  String? _weeklyPassword;

  // Lista base de trabajadores (se puede ampliar desde la UI)
  final List<RegisteredWorker> _workers = [
    RegisteredWorker(name: 'Karolina', role: UserRole.waiter),
    RegisteredWorker(name: 'Jhon',      role: UserRole.waiter),
    RegisteredWorker(name: 'Paula',     role: UserRole.waiter),
    RegisteredWorker(name: 'Luz',       role: UserRole.kitchen),
  ];

  String get adminPassword => _adminPassword;
  String? get weeklyPassword => _weeklyPassword;
  List<RegisteredWorker> get registeredWorkers => List.from(_workers);

  /// Carga configuración y sesiones desde SharedPreferences.
  /// Llamar en el initState del LoginScreen.
  Future<void> loadAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminPassword = prefs.getString('auth_admin_pwd') ?? 'AMANDA123';
      _weeklyPassword = prefs.getString('auth_weekly_pwd');

      // Trabajadores extra añadidos por el admin
      final extraNames = prefs.getStringList('auth_extra_workers') ?? [];
      for (final name in extraNames) {
        if (!_workers.any((w) => w.name == name)) {
          final roleStr = prefs.getString('auth_worker_role_$name') ?? 'waiter';
          _workers.add(RegisteredWorker(
            name: name,
            role: roleStr == 'kitchen' ? UserRole.kitchen : UserRole.waiter,
          ));
        }
      }

      // Estado de expulsados y sesiones
      final expelled = prefs.getStringList('auth_expelled') ?? [];
      for (final w in _workers) {
        w.isExpelled = expelled.contains(w.name);
        final sessionStr = prefs.getString('auth_session_${w.name}');
        if (sessionStr != null) {
          w.lastLogin = DateTime.tryParse(sessionStr);
        }
      }
    } catch (_) {}
    await loadDailyCounter();
    notifyListeners();
  }

  /// Verifica si un trabajador tiene sesión válida (< 7 días).
  bool checkWorkerSession(String name) {
    final w = _findWorker(name);
    if (w == null || w.isExpelled) return false;
    if (w.lastLogin == null) return false;
    return DateTime.now().difference(w.lastLogin!).inDays < 7;
  }

  /// Login de administrador con contraseña.
  bool loginAdmin(String password) {
    if (password != _adminPassword) return false;
    currentRole = UserRole.admin;
    currentUserName = 'Amanda';
    notifyListeners();
    return true;
  }

  /// Login de trabajador con contraseña semanal.
  /// Retorna null si fue exitoso, o un mensaje de error.
  Future<String?> loginWorker(String name, String password) async {
    if (_weeklyPassword == null || _weeklyPassword!.isEmpty) {
      return 'El administrador no ha configurado la contraseña semanal todavía.';
    }
    if (password != _weeklyPassword) {
      return 'Contraseña semanal incorrecta. Solicítala al administrador.';
    }
    final w = _findWorker(name);
    if (w == null) return 'Trabajador no registrado.';
    if (w.isExpelled) return 'Tu acceso fue revocado. Contacta al administrador.';

    final now = DateTime.now();
    w.lastLogin = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_session_$name', now.toIso8601String());
    } catch (_) {}

    currentRole = w.role;
    currentUserName = name;
    notifyListeners();
    return null;
  }

  /// Login con sesión guardada (sin contraseña).
  void loginWithSession(String name) {
    final w = _findWorker(name);
    if (w == null) return;
    currentRole = w.role;
    currentUserName = name;
    notifyListeners();
  }

  /// Cierra la sesión en memoria (no elimina la sesión guardada).
  void logout() {
    currentRole = null;
    currentUserName = '';
    notifyListeners();
  }

  /// Cambia la contraseña del administrador.
  Future<void> setAdminPassword(String newPwd) async {
    _adminPassword = newPwd;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_admin_pwd', newPwd);
    } catch (_) {}
    notifyListeners();
  }

  /// Establece (o borra si vacío) la contraseña semanal.
  Future<void> setWeeklyPassword(String pwd) async {
    _weeklyPassword = pwd.isEmpty ? null : pwd;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pwd.isEmpty) {
        await prefs.remove('auth_weekly_pwd');
      } else {
        await prefs.setString('auth_weekly_pwd', pwd);
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Expulsa a un trabajador e invalida su sesión.
  Future<void> expelWorker(String name) async {
    final w = _findWorker(name);
    if (w == null) return;
    w.isExpelled = true;
    w.lastLogin = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_session_$name');
      final expelled = _workers.where((r) => r.isExpelled).map((r) => r.name).toList();
      await prefs.setStringList('auth_expelled', expelled);
    } catch (_) {}
    notifyListeners();
  }

  /// Restaura a un trabajador expulsado.
  Future<void> restoreWorker(String name) async {
    final w = _findWorker(name);
    if (w == null) return;
    w.isExpelled = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final expelled = _workers.where((r) => r.isExpelled).map((r) => r.name).toList();
      await prefs.setStringList('auth_expelled', expelled);
    } catch (_) {}
    notifyListeners();
  }

  /// Añade un nuevo trabajador al sistema.
  Future<void> addWorker(String name, UserRole role) async {
    if (_workers.any((w) => w.name.toLowerCase() == name.toLowerCase())) return;
    _workers.add(RegisteredWorker(name: name, role: role));
    try {
      final prefs = await SharedPreferences.getInstance();
      final extra = _workers
          .where((w) => !['Maricielo', 'Jhon', 'Paula', 'Luz'].contains(w.name))
          .map((w) => w.name)
          .toList();
      await prefs.setStringList('auth_extra_workers', extra);
      final roleStr = role == UserRole.kitchen ? 'kitchen' : 'waiter';
      await prefs.setString('auth_worker_role_$name', roleStr);
    } catch (_) {}
    notifyListeners();
  }

  RegisteredWorker? _findWorker(String name) {
    try {
      return _workers.firstWhere((w) => w.name == name);
    } catch (_) {
      return null;
    }
  }

  // ─── Gestión del menú ────────────────────────────────────────────────────────

  void addMenuItem(String name, MenuSection section, double price) {
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    _menuItems.add(MenuItem(id: id, name: name, section: section, price: price));
    notifyListeners();
  }

  void removeMenuItem(String id) {
    _menuItems.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void toggleMenuItemAvailability(String id) {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _menuItems[idx].isAvailable = !_menuItems[idx].isAvailable;
      notifyListeners();
    }
  }

  void updateMenuItem(String id, String name, double price) {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _menuItems[idx].name = name;
      _menuItems[idx].price = price;
      notifyListeners();
    }
  }

  /// Establece el stock de un ítem. null = sin límite.
  void setItemStock(String id, int? stock) {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _menuItems[idx].stock = stock;
      if (stock != null && stock <= 0) {
        _menuItems[idx].isAvailable = false;
      } else if (stock == null || stock > 0) {
        _menuItems[idx].isAvailable = true;
      }
      notifyListeners();
    }
  }

  // Descuenta stock según las items pedidos
  void _reduceStock(List<OrderItem> items) {
    for (final item in items) {
      final idx = _menuItems.indexWhere((m) => m.id == item.menuItemId);
      if (idx != -1 && _menuItems[idx].stock != null) {
        final newStock =
            (_menuItems[idx].stock! - item.quantity).clamp(0, 9999);
        _menuItems[idx].stock = newStock;
        if (newStock <= 0) _menuItems[idx].isAvailable = false;
      }
    }
  }

  // ─── Pedidos de mozo ─────────────────────────────────────────────────────────

  Order submitOrder({
    required int tableNumber,
    required List<OrderItem> items,
    required String waiterName,
  }) {
    final orderNum = _dailyOrderNumber();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: tableNumber,
      items: List.from(items),
      createdAt: DateTime.now(),
      waiterName: waiterName,
      orderNumber: orderNum,
    );
    _orders.add(order);
    _reduceStock(items);
    notifyListeners();
    return order;
  }

  /// Venta directa del admin: no va a cocina, se marca entregado al instante.
  Order submitDirectSale({
    required List<OrderItem> items,
    required String adminName,
  }) {
    final orderNum = _dailyOrderNumber();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: 0,
      items: List.from(items),
      status: OrderStatus.delivered,
      createdAt: DateTime.now(),
      waiterName: adminName,
      orderNumber: orderNum,
      isDirectSale: true,
    );
    _orders.add(order);
    _reduceStock(items);
    notifyListeners();
    return order;
  }

  void markOrderDelivered(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = OrderStatus.delivered;
      notifyListeners();
    }
  }

  void addItemsToOrder(String orderId, List<OrderItem> newItems) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final wasDelivered = _orders[idx].status == OrderStatus.delivered;
      for (final newItem in newItems) {
        // Solo fusionar si mismo plato Y misma nota
        final existingIdx = _orders[idx].items.indexWhere((i) =>
            i.menuItemId == newItem.menuItemId &&
            (i.notes ?? '') == (newItem.notes ?? ''));
        if (existingIdx != -1) {
          _orders[idx].items[existingIdx].quantity += newItem.quantity;
        } else {
          _orders[idx].items.add(OrderItem(
            menuItemId: newItem.menuItemId,
            menuItemName: newItem.menuItemName,
            quantity: newItem.quantity,
            price: newItem.price,
            isExtra: true,
            notes: newItem.notes,
          ));
        }
      }
      _orders[idx].customTotal = null;
      // Si ya estaba entregado, marcar alerta de cocina
      if (wasDelivered) {
        _orders[idx].hasKitchenAlert = true;
        _orders[idx].extraAddedAt = DateTime.now();
      }
      _reduceStock(newItems);
      notifyListeners();
    }
  }

  void acknowledgeKitchenAlert(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].hasKitchenAlert = false;
      _orders[idx].extraAddedAt = null;
      notifyListeners();
    }
  }

  List<Order> get ordersWithKitchenAlerts =>
      _orders.where((o) => o.hasKitchenAlert).toList();

  void removeItemFromOrder(String orderId, int itemIndex) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1 && itemIndex >= 0 && itemIndex < _orders[idx].items.length) {
      final removed = _orders[idx].items.removeAt(itemIndex);
      // Restaurar stock
      final mIdx = _menuItems.indexWhere((m) => m.id == removed.menuItemId);
      if (mIdx != -1 && _menuItems[mIdx].stock != null) {
        _menuItems[mIdx].stock = _menuItems[mIdx].stock! + removed.quantity;
        if (_menuItems[mIdx].stock! > 0) _menuItems[mIdx].isAvailable = true;
      }
      _orders[idx].customTotal = null;
      notifyListeners();
    }
  }

  void setOrderCustomTotal(String orderId, double total) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].customTotal = total;
      notifyListeners();
    }
  }

  void setPaymentStatus(String orderId, PaymentStatus status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].paymentStatus = status;
      notifyListeners();
    }
  }

  void markTableCompleted(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].isTableCompleted = true;
      notifyListeners();
    }
  }

  void archiveOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].isArchived = true;
      notifyListeners();
    }
  }

  void deleteOrder(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  void returnOrderToWaiter(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = OrderStatus.pending;
      _orders[idx].isTableCompleted = false;
      _orders[idx].paymentStatus = PaymentStatus.none;
      notifyListeners();
    }
  }

  void setInvoiceData(String orderId, String type, String ruc, String name, {String? concept, String? phone}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].invoiceType = type;
      _orders[idx].invoiceRuc = ruc;
      _orders[idx].invoiceName = name;
      _orders[idx].invoiceConcept = concept;
      _orders[idx].invoicePhone = phone;
      notifyListeners();
    }
  }

  void setPaymentDetails(String orderId, double paidAmount, double changeAmount) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].paidAmount = paidAmount;
      _orders[idx].changeAmount = changeAmount;
      notifyListeners();
    }
  }

  /// Pedido para llevar (va a cocina)
  Order submitTakeawayOrder({
    required List<OrderItem> items,
    required String adminName,
  }) {
    final orderNum = _dailyOrderNumber();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: 0,
      items: List.from(items),
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      waiterName: adminName,
      orderNumber: orderNum,
      isTakeaway: true,
    );
    _orders.add(order);
    _reduceStock(items);
    notifyListeners();
    return order;
  }

  /// Pedido delivery (va a cocina)
  Order submitDeliveryOrder({
    required List<OrderItem> items,
    required String waiterName,
    required String phone,
  }) {
    final orderNum = _dailyOrderNumber();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: 0,
      items: List.from(items),
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      waiterName: waiterName,
      orderNumber: orderNum,
      isDelivery: true,
      deliveryPhone: phone,
    );
    _orders.add(order);
    _reduceStock(items);
    notifyListeners();
    return order;
  }

  /// Ganancia del dia (solo pedidos marcados como pagados)
  double get todayRevenue {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.paymentStatus == PaymentStatus.paid &&
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .fold(0.0, (sum, o) => sum + (o.customTotal ?? o.calculatedTotal));
  }

  List<Order> getWaiterOrders(String waiterName) {
    return _orders
        .where((o) => o.waiterName == waiterName && !o.isArchived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  // \u2500\u2500 Inventario \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

  List<InventoryItem> get inventory => List.from(_inventory);

  void addInventoryItem(String name, int qty, String notes) {
    final id = 'inv_${DateTime.now().millisecondsSinceEpoch}';
    _inventory.add(InventoryItem(id: id, name: name, quantity: qty, notes: notes));
    notifyListeners();
  }

  void updateInventoryItem(String id, {String? name, int? quantity, String? notes}) {
    final idx = _inventory.indexWhere((i) => i.id == id);
    if (idx != -1) {
      if (name != null) _inventory[idx].name = name;
      if (quantity != null) _inventory[idx].quantity = quantity;
      if (notes != null) _inventory[idx].notes = notes;
      notifyListeners();
    }
  }

  void removeInventoryItem(String id) {
    _inventory.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
