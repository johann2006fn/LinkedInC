import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';


class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _collegeCodeController = TextEditingController();
  final _idController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _collegeCodeController.dispose();
    _idController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final collegeCode = _collegeCodeController.text.trim();
    final identityId = _idController.text.trim();
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();

    if (collegeCode.isEmpty || identityId.isEmpty || inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser?.uid;

      if (uid == null) throw Exception('User not authenticated');

      final success = await authService.verifyCollegeIdentity(
        collegeCode: collegeCode,
        identityId: identityId,
        inviteCode: inviteCode,
        uid: uid,
      );

      if (success && mounted) {
        // Refresh the user provider to get the updated status
        ref.invalidate(currentUserProvider);
        context.go('/role-selection');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Prevents double back-press
        if (_isLoading) return;
        
        setState(() => _isLoading = true);
        
        try {
          // Robust sign out to ensure account picker shows next time
          await ref.read(authServiceProvider).signOut();
          
          if (context.mounted) {
            context.go('/welcome');
          }
        } catch (e) {
          if (mounted) {
            context.go('/welcome');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: Scaffold(
        body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Campus Access',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your identity to join your college network.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(
                  controller: _collegeCodeController,
                  label: 'College Code',
                  hint: 'e.g., SFIT-2026',
                  icon: Icons.school_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _idController,
                  label: 'Roll No / Faculty ID',
                  hint: 'e.g., 401',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _inviteCodeController,
                  label: '6-Digit Invite Code',
                  hint: 'UNIQUE KEY',
                  icon: Icons.key_outlined,
                  textCapitalization: TextCapitalization.characters,
                  isLast: true,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify Identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: (_) =>
              isLast ? _verify() : FocusScope.of(context).nextFocus(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
