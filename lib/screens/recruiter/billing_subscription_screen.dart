import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BillingSubscriptionScreen extends StatefulWidget {
  const BillingSubscriptionScreen({super.key});

  @override
  State<BillingSubscriptionScreen> createState() => _BillingSubscriptionScreenState();
}

class _BillingSubscriptionScreenState extends State<BillingSubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to Pro
  final int _currentPlanIndex = 0; // The actual active plan
  bool _isYearly = false;

  final List<Map<String, dynamic>> _billingHistory = [
    {
      'date': 'Oct 1, 2026',
      'amount': '\$19.00',
      'status': 'Paid',
      'invoice': '#INV-10293'
    },
    {
      'date': 'Sep 1, 2026',
      'amount': '\$19.00',
      'status': 'Paid',
      'invoice': '#INV-09827'
    },
  ];

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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add-on store opening...')));
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
                onPressed: isCurrentPlan ? null : () {
                   setState(() => _selectedPlanIndex = index);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to $title plan!')));
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
            children: _billingHistory.map((invoice) {
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      invoice['invoice'],
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    subtitle: Text(
                      invoice['date'],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          invoice['amount'],
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Text(
                          invoice['status'],
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading invoice pdf...')));
                    },
                  ),
                  if (invoice != _billingHistory.last)
                    Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 70),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
