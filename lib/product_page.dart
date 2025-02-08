import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_product.dart';
import 'home_page.dart';
import 'full_screen_image.dart'; // Tambahkan ini jika FullScreenImage ada di file terpisah

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> barang;

  const ProductPage({super.key, required this.barang});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  late List<String> imageList;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _prepareImageList();
  }

  void _prepareImageList() {
    final gambarListData = widget.barang['gambar_list'];

    if (gambarListData is List) {
      imageList = List<String>.from(gambarListData.map((e) => e.toString()));
    } else {
      imageList = [];
    }

    if (widget.barang['gambar_url'] != null && widget.barang['gambar_url'].isNotEmpty) {
      imageList.insert(0, widget.barang['gambar_url']);
    }

    imageList = imageList.take(10).toList();
  }

  Future<void> _deleteProduct() async {
    final bool confirmDelete = await _showDeleteConfirmationDialog();
    if (!confirmDelete) return;

    setState(() => _isDeleting = true);

    try {
      await supabase.from('barang').delete().match({'id': widget.barang['id']});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Produk berhasil dihapus")));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus produk")));
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Konfirmasi Hapus"),
            content: Text("Apakah Anda yakin ingin menghapus produk ini?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Batal")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Hapus"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.barang['nama_barang'] ?? "Produk")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageList.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 250.0,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      autoPlayAnimationDuration: Duration(milliseconds: 800),
                      viewportFraction: 0.8,
                    ),
                    items: imageList.map((imageUrl) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FullScreenImage(imageUrl: imageUrl)),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 100),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text(
              widget.barang['nama_barang'] ?? "Tanpa Nama",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.barang['harga'] == "Gratis" ? "Gratis" : "Rp ${widget.barang['harga']}",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Deskripsi:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.barang['deskripsi'] ?? "Tidak ada deskripsi",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (widget.barang['file_url'] != null && widget.barang['file_url'].isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri url = Uri.parse(widget.barang['file_url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka file")));
                  }
                },
                icon: Icon(Icons.download),
                label: Text("Download File"),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
              ),
            SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProductPage(productData: widget.barang)),
                    ),
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text("Edit Produk", style: TextStyle(color: Colors.blue)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 10),
                  _isDeleting
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _deleteProduct,
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text("Hapus Produk"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
