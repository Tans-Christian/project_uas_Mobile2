import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_page.dart';
import 'UploadProductPage.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  String? _userEmail;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _fetchProducts();
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthPage()));
      }
    } else {
      setState(() {
        _userEmail = session.user.email;
      });
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final List<dynamic> response = await supabase.from('barang').select();
      setState(() {
        _products = response.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching products: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil produk, coba lagi!")),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthPage()));
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductPage(barang: product)),
    );
  }

  void _navigateToUploadProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadProductPage()),
    ).then((_) => _fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Produk", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(_userEmail ?? "Loading...", style: TextStyle(fontSize: 14)),
            ),
          ),
          _isLoggingOut
              ? Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _logout,
                ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(child: Text("Belum ada produk."))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final String? imageUrl = product['gambar_url'];

                      return GestureDetector(
                        onTap: () => _navigateToProductDetail(product),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.broken_image, size: 60, color: Colors.grey);
                                          },
                                        )
                                      : Container(
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['nama_barang'],
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      product['harga'] == "Gratis" ? "Gratis" : "Rp ${product['harga']}",
                                      style: TextStyle(fontSize: 14, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUploadProduct,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
