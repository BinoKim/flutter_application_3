// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ItemListPage(),
    );
  }
}

// ----- 공통 유틸 -----
final NumberFormat wonFmt = NumberFormat('#,###');
String formatWon(int v) => '${wonFmt.format(v)} 원';

// ----- 데이터 모델 -----
class Product {
  final String name;
  final int price;
  final String description;
  final String? imagePath;
  Product({
    required this.name,
    required this.price,
    required this.description,
    this.imagePath,
  });
  Product copyWith({
    String? name,
    int? price,
    String? description,
    String? imagePath,
  }) {
    return Product(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});
}

// 상세 → 메인으로 되돌릴 액션
enum DetailAction { none, updated, deleted }
class ProductDetailResult {
  final DetailAction action;
  final Product? product; // updated일 때
  const ProductDetailResult({required this.action, this.product});
}

// 상세 → 메인으로 되돌릴 장바구니 담기 결과
class _AddToCartResult {
  final Product product;
  final int qty;
  _AddToCartResult({required this.product, required this.qty});
}

// ----- 공용 위젯 -----
class RoundedThumb extends StatelessWidget {
  const RoundedThumb({super.key, this.path, this.size = 200});
  final String? path;
  final double size;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: path == null
            ? const Icon(Icons.image, color: Colors.grey, size: 36)
            : Image.file(File(path!), fit: BoxFit.cover),
      ),
    );
  }
}

// ----- 메인: 리스트 + 등록 + 상세 + 장바구니 -----
class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});
  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final List<Product> _products = [
    Product(name: '첫사랑 향수', price: 128000, description: '그 시절의 향기를 담은…'),
    Product(name: '초등학교 소풍 패키지', price: 15900, description: '김밥+과자+쥬스 세트'),
  ];
  final List<CartItem> _cart = [];

  Future<void> _goToAddPage() async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const EditProductPage()),
    );
    if (result != null) setState(() => _products.add(result));
  }

  Future<void> _goDetail(Product p, int index) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
    );

    // 장바구니 담기
    if (res is _AddToCartResult) {
      _addToCart(res.product, res.qty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장바구니에 담았습니다: ${res.product.name} x${res.qty}')),
      );
      return;
    }

    // 수정/삭제
    if (res is ProductDetailResult) {
      switch (res.action) {
        case DetailAction.updated:
          if (res.product != null) {
            setState(() => _products[index] = res.product!);
          }
          break;
        case DetailAction.deleted:
          setState(() => _products.removeAt(index));
          break;
        case DetailAction.none:
          break;
      }
    }
  }

  void _addToCart(Product p, int qty) {
    final idx = _cart.indexWhere((e) => e.product.name == p.name);
    if (idx == -1) {
      _cart.add(CartItem(product: p, qty: qty));
    } else {
      _cart[idx].qty += qty;
    }
    setState(() {});
  }

  Future<void> _openCart() async {
    final updated = await Navigator.push<List<CartItem>>(
      context,
      MaterialPageRoute(builder: (_) => CartPage(items: List<CartItem>.from(_cart))),
    );
    if (updated != null) {
      setState(() {
        _cart
          ..clear()
          ..addAll(updated);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _products.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MEMORY MARKET',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '장바구니',
            onPressed: _openCart,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_cart.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: isEmpty
          ? const Center(
              child: Text(
                '판매할 추억을 등록해 주세요!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.separated(
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _products[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: InkWell(
                    onTap: () => _goDetail(p, i),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundedThumb(path: p.imagePath, size: 200),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(p.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 120),
                              Text(formatWon(p.price),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // itemBuilder: (_, i) {
              //   final p = _products[i];
              //   return ListTile(
              //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //     leading: RoundedThumb(path: p.imagePath),
              //     title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              //     subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              //     trailing: Text(formatWon(p.price)),
              //     onTap: () => _goDetail(p, i),
              //   );
              // },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ----- 상세 페이지: 수정/삭제 + 장바구니 담기 -----
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int qty = 1;
  void _inc() => setState(() => qty++);
  void _dec() => setState(() { if (qty > 1) qty--; });

  Future<void> _edit() async {
    final edited = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => EditProductPage(initial: widget.product)),
    );
    if (edited != null) {
      Navigator.pop(
        context,
        ProductDetailResult(action: DetailAction.updated, product: edited),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      Navigator.pop(context, const ProductDetailResult(action: DetailAction.deleted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final total = p.price * qty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 상세'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: p.imagePath == null
                        ? const Center(child: Icon(Icons.image, size: 48, color: Colors.grey))
                        : Image.file(File(p.imagePath!), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatWon(p.price),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('상품 설명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(p.description, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: _dec, splashRadius: 20),
                        Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        IconButton(icon: const Icon(Icons.add), onPressed: _inc, splashRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '총 가격: ${formatWon(total)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _AddToCartResult(product: p, qty: qty));
                      },
                      child: const Text('장바구니 담기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----- 등록/수정 공용 페이지 -----
class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key, this.initial});
  final Product? initial;
  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _imagePath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.price.toString();
      _descCtrl.text = p.description;
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        name: _nameCtrl.text.trim(),
        price: int.parse(_priceCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        imagePath: _imagePath,
      );
      Navigator.pop(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '상품 수정' : '상품 등록')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text('상품 이미지 추가 (탭해서 선택)', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : Image.file(File(_imagePath!), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('상품 이름', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(border: OutlineInputBorder(), hintText: '예) 첫사랑 향수'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '상품 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              const Text('상품 가격', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 12000',
                  suffixText: '원',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '가격을 입력하세요';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return '숫자로 입력하세요';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('상품 설명', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 6,
                decoration:
                    const InputDecoration(border: OutlineInputBorder(), hintText: '설명을 입력하세요'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '상품 설명을 입력하세요' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEdit ? '수정 완료' : '등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- 장바구니 -----
class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.items});
  final List<CartItem> items;
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<CartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items; // 참조 사용(데모 용)
  }

  void _inc(int i) => setState(() => _items[i].qty++);
  void _dec(int i) => setState(() { if (_items[i].qty > 1) _items[i].qty--; });
  void _remove(int i) => setState(() => _items.removeAt(i));
  int get _total => _items.fold(0, (s, e) => s + e.product.price * e.qty);

  @override
  Widget build(BuildContext context) {
    final isEmpty = _items.isEmpty;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _items);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('장바구니'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _items),
          ),
        ),
        body: isEmpty
            ? const Center(
                child: Text(
                  '장바구니가 비어있습니다.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              )
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final p = item.product;
                  final lineTotal = p.price * item.qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RoundedThumb(path: p.imagePath, size: 72),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: '삭제',
                                    onPressed: () => _remove(i),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => _dec(i),
                                          splashRadius: 18,
                                        ),
                                        Text(
                                          '${item.qty}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => _inc(i),
                                          splashRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                  //const SizedBox(width: 12),
                                  Spacer(),
                                  Text(
                                    formatWon(lineTotal),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        bottomNavigationBar: isEmpty
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '총 ${formatWon(_total)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('구매하기: 총 ${formatWon(_total)} (${_items.length}종)'),
                              ),
                            );
                          },
                          child: const Text('구매하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
