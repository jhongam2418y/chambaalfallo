import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

// ─── Diálogo reutilizable para notas de plato ─────────────────────────────────

Future<String?> showItemNoteDialog(
    BuildContext context, String itemName, String? currentNote) async {
  final ctrl = TextEditingController(text: currentNote ?? '');
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardDark,
      title: Text('Nota: $itemName',
          style: const TextStyle(color: AppTheme.textLight, fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: AppTheme.textLight),
        decoration: const InputDecoration(
          hintText: 'Ej: sin papa, solo pollo...',
        ),
      ),
      actions: [
        if (currentNote != null && currentNote.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child:
                const Text('Quitar', style: TextStyle(color: AppTheme.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar',
              style: TextStyle(color: AppTheme.textLight)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

class WaiterScreen extends StatelessWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myOrders = state.getWaiterOrders(state.currentUserName);

    return Scaffold(
      appBar: AppBar(
        title: Text('🍽️  ${state.currentUserName}'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () {
            state.logout();
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _AnimatedBadge(count: myOrders
                  .where((o) => o.status != OrderStatus.delivered)
                  .length),
            ),
          ),
        ],
      ),
      body: myOrders.isEmpty
          ? _EmptyWaiter(name: state.currentUserName)
          : _OrdersList(orders: myOrders),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'waiter_delivery',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const _WaiterDeliveryScreen()),
            ),
            backgroundColor: AppTheme.kitchenBlue,
            foregroundColor: Colors.white,
            mini: true,
            tooltip: 'Delivery',
            child: const Icon(Icons.delivery_dining),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'waiter_direct_pay',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WaiterDirectSaleScreen()),
            ),
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.darkBrown,
            mini: true,
            tooltip: 'Cobro directo',
            child: const Icon(Icons.point_of_sale),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'waiter_new_order',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TakeOrderScreen()),
            ),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nuevo Pedido',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyWaiter extends StatelessWidget {
  final String name;
  const _EmptyWaiter({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long,
              color: AppTheme.gold, size: 80),
          const SizedBox(height: 16),
          Text('¡Hola, $name!',
              style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Todavía no tomaste pedidos hoy.',
              style: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.6),
                  fontSize: 15)),
          const SizedBox(height: 8),
          Text('Usá el botón para comenzar 👇',
              style: TextStyle(
                  color: AppTheme.primaryOrange.withOpacity(0.8),
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Lista de pedidos del mozo ────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final order = orders[i];
        return _OrderTile(order: order, key: ValueKey(order.id));
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order, super.key});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return AppTheme.primaryOrange;
      case OrderStatus.inProgress:
        return AppTheme.kitchenBlue;
      case OrderStatus.ready:
        return AppTheme.success;
      case OrderStatus.delivered:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:
        return 'EN COCINA';
      case OrderStatus.inProgress:
        return 'PREPARANDO';
      case OrderStatus.ready:
        return '¡LISTO!';
      case OrderStatus.delivered:
        return 'ENTREGADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(orderId: order.id),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Número de pedido + mesa
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor.withOpacity(0.15),
                    border: Border.all(color: _statusColor, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(
                    order.isDelivery
                        ? 'D.'
                        : order.isTakeaway
                            ? 'LL.'
                            : 'M.${order.tableNumber}',
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    '#${order.orderNumber}',
                    style: TextStyle(
                        color: _statusColor.withOpacity(0.7), fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.isDelivery
                        ? 'Delivery  —  Pedido #${order.orderNumber}'
                        : order.isTakeaway
                            ? 'Para Llevar  —  Pedido #${order.orderNumber}'
                            : 'Mesa ${order.tableNumber}  —  Pedido #${order.orderNumber}',
                    style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.items.length} ítem${order.items.length != 1 ? 's' : ''}  •  S/ ${order.calculatedTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.65),
                        fontSize: 13),
                  ),
                  if (order.isDelivery && order.deliveryPhone != null && order.deliveryPhone!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: AppTheme.kitchenBlue.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryPhone!,
                          style: TextStyle(
                              color: AppTheme.kitchenBlue.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(
                        color: AppTheme.gold.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
            // Estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                const SizedBox(height: 6),
                if (order.status == OrderStatus.ready)
                  GestureDetector(
                    onTap: () {
                      context.read<AppState>().markOrderDelivered(order.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.success),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: AppTheme.success, size: 12),
                          SizedBox(width: 3),
                          Text('Entregar',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  const Icon(Icons.receipt_long,
                      color: AppTheme.gold, size: 18),
              ],
            ),
              ],
            ),
            // ── Botones mesa completada ──
            if (order.isTableCompleted) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.done_all, color: AppTheme.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Mesa completada',
                      style: TextStyle(
                          color: AppTheme.gold.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    if (order.invoiceType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.kitchenBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.kitchenBlue.withOpacity(0.5)),
                        ),
                        child: Text(
                          order.invoiceType == 'factura'
                              ? '📄 Factura'
                              : '🧾 B. Electrónica',
                          style: const TextStyle(
                              color: AppTheme.kitchenBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (order.invoiceConcept != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.invoiceConcept == 'consumo'
                                ? 'Consumo'
                                : 'Específico',
                            style: TextStyle(
                                color: AppTheme.gold.withOpacity(0.8),
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    if (order.invoiceType == null)
                      GestureDetector(
                        onTap: () => _showInvoiceDialog(context, order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.kitchenBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.kitchenBlue),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt, color: AppTheme.kitchenBlue,
                                  size: 12),
                              SizedBox(width: 3),
                              Text('Boleta/Factura',
                                  style: TextStyle(
                                      color: AppTheme.kitchenBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          context.read<AppState>().archiveOrder(order.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.archive, color: Colors.grey, size: 12),
                            SizedBox(width: 3),
                            Text('A historial',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Order order) {
    String selectedType = 'boleta_electronica';
    String selectedConcept = 'consumo';
    final rucCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.gold),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Comprobante electrónico',
                      style: TextStyle(color: AppTheme.gold, fontSize: 15)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector tipo
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(
                              () => selectedType = 'boleta_electronica'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'boleta_electronica'
                                  ? AppTheme.kitchenBlue.withOpacity(0.2)
                                  : AppTheme.cardMedium,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedType == 'boleta_electronica'
                                    ? AppTheme.kitchenBlue
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.receipt,
                                    color: selectedType == 'boleta_electronica'
                                        ? AppTheme.kitchenBlue
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text('Boleta',
                                    style: TextStyle(
                                        color:
                                            selectedType == 'boleta_electronica'
                                                ? AppTheme.kitchenBlue
                                                : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedType = 'factura'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'factura'
                                  ? AppTheme.primaryOrange.withOpacity(0.2)
                                  : AppTheme.cardMedium,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedType == 'factura'
                                    ? AppTheme.primaryOrange
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.description,
                                    color: selectedType == 'factura'
                                        ? AppTheme.primaryOrange
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text('Factura',
                                    style: TextStyle(
                                        color: selectedType == 'factura'
                                            ? AppTheme.primaryOrange
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Selector concepto
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Concepto',
                        style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(
                              () => selectedConcept = 'consumo'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedConcept == 'consumo'
                                  ? AppTheme.success.withOpacity(0.2)
                                  : AppTheme.cardMedium,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedConcept == 'consumo'
                                    ? AppTheme.success
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_menu,
                                    color: selectedConcept == 'consumo'
                                        ? AppTheme.success
                                        : Colors.grey,
                                    size: 16),
                                const SizedBox(width: 5),
                                Text('Por consumo',
                                    style: TextStyle(
                                        color: selectedConcept == 'consumo'
                                            ? AppTheme.success
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(
                              () => selectedConcept = 'especifico'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedConcept == 'especifico'
                                  ? AppTheme.gold.withOpacity(0.2)
                                  : AppTheme.cardMedium,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedConcept == 'especifico'
                                    ? AppTheme.gold
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt,
                                    color: selectedConcept == 'especifico'
                                        ? AppTheme.gold
                                        : Colors.grey,
                                    size: 16),
                                const SizedBox(width: 5),
                                Text('Por específico',
                                    style: TextStyle(
                                        color: selectedConcept == 'especifico'
                                            ? AppTheme.gold
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: rucCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    style: const TextStyle(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      labelText: selectedType == 'factura' ? 'RUC' : 'DNI',
                      prefixIcon: const Icon(Icons.badge),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      labelText: selectedType == 'factura'
                          ? 'Razón Social'
                          : 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                    ],
                    style: const TextStyle(color: AppTheme.textLight),
                    decoration: const InputDecoration(
                      labelText: 'Celular (opcional)',
                      prefixIcon: Icon(Icons.phone),
                      counterText: '',
                    ),
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
                  if (rucCtrl.text.trim().isEmpty ||
                      nameCtrl.text.trim().isEmpty) return;
                  final phone = phoneCtrl.text.trim();
                  context.read<AppState>().setInvoiceData(
                    order.id,
                    selectedType,
                    rucCtrl.text.trim(),
                    nameCtrl.text.trim(),
                    concept: selectedConcept,
                    phone: phone.isEmpty ? null : phone,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m hs';
  }
}

// ─── Badge animado ────────────────────────────────────────────────────────────

class _AnimatedBadge extends StatefulWidget {
  final int count;
  const _AnimatedBadge({required this.count});

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.count;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedBadge old) {
    super.didUpdateWidget(old);
    if (widget.count != _prevCount) {
      _prevCount = widget.count;
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) return const SizedBox.shrink();
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${widget.count} activo${widget.count != 1 ? 's' : ''}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: TOMAR PEDIDO
// ═══════════════════════════════════════════════════════════════════════════════

class TakeOrderScreen extends StatefulWidget {
  const TakeOrderScreen({super.key});

  @override
  State<TakeOrderScreen> createState() => _TakeOrderScreenState();
}

class _TakeOrderScreenState extends State<TakeOrderScreen> {
  int _tableNumber = 1;
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

  int _cartTotal(AppState state) {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null) total += (item.price * entry.value).toInt();
    }
    for (final e in _manualExtras) {
      total += (e.price * e.qty).toInt();
    }
    return total;
  }

  int get _cartCount =>
      _cart.values.fold(0, (a, b) => a + b) +
      _manualExtras.fold(0, (a, e) => a + e.qty);

  void _submitOrder(BuildContext context, AppState state) {
    if (_cart.isEmpty && _manualExtras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido está vacío. Agregá ítems primero.'),
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
    for (final e in _manualExtras) {
      if (e.qty > 0) {
        items.add(OrderItem(
          menuItemId: 'extra_${DateTime.now().millisecondsSinceEpoch}',
          menuItemName: e.name,
          quantity: e.qty,
          price: e.price,
          isExtra: true,
        ));
      }
    }

    final order = state.submitOrder(
      tableNumber: _tableNumber,
      items: items,
      waiterName: state.currentUserName,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(orderId: order.id)),
    );
  }

  void _handleNoteTap(String itemId) async {
    final state = context.read<AppState>();
    final menuItem = state.getMenuItemById(itemId);
    if (menuItem == null) return;
    final result =
        await showItemNoteDialog(context, menuItem.name, _itemNotes[itemId]);
    if (result == null) return;
    setState(() {
      if (result.isEmpty) {
        _itemNotes.remove(itemId);
      } else {
        _itemNotes[itemId] = result;
      }
    });
  }

  // ─── Extras manuales ─────────────────────────────────────────────────────
  final List<ManualExtra> _manualExtras = [];
  void _addManualExtra(ManualExtra e) => setState(() => _manualExtras.add(e));
  void _removeManualExtra(int i) =>
      setState(() => _manualExtras.removeAt(i));
  void _changeManualQty(int i, int delta) => setState(() {
        _manualExtras[i] = _manualExtras[i]
            .copyWith(qty: (_manualExtras[i].qty + delta).clamp(1, 99));
      });

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isExtraFilter = _selectedFilter == 'Extra';

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Pedido')),
      body: Column(
        children: [
          _TableSelector(
            current: _tableNumber,
            onChanged: (v) => setState(() => _tableNumber = v),
          ),
          _SectionFilterBar(
            selected: _selectedFilter,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onFilterChanged: (f) => setState(() {
              _selectedFilter = f;
              _searchQuery = '';
              _searchCtrl.clear();
              _showSearch = false;
            }),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          Expanded(
            child: isExtraFilter
                ? ManualExtraSection(
                    extras: _manualExtras,
                    onAdd: _addManualExtra,
                    onRemove: _removeManualExtra,
                    onQtyChange: _changeManualQty,
                  )
                : SectionedMenuList(
                    cart: _cart,
                    filterSections: _filterGroups[_selectedFilter],
                    searchQuery: _searchQuery,
                    itemNotes: _itemNotes,
                    onNoteTap: _handleNoteTap,
                    onAdd: (id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1),
                    onRemove: (id) => setState(() {
                      if ((_cart[id] ?? 0) > 0) _cart[id] = _cart[id]! - 1;
                      if (_cart[id] == 0) _cart.remove(id);
                    }),
                  ),
          ),
          CartBar(
            count: _cartCount,
            total: _cartTotal(state),
            onSubmit: () => _submitOrder(context, state),
          ),
        ],
      ),
    );
  }
}

// ─── Selector de mesa ─────────────────────────────────────────────────────────

class _TableSelector extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const _TableSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.cardDark,
      child: Row(
        children: [
          const Icon(Icons.table_restaurant, color: AppTheme.gold),
          const SizedBox(width: 10),
          const Text('Mesa:',
              style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (current > 1) onChanged(current - 1);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.cardMedium,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.remove, color: AppTheme.gold, size: 18),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$current',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(current + 1),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.cardMedium,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.gold, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filtro de secciones (TakeOrderScreen) ────────────────────────────────────

class _SectionFilterBar extends StatelessWidget {
  final String selected;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;

  const _SectionFilterBar({
    required this.selected,
    required this.showSearch,
    required this.searchCtrl,
    required this.onFilterChanged,
    required this.onSearchToggle,
    required this.onSearchChanged,
  });

  static const _filters = ['Todos', 'Marinos', 'Criollos', 'Bebidas', 'Tragos', 'Extra'];

  static const _filterIcons = <String, IconData>{
    'Todos': Icons.grid_view_rounded,
    'Marinos': Icons.set_meal,
    'Criollos': Icons.restaurant,
    'Bebidas': Icons.local_drink,
    'Tragos': Icons.emoji_food_beverage,
    'Extra': Icons.add_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final sel = selected == f;
                        final icon = _filterIcons[f] ?? Icons.category;
                        return GestureDetector(
                          onTap: () => onFilterChanged(f),
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
                                    size: 14,
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
                IconButton(
                  icon: Icon(
                    showSearch ? Icons.search_off : Icons.search,
                    color: showSearch
                        ? AppTheme.primaryOrange
                        : AppTheme.gold,
                  ),
                  onPressed: onSearchToggle,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: TextField(
                controller: searchCtrl,
                autofocus: true,
                onChanged: onSearchChanged,
                style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar plato o bebida...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            searchCtrl.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Constantes de sección ────────────────────────────────────────────────────

const _sectionIcons = <MenuSection, IconData>{
  MenuSection.marineFood: Icons.set_meal,
  MenuSection.creoleFood: Icons.restaurant,
  MenuSection.soda:       Icons.local_drink,
  MenuSection.water:      Icons.water_drop,
  MenuSection.chicha:     Icons.emoji_food_beverage,
};

const _sectionColors = <MenuSection, Color>{
  MenuSection.marineFood: AppTheme.kitchenBlue,
  MenuSection.creoleFood: AppTheme.primaryOrange,
  MenuSection.soda:       AppTheme.success,
  MenuSection.water:      Color(0xFF64B5F6),
  MenuSection.chicha:     AppTheme.gold,
};

// ─── Menú por secciones (público para reusar en Admin) ───────────────────────

class SectionedMenuList extends StatelessWidget {
  final Map<String, int> cart;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final List<MenuSection>? filterSections;
  final String searchQuery;
  final Map<String, String>? itemNotes;
  final ValueChanged<String>? onNoteTap;

  const SectionedMenuList({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    this.filterSections,
    this.searchQuery = '',
    this.itemNotes,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final List<Widget> children = [];
    final sectionsToShow = filterSections ?? MenuSection.values.toList();

    for (final section in sectionsToShow) {
      var items = state.allItemsBySection(section);
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        items =
            items.where((i) => i.name.toLowerCase().contains(q)).toList();
      }
      if (items.isEmpty) continue;
      children.add(SectionHeader(section: section));
      for (final item in items) {
        children.add(MenuListTile(
          item: item,
          quantity: cart[item.id] ?? 0,
          onAdd: () => onAdd(item.id),
          onRemove: () => onRemove(item.id),
          note: itemNotes?[item.id],
          onNoteTap: onNoteTap != null ? () => onNoteTap!(item.id) : null,
        ));
      }
    }

    if (children.isEmpty) {
      return Center(
        child: Text(
          'No hay platos en esta seccion',
          style: TextStyle(color: AppTheme.textLight.withOpacity(0.5)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
      children: children,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final MenuSection section;
  const SectionHeader({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final color = _sectionColors[section] ?? AppTheme.gold;
    final icon = _sectionIcons[section] ?? Icons.category;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            section.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: color.withOpacity(0.25))),
        ],
      ),
    );
  }
}

class MenuListTile extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final String? note;
  final VoidCallback? onNoteTap;

  const MenuListTile({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.note,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasQty = quantity > 0;
    final sectionColor = _sectionColors[item.section] ?? AppTheme.gold;
    final isLowStock = item.stock != null && item.stock! <= 5;
    final soldOut = !item.isAvailable;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: soldOut
            ? AppTheme.cardDark.withOpacity(0.5)
            : hasQty
                ? AppTheme.cardMedium
                : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: soldOut
              ? AppTheme.danger.withOpacity(0.25)
              : hasQty
                  ? AppTheme.primaryOrange.withOpacity(0.7)
                  : AppTheme.gold.withOpacity(0.15),
          width: hasQty ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: soldOut ? 0.5 : 1.0,
        child: Row(
        children: [
          // Ícono sección
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sectionColor.withOpacity(0.12),
            ),
            child: Icon(
              _sectionIcons[item.section] ?? Icons.category,
              color: sectionColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Nombre + precio + stock + nota
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: soldOut ? Colors.grey : AppTheme.textLight,
                    fontWeight: hasQty ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    decoration: soldOut ? TextDecoration.lineThrough : null,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'S/ ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: soldOut ? Colors.grey : AppTheme.gold,
                          fontSize: 12),
                    ),
                    if (soldOut) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: AppTheme.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                    if (!soldOut && item.stock != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isLowStock
                                  ? AppTheme.danger
                                  : AppTheme.success)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.stock} und.',
                          style: TextStyle(
                            color: isLowStock
                                ? AppTheme.danger
                                : AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Botón/texto de nota (solo cuando hay cantidad)
                if (hasQty && onNoteTap != null)
                  GestureDetector(
                    onTap: onNoteTap,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            note != null && note!.isNotEmpty
                                ? Icons.sticky_note_2
                                : Icons.note_add_outlined,
                            size: 12,
                            color: note != null && note!.isNotEmpty
                                ? AppTheme.primaryOrange
                                : AppTheme.textLight.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              note != null && note!.isNotEmpty
                                  ? note!
                                  : 'Agregar nota...',
                              style: TextStyle(
                                color: note != null && note!.isNotEmpty
                                    ? AppTheme.primaryOrange
                                    : AppTheme.textLight.withOpacity(0.4),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Controles
          if (soldOut)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: const Text(
                'Sin stock',
                style: TextStyle(
                    color: AppTheme.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QtyButton(
                  icon: Icons.remove,
                  color: AppTheme.danger,
                  onTap: onRemove,
                  enabled: hasQty,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      color: hasQty
                          ? AppTheme.primaryOrange
                          : AppTheme.textLight.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                QtyButton(
                  icon: Icons.add,
                  color: AppTheme.success,
                  onTap: onAdd,
                  enabled: true,
                ),
              ],
            ),
        ],
      ),
      ),
    );
  }
}

class QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const QtyButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color : color.withOpacity(0.2),
          ),
        ),
        child:
            Icon(icon, color: enabled ? color : color.withOpacity(0.2), size: 16),
      ),
    );
  }
}

// ─── Ítem extra manual ───────────────────────────────────────────────────────

class ManualExtra {
  final String name;
  final double price;
  final int qty;
  const ManualExtra({required this.name, required this.price, this.qty = 1});
  ManualExtra copyWith({String? name, double? price, int? qty}) => ManualExtra(
        name: name ?? this.name,
        price: price ?? this.price,
        qty: qty ?? this.qty,
      );
}

// ─── Sección de ítems extra manuales ─────────────────────────────────────────

class ManualExtraSection extends StatelessWidget {
  final List<ManualExtra> extras;
  final ValueChanged<ManualExtra> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int idx, int delta) onQtyChange;

  const ManualExtraSection({
    super.key,
    required this.extras,
    required this.onAdd,
    required this.onRemove,
    required this.onQtyChange,
  });

  void _openAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.add_circle, color: AppTheme.gold),
          SizedBox(width: 8),
          Text('Ítem Extra', style: TextStyle(color: AppTheme.gold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(
                labelText: 'Descripción del ítem',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(
                labelText: 'Precio (S/)',
                prefixIcon: Icon(Icons.attach_money),
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isEmpty || price == null || price <= 0) return;
              onAdd(ManualExtra(name: name, price: price));
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      priceCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: extras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: AppTheme.gold.withOpacity(0.4), size: 48),
                      const SizedBox(height: 10),
                      Text(
                        'Agrega ítems manuales\npara incluir en el pedido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textLight.withOpacity(0.45),
                            fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: extras.length,
                  itemBuilder: (ctx, i) {
                    final e = extras[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardMedium,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('EXTRA',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name,
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontWeight: FontWeight.w600)),
                                Text('S/ ${e.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: AppTheme.primaryOrange,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.danger, size: 20),
                            onPressed: e.qty <= 1
                                ? () => onRemove(i)
                                : () => onQtyChange(i, -1),
                          ),
                          Text('${e.qty}',
                              style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppTheme.success, size: 20),
                            onPressed: () => onQtyChange(i, 1),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.danger, size: 20),
                            onPressed: () => onRemove(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ítem extra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold.withOpacity(0.85),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Barra del carrito (pública) ──────────────────────────────────────────────

class CartBar extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onSubmit;
  final String submitLabel;
  final IconData submitIcon;

  const CartBar({
    super.key,
    required this.count,
    required this.total,
    required this.onSubmit,
    this.submitLabel = 'Enviar a Cocina',
    this.submitIcon = Icons.send,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: count > 0
                ? AppTheme.primaryOrange.withOpacity(0.6)
                : AppTheme.gold.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count ítem${count != 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: S/ $total',
                style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: Icon(submitIcon),
              label: Text(submitLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    count > 0 ? AppTheme.primaryOrange : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: BOLETA / RECEIPT
// ═══════════════════════════════════════════════════════════════════════════════

class ReceiptScreen extends StatefulWidget {
  final String orderId;
  final String backRoute;
  final String backLabel;

  const ReceiptScreen({
    super.key,
    required this.orderId,
    this.backRoute = '/waiter',
    this.backLabel = 'Ver mis pedidos',
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _totalCtrl = TextEditingController();
  final TextEditingController _billCtrl = TextEditingController();
  double? _billAmount;
  String _payMethod = 'efectivo'; // 'efectivo' | 'yape'
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _totalCtrl.dispose();
    _billCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$mo/$y';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m hs';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.getOrderById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boleta')),
        body: const Center(child: Text('Pedido no encontrado')),
      );
    }

    _totalCtrl.text =
        (order.customTotal ?? order.calculatedTotal).toStringAsFixed(0);

    final tableLabel = order.isDelivery
        ? 'Delivery'
        : order.isTakeaway
            ? 'Para Llevar'
            : order.isDirectSale
                ? 'Venta Directa'
                : 'Mesa ${order.tableNumber}';
    final double? billChange = _billAmount != null
        ? _billAmount! - (order.customTotal ?? order.calculatedTotal)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.darkBrown,
      appBar: AppBar(
        title: Text('Boleta — $tableLabel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          child: Column(
            children: [
              // ── Boleta compacta ───────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.gold.withOpacity(0.35), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cabin,
                                  color: AppTheme.gold, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'La Cabaña del Sabor',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              const Spacer(),
                              Text(
                                'RESTOBAR',
                                style: TextStyle(
                                    color: AppTheme.primaryOrange
                                        .withOpacity(0.85),
                                    fontSize: 10,
                                    letterSpacing: 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '$tableLabel  ·  Pedido #${order.orderNumber}',
                                style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmtDate(order.createdAt),
                                    style: const TextStyle(
                                        color: AppTheme.gold, fontSize: 12),
                                  ),
                                  Text(
                                    _fmtTime(order.createdAt),
                                    style: const TextStyle(
                                        color: AppTheme.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            'Atendido por: ${order.waiterName}',
                            style: TextStyle(
                                color: AppTheme.textLight.withOpacity(0.45),
                                fontSize: 11),
                          ),
                          if (order.isDelivery && order.deliveryPhone != null && order.deliveryPhone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.delivery_dining,
                                      color: AppTheme.kitchenBlue.withOpacity(0.8), size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Tel: ${order.deliveryPhone}',
                                    style: TextStyle(
                                        color: AppTheme.kitchenBlue.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(
                        color: AppTheme.gold, height: 1, indent: 14, endIndent: 14),

                    // Ítems
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Row(
                        children: [
                          const Text('ÍTEM',
                              style: TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 10,
                                  letterSpacing: 1.2)),
                          const Spacer(),
                          Text('SUBTOTAL',
                              style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.7),
                                  fontSize: 10,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}×',
                                style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.menuItemName,
                                        style: const TextStyle(
                                            color: AppTheme.textLight,
                                            fontSize: 13)),
                                    if (item.isExtra)
                                      Text(
                                        'extra',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    if (item.notes != null && item.notes!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.sticky_note_2,
                                              size: 10,
                                              color: AppTheme.primaryOrange),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              item.notes!,
                                              style: const TextStyle(
                                                color: AppTheme.primaryOrange,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'S/ ${item.subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )),

                    // Agregar plato rápido
                    if (order.status != OrderStatus.delivered && !order.isTableCompleted)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditOrderScreen(orderId: order.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: AppTheme.gold.withOpacity(0.55), size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'Agregar plato',
                                style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.55),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Divider(
                        color: AppTheme.gold,
                        height: 1,
                        indent: 14,
                        endIndent: 14),

                    // Total editable
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'TOTAL A COBRAR',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.5),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 130,
                                child: TextField(
                                  controller: _totalCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  maxLength: 4,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    prefixText: 'S/ ',
                                    prefixStyle: TextStyle(
                                        color: AppTheme.gold,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    isDense: true,
                                    counterText: '',
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 4),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppTheme.gold),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) {
                                      context
                                          .read<AppState>()
                                          .setOrderCustomTotal(order.id, val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Editá el total para aplicar descuentos o propinas',
                            style: TextStyle(
                                color: AppTheme.textLight.withOpacity(0.35),
                                fontSize: 10),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                              color: AppTheme.gold.withOpacity(0.3),
                              height: 1),
                          const SizedBox(height: 12),
                          // ── Selector modo de pago ──
                          Row(
                            children: [
                              const Text(
                                'MODO DE PAGO',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.2),
                              ),
                              const Spacer(),
                              _PayMethodChip(
                                label: 'Efectivo',
                                icon: Icons.payments_outlined,
                                selected: _payMethod == 'efectivo',
                                color: AppTheme.success,
                                onTap: () => setState(() {
                                  _payMethod = 'efectivo';
                                }),
                              ),
                              const SizedBox(width: 8),
                              _PayMethodChip(
                                label: 'Yape',
                                icon: Icons.phone_android,
                                selected: _payMethod == 'yape',
                                color: const Color(0xFF7B2DDB),
                                onTap: () => setState(() {
                                  _payMethod = 'yape';
                                  _billAmount = null;
                                  _billCtrl.clear();
                                }),
                              ),
                            ],
                          ),
                          if (_payMethod == 'efectivo') ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'PAGO CON',
                                  style: TextStyle(
                                      color: AppTheme.kitchenBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.5),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 130,
                                  child: TextField(
                                    controller: _billCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      prefixText: 'S/ ',
                                      prefixStyle: TextStyle(
                                          color: AppTheme.kitchenBlue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 4),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppTheme.kitchenBlue),
                                      ),
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                          color: AppTheme.kitchenBlue,
                                          fontSize: 22),
                                    ),
                                    onChanged: (v) => setState(
                                        () => _billAmount = double.tryParse(v)),
                                  ),
                                ),
                              ],
                            ),
                            if (billChange != null) ...[  
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    billChange >= 0 ? 'VUELTO' : 'FALTA',
                                    style: TextStyle(
                                        color: billChange >= 0
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.5),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'S/ ${billChange.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: billChange >= 0
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          if (_payMethod == 'yape') ...[
                            const SizedBox(height: 14),
                            // QR del Yape (si el admin lo configuró)
                            if (state.yapeQrImagePath != null) ...[
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B2DDB)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF7B2DDB)
                                          .withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(12, 10, 12, 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_2,
                                              color: Color(0xFF7B2DDB),
                                              size: 18),
                                          SizedBox(width: 6),
                                          Text('QR de Yape',
                                              style: TextStyle(
                                                  color: Color(0xFF7B2DDB),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      child: Image.file(
                                        File(state.yapeQrImagePath!),
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                          height: 100,
                                          child: Center(
                                              child: Text('Error al cargar QR',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.danger))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            // Número de Yape
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B2DDB)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF7B2DDB)
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_android,
                                      color: Color(0xFF7B2DDB), size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Pago con Yape',
                                          style: TextStyle(
                                              color: Color(0xFF7B2DDB),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        if (state.yapePhone.isNotEmpty)
                                          Text(
                                            'Nro: ${state.yapePhone}',
                                            style: const TextStyle(
                                                color: Color(0xFF7B2DDB),
                                                fontSize: 13),
                                          )
                                        else
                                          const Text(
                                            'Verificar transferencia',
                                            style: TextStyle(
                                                color: Color(0xFF7B2DDB),
                                                fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF7B2DDB), size: 24),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Foto del pago (opcional)
                            if (order.yapeScreenshot != null)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.success.withOpacity(0.5)),
                                ),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified,
                                              color: AppTheme.success,
                                              size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                              'Captura del pago guardada',
                                              style: TextStyle(
                                                  color: AppTheme.success,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      child: Image.file(
                                        File(order.yapeScreenshot!),
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked =
                                        await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 800,
                                      maxHeight: 800,
                                      imageQuality: 80,
                                    );
                                    if (picked != null && context.mounted) {
                                      context
                                          .read<AppState>()
                                          .setYapeScreenshot(
                                              order.id, picked.path);
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt,
                                      color: Color(0xFF7B2DDB), size: 18),
                                  label: const Text(
                                      'Tomar foto del pago (opcional)',
                                      style: TextStyle(
                                          color: Color(0xFF7B2DDB),
                                          fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: const Color(0xFF7B2DDB)
                                            .withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Estado
              _StatusBanner(status: order.status),

              const SizedBox(height: 10),

              // Editar (solo si no está pagado y no es venta directa)
              if (order.paymentStatus != PaymentStatus.paid && !order.isDirectSale)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditOrderScreen(orderId: order.id)),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Editar Pedido',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kitchenBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Pagar por separado
              if (order.items.length > 1)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.cardDark,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _SplitPaySheet(order: order),
                    ),
                    icon: const Icon(Icons.call_split,
                        color: AppTheme.success),
                    label: const Text('Pagar por separado',
                        style: TextStyle(color: AppTheme.success)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.success),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Marcar pago ──
              if (order.paymentStatus == PaymentStatus.none)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final appState = context.read<AppState>();
                          if (_payMethod == 'efectivo' && _billAmount != null) {
                            final total =
                                order.customTotal ?? order.calculatedTotal;
                            appState.setPaymentDetails(
                                order.id, _billAmount!, _billAmount! - total);
                          }
                          appState.setPaymentStatus(
                              order.id, PaymentStatus.paid);
                        },
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('PAGADO',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .read<AppState>()
                            .setPaymentStatus(order.id, PaymentStatus.notPaid),
                        icon: const Icon(Icons.cancel, size: 20),
                        label: const Text('NO CANCELADO',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (order.paymentStatus == PaymentStatus.paid
                            ? AppTheme.success
                            : AppTheme.danger)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: order.paymentStatus == PaymentStatus.paid
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        order.paymentStatus == PaymentStatus.paid
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: order.paymentStatus == PaymentStatus.paid
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.paymentStatus == PaymentStatus.paid
                            ? 'PAGADO'
                            : 'NO CANCELADO',
                        style: TextStyle(
                          color: order.paymentStatus == PaymentStatus.paid
                              ? AppTheme.success
                              : AppTheme.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── Mesa completada ──
              if (!order.isTableCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          title: const Row(
                            children: [
                              Icon(Icons.done_all, color: AppTheme.gold),
                              SizedBox(width: 8),
                              Text('¿Mesa completada?',
                                  style: TextStyle(
                                      color: AppTheme.gold, fontSize: 16)),
                            ],
                          ),
                          content: const Text(
                            'Confirma que esta mesa ya fue atendida y está lista para cerrar.',
                            style: TextStyle(color: AppTheme.textLight),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar',
                                  style:
                                      TextStyle(color: AppTheme.textLight)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<AppState>()
                                    .markTableCompleted(order.id);
                                Navigator.pop(ctx);       // cierra el diálogo
                                Navigator.pop(context);   // cierra la pantalla
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gold),
                              child: const Text('Sí, completada'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.done_all, size: 20),
                    label: const Text('MESA COMPLETADA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.darkBrown,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all, color: AppTheme.gold, size: 20),
                      SizedBox(width: 8),
                      Text('MESA COMPLETADA ✓',
                          style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = AppTheme.primaryOrange;
        icon = Icons.hourglass_top;
        label = 'Pedido enviado a cocina ⏳';
        break;
      case OrderStatus.inProgress:
        color = AppTheme.kitchenBlue;
        icon = Icons.soup_kitchen;
        label = 'La cocina está preparando tu pedido 🔥';
        break;
      case OrderStatus.ready:
        color = AppTheme.success;
        icon = Icons.check_circle;
        label = '¡El pedido está listo para servir! ✅';
        break;
      case OrderStatus.delivered:
        color = Colors.grey;
        icon = Icons.done_all;
        label = 'Pedido entregado';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Chip de modo de pago ─────────────────────────────────────────────────────

class _PayMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PayMethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: EDITAR PEDIDO (agregar ítems a un pedido existente)
// ═══════════════════════════════════════════════════════════════════════════════

class EditOrderScreen extends StatefulWidget {
  final String orderId;
  const EditOrderScreen({super.key, required this.orderId});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
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

  int _cartTotal(AppState state) {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null) total += (item.price * entry.value).toInt();
    }
    for (final e in _manualExtras) {
      total += (e.price * e.qty).toInt();
    }
    return total;
  }

  int get _cartCount =>
      _cart.values.fold(0, (a, b) => a + b) +
      _manualExtras.fold(0, (a, e) => a + e.qty);

  void _handleNoteTap(String itemId) async {
    final state = context.read<AppState>();
    final menuItem = state.getMenuItemById(itemId);
    if (menuItem == null) return;
    final result =
        await showItemNoteDialog(context, menuItem.name, _itemNotes[itemId]);
    if (result == null) return;
    setState(() {
      if (result.isEmpty) {
        _itemNotes.remove(itemId);
      } else {
        _itemNotes[itemId] = result;
      }
    });
  }

  // ─── Extras manuales ─────────────────────────────────────────────────────
  final List<ManualExtra> _manualExtras = [];
  void _addManualExtra(ManualExtra e) => setState(() => _manualExtras.add(e));
  void _removeManualExtra(int i) =>
      setState(() => _manualExtras.removeAt(i));
  void _changeManualQty(int i, int delta) => setState(() {
        _manualExtras[i] = _manualExtras[i]
            .copyWith(qty: (_manualExtras[i].qty + delta).clamp(1, 99));
      });

  void _saveChanges(BuildContext context, AppState state) {
    if (_cart.isEmpty && _manualExtras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No agregaste ningún plato nuevo.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<OrderItem> newItems = [];
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null && entry.value > 0) {
        newItems.add(OrderItem(
          menuItemId: item.id,
          menuItemName: item.name,
          quantity: entry.value,
          price: item.price,
          notes: _itemNotes[entry.key],
        ));
      }
    }
    for (final e in _manualExtras) {
      if (e.qty > 0) {
        newItems.add(OrderItem(
          menuItemId: 'extra_${DateTime.now().millisecondsSinceEpoch}',
          menuItemName: e.name,
          quantity: e.qty,
          price: e.price,
          isExtra: true,
        ));
      }
    }

    state.addItemsToOrder(widget.orderId, newItems);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Platos agregados al pedido'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  void _confirmRemoveItem(BuildContext context, AppState state, Order order, int itemIndex) {
    final item = order.items[itemIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Eliminar plato',
            style: TextStyle(color: AppTheme.textLight, fontSize: 16)),
        content: Text(
          '¿Quitar "${item.menuItemName}" (${item.quantity}u) del pedido?',
          style: const TextStyle(color: AppTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              state.removeItemFromOrder(order.id, itemIndex);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.getOrderById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Pedido')),
        body: const Center(child: Text('Pedido no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Editar Pedido Mesa ${order.tableNumber}')),
      body: Column(
        children: [
          // ─── Platos actuales con opción de eliminar ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.kitchenBlue.withOpacity(0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: AppTheme.kitchenBlue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido #${order.orderNumber} · ${order.items.length} plato${order.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.kitchenBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(order.items.length, (idx) {
                  final item = order.items[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}×',
                          style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItemName,
                                style: const TextStyle(
                                    color: AppTheme.textLight, fontSize: 12),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  item.notes!,
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (item.isExtra)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('extra',
                                style: TextStyle(
                                    color: AppTheme.gold, fontSize: 9)),
                          ),
                        GestureDetector(
                          onTap: () =>
                              _confirmRemoveItem(context, state, order, idx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.close,
                                color: AppTheme.danger, size: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // ─── Filtro de secciones + búsqueda ───
          _SectionFilterBar(
            selected: _selectedFilter,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onFilterChanged: (f) => setState(() {
              _selectedFilter = f;
              _searchQuery = '';
              _searchCtrl.clear();
              _showSearch = false;
            }),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          // ─── Menú filtrado ───
          Expanded(
            child: _selectedFilter == 'Extra'
                ? ManualExtraSection(
                    extras: _manualExtras,
                    onAdd: _addManualExtra,
                    onRemove: _removeManualExtra,
                    onQtyChange: _changeManualQty,
                  )
                : SectionedMenuList(
                    cart: _cart,
                    filterSections: _filterGroups[_selectedFilter],
                    searchQuery: _searchQuery,
                    itemNotes: _itemNotes,
                    onNoteTap: _handleNoteTap,
                    onAdd: (id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1),
                    onRemove: (id) => setState(() {
                      if ((_cart[id] ?? 0) > 0) _cart[id] = _cart[id]! - 1;
                      if (_cart[id] == 0) _cart.remove(id);
                    }),
                  ),
          ),
          CartBar(
            count: _cartCount,
            total: _cartTotal(state),
            onSubmit: () => _saveChanges(context, state),
            submitLabel: 'Agregar al Pedido',
            submitIcon: Icons.add_circle_outline,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: COBRO DIRECTO (MOZO)
// ═══════════════════════════════════════════════════════════════════════════════

class WaiterDirectSaleScreen extends StatefulWidget {
  const WaiterDirectSaleScreen({super.key});

  @override
  State<WaiterDirectSaleScreen> createState() =>
      _WaiterDirectSaleScreenState();
}

class _WaiterDirectSaleScreenState extends State<WaiterDirectSaleScreen> {
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

  int _cartTotal(AppState state) {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null) total += (item.price * entry.value).toInt();
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _submit(BuildContext context, AppState state) {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregá al menos un ítem para cobrar.'),
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
    final order = state.submitDirectSale(
      items: items,
      adminName: state.currentUserName,
    );
    setState(() => _cart.clear());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          orderId: order.id,
          backRoute: '/waiter',
          backLabel: 'Volver a mis pedidos',
        ),
      ),
    );
  }

  void _handleNoteTap(String itemId) async {
    final state = context.read<AppState>();
    final menuItem = state.getMenuItemById(itemId);
    if (menuItem == null) return;
    final result =
        await showItemNoteDialog(context, menuItem.name, _itemNotes[itemId]);
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
        title: const Text('💳 Cobro Directo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.gold.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.gold, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Cobro directo — no pasa por cocina',
                  style: TextStyle(
                      color: AppTheme.gold.withOpacity(0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          _SectionFilterBar(
            selected: _selectedFilter,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onFilterChanged: (f) => setState(() {
              _selectedFilter = f;
              _searchQuery = '';
              _searchCtrl.clear();
              _showSearch = false;
            }),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
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
            onSubmit: () => _submit(context, state),
            submitLabel: 'Cobrar',
            submitIcon: Icons.point_of_sale,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//   PANTALLA: PEDIDO DELIVERY (MOZO)
// ═══════════════════════════════════════════════════════════════════════════════

class _WaiterDeliveryScreen extends StatefulWidget {
  const _WaiterDeliveryScreen();

  @override
  State<_WaiterDeliveryScreen> createState() => _WaiterDeliveryScreenState();
}

class _WaiterDeliveryScreenState extends State<_WaiterDeliveryScreen> {
  final Map<String, int> _cart = {};
  final Map<String, String> _itemNotes = {};
  final TextEditingController _phoneCtrl = TextEditingController();
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

  int _cartTotal(AppState state) {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = state.getMenuItemById(entry.key);
      if (item != null) total += (item.price * entry.value).toInt();
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _submit(BuildContext context, AppState state) {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregá al menos un plato.'),
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
    final order = state.submitDeliveryOrder(
      items: items,
      waiterName: state.currentUserName,
      phone: _phoneCtrl.text.trim(),
    );
    setState(() => _cart.clear());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          orderId: order.id,
          backRoute: '/waiter',
          backLabel: 'Volver',
        ),
      ),
    );
  }

  void _handleNoteTap(String itemId) async {
    final state = context.read<AppState>();
    final menuItem = state.getMenuItemById(itemId);
    if (menuItem == null) return;
    final result =
        await showItemNoteDialog(context, menuItem.name, _itemNotes[itemId]);
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
    _phoneCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛵 Delivery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Teléfono del cliente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppTheme.kitchenBlue.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.phone, color: AppTheme.kitchenBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        color: AppTheme.textLight, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Teléfono del cliente',
                      hintStyle: TextStyle(
                          color: AppTheme.kitchenBlue.withOpacity(0.5)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AppTheme.kitchenBlue.withOpacity(0.4)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AppTheme.kitchenBlue.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SectionFilterBar(
            selected: _selectedFilter,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onFilterChanged: (f) => setState(() {
              _selectedFilter = f;
              _searchQuery = '';
              _searchCtrl.clear();
              _showSearch = false;
            }),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
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
            onSubmit: () => _submit(context, state),
            submitLabel: 'Enviar Delivery',
            submitIcon: Icons.delivery_dining,
          ),
        ],
      ),
    );
  }
}

// ─── Pagar por separado (bottom sheet) ──────────────────────────────────────────

class _SplitPaySheet extends StatefulWidget {
  final Order order;
  const _SplitPaySheet({required this.order});

  @override
  State<_SplitPaySheet> createState() => _SplitPaySheetState();
}

class _SplitPaySheetState extends State<_SplitPaySheet> {
  static const _colors = [
    AppTheme.primaryOrange,
    Color(0xFF29B6F6),
    AppTheme.success,
    AppTheme.gold,
    Color(0xFFE040FB),
    Color(0xFFFF7043),
  ];

  List<List<int>> _qtys = [];
  List<String> _names = [];
  int _active = 0;
  List<TextEditingController> _payControllers = [];
  List<bool> _personConfirmed = [];

  @override
  void initState() {
    super.initState();
    _addPerson();
    _addPerson();
  }

  void _addPerson() {
    final n = widget.order.items.length;
    setState(() {
      _names.add('Persona ${_qtys.length + 1}');
      _qtys.add(List.filled(n, 0));
      _payControllers.add(TextEditingController());
      _personConfirmed.add(false);
      _active = _qtys.length - 1;
    });
  }

  void _removePerson(int idx) {
    if (_qtys.length <= 1) return;
    setState(() {
      _qtys.removeAt(idx);
      _names.removeAt(idx);
      _payControllers[idx].dispose();
      _payControllers.removeAt(idx);
      _personConfirmed.removeAt(idx);
      if (_active >= _qtys.length) _active = _qtys.length - 1;
    });
  }

  int _assigned(int itemIdx) =>
      _qtys.fold(0, (s, p) => s + p[itemIdx]);

  int _maxFor(int itemIdx) {
    final total = widget.order.items[itemIdx].quantity;
    final mine = _qtys[_active][itemIdx];
    return total - _assigned(itemIdx) + mine;
  }

  bool get _allAssigned {
    for (int i = 0; i < widget.order.items.length; i++) {
      if (_assigned(i) != widget.order.items[i].quantity) return false;
    }
    return true;
  }

  double _subtotalFor(int pIdx) {
    double t = 0;
    for (int i = 0; i < widget.order.items.length; i++) {
      t += _qtys[pIdx][i] * widget.order.items[i].price;
    }
    return t;
  }

  void _renamePerson(int idx) async {
    final ctrl = TextEditingController(text: _names[idx]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nombre de la persona',
            style: TextStyle(color: AppTheme.gold, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _names[idx] = result.trim());
    }
  }

  Color _colorOf(int idx) => _colors[idx % _colors.length];

  bool get _allPaymentsConfirmed {
    for (int i = 0; i < _qtys.length; i++) {
      if (_subtotalFor(i) > 0 && !_personConfirmed[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    for (final c in _payControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items;
    final total = items.fold(0.0, (s, it) => s + it.subtotal);
    final unassigned = items.asMap().entries.fold(
        0.0,
        (s, e) =>
            s + (e.value.quantity - _assigned(e.key)) * e.value.price);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titulo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.call_split, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Dividir cuenta',
                      style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  Text(
                    'Total: S/ ${total.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.5),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            // Pestanas de personas
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  ...List.generate(_qtys.length, (idx) {
                    final isActive = idx == _active;
                    final color = _colorOf(idx);
                    return GestureDetector(
                      onTap: () => setState(() => _active = idx),
                      onLongPress: () => _renamePerson(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color
                              : color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color, width: isActive ? 0 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _names[idx],
                              style: TextStyle(
                                color: isActive ? Colors.white : color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (_qtys.length > 1) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removePerson(idx),
                                child: Icon(Icons.close,
                                    size: 14,
                                    color: isActive
                                        ? Colors.white70
                                        : color.withOpacity(0.7)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_qtys.length < 6)
                    GestureDetector(
                      onTap: _addPerson,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.textLight.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 14,
                                color: AppTheme.textLight.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              'Agregar',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.5),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppTheme.cardMedium, height: 1),
            // Ayuda
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12,
                      color: AppTheme.textLight.withOpacity(0.4)),
                  const SizedBox(width: 6),
                  Text(
                    'Asigna cuantas unidades paga ${_names[_active]}',
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.4),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            // Lista de items
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final mine = _qtys[_active][i];
                  final max = _maxFor(i);
                  final remaining = item.quantity - _assigned(i) + mine;
                  final activeColor = _colorOf(_active);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: mine > 0
                          ? activeColor.withOpacity(0.08)
                          : AppTheme.cardMedium.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: mine > 0
                            ? activeColor.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.menuItemName,
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (item.isExtra) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'extra',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.sticky_note_2,
                                        size: 10,
                                        color: AppTheme.primaryOrange),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        item.notes!,
                                        style: const TextStyle(
                                          color: AppTheme.primaryOrange,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    'Total: ${item.quantity}u',
                                    style: TextStyle(
                                        color: AppTheme.textLight
                                            .withOpacity(0.4),
                                        fontSize: 10),
                                  ),
                                  ...List.generate(
                                      _qtys.length,
                                      (p) => _qtys[p][i] > 0
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: _colorOf(p)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${_names[p]}: ${_qtys[p][i]}',
                                                style: TextStyle(
                                                    color: _colorOf(p),
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )
                                          : const SizedBox.shrink()),
                                  if (remaining > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.danger.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Sin asignar: $remaining',
                                        style: TextStyle(
                                            color: AppTheme.danger
                                                .withOpacity(0.8),
                                            fontSize: 9),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/ ${item.price.toStringAsFixed(0)}/u',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.4),
                                  fontSize: 10),
                            ),
                            if (mine > 0)
                              Text(
                                'S/ ${(mine * item.price).toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: activeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Control - n +
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyBtn(
                              icon: Icons.remove,
                              color: activeColor,
                              enabled: mine > 0,
                              onTap: () =>
                                  setState(() => _qtys[_active][i] = mine - 1),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$mine',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mine > 0
                                      ? activeColor
                                      : AppTheme.textLight.withOpacity(0.3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _QtyBtn(
                              icon: Icons.add,
                              color: activeColor,
                              enabled: mine < max,
                              onTap: () =>
                                  setState(() => _qtys[_active][i] = mine + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppTheme.cardMedium, height: 1),
            // Resumen por persona con formulario de pago
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _allAssigned ? 'CONFIRMAR PAGOS' : 'RESUMEN',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.4),
                          fontSize: 10,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(_qtys.length, (p) {
                      final sub = _subtotalFor(p);
                      if (sub == 0) return const SizedBox.shrink();
                      final color = _colorOf(p);
                      final payAmount = double.tryParse(_payControllers[p].text);
                      final change = payAmount != null ? payAmount - sub : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _personConfirmed[p]
                              ? AppTheme.success.withOpacity(0.06)
                              : color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _personConfirmed[p]
                                ? AppTheme.success.withOpacity(0.5)
                                : color.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre + subtotal
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _names[p],
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                                Text(
                                  'S/ ${sub.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            // Formulario de pago (solo si todos asignados y no confirmado)
                            if (_allAssigned && !_personConfirmed[p]) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Pagó con',
                                    style: TextStyle(
                                        color: AppTheme.textLight.withOpacity(0.7),
                                        fontSize: 12),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _payControllers[p],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        prefixText: 'S/ ',
                                        prefixStyle: TextStyle(
                                            color: color.withOpacity(0.7),
                                            fontSize: 14),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 4),
                                        border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: color.withOpacity(0.5))),
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                            color: color.withOpacity(0.3),
                                            fontSize: 18),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              if (change != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      change >= 0 ? 'Vuelto' : 'Falta',
                                      style: TextStyle(
                                        color: change >= 0
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'S/ ${change.abs().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: change >= 0
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (change >= 0) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(
                                          () => _personConfirmed[p] = true),
                                      icon: const Icon(Icons.check_circle,
                                          size: 16),
                                      label: Text(
                                        'Confirmar pago de ${_names[p]}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                            // Pago confirmado
                            if (_personConfirmed[p])
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: AppTheme.success, size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Pago confirmado',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _personConfirmed[p] = false),
                                      child: Text(
                                        'Editar',
                                        style: TextStyle(
                                          color: AppTheme.textLight
                                              .withOpacity(0.4),
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (unassigned > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Sin asignar',
                                style: TextStyle(
                                    color: AppTheme.danger, fontSize: 13),
                              ),
                            ),
                            Text(
                              'S/ ${unassigned.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Boton confirmar
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(!_allAssigned
                        ? 'Faltan asignar items'
                        : !_allPaymentsConfirmed
                            ? 'Confirmar pagos pendientes'
                            : 'Listo \u2714'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allAssigned && _allPaymentsConfirmed
                          ? AppTheme.success
                          : AppTheme.cardMedium,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _allAssigned && _allPaymentsConfirmed
                        ? () => Navigator.pop(context)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
              color: enabled ? color : AppTheme.textLight.withOpacity(0.15)),
        ),
        child: Icon(icon,
            size: 14,
            color: enabled ? color : AppTheme.textLight.withOpacity(0.2)),
      ),
    );
  }
}