import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'waiter_screen.dart' show ReceiptScreen, SectionedMenuList, CartBar, showItemNoteDialog;

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA PRINCIPAL ADMIN
// ═══════════════════════════════════════════════════════════════════════════════

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️  Administrador'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () {
            context.read<AppState>().logout();
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: AppTheme.gold),
            tooltip: 'Gestionar cuentas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AccountsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_android, color: Color(0xFF7B2DDB)),
            tooltip: 'Config Yape',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _YapeConfigScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: AppTheme.gold),
            tooltip: 'Inventario',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _InventoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppTheme.gold),
            tooltip: 'Historial de boletas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AllOrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delivery_dining, color: AppTheme.primaryOrange),
            tooltip: 'Pedido para llevar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _TakeawayScreen()),
            ),
          ),
        ],
      ),
      body: const _AdminMenuTab(),
      floatingActionButton: const _AddItemFab(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   CARTA — chips de sección en la parte superior
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminMenuTab extends StatefulWidget {
  const _AdminMenuTab();

  @override
  State<_AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends State<_AdminMenuTab> {
  MenuSection _selected = MenuSection.marineFood;

  static const _sectionIcons = <MenuSection, IconData>{
    MenuSection.marineFood: Icons.set_meal,
    MenuSection.creoleFood: Icons.restaurant,
    MenuSection.soda:       Icons.local_drink,
    MenuSection.water:      Icons.water_drop,
    MenuSection.chicha:     Icons.emoji_food_beverage,
  };

  static const _sectionColors = <MenuSection, Color>{
    MenuSection.marineFood: AppTheme.kitchenBlue,
    MenuSection.creoleFood: AppTheme.primaryOrange,
    MenuSection.soda:       AppTheme.success,
    MenuSection.water:      Color(0xFF64B5F6),
    MenuSection.chicha:     AppTheme.gold,
  };

  static const _sectionLabels = <MenuSection, String>{
    MenuSection.marineFood: 'Marinos',
    MenuSection.creoleFood: 'Criollos',
    MenuSection.soda:       'Gaseosas',
    MenuSection.water:      'Agua',
    MenuSection.chicha:     'Tragos',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.allItemsBySection(_selected);
    final color = _sectionColors[_selected] ?? AppTheme.gold;

    return Column(
      children: [
        // ── Chips de sección ──────────────────────────────────────────────
        Container(
          color: AppTheme.cardDark,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MenuSection.values.map((s) {
                final sel = _selected == s;
                final sc = _sectionColors[s] ?? AppTheme.gold;
                final si = _sectionIcons[s] ?? Icons.category;
                final sl = _sectionLabels[s] ?? s.label;
                return GestureDetector(
                  onTap: () => setState(() => _selected = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? sc : AppTheme.cardMedium,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? sc : sc.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(si, size: 15, color: sel ? Colors.white : sc),
                        const SizedBox(width: 6),
                        Text(
                          sl,
                          style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textLight,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // ── Contador ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          color: color.withOpacity(0.07),
          child: Text(
            '${items.length} plato${items.length != 1 ? 's' : ''} en esta sección',
            style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                letterSpacing: 0.5),
          ),
        ),
        // ── Lista de ítems ────────────────────────────────────────────────
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sectionIcons[_selected] ?? Icons.category,
                        color: color.withOpacity(0.25),
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin platos. Tocá + para agregar.',
                        style: TextStyle(
                            color: AppTheme.textLight.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _MenuItemTile(
                      item: items[i], key: ValueKey(items[i].id)),
                ),
        ),
      ],
    );
  }
}

// ─── Tile de ítem del admin ───────────────────────────────────────────────────

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;

  const _MenuItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: item.isAvailable ? AppTheme.cardMedium : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isAvailable
              ? AppTheme.gold.withOpacity(0.35)
              : Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (item.isAvailable ? AppTheme.primaryOrange : Colors.grey)
                .withOpacity(0.18),
          ),
          child: Icon(
            item.isFood ? Icons.restaurant : Icons.local_bar,
            color: item.isAvailable ? AppTheme.primaryOrange : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: item.isAvailable
                ? AppTheme.textLight
                : AppTheme.textLight.withOpacity(0.4),
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: item.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              'S/ ${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: item.isAvailable ? AppTheme.gold : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            if (item.stock != null)
              GestureDetector(
                onTap: () => _showStockDialog(context, state, item),
                child: _StockBadge(stock: item.stock!),
              )
            else
              GestureDetector(
                onTap: () => _showStockDialog(context, state, item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.textLight.withOpacity(0.2),
                        width: 0.8),
                  ),
                  child: Text(
                    '∞ stock',
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.4),
                        fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => state.toggleMenuItemAvailability(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? AppTheme.success.withOpacity(0.2)
                      : AppTheme.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isAvailable ? AppTheme.success : AppTheme.danger,
                  ),
                ),
                child: Text(
                  item.isAvailable ? 'ON' : 'OFF',
                  style: TextStyle(
                    color:
                        item.isAvailable ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.gold, size: 18),
              onPressed: () => _showEditDialog(context, state, item),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.danger, size: 18),
              onPressed: () => _confirmDelete(context, state, item),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context, AppState state, MenuItem item) {
    final ctrl =
        TextEditingController(text: item.stock?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: AppTheme.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Stock: ${item.name}',
                  style:
                      const TextStyle(color: AppTheme.gold, fontSize: 15)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cantidad disponible (vacío = sin límite):',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style:
                  const TextStyle(color: AppTheme.textLight, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Ej: 10  (vacío = ∞)',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kitchenBlue),
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              state.setItemStock(item.id, v);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppState state, MenuItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppTheme.gold),
            SizedBox(width: 8),
            Text('Editar plato', style: TextStyle(color: AppTheme.gold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.label)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(
                  labelText: 'Precio (S/)',
                  prefixIcon: Icon(Icons.attach_money)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? item.price;
              state.updateMenuItem(item.id, nameCtrl.text.trim(), price);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Eliminar plato?',
            style: TextStyle(color: AppTheme.danger)),
        content: Text(
          '¿Seguro querés eliminar "${item.name}"?',
          style: const TextStyle(color: AppTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              state.removeMenuItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock > 5
        ? AppTheme.success
        : stock > 0
            ? AppTheme.primaryOrange
            : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        '$stock und.',
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── FAB Agregar ítem ─────────────────────────────────────────────────────────

class _AddItemFab extends StatelessWidget {
  const _AddItemFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Nuevo plato',
          style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    MenuSection selectedSection = MenuSection.marineFood;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.gold),
              SizedBox(width: 8),
              Text('Agregar a la carta',
                  style: TextStyle(color: AppTheme.gold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                      labelText: 'Nombre del plato',
                      prefixIcon: Icon(Icons.label)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                      labelText: 'Precio (S/)',
                      prefixIcon: Icon(Icons.attach_money)),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sección:',
                      style:
                          TextStyle(color: AppTheme.gold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: MenuSection.values.map((s) {
                    final sel = selectedSection == s;
                    return GestureDetector(
                      onTap: () => setSt(() => selectedSection = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primaryOrange
                              : AppTheme.cardMedium,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppTheme.primaryOrange
                                : AppTheme.gold.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          s.label,
                          style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textLight,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                context.read<AppState>().addMenuItem(
                    nameCtrl.text.trim(), selectedSection, price);
                Navigator.pop(ctx2);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: ESTADO DE TODOS LOS PEDIDOS
// ═══════════════════════════════════════════════════════════════════════════════

class _AllOrdersScreen extends StatelessWidget {
  const _AllOrdersScreen();

  static const _statusColors = <OrderStatus, Color>{
    OrderStatus.pending:    AppTheme.primaryOrange,
    OrderStatus.inProgress: AppTheme.kitchenBlue,
    OrderStatus.ready:      AppTheme.success,
    OrderStatus.delivered:  Colors.grey,
  };

  static const _statusLabels = <OrderStatus, String>{
    OrderStatus.pending:    'En espera',
    OrderStatus.inProgress: 'Preparando',
    OrderStatus.ready:      'Listo',
    OrderStatus.delivered:  'Entregado',
  };

  static const _statusIcons = <OrderStatus, IconData>{
    OrderStatus.pending:    Icons.hourglass_top,
    OrderStatus.inProgress: Icons.soup_kitchen,
    OrderStatus.ready:      Icons.check_circle,
    OrderStatus.delivered:  Icons.done_all,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final orders = List<Order>.from(state.orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final revenue = state.todayRevenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de boletas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: AppTheme.gold.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No hay pedidos todavía',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final order = orders[i];
                final color =
                    _statusColors[order.status] ?? Colors.grey;
                final label = _statusLabels[order.status] ?? '';
                final icon = _statusIcons[order.status] ?? Icons.circle;
                final tableLabel = order.isTakeaway
                    ? 'Para llevar'
                    : order.isDirectSale
                        ? 'Venta directa'
                        : 'Mesa ${order.tableNumber}';
                final h = order.createdAt.hour.toString().padLeft(2, '0');
                final m = order.createdAt.minute.toString().padLeft(2, '0');

                // Payment badge
                Color? payColor;
                String? payLabel;
                if (order.paymentStatus == PaymentStatus.paid) {
                  payColor = AppTheme.success;
                  payLabel = 'Pagado';
                } else if (order.paymentStatus == PaymentStatus.notPaid) {
                  payColor = AppTheme.danger;
                  payLabel = 'No cancelado';
                }

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptScreen(
                        orderId: order.id,
                        backRoute: '/admin',
                        backLabel: 'Volver al admin',
                      ),
                    ),
                  ),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardMedium,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$tableLabel  ·  #${order.orderNumber}',
                              style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'S/ ${(order.customTotal ?? order.calculatedTotal).toStringAsFixed(0)}  ·  $h:$m',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                            Text(
                              '${order.waiterName}',
                              style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.6),
                                  fontSize: 11),
                            ),
                            if (order.paidAmount != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Recibió S/ ${order.paidAmount!.toStringAsFixed(0)}  ·  Vuelto S/ ${order.changeAmount!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (order.invoicePhone != null &&
                                order.invoicePhone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone,
                                      color: AppTheme.kitchenBlue, size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    order.invoicePhone!,
                                    style: const TextStyle(
                                        color: AppTheme.kitchenBlue,
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                            if (order.invoiceName != null &&
                                order.invoiceName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${order.invoiceType == 'factura' ? 'Fact.' : 'Bol.'}  ${order.invoiceName}${order.invoiceRuc != null ? '  ·  ${order.invoiceRuc}' : ''}',
                                style: TextStyle(
                                    color: AppTheme.gold.withOpacity(0.8),
                                    fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                          if (payLabel != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: payColor!.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: payColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                payLabel,
                                style: TextStyle(
                                    color: payColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.cardDark,
                                      title: const Text('¿Devolver al mozo?',
                                          style: TextStyle(color: AppTheme.textLight)),
                                      content: Text(
                                        'El pedido volverá a estado pendiente y el mozo podrá editarlo.',
                                        style: TextStyle(color: AppTheme.textLight.withOpacity(0.7)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar',
                                              style: TextStyle(color: AppTheme.textLight)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kitchenBlue),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Devolver'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    context.read<AppState>().returnOrderToWaiter(order.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.kitchenBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.kitchenBlue.withOpacity(0.5)),
                                  ),
                                  child: const Icon(Icons.undo, color: AppTheme.kitchenBlue, size: 15),
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.cardDark,
                                      title: const Text('¿Borrar pedido?',
                                          style: TextStyle(color: AppTheme.textLight)),
                                      content: Text(
                                        'Esta acción eliminará el pedido permanentemente.',
                                        style: TextStyle(color: AppTheme.textLight.withOpacity(0.7)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar',
                                              style: TextStyle(color: AppTheme.textLight)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Borrar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    context.read<AppState>().deleteOrder(order.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
                                  ),
                                  child: const Icon(Icons.delete_forever, color: AppTheme.danger, size: 15),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          border: Border(
            top: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.success, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Ganancia del dia:',
                style: TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const Spacer(),
              Text(
                'S/ ${revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: PEDIDO PARA LLEVAR
// ═══════════════════════════════════════════════════════════════════════════════

class _TakeawayScreen extends StatefulWidget {
  const _TakeawayScreen();

  @override
  State<_TakeawayScreen> createState() => _TakeawayScreenState();
}

class _TakeawayScreenState extends State<_TakeawayScreen> {
  final Map<String, int> _cart = {};
  final Map<String, String> _itemNotes = {};
  String _selectedFilter = 'Todos';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();

  static final _filterGroups = <String, List<MenuSection>?>{
    'Todos': null,
    'Marinos': [MenuSection.marineFood],
    'Criollos': [MenuSection.creoleFood],
    'Bebidas': [MenuSection.soda, MenuSection.water],
    'Tragos': [MenuSection.chicha],
  };

  static const _filterIcons = <String, IconData>{
    'Todos': Icons.grid_view_rounded,
    'Marinos': Icons.set_meal,
    'Criollos': Icons.restaurant,
    'Bebidas': Icons.local_drink,
    'Tragos': Icons.emoji_food_beverage,
  };

  int _cartTotal(AppState state) {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null) total += (item.price * entry.value).toInt();
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _submitTakeaway(BuildContext context, AppState state) {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un plato.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final List<OrderItem> items = [];
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null && entry.value > 0) {
        items.add(OrderItem(
          menuItemId: item.id,
          menuItemName: item.name,
          quantity: entry.value,
          price: item.price,
          notes: _itemNotes[entry.key],
        ));
      }
    }
    final order = state.submitTakeawayOrder(
      items: items,
      adminName: state.currentUserName,
    );
    setState(() => _cart.clear());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          orderId: order.id,
          backRoute: '/admin',
          backLabel: 'Volver al admin',
        ),
      ),
    );
  }

  void _handleNoteTap(String itemId) async {
    final state = context.read<AppState>();
    final menuItem = state.getMenuItemById(itemId);
    if (menuItem == null) return;
    final result = await showItemNoteDialog(
        context, menuItem.name, _itemNotes[itemId]);
    if (result == null) return;
    setState(() {
      if (result.isEmpty) {
        _itemNotes.remove(itemId);
      } else {
        _itemNotes[itemId] = result;
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido para llevar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.primaryOrange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining,
                    color: AppTheme.primaryOrange, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Para llevar — va a cocina',
                  style: TextStyle(
                      color: AppTheme.primaryOrange.withOpacity(0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterGroups.keys.map((f) {
                        final sel = _selectedFilter == f;
                        final icon = _filterIcons[f] ?? Icons.category;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedFilter = f;
                            _searchQuery = '';
                            _searchCtrl.clear();
                            _showSearch = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primaryOrange
                                  : AppTheme.cardMedium,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primaryOrange
                                    : AppTheme.gold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 13,
                                    color:
                                        sel ? Colors.white : AppTheme.gold),
                                const SizedBox(width: 5),
                                Text(
                                  f,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textLight,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showSearch ? Icons.search_off : Icons.search,
                    color:
                        _showSearch ? AppTheme.primaryOrange : AppTheme.gold,
                  ),
                  onPressed: () => setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchQuery = '';
                      _searchCtrl.clear();
                    }
                  }),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (q) => setState(() => _searchQuery = q),
                style:
                    const TextStyle(color: AppTheme.textLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ),
          Expanded(
            child: SectionedMenuList(
              cart: _cart,
              filterSections: _filterGroups[_selectedFilter],
              searchQuery: _searchQuery,
              itemNotes: _itemNotes,
              onNoteTap: _handleNoteTap,
              onAdd: (id) =>
                  setState(() => _cart[id] = (_cart[id] ?? 0) + 1),
              onRemove: (id) => setState(() {
                if ((_cart[id] ?? 0) > 0) _cart[id] = _cart[id]! - 1;
                if (_cart[id] == 0) _cart.remove(id);
              }),
            ),
          ),
          CartBar(
            count: _cartCount,
            total: _cartTotal(state),
            onSubmit: () => _submitTakeaway(context, state),
            submitLabel: 'Enviar a cocina',
            submitIcon: Icons.delivery_dining,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: INVENTARIO
// ═══════════════════════════════════════════════════════════════════════════════

class _InventoryScreen extends StatelessWidget {
  const _InventoryScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.inventory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppTheme.gold.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('Sin items en inventario',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.5))),
                  const SizedBox(height: 6),
                  Text('Toca + para agregar',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.35),
                          fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final hasStock = item.quantity > 0;
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: AppTheme.danger),
                  ),
                  onDismissed: (_) =>
                      context.read<AppState>().removeInventoryItem(item.id),
                  child: GestureDetector(
                    onTap: () => _showEditDialog(context, item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardMedium,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasStock
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (hasStock
                                      ? AppTheme.success
                                      : AppTheme.danger)
                                  .withOpacity(0.15),
                            ),
                            child: Icon(
                              hasStock
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: hasStock
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                if (item.notes.isNotEmpty)
                                  Text(
                                    item.notes,
                                    style: TextStyle(
                                        color:
                                            AppTheme.textLight.withOpacity(0.5),
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (hasStock
                                      ? AppTheme.success
                                      : AppTheme.danger)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: hasStock
                                      ? AppTheme.success
                                      : AppTheme.danger),
                            ),
                            child: Text(
                              hasStock ? '${item.quantity} und.' : 'Falta',
                              style: TextStyle(
                                color: hasStock
                                    ? AppTheme.success
                                    : AppTheme.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.gold),
            SizedBox(width: 8),
            Text('Agregar al inventario',
                style: TextStyle(color: AppTheme.gold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Nombre', prefixIcon: Icon(Icons.label)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(Icons.numbers)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.note)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              context.read<AppState>().addInventoryItem(
                nameCtrl.text.trim(),
                int.tryParse(qtyCtrl.text) ?? 0,
                notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final notesCtrl = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppTheme.gold),
            SizedBox(width: 8),
            Text('Editar item',
                style: TextStyle(color: AppTheme.gold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Nombre', prefixIcon: Icon(Icons.label)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(Icons.numbers)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.note)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().updateInventoryItem(
                item.id,
                name: nameCtrl.text.trim(),
                quantity: int.tryParse(qtyCtrl.text) ?? 0,
                notes: notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: CONFIG YAPE (QR + NÚMERO)
// ═══════════════════════════════════════════════════════════════════════════════

class _YapeConfigScreen extends StatefulWidget {
  const _YapeConfigScreen();

  @override
  State<_YapeConfigScreen> createState() => _YapeConfigScreenState();
}

class _YapeConfigScreenState extends State<_YapeConfigScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _phoneCtrl.text = state.yapePhone;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage(AppState state) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      state.setYapeConfig(qrImagePath: picked.path);
    }
  }

  Future<void> _takeQrPhoto(AppState state) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      state.setYapeConfig(qrImagePath: picked.path);
    }
  }

  Future<void> _pickQrFile(AppState state) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      state.setYapeConfig(qrImagePath: result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const yapeColor = Color(0xFF7B2DDB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Yape'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: yapeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: yapeColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_android, color: yapeColor, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yape - Datos de pago',
                            style: TextStyle(
                                color: yapeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        SizedBox(height: 2),
                        Text(
                            'Configura el QR y el número para que los mozos muestren al cliente.',
                            style: TextStyle(
                                color: yapeColor, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Número de Yape
            const Text('NÚMERO DE YAPE',
                style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              style: const TextStyle(
                  color: AppTheme.textLight, fontSize: 20),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.phone, color: yapeColor),
                hintText: '999 999 999',
                counterText: '',
                filled: true,
                fillColor: AppTheme.cardMedium,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: yapeColor)),
              ),
              onChanged: (v) =>
                  state.setYapeConfig(phone: v.trim()),
            ),
            const SizedBox(height: 24),

            // QR
            const Text('IMAGEN DEL QR',
                style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),

            if (state.yapeQrImagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(state.yapeQrImagePath!),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppTheme.cardMedium,
                    child: const Center(
                      child: Text('Error al cargar imagen',
                          style: TextStyle(color: AppTheme.danger)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickQrImage(state),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yapeColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _takeQrPhoto(state),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yapeColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _pickQrFile(state),
                icon: Icon(Icons.upload_file,
                    size: 15, color: yapeColor.withOpacity(0.7)),
                label: Text('Subir archivo',
                    style: TextStyle(
                        color: yapeColor.withOpacity(0.7),
                        fontSize: 11)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            if (state.yapeQrImagePath == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.cardMedium,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: yapeColor.withOpacity(0.2),
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 48,
                          color: yapeColor.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text('Sin QR configurado',
                          style: TextStyle(
                              color:
                                  AppTheme.textLight.withOpacity(0.4))),
                      const SizedBox(height: 4),
                      Text('Sube una foto del QR de Yape',
                          style: TextStyle(
                              color:
                                  AppTheme.textLight.withOpacity(0.3),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Resumen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumen',
                      style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: yapeColor),
                      const SizedBox(width: 8),
                      Text(
                        state.yapePhone.isNotEmpty
                            ? state.yapePhone
                            : 'No configurado',
                        style: TextStyle(
                            color: state.yapePhone.isNotEmpty
                                ? AppTheme.textLight
                                : AppTheme.textLight.withOpacity(0.4),
                            fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2,
                          size: 16, color: yapeColor),
                      const SizedBox(width: 8),
                      Text(
                        state.yapeQrImagePath != null
                            ? 'QR cargado ✓'
                            : 'Sin QR',
                        style: TextStyle(
                            color: state.yapeQrImagePath != null
                                ? AppTheme.success
                                : AppTheme.textLight.withOpacity(0.4),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   GESTIÓN DE CUENTAS
// ═══════════════════════════════════════════════════════════════════════════════

class _AccountsScreen extends StatefulWidget {
  const _AccountsScreen();

  @override
  State<_AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<_AccountsScreen> {
  // ─── Cambiar contraseña admin ───────────────────────────────────────────────

  Future<void> _changeAdminPwd() async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cfmCtrl = TextEditingController();
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Cambiar Contraseña Admin',
              style: TextStyle(color: AppTheme.gold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: curCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: Icon(Icons.lock, color: AppTheme.gold),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: Icon(Icons.lock_open, color: AppTheme.gold),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cfmCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: AppTheme.gold),
                ),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!,
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final state = context.read<AppState>();
                if (curCtrl.text != state.adminPassword) {
                  setSt(() => err = 'Contraseña actual incorrecta.');
                  return;
                }
                if (newCtrl.text.trim().length < 6) {
                  setSt(() => err = 'Mínimo 6 caracteres.');
                  return;
                }
                if (newCtrl.text != cfmCtrl.text) {
                  setSt(() => err = 'Las contraseñas no coinciden.');
                  return;
                }
                await state.setAdminPassword(newCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Contraseña cambiada'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    curCtrl.dispose();
    newCtrl.dispose();
    cfmCtrl.dispose();
  }

  // ─── Establecer contraseña semanal ─────────────────────────────────────────

  Future<void> _setWeeklyPwd() async {
    final ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Contraseña Semanal',
            style: TextStyle(
                color: AppTheme.primaryOrange, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Todos los mozos y cocina usarán esta contraseña para ingresar durante esta semana.',
              style:
                  TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña semanal',
                prefixIcon:
                    Icon(Icons.key, color: AppTheme.primaryOrange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              await context.read<AppState>().setWeeklyPassword(val);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Contraseña semanal actualizada'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Establecer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  // ─── Añadir trabajador ─────────────────────────────────────────────────────

  Future<void> _addWorker() async {
    final nameCtrl = TextEditingController();
    UserRole selectedRole = UserRole.waiter;
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Añadir Trabajador',
              style: TextStyle(
                  color: AppTheme.kitchenBlue, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_add,
                      color: AppTheme.kitchenBlue),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Rol: ',
                      style: TextStyle(
                          color: AppTheme.textLight, fontSize: 13)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Mozo'),
                    selected: selectedRole == UserRole.waiter,
                    onSelected: (_) =>
                        setSt(() => selectedRole = UserRole.waiter),
                    selectedColor:
                        AppTheme.primaryOrange.withOpacity(0.3),
                    labelStyle: TextStyle(
                        color: selectedRole == UserRole.waiter
                            ? AppTheme.primaryOrange
                            : AppTheme.textLight),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Cocina'),
                    selected: selectedRole == UserRole.kitchen,
                    onSelected: (_) =>
                        setSt(() => selectedRole = UserRole.kitchen),
                    selectedColor:
                        AppTheme.kitchenBlue.withOpacity(0.3),
                    labelStyle: TextStyle(
                        color: selectedRole == UserRole.kitchen
                            ? AppTheme.kitchenBlue
                            : AppTheme.textLight),
                  ),
                ],
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!,
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setSt(() => err = 'Escribe el nombre.');
                  return;
                }
                await context.read<AppState>().addWorker(name, selectedRole);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥  Gestión de Cuentas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorker,
        icon: const Icon(Icons.person_add),
        label: const Text('Añadir trabajador'),
        backgroundColor: AppTheme.kitchenBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Contraseña admin ──────────────────────────────────────────
          _AccountCard(
            icon: Icons.admin_panel_settings,
            iconColor: AppTheme.gold,
            title: 'Cuenta Administrador',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: AppTheme.gold, size: 14),
                    SizedBox(width: 6),
                    Text('Usuario: Amanda',
                        style: TextStyle(
                            color: AppTheme.textLight, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lock, color: AppTheme.gold, size: 14),
                    const SizedBox(width: 6),
                    Text('Contraseña: ${'●' * state.adminPassword.length}',
                        style: TextStyle(
                            color: AppTheme.textLight.withOpacity(0.7),
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _changeAdminPwd,
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Cambiar contraseña'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.gold),
                    foregroundColor: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Contraseña semanal ────────────────────────────────────────
          _AccountCard(
            icon: Icons.calendar_month,
            iconColor: AppTheme.primaryOrange,
            title: 'Contraseña Semanal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.weeklyPassword != null
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      color: state.weeklyPassword != null
                          ? AppTheme.success
                          : AppTheme.danger,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.weeklyPassword != null
                            ? 'Configurada · Los trabajadores pueden ingresar'
                            : 'No configurada · Nadie puede ingresar aún',
                        style: TextStyle(
                          color: state.weeklyPassword != null
                              ? AppTheme.success
                              : AppTheme.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.weeklyPassword != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key,
                            color: AppTheme.primaryOrange, size: 14),
                        const SizedBox(width: 8),
                        Text(state.weeklyPassword!,
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1,
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _setWeeklyPwd,
                  icon: const Icon(Icons.key, size: 15),
                  label: Text(state.weeklyPassword != null
                      ? 'Cambiar contraseña semanal'
                      : 'Establecer contraseña semanal'),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppTheme.primaryOrange),
                    foregroundColor: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Trabajadores ──────────────────────────────────────────────
          _AccountCard(
            icon: Icons.people,
            iconColor: AppTheme.kitchenBlue,
            title: 'Trabajadores (${state.registeredWorkers.length})',
            child: Column(
              children: state.registeredWorkers
                  .map((w) => _WorkerTile(worker: w))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de sección ───────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _AccountCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Ficha de trabajador ──────────────────────────────────────────────────────

class _WorkerTile extends StatelessWidget {
  final RegisteredWorker worker;

  const _WorkerTile({required this.worker});

  String _formatLastLogin(DateTime? dt) {
    if (dt == null) return 'Nunca ingresó';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final sessionActive = state.checkWorkerSession(worker.name);
    final roleColor = worker.role == UserRole.waiter
        ? AppTheme.primaryOrange
        : AppTheme.kitchenBlue;
    final roleLabel =
        worker.role == UserRole.waiter ? 'Mozo' : 'Cocina';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: worker.isExpelled
            ? AppTheme.danger.withOpacity(0.08)
            : AppTheme.cardMedium.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: worker.isExpelled
              ? AppTheme.danger.withOpacity(0.3)
              : sessionActive
                  ? AppTheme.success.withOpacity(0.4)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withOpacity(0.15),
            ),
            child: Icon(
              worker.role == UserRole.waiter
                  ? Icons.restaurant
                  : Icons.soup_kitchen,
              color: roleColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(worker.name,
                        style: TextStyle(
                          color: worker.isExpelled
                              ? AppTheme.textLight.withOpacity(0.4)
                              : AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                    const SizedBox(width: 6),
                    _MiniTag(
                        label: roleLabel, color: roleColor),
                    if (sessionActive && !worker.isExpelled) ...[
                      const SizedBox(width: 4),
                      _MiniTag(
                          label: '● activo',
                          color: AppTheme.success),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  worker.isExpelled
                      ? 'ACCESO REVOCADO'
                      : _formatLastLogin(worker.lastLogin),
                  style: TextStyle(
                    color: worker.isExpelled
                        ? AppTheme.danger
                        : AppTheme.textLight.withOpacity(0.5),
                    fontSize: 11,
                    fontStyle: worker.isExpelled
                        ? FontStyle.normal
                        : FontStyle.italic,
                    fontWeight: worker.isExpelled
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Botón expulsar / restaurar
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  worker.isExpelled ? AppTheme.success : AppTheme.danger,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            onPressed: () async {
              if (worker.isExpelled) {
                await context.read<AppState>().restoreWorker(worker.name);
              } else {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    title: Text('Expulsar ${worker.name}',
                        style: const TextStyle(
                            color: AppTheme.textLight, fontSize: 16)),
                    content: Text(
                      '¿Revocar el acceso de ${worker.name}? Podrás restaurarlo en cualquier momento.',
                      style: const TextStyle(color: AppTheme.textLight),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar',
                            style:
                                TextStyle(color: AppTheme.textLight)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Expulsar'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AppState>().expelWorker(worker.name);
                }
              }
            },
            child: Text(
              worker.isExpelled ? 'Restaurar' : 'Expulsar',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}
