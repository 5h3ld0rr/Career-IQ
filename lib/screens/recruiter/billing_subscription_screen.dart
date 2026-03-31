import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_snackbar.dart';
import 'payment_checkout_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillingSubscriptionScreen extends StatefulWidget {
  const BillingSubscriptionScreen({super.key});

  @override
  State<BillingSubscriptionScreen> createState() => _BillingSubscriptionScreenState();
}

class _BillingSubscriptionScreenState extends State<BillingSubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to Pro
  int _currentPlanIndex = 0; // The actual active plan
  bool _isYearly = false;

  final List<Map<String, dynamic>> _billingHistory = [
    {
      'date': 'Oct 1, 2026',
      'amount': '\$10.00',
      'plan': 'Pro Plan',
      'status': 'Paid',
      'invoice': '#INV-10293'
    },
    {
      'date': 'Sep 1, 2026',
      'amount': '\$10.00',
      'plan': 'Pro Plan',
      'status': 'Paid',
      'invoice': '#INV-09827'
    },
    {
      'date': 'Aug 1, 2026',
      'amount': '\$0.00',
      'plan': 'Free Tier',
      'status': 'Paid',
      'invoice': '#INV-08731'
    },
  ];

  Future<void> _generateAndDownloadInvoice(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CareerIQ Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.Text('Recruiter Account'),
                        pw.Text('CareerIQ User'),
                      ]
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Invoice #: ${invoice['invoice']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Date: ${invoice['date']}"),
                      ]
                    ),
                  ]
                ),
                pw.SizedBox(height: 40),
                pw.Text('Subscription Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Plan: ${invoice['plan']}"),
                      pw.Text("Status: ${invoice['status']}", style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL DUE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Text(invoice['amount'] as String, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                pw.Text('Thank you for choosing CareerIQ!', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                pw.Text('For support, contact billing@careeriq.com', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: "${invoice['invoice']}.pdf");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      appBar: AppBar(
        title: Text(
          'Billing & Subscription',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUsageTracker(theme, isDark),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upgrade Your Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isYearly = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: !_isYearly ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Monthly',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_isYearly ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isYearly = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isYearly ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Yearly',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isYearly ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Save \$20',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPricingPlans(theme, isDark),
              const SizedBox(height: 32),
              
              Text(
                'Billing History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildBillingHistory(theme, isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTracker(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Plan: FREE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'AI Candidates Match limit this month',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 15 / 50,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '15/50 Used',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                AppSnackBar.show('Add-on store opening...');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch_rounded, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Boost AI Limit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPricingPlans(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildPlanCard(0, 'Free', '\$0', _isYearly ? '/yr' : '/mo', ['Unlimited Jobs', '50 AI Matches/mo', 'Standard Support'], theme, isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildPlanCard(1, 'Pro', _isYearly ? '\$100' : '\$10', _isYearly ? '/yr' : '/mo', ['Unlimited Jobs', 'Unlimited AI Matches', 'Priority Support'], theme, isDark)),
      ],
    );
  }

  Widget _buildPlanCard(int index, String title, String price, String period, List<String> features, ThemeData theme, bool isDark) {
    final isSelected = _selectedPlanIndex == index;
    final isCurrentPlan = _currentPlanIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentPlan
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : (isSelected 
                  ? theme.colorScheme.primary.withValues(alpha: 0.15) 
                  : AppTheme.getGlassColor(context).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : (isCurrentPlan ? theme.colorScheme.primary.withValues(alpha: 0.3) : AppTheme.getGlassBorderColor(context)),
            width: isSelected ? 2 : (isCurrentPlan ? 1.5 : 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCurrentPlan)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('CURRENT PLAN', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w900)),
                  )
                else if (title == 'Pro')
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('RECOMMENDED', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : () async {
                   setState(() => _selectedPlanIndex = index);
                   final bool? paymentSuccess = await Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => PaymentCheckoutScreen(
                         planTitle: title,
                         planPrice: price,
                         period: period,
                       ),
                     ),
                   );
                   if (paymentSuccess == true) {
                     setState(() {
                       _currentPlanIndex = index;
                     });
                     AppSnackBar.show('Successfully upgraded to $title plan! 🚀');
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.05) 
                    : (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                  foregroundColor: isCurrentPlan 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4) 
                    : (isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(isCurrentPlan ? 'Current Plan' : (isSelected ? 'Selected' : 'Select Plan'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingHistory(ThemeData theme, bool isDark) {
    if (_billingHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No billing history available')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getGlassBorderColor(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              ..._billingHistory.map((invoice) {
                final isLast = invoice == _billingHistory.last;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        AppSnackBar.show("Preparing ${invoice['invoice']}...");
                        await _generateAndDownloadInvoice(invoice);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        invoice['plan'],
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          invoice['status'],
                                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${invoice['invoice']} • ${invoice['date']}",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  invoice['amount'],
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Icon(Icons.file_download_outlined, color: theme.colorScheme.primary, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 70),
                  ],
                );
              }),
              Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              InkWell(
                onTap: () {
                  AppSnackBar.show('Opening all invoices...');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'View All Invoices',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
