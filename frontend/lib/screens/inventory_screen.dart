import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final items = data.items;

    final totalItems = items.length;
    final stockValue = items.fold<double>(0, (sum, i) {
      final qty = double.tryParse(i['quantity']?.toString() ?? '0') ?? 0;
      final cost = double.tryParse(i['cost_price']?.toString() ?? '0') ?? 0;
      return sum + (qty * cost);
    });
    final lowStock = items.where((i) => i['is_low_stock'] == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: RefreshIndicator(
        onRefresh: () => data.loadItems(),
        child: data.itemsLoading
            ? const LoadingWidget()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Total Items', '$totalItems'),
                        _statItem('Stock Value', CurrencyFormatter.compact(stockValue)),
                        _statItem('Low Stock', '$lowStock', isWarning: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search + Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryBlue),
                              onPressed: () => data.loadItems(search: _searchCtrl.text),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (v) => data.loadItems(search: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () => context.push('/inventory/sales-list'),
                          child: const Text('Sales List', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (items.isEmpty)
                    const EmptyWidget(message: 'No items yet', icon: Icons.inventory_2_outlined)
                  else
                    ...items.map((item) => _itemCard(item)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statItem(String label, String value, {bool isWarning = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: isWarning ? AppTheme.warningYellow : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final isLow = item['is_low_stock'] == true;
    final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    final sp = double.tryParse(item['selling_price']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isLow ? Border.all(color: AppTheme.errorRed.withOpacity(0.3)) : null,
      ),
      child: InkWell(
        onTap: () => context.push('/inventory/edit/${item['id']}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (isLow) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warningYellow, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(sp)} / ${item['unit'] ?? 'pcs'}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLow ? AppTheme.errorRed.withOpacity(0.1) : AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${qty.toStringAsFixed(0)} ${item['unit'] ?? ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLow ? AppTheme.errorRed : AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Item ─────────────────────────────────
class AddItemScreen extends StatefulWidget {
  final String? itemId;
  const AddItemScreen({super.key, this.itemId});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  String _unit = 'pcs';
  bool _saving = false;

  final _units = ['pcs', 'kg', 'litre', 'bag', 'box', 'meter', 'dozen'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemId != null ? 'Edit Item' : 'Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _unit = v!),
            ),
            const SizedBox(height: 14),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
            const SizedBox(height: 14),
            TextField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (NPR)', prefixText: 'NPR ')),
            const SizedBox(height: 14),
            TextField(controller: _sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (NPR)', prefixText: 'NPR ')),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Item', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final dp = context.read<DataProvider>();
    final itemData = {
      'name': _nameCtrl.text.trim(),
      'unit': _unit,
      'quantity': _qtyCtrl.text.trim(),
      'cost_price': _costCtrl.text.trim(),
      'selling_price': _sellCtrl.text.trim(),
    };

    bool success;
    if (widget.itemId != null) {
      success = await dp.updateItem(widget.itemId!, itemData);
    } else {
      success = await dp.createItem(itemData);
    }

    setState(() => _saving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item saved!'), backgroundColor: AppTheme.accentGreen));
      context.pop();
    }
  }
}

// ─── Stock Entry ─────────────────────────────────
class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  String? _selectedItemId;
  String _type = 'in';
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DataProvider>().loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedItemId,
              decoration: const InputDecoration(labelText: 'Select Item'),
              items: dp.items.map<DropdownMenuItem<String>>((i) {
                return DropdownMenuItem(value: i['id'].toString(), child: Text(i['name'] ?? ''));
              }).toList(),
              onChanged: (v) => setState(() => _selectedItemId = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _typeButton('Stock In', 'in', AppTheme.accentGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeButton('Stock Out', 'out', AppTheme.errorRed),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
            const SizedBox(height: 14),
            TextField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate (NPR)', prefixText: 'NPR ')),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Record Entry', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String label, String value, Color color) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.cardBorder),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedItemId == null) return;
    setState(() => _saving = true);
    final success = await context.read<DataProvider>().createStockEntry({
      'item_id': _selectedItemId,
      'type': _type,
      'quantity': _qtyCtrl.text.trim(),
      'rate': _rateCtrl.text.trim(),
      'date': DateFormatter.today(),
    });
    setState(() => _saving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock entry recorded!'), backgroundColor: AppTheme.accentGreen));
      context.pop();
    }
  }
}

// ─── Sales List (Quick Reference) ────────────────
class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final Map<String, int> _selectedQty = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DataProvider>().loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final items = dp.items;
    final selectedItems = items.where((i) => (_selectedQty[i['id'].toString()] ?? 0) > 0).toList();
    final grandTotal = selectedItems.fold<double>(0, (sum, i) {
      final qty = _selectedQty[i['id'].toString()] ?? 0;
      final price = double.tryParse(i['selling_price']?.toString() ?? '0') ?? 0;
      return sum + (qty * price);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales List'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.warningYellow.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warningYellow, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quick reference - not a bill',
                    style: TextStyle(fontSize: 13, color: AppTheme.warningYellow, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final id = item['id'].toString();
                final qty = _selectedQty[id] ?? 0;
                final stock = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                Color stockColor = stock < 10 ? AppTheme.errorRed : stock < 30 ? AppTheme.warningYellow : AppTheme.accentGreen;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: qty > 0 ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                Text(CurrencyFormatter.format(item['selling_price']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                const SizedBox(width: 8),
                                Text('CP: ${CurrencyFormatter.format(item['cost_price'])}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                              ],
                            ),
                            Text('Stock: ${stock.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: stockColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: qty > 0 ? () => setState(() => _selectedQty[id] = qty - 1) : null,
                            iconSize: 28,
                            color: AppTheme.errorRed,
                          ),
                          Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _selectedQty[id] = qty + 1),
                            iconSize: 28,
                            color: AppTheme.accentGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Column(
                children: [
                  ...selectedItems.map((i) {
                    final q = _selectedQty[i['id'].toString()]!;
                    final p = double.tryParse(i['selling_price']?.toString() ?? '0') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i['name']} × $q', style: const TextStyle(fontSize: 13)),
                          Text(CurrencyFormatter.format(q * p), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('This is a quick reference list, not an invoice or bill', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _selectedQty.clear()),
                    child: const Text('Clear', style: TextStyle(color: AppTheme.errorRed)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
