import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  // Timer para actualizar el tiempo transcurrido cada segundo
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeOrders = state.activeKitchenOrders;
    final queueSize = state.kitchenQueueSize;
    final completed = state.todayCompletedOrders;
    final total = state.todayTotalOrders;
    final alerts = state.ordersWithKitchenAlerts;

    return Scaffold(
      backgroundColor: AppTheme.darkBrown,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.soup_kitchen, color: AppTheme.gold, size: 22),
            SizedBox(width: 8),
            Text('COCINA'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () {
            state.logout();
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
        actions: [
          // Botón cola completa
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.format_list_numbered, color: AppTheme.gold),
                if (queueSize > 2)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$queueSize',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Ver cola completa',
            onPressed: () => _showFullQueueSheet(context, state),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _HeaderStats(
                completed: completed, total: total, queue: queueSize),
          ),
        ],
      ),
      floatingActionButton: _ReviewButton(state: state),
      body: Column(
        children: [
          // Banner de alertas de extras
          if (alerts.isNotEmpty)
            _ExtraAlertBanner(alerts: alerts, state: state),

          // Banner de estado de cola
          _QueueBanner(queueSize: queueSize, completed: completed),

          // Pedidos activos (máx 2)
          Expanded(
            child: activeOrders.isEmpty
                ? const _EmptyKitchen()
                : _ActiveOrdersView(orders: activeOrders),
          ),

          // Historial del día en la parte inferior
          _TodayHistory(state: state),
        ],
      ),
    );
  }
}

// ─── Stats en la AppBar ───────────────────────────────────────────────────────

class _HeaderStats extends StatelessWidget {
  final int completed;
  final int total;
  final int queue;

