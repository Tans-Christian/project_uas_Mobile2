import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadProductPage extends StatefulWidget {
  const UploadProductPage({super.key});

  @override
  _UploadProductPageState createState() => _UploadProductPageState();
}

class _UploadProductPageState extends State<UploadProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  Uint8List? _imageBytes;
  String? _gambarUrl;
  String? _imageFileName;

  Uint8List? _fileBytes;
  String? _fileUrl;
  String? _fileUploadedName;

  /// **🔹 Memilih Gambar dari Galeri**
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  /// **🔹 Mengunggah Gambar ke Supabase**
  Future<void> _uploadImage() async {
    if (_imageBytes == null || _imageFileName == null) return;

    try {
      const bucketName = 'product-images';
      final filePath = 'uploads/$_imageFileName'; // Path untuk Supabase

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            _imageBytes!,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);

      setState(() {
        _gambarUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gambar berhasil diunggah")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengunggah gambar: $error")),
      );
    }
  }

  /// **🔹 Memilih File dari Penyimpanan**
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileUploadedName =
            'file_${DateTime.now().millisecondsSinceEpoch}.${result.files.single.extension}';
      });
    }
  }

  /// **🔹 Mengunggah File ke Supabase**
  Future<void> _uploadFile() async {
    if (_fileBytes == null || _fileUploadedName == null) return;

    try {
      const bucketName = 'file-user';
      final filePath = 'uploads/$_fileUploadedName'; // Path penyimpanan

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            _fileBytes!,
            fileOptions: FileOptions(contentType: 'application/octet-stream'),
          );

      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);

      setState(() {
        _fileUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File berhasil diunggah")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengunggah file: $error")),
      );
    }
  }

  /// **🔹 Menambahkan Produk ke Database**
  Future<void> _uploadProduct() async {
    if (_namaController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _stokController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap isi semua data")),
      );
      return;
    }

    final int? stokValue = int.tryParse(_stokController.text);
    if (stokValue == null || stokValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stok harus berupa angka positif")),
      );
      return;
    }

    try {
      await _uploadImage();
      await _uploadFile();

      await supabase.from('barang').insert({
        'nama_barang': _namaController.text,
        'harga': _hargaController.text.isNotEmpty ? _hargaController.text : "Gratis",
        'deskripsi': _deskripsiController.text,
        'stok': stokValue,
        'gambar_url': _gambarUrl,
        'file_url': _fileUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Produk berhasil ditambahkan")),
      );
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Tambah Produk", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_namaController, "Nama Barang", Icons.shopping_cart),
            _buildTextField(_hargaController, "Harga", Icons.attach_money),
            _buildTextField(_deskripsiController, "Deskripsi", Icons.description, maxLines: 3),
            _buildTextField(_stokController, "Stok", Icons.storage, keyboardType: TextInputType.number),

            SizedBox(height: 15),

            _buildImagePicker(),

            SizedBox(height: 15),

            _buildFilePicker(),

            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _uploadProduct,
              icon: Icon(Icons.cloud_upload),
              label: Text("Tambah Produk", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return _buildPicker(Icons.image, "Pilih Gambar", _pickImage, _imageBytes);
  }

  Widget _buildFilePicker() {
    return _buildPicker(Icons.file_present, "Pilih File", _pickFile, _fileBytes);
  }

  Widget _buildPicker(IconData icon, String title, VoidCallback onTap, Uint8List? file) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        trailing: IconButton(icon: Icon(Icons.upload_file, color: Colors.teal), onPressed: onTap),
      ),
    );
  }
}
