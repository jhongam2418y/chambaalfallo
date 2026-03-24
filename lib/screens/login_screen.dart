import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnim;

  // Estado de carga inicial
  bool _isLoading = true;

  // Modo: 'select' | 'admin' | 'worker'
  String _mode = 'select';

  // Formulario compartido
  bool _obscure = true;
  final _pwdCtrl = TextEditingController();
  String? _errorMsg;
  bool _busy = false;

  // Solo modo worker
  String? _selectedWorker;
  bool _workerHasSession = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _rotateController,
    );

    // Cargar configuración de auth desde SharedPreferences
    Future.microtask(() async {
      await context.read<AppState>().loadAuth();
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // ─── Acciones ───────────────────────────────────────────────────────────────

  void _setMode(String mode) => setState(() {
        _mode = mode;
        _errorMsg = null;
        _pwdCtrl.clear();
        _selectedWorker = null;
        _workerHasSession = false;
        _obscure = true;
        _busy = false;
      });

  void _pickWorker(String? name) {
    if (name == null) return;
    final valid = context.read<AppState>().checkWorkerSession(name);
    setState(() {
      _selectedWorker = name;
      _workerHasSession = valid;
      _pwdCtrl.clear();
      _errorMsg = null;
    });
  }

  void _doAdminLogin() {
    final state = context.read<AppState>();
    if (!state.loginAdmin(_pwdCtrl.text.trim())) {
      setState(() => _errorMsg = 'Contraseña incorrecta. Intenta de nuevo.');
      return;
    }
    Navigator.of(context).pushReplacementNamed('/admin');
  }

  Future<void> _doWorkerLogin() async {
    if (_selectedWorker == null) return;
    setState(() {
      _busy = true;
      _errorMsg = null;
    });
    final state = context.read<AppState>();
    if (_workerHasSession) {
      state.loginWithSession(_selectedWorker!);
    } else {
      final err =
          await state.loginWorker(_selectedWorker!, _pwdCtrl.text.trim());
      if (err != null) {
        setState(() {
          _errorMsg = err;
          _busy = false;
        });
        return;
      }
    }
    if (!mounted) return;
    final role = state.currentRole;
    Navigator.of(context).pushReplacementNamed(
        role == UserRole.waiter ? '/waiter' : '/kitchen');
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo con degradado rico ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0200),
                  Color(0xFF1E0900),
                  Color(0xFF0F0400),
                  Color(0xFF050100),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          // ── Destellos decorativos de fondo ───────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(color: AppTheme.primaryOrange.withOpacity(0.18), size: 260),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _GlowOrb(color: AppTheme.gold.withOpacity(0.12), size: 200),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -50,
            child: _GlowOrb(color: AppTheme.gold.withOpacity(0.08), size: 160),
          ),
          // ── Contenido principal ──────────────────────────────────────────
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                          ),
                          child: const CircularProgressIndicator(
                              color: AppTheme.gold, strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            color: AppTheme.gold.withOpacity(0.7),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Column(
                          children: [
                            // ── barra superior ──────────────────────────
                            SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  if (_mode != 'select')
                                    GestureDetector(
                                      onTap: () => _setMode('select'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.gold
                                                  .withOpacity(0.35)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.gold.withOpacity(0.15),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.arrow_back_ios_new,
                                                color: AppTheme.gold,
                                                size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Volver',
                                              style: TextStyle(
                                                color: AppTheme.gold.withOpacity(0.9),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                            // ── Header con logo y nombre ─────────────────
                            _buildHeader(),
                            const SizedBox(height: 22),
                            // ── contenido ────────────────────────────────
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                                child: _buildContent(),
                              ),
                            ),
                            // ── footer elegante ───────────────────────────
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _miniDivider(),
                                  const SizedBox(width: 10),
                                  Text(
                                    'La Cabaña del Sabor  ·  v1.0',
                                    style: TextStyle(
                                      color: AppTheme.gold.withOpacity(0.45),
                                      fontSize: 10,
                                      letterSpacing: 1.8,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _miniDivider(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header decorativo ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Anillo exterior giratorio + logo con pulso
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _rotateAnim]),
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Resplandor exterior muy suave
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.25 * _pulseAnim.value),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Anillo decorativo giratorio
                Transform.rotate(
                  angle: _rotateAnim.value,
                  child: CustomPaint(
                    size: const Size(112, 112),
                    painter: _DashedRingPainter(
                      color: AppTheme.gold.withOpacity(0.45),
                    ),
                  ),
                ),
                // Logo con escala pulsante
                Transform.scale(
                  scale: 0.92 + 0.08 * _pulseAnim.value,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFE8720A), Color(0xFF7A2800)],
                        center: Alignment(-0.3, -0.3),
                      ),
                      border: Border.all(
                          color: AppTheme.gold.withOpacity(0.75), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange
                              .withOpacity(0.55 * _pulseAnim.value),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cabin, color: Colors.white, size: 44),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Nombre del restaurante con efecto shimmer
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD860),
              Color(0xFFFFFFFF),
              Color(0xFFFFB020),
              Color(0xFFFFD860),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ).createShader(bounds),
          child: const Text(
            'La Cabaña del Sabor',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Subtítulo tipo divider ornamental
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornamentLine(),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'RESTAURANTE',
                style: TextStyle(
                  color: AppTheme.gold.withOpacity(0.85),
                  fontSize: 9.5,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ornamentLine(),
          ],
        ),
        const SizedBox(height: 10),
        // Modo actual
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(_mode),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _mode == 'select'
                  ? '✦  Bienvenido · Selecciona tu acceso  ✦'
                  : _mode == 'admin'
                      ? '◆ Acceso Administrador ◆'
                      : '◆ Acceso Personal ◆',
              style: TextStyle(
                color: AppTheme.cream.withOpacity(0.72),
                fontSize: 12,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ornamentLine() => Container(
        width: 48,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppTheme.gold.withOpacity(0.65)],
          ),
        ),
      );

  Widget _miniDivider() => Container(
        width: 28,
        height: 1,
        color: AppTheme.gold.withOpacity(0.3),
      );

  Widget _buildContent() {
    switch (_mode) {
      case 'admin':
        return _buildAdminForm();
      case 'worker':
        return _buildWorkerForm();
      default:
        return _buildSelectCards();
    }
  }

  // ── Pantalla de selección de rol ───────────────────────────────────────────

  Widget _buildSelectCards() {
    return Column(
      key: const ValueKey('select'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassLoginCard(
          icon: Icons.people_alt_rounded,
          label: 'MOZOS / COCINA',
          subtitle: 'Ingresa con tu contraseña semanal',
          accentColor: AppTheme.primaryOrange,
          badgeText: 'PERSONAL',
          onTap: () => _setMode('worker'),
        ),
        const SizedBox(height: 16),
        _GlassLoginCard(
          icon: Icons.admin_panel_settings_rounded,
          label: 'ADMINISTRADOR',
          subtitle: 'Acceso con contraseña personal',
          accentColor: AppTheme.gold,
          badgeText: 'ADMIN',
          onTap: () => _setMode('admin'),
        ),
      ],
    );
  }

  // ── Formulario administrador ───────────────────────────────────────────────

  Widget _buildAdminForm() {
    return SingleChildScrollView(
      key: const ValueKey('admin'),
      child: _GlassFormCard(
        icon: Icons.admin_panel_settings_rounded,
        iconColor: AppTheme.gold,
        title: 'Acceso Administrador',
        children: [
          _styledTextField(
            controller: _pwdCtrl,
            label: 'Contraseña de administrador',
            prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.gold),
            accentColor: AppTheme.gold,
            onSubmitted: (_) => _doAdminLogin(),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorMsg!),
          ],
          const SizedBox(height: 20),
          _GlowButton(
            label: 'Entrar como Administrador',
            icon: Icons.login_rounded,
            color: AppTheme.gold,
            onPressed: _busy ? null : _doAdminLogin,
          ),
        ],
      ),
    );
  }

  // ── Formulario trabajador ──────────────────────────────────────────────────

  Widget _buildWorkerForm() {
    final state = context.watch<AppState>();
    final workers =
        state.registeredWorkers.where((w) => !w.isExpelled).toList();

    return SingleChildScrollView(
      key: const ValueKey('worker'),
      child: _GlassFormCard(
        icon: Icons.badge_rounded,
        iconColor: AppTheme.primaryOrange,
        title: 'Acceso Personal',
        children: [
          // Dropdown de nombre
          _styledDropdown(workers),

          if (workers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ErrorBanner(
                  message:
                      'No hay trabajadores disponibles. Contacta al administrador.'),
            ),

          // Si hay nombre seleccionado
          if (_selectedWorker != null) ...[
            const SizedBox(height: 14),
            if (_workerHasSession)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sesión activa  ·  Podés continuar sin contraseña',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _styledTextField(
                controller: _pwdCtrl,
                label: 'Contraseña semanal',
                hint: 'Solicítala al administrador',
                prefixIcon: const Icon(Icons.key_rounded,
                    color: AppTheme.primaryOrange),
                accentColor: AppTheme.primaryOrange,
                onSubmitted: (_) => _doWorkerLogin(),
              ),
          ],

          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorMsg!),
          ],

          if (_selectedWorker != null) ...[
            const SizedBox(height: 20),
            _GlowButton(
              label: _workerHasSession ? 'Continuar sesión' : 'Entrar',
              icon: _workerHasSession
                  ? Icons.play_circle_rounded
                  : Icons.login_rounded,
              color: AppTheme.primaryOrange,
              onPressed: _busy ? null : _doWorkerLogin,
            ),
          ],
        ],
      ),
    );
  }

  // ── Campo de texto estilizado ──────────────────────────────────────────────

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required Widget prefixIcon,
    required Color accentColor,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscure,
      autofocus: true,
      style: const TextStyle(color: AppTheme.textLight),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.black38,
        labelStyle: TextStyle(color: accentColor.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: accentColor.withOpacity(0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
              _obscure ? Icons.visibility : Icons.visibility_off,
              color: accentColor.withOpacity(0.7)),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }

  // ── Dropdown estilizado ────────────────────────────────────────────────────

  Widget _styledDropdown(List<RegisteredWorker> workers) {
    return DropdownButtonFormField<String>(
      value: _selectedWorker,
      dropdownColor: const Color(0xFF1A0800),
      style: const TextStyle(color: AppTheme.textLight),
      hint: const Text('Selecciona tu nombre',
          style: TextStyle(color: Colors.grey)),
      decoration: InputDecoration(
        labelText: 'Tu nombre',
        labelStyle:
            TextStyle(color: AppTheme.primaryOrange.withOpacity(0.9)),
        prefixIcon:
            const Icon(Icons.person, color: AppTheme.primaryOrange),
        filled: true,
        fillColor: Colors.black38,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppTheme.primaryOrange.withOpacity(0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.primaryOrange, width: 2),
        ),
      ),
      items: workers
          .map((w) => DropdownMenuItem(
                value: w.name,
                child: Row(
                  children: [
                    Icon(
                      w.role == UserRole.waiter
                          ? Icons.restaurant
                          : Icons.soup_kitchen,
                      size: 14,
                      color: w.role == UserRole.waiter
                          ? AppTheme.primaryOrange
                          : AppTheme.kitchenBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(w.name,
                        style:
                            const TextStyle(color: AppTheme.textLight)),
                  ],
                ),
              ))
          .toList(),
      onChanged: _pickWorker,
    );
  }
}

