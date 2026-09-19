import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.sender;
  String _organizationType = 'hotel';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final success = await ref.read(authServiceProvider.notifier).registerUser(
          email: email,
          organizationName: name,
          organizationType: _organizationType,
          role: _selectedRole,
        );

    if (success && mounted) {
      if (_selectedRole == UserRole.sender) {
        context.go('/sender/dashboard');
      } else {
        context.go('/recipient/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Organization'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join the FoodBridge Network',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register your organization to prevent surplus waste or receive verified meals.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Role Selector Tabs
              const Text(
                'ORGANIZATION ROLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Food Provider'),
                      selected: _selectedRole == UserRole.sender,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRole = UserRole.sender;
                            _organizationType = 'hotel';
                          });
                        }
                      },
                      avatar: const Icon(Icons.restaurant, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Food Recipient'),
                      selected: _selectedRole == UserRole.recipient,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRole = UserRole.recipient;
                            _organizationType = 'community_kitchen';
                          });
                        }
                      },
                      avatar: const Icon(Icons.volunteer_activism, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _selectedRole == UserRole.sender
                      ? 'Business / Venue Name'
                      : 'NGO / Shelter Name',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Official Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _organizationType,
                decoration: const InputDecoration(
                  labelText: 'Organization Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: _selectedRole == UserRole.sender
                    ? const [
                        DropdownMenuItem(value: 'hotel', child: Text('Hotel / Resort')),
                        DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                        DropdownMenuItem(value: 'wedding_hall', child: Text('Wedding / Event Hall')),
                        DropdownMenuItem(value: 'college', child: Text('College / Hostel')),
                        DropdownMenuItem(value: 'caterer', child: Text('Catering Service')),
                      ]
                    : const [
                        DropdownMenuItem(value: 'community_kitchen', child: Text('Community Kitchen')),
                        DropdownMenuItem(value: 'shelter', child: Text('Homeless / Night Shelter')),
                        DropdownMenuItem(value: 'ngo', child: Text('Welfare NGO')),
                        DropdownMenuItem(value: 'old_age_home', child: Text('Old Age Home')),
                      ],
                onChanged: (val) {
                  if (val != null) setState(() => _organizationType = val);
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleRegister,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
