import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/factory_profile/factory_profile_bloc.dart';
import '../../../data/services/export/business_card_pdf_service.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../widgets/business_card/business_card_preview_widget.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({
    super.key,
    this.factoryProfile,
  });

  final FactoryProfile? factoryProfile;

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8860B);

  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    if (widget.factoryProfile == null) {
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final factoryId = user?.factoryId;
      if (factoryId != null && factoryId.isNotEmpty) {
        context.read<FactoryProfileBloc>().add(FactoryProfileWatchStarted(factoryId));
      }
    }
  }

  Future<void> _handlePrintA4(FactoryProfile profile) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await BusinessCardPdfService.generateA4PrintSheet(profile);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'BusinessCards_${profile.identity.businessName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSharePdf(FactoryProfile profile) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await BusinessCardPdfService.generateA4PrintSheet(profile);
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'BusinessCards_${profile.identity.businessName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handlePrintSingle(FactoryProfile profile) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await BusinessCardPdfService.generateSingleCardPdf(profile);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'BusinessCard_${profile.identity.businessName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Generator'),
      ),
      body: widget.factoryProfile != null
          ? _buildCardView(widget.factoryProfile!)
          : BlocBuilder<FactoryProfileBloc, FactoryProfileState>(
              builder: (context, state) {
                if ((state.status == FactoryProfileStatus.loading ||
                        state.status == FactoryProfileStatus.initial) &&
                    state.profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
                    ),
                  );
                }

                if (state.profile == null) {
                  return const EmptyStateView(
                    icon: Icons.business_rounded,
                    title: 'No Factory Profile Found',
                    subtitle:
                        'Please create or set up your business profile first.',
                  );
                }

                return _buildCardView(state.profile!);
              },
            ),
    );
  }

  Widget _buildCardView(FactoryProfile profile) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Card Info Surface
              DashboardSurfaceCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: goldDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.identity.businessName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Standard 3.5" x 2.0" Onyx & Gold Edition',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Interactive Flip Preview Widget (Width 460)
              BusinessCardPreviewWidget(
                profile: profile,
                width: 460,
              ),

              const SizedBox(height: 32),

              // Export & Print Actions Surface
              DashboardSurfaceCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.print_rounded,
                          color: goldDark,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Print & Export Options',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a high-resolution A4 print sheet containing 10 grid-aligned cards with crop lines for easy local cutting.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Primary Action: Print A4 Grid
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPdf
                            ? null
                            : () => _handlePrintA4(profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldAccent,
                          foregroundColor: const Color(0xFF141414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF141414)),
                                ),
                              )
                            : const Icon(Icons.grid_on_rounded, size: 22),
                        label: const Text(
                          'PRINT 10-CARD A4 SHEET',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Secondary Action Buttons: Share & Single Card
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _handleSharePdf(profile),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: goldDark,
                              side: BorderSide(
                                color: goldDark.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 19),
                            label: const Text(
                              'Share A4 PDF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _handlePrintSingle(profile),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              side: BorderSide(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                size: 19),
                            label: const Text(
                              'Single Card',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