// ─── Tarjeta glass de selección de rol ───────────────────────────────────────

class _GlassLoginCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final String badgeText;
  final VoidCallback onTap;

  const _GlassLoginCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.badgeText,
    required this.onTap,
  });

  @override
  State<_GlassLoginCard> createState() => _GlassLoginCardState();
}

class _GlassLoginCardState extends State<_GlassLoginCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.black.withOpacity(0.40),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: widget.accentColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono con círculo degradado
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.accentColor.withOpacity(0.8),
                          widget.accentColor.withOpacity(0.25),
                        ],
                      ),
                      border: Border.all(
                          color: widget.accentColor.withOpacity(0.55),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: widget.accentColor.withOpacity(0.4),
                                    width: 0.8),
                              ),
                              child: Text(
                                widget.badgeText,
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flecha
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withOpacity(0.15),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        color: widget.accentColor.withOpacity(0.8), size: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contenedor glass de formulario ──────────────────────────────────────────

class _GlassFormCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _GlassFormCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.black.withOpacity(0.50),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: iconColor.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera del formulario
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          iconColor.withOpacity(0.3),
                          iconColor.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                          color: iconColor.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 34),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        iconColor.withOpacity(0.4),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón con efecto glow ────────────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _GlowButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onPressed == null
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : [
                    color,
                    Color.lerp(color, Colors.black, 0.25)!,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.55),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
          border: Border.all(
            color: onPressed == null
                ? Colors.transparent
                : color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.danger.withOpacity(0.18),
            ),
            child: const Icon(Icons.error_rounded, color: AppTheme.danger, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Orbe de luz decorativo ───────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Pintor de anillo punteado ornamental ────────────────────────────────────

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const dashCount = 24;
    const dashAngle = 2 * math.pi / dashCount;
    const gapRatio = 0.45;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      // pequeño diamante al inicio de cada guion
      if (i % 6 == 0) {
        final dotAngle = startAngle + sweepAngle / 2;
        final dx = center.dx + radius * math.cos(dotAngle);
        final dy = center.dy + radius * math.sin(dotAngle);
        final dotPaint = Paint()
          ..color = color.withOpacity(0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}