  const _HeaderStats(
      {required this.completed, required this.total, required this.queue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(
          value: '$completed',
          label: 'listos',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          value: '$queue',
          label: 'en cola',
          color: AppTheme.primaryOrange,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─── Banner de cola ───────────────────────────────────────────────────────────

class _QueueBanner extends StatelessWidget {
  final int queueSize;
  final int completed;

  const _QueueBanner({required this.queueSize, required this.completed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.cardDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pending_actions,
              color: AppTheme.gold, size: 18),
          const SizedBox(width: 8),
          Text(
            queueSize == 0
                ? '✅  Sin pedidos pendientes'
                : queueSize <= 2
                    ? '🔥  Mostrando $queueSize pedido${queueSize != 1 ? 's' : ''} activo${queueSize != 1 ? 's' : ''}'
                    : '🔥  Mostrando 2 de $queueSize pedidos — ${queueSize - 2} en espera',
            style: TextStyle(
              color: queueSize == 0
                  ? AppTheme.success
                  : AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyKitchen extends StatefulWidget {
  const _EmptyKitchen();

  @override
  State<_EmptyKitchen> createState() => _EmptyKitchenState();
}

class _EmptyKitchenState extends State<_EmptyKitchen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _anim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.success, size: 100),
            const SizedBox(height: 16),
            const Text(
              '¡Todo al día!',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay pedidos pendientes.',
              style: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.6), fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Esperando nuevos pedidos... 🍽️',
              style: TextStyle(
                  color: AppTheme.gold.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vista de pedidos activos ─────────────────────────────────────────────────

class _ActiveOrdersView extends StatelessWidget {
  final List<Order> orders;

  const _ActiveOrdersView({required this.orders});

  @override
  Widget build(BuildContext context) {
    // En landscape o pantallas grandes: lado a lado; sino: apilados
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: orders
                  .map((o) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _OrderCard(order: o, key: ValueKey(o.id)),
                        ),
                      ))
                  .toList(),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: orders
              .map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(order: o, key: ValueKey(o.id)),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─── Tarjeta de pedido en cocina ─────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final Order order;

  const _OrderCard({required this.order, super.key});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markReady(BuildContext context) async {
    if (_completing) return;
    setState(() => _completing = true);

    // Animación de salida
    await _ctrl.reverse();

    if (context.mounted) {
      context.read<AppState>().markOrderDelivered(widget.order.id);
    }
  }

  String _elapsed(DateTime from) {
    final diff = DateTime.now().difference(from);
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inHours < 1) return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color get _timeColor {
    final minutes = DateTime.now().difference(widget.order.createdAt).inMinutes;
    if (minutes < 5) return AppTheme.success;
    if (minutes < 10) return AppTheme.gold;
    return AppTheme.danger;
  }

  String get _orderOrdinal {
    final n = widget.order.orderNumber;
    if (n == 1) return '1° pedido del día';
    if (n == 2) return '2° pedido del día';
    if (n == 3) return '3° pedido del día';
    return '${n}° pedido del día';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardMedium,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryOrange.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la tarjeta
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryOrange, Color(0xFFAA4500)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.isDelivery
                              ? '🛵  DELIVERY'
                              : widget.order.isTakeaway
                                  ? '📦  PARA LLEVAR'
                                  : '🪑  MESA ${widget.order.tableNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                        if (widget.order.isDelivery && widget.order.deliveryPhone != null && widget.order.deliveryPhone!.isNotEmpty)
                          Text(
                            '📞 ${widget.order.deliveryPhone}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            _orderOrdinal,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '⏱  ${_elapsed(widget.order.createdAt)}',
                          style: TextStyle(
                            color: _timeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Mozo: ${widget.order.waiterName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de ítems con check
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.order.items.length, (idx) {
                    final item = widget.order.items[idx];
                    final state = context.watch<AppState>();
                    final checks = state.getKitchenChecks(widget.order.id);
                    final isChecked = checks.contains(idx);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          // Mini checkbox
                          GestureDetector(
                            onTap: () => state.toggleKitchenItemCheck(
                                widget.order.id, idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppTheme.success.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isChecked
                                      ? AppTheme.success
                                      : AppTheme.primaryOrange.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check,
                                      color: AppTheme.success, size: 16)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? AppTheme.success.withOpacity(0.15)
                                  : AppTheme.primaryOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isChecked
                                      ? AppTheme.success.withOpacity(0.5)
                                      : AppTheme.primaryOrange.withOpacity(0.5)),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  color: isChecked
                                      ? AppTheme.success
                                      : AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItemName,
                                  style: TextStyle(
                                    color: isChecked
                                        ? AppTheme.success.withOpacity(0.6)
                                        : AppTheme.textLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.sticky_note_2,
                                            size: 12,
                                            color: AppTheme.primaryOrange),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            item.notes!,
                                            style: TextStyle(
                                              color: isChecked
                                                  ? AppTheme.primaryOrange.withOpacity(0.4)
                                                  : AppTheme.primaryOrange,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const Divider(
                  color: AppTheme.gold, height: 1, indent: 14, endIndent: 14),

              // Total de ítems + progreso + botón LISTO
              Padding(
                padding: const EdgeInsets.all(14),
                child: Builder(
                  builder: (ctx) {
                    final state = ctx.watch<AppState>();
                    final checks = state.getKitchenChecks(widget.order.id);
                    final totalItems = widget.order.items.length;
                    final checkedCount = checks.length.clamp(0, totalItems);
                    final allDone = checkedCount >= totalItems;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$checkedCount / $totalItems plato${totalItems != 1 ? 's' : ''} listo${checkedCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                  color: allDone
                                      ? AppTheme.success
                                      : AppTheme.gold,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pedido #${widget.order.orderNumber}',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.5),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        _ReadyButton(
                          onPressed: _completing
                              ? null
                              : () => _markReady(context),
                          completing: _completing,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón LISTO animado ──────────────────────────────────────────────────────

class _ReadyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool completing;

  const _ReadyButton({required this.onPressed, required this.completing});

  @override
  State<_ReadyButton> createState() => _ReadyButtonState();
}

class _ReadyButtonState extends State<_ReadyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppTheme.success,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 8),
            Text('Procesando...',
                style: TextStyle(
                    color: AppTheme.success, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.success, Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                '¡LISTO!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Historial del día ─────────────────────────────────────────────────────────

class _TodayHistory extends StatelessWidget {
  final AppState state;

  const _TodayHistory({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final delivered = state.orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            !o.isArchived &&
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (delivered.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(color: AppTheme.gold.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppTheme.gold, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Completados hoy (${delivered.length})',
                  style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: delivered.length,
              itemBuilder: (ctx, i) {
                final o = delivered[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Mesa ${o.tableNumber}',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Text('#${o.orderNumber}',
                          style: TextStyle(
                              color: AppTheme.success.withOpacity(0.6),
                              fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Banner de alertas: se agregaron extras a pedidos ya entregados ───────────

class _ExtraAlertBanner extends StatelessWidget {
  final List<Order> alerts;
  final AppState state;

  const _ExtraAlertBanner({required this.alerts, required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReviewSheet(context, state, initialAlerts: true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.notification_important,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️  ${alerts.length} pedido${alerts.length != 1 ? 's' : ''} con ítems añadidos después: '
                '${alerts.map((o) => o.isDelivery ? 'Delivery' : o.isTakeaway ? 'Llevar' : 'Mesa ${o.tableNumber}').join(', ')} — Toca para revisar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón flotante "Revisar pedidos sacados" ─────────────────────────────────

class _ReviewButton extends StatelessWidget {
  final AppState state;

  const _ReviewButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final alerts = state.ordersWithKitchenAlerts;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        FloatingActionButton.extended(
          heroTag: 'kitchen_review',
          onPressed: () => _showReviewSheet(context, state),
          backgroundColor: AppTheme.cardMedium,
          foregroundColor: AppTheme.gold,
          icon: const Icon(Icons.receipt_long),
          label: const Text('Revisar pedidos',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (alerts.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFB71C1C),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${alerts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Bottom sheet: revisión de todos los pedidos del día ─────────────────────

void _showReviewSheet(BuildContext context, AppState state,
    {bool initialAlerts = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(state: state, showAlerts: initialAlerts),
  );
}

class _ReviewSheet extends StatefulWidget {
  final AppState state;
  final bool showAlerts;

  const _ReviewSheet({required this.state, required this.showAlerts});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this,
        initialIndex: widget.showAlerts ? 1 : 0);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final delivered = state.orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            !o.isArchived &&
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day &&
            !o.isDirectSale)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final alerts = state.ordersWithKitchenAlerts;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: AppTheme.gold, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Pedidos del día',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${delivered.length} total',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.5),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.gold,
                labelColor: AppTheme.gold,
                unselectedLabelColor: AppTheme.textLight.withOpacity(0.5),
                tabs: [
                  const Tab(text: 'Todos del día'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Con extras'),
                        if (alerts.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${alerts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Contenido
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: todos los pedidos del día
                    delivered.isEmpty
                        ? Center(
                            child: Text(
                              'Sin pedidos entregados aún.',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.4),
                                  fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: delivered.length,
                            itemBuilder: (ctx, i) =>
                                _ReviewOrderTile(order: delivered[i], state: state),
                          ),
                    // Tab 2: pedidos con extras pendientes
                    alerts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: AppTheme.success, size: 56),
                                const SizedBox(height: 12),
                                Text(
                                  'Sin extras pendientes.',
                                  style: TextStyle(
                                      color: AppTheme.textLight.withOpacity(0.5),
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: alerts.length,
                            itemBuilder: (ctx, i) => _ReviewOrderTile(
                                order: alerts[i],
                                state: state,
                                highlightAlert: true),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tile de pedido en la revisión ───────────────────────────────────────────

class _ReviewOrderTile extends StatelessWidget {
  final Order order;
  final AppState state;
  final bool highlightAlert;

  const _ReviewOrderTile(
      {required this.order,
      required this.state,
      this.highlightAlert = false});

  @override
  Widget build(BuildContext context) {
    final alertColor =
        highlightAlert ? const Color(0xFFB71C1C) : AppTheme.success;
    final borderColor = highlightAlert
        ? const Color(0xFFB71C1C).withOpacity(0.6)
        : AppTheme.success.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: highlightAlert ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del tile
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  order.isDelivery
                      ? '🛵 DELIVERY'
                      : order.isTakeaway
                          ? '📦 PARA LLEVAR'
                          : '🪑 Mesa ${order.tableNumber}',
                  style: TextStyle(
                    color: alertColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${order.orderNumber}',
                  style: TextStyle(
                      color: alertColor.withOpacity(0.7), fontSize: 13),
                ),
                const Spacer(),
                if (highlightAlert && order.extraAddedAt != null)
                  Text(
                    'Extra a las ${_fmt(order.extraAddedAt!)}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    _fmt(order.createdAt),
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.5),
                        fontSize: 11),
                  ),
                if (highlightAlert) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => state.acknowledgeKitchenAlert(order.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'Visto ✓',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Lista de ítems
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) {
                final isExtra = item.isExtra;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isExtra
                              ? Colors.orangeAccent.withOpacity(0.15)
                              : AppTheme.primaryOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(
                              color: isExtra
                                  ? Colors.orangeAccent
                                  : AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.menuItemName,
                                    style: TextStyle(
                                      color: AppTheme.textLight
                                          .withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isExtra)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '+ EXTRA',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                '📝 ${item.notes}',
                                style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Cola completa: abrir sheet ───────────────────────────────────────────────

void _showFullQueueSheet(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FullQueueSheet(state: state),
  );
}

// ─── Sheet: lista de todos los pedidos activos como tickets ──────────────────

class _FullQueueSheet extends StatelessWidget {
  final AppState state;
  const _FullQueueSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<AppState>().kitchenQueue;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.format_list_numbered,
                        color: AppTheme.gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Cola activa  —  ${queue.length} pedido${queue.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Toca para abrir',
                      style: TextStyle(
                          color: AppTheme.textLight.withOpacity(0.4),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(
                  color: AppTheme.gold, height: 1, indent: 16, endIndent: 16),
              const SizedBox(height: 4),
              // Lista de tickets
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppTheme.success, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'Sin pedidos activos.',
                              style: TextStyle(
                                  color: AppTheme.textLight.withOpacity(0.5),
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: queue.length,
                        itemBuilder: (ctx, i) {
                          final order = queue[i];
                          return _QueueTicket(
                            order: order,
                            position: i + 1,
                            onTap: () {
                              Navigator.pop(ctx); // cierra el sheet
                              _showOrderDetail(context, order);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Ticket compacto en la cola ───────────────────────────────────────────────

class _QueueTicket extends StatelessWidget {
  final Order order;
  final int position;
  final VoidCallback onTap;

  const _QueueTicket({
    required this.order,
    required this.position,
    required this.onTap,
  });

  String _elapsed(DateTime from) {
    final diff = DateTime.now().difference(from);
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inHours < 1) return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color get _waitColor {
    final min = DateTime.now().difference(order.createdAt).inMinutes;
    if (min < 5) return AppTheme.success;
    if (min < 10) return AppTheme.gold;
    return AppTheme.danger;
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = position <= 2;
    final accentColor = isFirst ? AppTheme.primaryOrange : AppTheme.gold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardMedium,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withOpacity(isFirst ? 0.7 : 0.3),
            width: isFirst ? 2 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja lateral con número de posición
              Container(
                width: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$position°',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isFirst)
                      Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: accentColor.withOpacity(0.7),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
              // Contenido del ticket
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila superior: mesa + #pedido + tiempo
                      Row(
                        children: [
                          Text(
                            order.isDelivery
                                ? '🛵 DELIVERY'
                                : order.isTakeaway
                                    ? '📦 LLEVAR'
                                    : '🪑 Mesa ${order.tableNumber}',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${order.orderNumber}',
                            style: TextStyle(
                                color: accentColor.withOpacity(0.6),
                                fontSize: 13),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _waitColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⏱ ${_elapsed(order.createdAt)}',
                              style: TextStyle(
                                color: _waitColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Fila inferior: hora toma / hora ingreso / ítems / mozo
                      Row(
                        children: [
                          _TicketBadge(
                            icon: Icons.access_time,
                            label: 'Tomado',
                            value: _fmtTime(order.createdAt),
                            color: AppTheme.textLight.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          _TicketBadge(
                            icon: Icons.login,
                            label: 'Ingresó',
                            value: _fmtTime(order.createdAt),
                            color: AppTheme.kitchenBlue.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          _TicketBadge(
                            icon: Icons.fastfood,
                            label: 'Ítems',
                            value: '${order.items.length}',
                            color: AppTheme.primaryOrange.withOpacity(0.8),
                          ),
                          const Spacer(),
                          Text(
                            order.waiterName,
                            style: TextStyle(
                                color: AppTheme.textLight.withOpacity(0.4),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Flecha
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right,
                    color: accentColor.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TicketBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ─── Detalle de un pedido seleccionado manualmente ───────────────────────────

void _showOrderDetail(BuildContext context, Order order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderDetailSheet(order: order),
  );
}

class _OrderDetailSheet extends StatelessWidget {
  final Order order;
  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkBrown,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_full,
                        color: AppTheme.gold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      order.isDelivery
                          ? 'Delivery — #${order.orderNumber}'
                          : order.isTakeaway
                              ? 'Para Llevar — #${order.orderNumber}'
                              : 'Mesa ${order.tableNumber} — #${order.orderNumber}',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar',
                          style: TextStyle(color: AppTheme.textLight)),
                    ),
                  ],
                ),
              ),
              const Divider(
                  color: AppTheme.gold, height: 1, indent: 16, endIndent: 16),
              // Tarjeta completa del pedido
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  child: _OrderCard(order: order, key: ValueKey(order.id)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
