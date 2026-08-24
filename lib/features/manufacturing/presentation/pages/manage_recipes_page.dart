import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class _Recipe {
  final String name;
  final List<String> ingredients;
  final String yield;
  final double estimatedCost;

  const _Recipe({
    required this.name,
    required this.ingredients,
    required this.yield,
    required this.estimatedCost,
  });
}

class ManageRecipesPage extends StatefulWidget {
  const ManageRecipesPage({super.key});

  @override
  State<ManageRecipesPage> createState() => _ManageRecipesPageState();
}

class _ManageRecipesPageState extends State<ManageRecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<_Recipe> _recipes = [
    _Recipe(name: 'Basic Tee', ingredients: ['Cotton Fabric (White)', 'Polyester Thread', 'Elastic Band'], yield: '1 unit', estimatedCost: 4500),
    _Recipe(name: 'Slim Fit Denim', ingredients: ['Denim Fabric', 'Zipper (Metal)', 'Button (Plastic)', 'Polyester Thread'], yield: '1 unit', estimatedCost: 12000),
    _Recipe(name: 'Winter Hoodie', ingredients: ['Cotton Fabric (White)', 'Polyester Thread', 'Elastic Band', 'Zipper (Metal)'], yield: '1 unit', estimatedCost: 9000),
    _Recipe(name: 'Casual Linen', ingredients: ['Linen Fabric', 'Sewing Needles', 'Silk Thread'], yield: '1 unit', estimatedCost: 7000),
    _Recipe(name: 'Active Shorts', ingredients: ['Cotton Fabric (White)', 'Elastic Band', 'Polyester Thread'], yield: '1 unit', estimatedCost: 3500),
    _Recipe(name: 'Silk Scarf', ingredients: ['Silk Thread', 'Fabric Dye (Blue)', 'Bleach Solution'], yield: '2 units', estimatedCost: 5000),
  ];

  int get _totalCount => _recipes.length;

  List<_Recipe> get _filteredRecipes {
    if (_searchQuery.isEmpty) return _recipes;
    return _recipes.where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSummarySection(),
                    const SizedBox(height: 14),
                    _buildActionButtons(context),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _filteredRecipes.isEmpty ? _buildEmptyState() : _buildRecipesList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Text('Manage Recipes', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: _buildSummaryCard(
        label: 'All Recipes',
        amount: _totalCount.toString(),
        color: AppColors.primary,
        bgColor: const Color(0xFFEBF2FF),
        icon: Icons.receipt_long_rounded,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 4),
            SizedBox(height: 18, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(amount, style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => AppFilterDialog.show(context),
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: Text('Filter', style: AppTypography.buttonLarge.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/manufacturing/recipes/create'),
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.textWhite),
                label: Text('New Recipe', style: AppTypography.buttonLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController, style: AppTypography.bodyMedium,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search recipes by name...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                child: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesList() {
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      itemCount: _filteredRecipes.length,
      itemBuilder: (ctx, i) => _buildRecipeCard(_filteredRecipes[i]),
    );
  }

  Widget _buildRecipeCard(_Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Yield: ${recipe.yield}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                child: Text(_fmt(recipe.estimatedCost), style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 10)),
              ),
            ],
          ),
          const Divider(height: 20),
          Text('Ingredients', style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: recipe.ingredients.map((ing) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6)),
              child: Text(ing, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/manufacturing/recipes/edit', extra: {
                  'name': recipe.name,
                  'yieldAmount': recipe.yield,
                  'ingredients': recipe.ingredients,
                  'estimatedCost': recipe.estimatedCost,
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(recipe.name),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_rounded, size: 14, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
            const SizedBox(height: 20),
            Text('No Recipes Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tap "New Recipe" to get started.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String recipeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 18)),
          const SizedBox(width: 10),
          Text('Delete Recipe', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        ]),
        content: Text('Are you sure you want to delete "$recipeName"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Delete', style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return 'Tsh ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
