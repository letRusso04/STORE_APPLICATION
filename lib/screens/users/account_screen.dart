import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Supón que tienes este modelo User y AuthProvider en otros archivos
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/users/widgets/my_orders_screen.dart'
    hide baseUrl;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/account');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.currentUser?.role == 'admin') {
          context.go('/admin');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = user != null && user.role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: user?.profileImageUrl != null
                    ? CircleAvatar(
                        key: ValueKey(user!.profileImageUrl),
                        radius: 52,
                        backgroundImage: NetworkImage(
                          "$baseUrl${user.profileImageUrl!}",
                        ),
                      )
                    : const CircleAvatar(
                        key: ValueKey('placeholder'),
                        radius: 52,
                        backgroundImage: AssetImage(
                          'assets/images/profile_placeholder.png',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user?.name ?? 'Nombre del Usuario',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                user?.email ?? 'usuario@correo.com',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildListTile(
              icon: Icons.edit,
              text: 'Modificar datos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditUserScreen()),
              ),
            ),
            _buildListTile(
              icon: Icons.lock,
              text: 'Cambiar contraseña',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            _buildListTile(
              icon: Icons.list_alt,
              text: 'Mis pedidos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
            ),
            _buildListTile(
              icon: Icons.logout,
              text: 'Cerrar sesión',
              onTap: () {
                auth.logout();
                context.go('/login');
              },
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cuenta',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Administrar',
            ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.orangeAccent),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.orangeAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.orangeAccent),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      horizontalTitleGap: 0,
    );
  }
}

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController locationController;
  late TextEditingController phoneController;

  String? selectedEstado;

  File? _image;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final List<String> estados = [
    'Amazonas',
    'Anzoátegui',
    'Apure',
    'Aragua',
    'Barinas',
    'Bolívar',
    'Carabobo',
    'Cojedes',
    'Delta Amacuro',
    'Falcón',
    'Guárico',
    'Lara',
    'Mérida',
    'Miranda',
    'Monagas',
    'Nueva Esparta',
    'Portuguesa',
    'Sucre',
    'Táchira',
    'Trujillo',
    'La Guaira',
    'Yaracuy',
    'Zulia',
  ];

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    locationController = TextEditingController(text: user?.location ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    selectedEstado = user?.estado;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    emailController.dispose();
    locationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updateUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      location: locationController.text.trim(),
      phone: phoneController.text.trim(),
      estado: selectedEstado,
      profileImageFile: _image,
    );

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modificar datos')),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: CircleAvatar(
                    key: ValueKey(_image?.path ?? 'profile'),
                    radius: 52,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : const AssetImage(
                                'assets/images/profile_placeholder.png',
                              )
                              as ImageProvider,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildTextField(nameController, 'Nombre completo', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                emailController,
                'Correo electrónico',
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                locationController,
                'Ubicación',
                Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildPhoneField(
                phoneController,
                'Número de teléfono',
                Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildEstadoDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildPhoneField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 12),
            Text('+58', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            VerticalDivider(thickness: 1, width: 1),
            SizedBox(width: 8),
          ],
        ),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        prefixIcon: const Icon(Icons.map),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedEstado,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            setState(() {
              selectedEstado = newValue;
            });
          },
          items: estados.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          hint: const Text('Seleccione un estado'),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.changePassword(
      currentPassword: currentPasswordController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada con éxito')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la contraseña')),
        );
      }
    }
  }

  void _toggleVisibility(int field) {
    setState(() {
      if (field == 0) _obscureCurrent = !_obscureCurrent;
      if (field == 1) _obscureNew = !_obscureNew;
      if (field == 2) _obscureConfirm = !_obscureConfirm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Contraseña actual',
                  obscure: _obscureCurrent,
                  toggleVisibility: () => _toggleVisibility(0),
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'Nueva contraseña',
                  obscure: _obscureNew,
                  toggleVisibility: () => _toggleVisibility(1),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    if (val.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirmar contraseña',
                  obscure: _obscureConfirm,
                  toggleVisibility: () => _toggleVisibility(2),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    if (val != newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Actualizar contraseña',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator:
          validator ??
          (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
