import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const EditProductPage({super.key, required this.productData});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _gramasiController = TextEditingController();

  Uint8List? _newImageBytes;
  String? _newImageName;
  String? _imageUrl;

  Uint8List? _newFileBytes;
  String? _newFileName;
  String? _fileUrl;

  bool _isFree = false;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.productData['nama_barang'] ?? '';
    _hargaController.text = widget.productData['harga'] ?? '';
    _deskripsiController.text = widget.productData['deskripsi'] ?? '';
    _gramasiController.text = widget.productData['gramasi']?.toString() ?? '0';
    _imageUrl = widget.productData['gambar_url'];
    _fileUrl = widget.productData['file_url'];
    _isFree = widget.productData['harga'] == "Gratis";
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
        _newImageName = 'uploads/product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _newFileBytes = result.files.single.bytes;
        _newFileName = 'uploads/file_${DateTime.now().millisecondsSinceEpoch}.${result.files.single.extension}';
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_newImageBytes == null || _newImageName == null) return _imageUrl;

    try {
      const bucketName = 'product-images';
      await supabase.storage.from(bucketName).uploadBinary(
            _newImageName!,
            _newImageBytes!,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );
      return supabase.storage.from(bucketName).getPublicUrl(_newImageName!);
    } catch (error) {
      print("Error upload image: $error");
      return null;
    }
  }

  Future<String?> _uploadFile() async {
    if (_newFileBytes == null || _newFileName == null) return _fileUrl;

    try {
      const bucketName = 'file-user';
      await supabase.storage.from(bucketName).uploadBinary(
            _newFileName!,
            _newFileBytes!,
            fileOptions: FileOptions(contentType: 'application/octet-stream'),
          );
      return supabase.storage.from(bucketName).getPublicUrl(_newFileName!);
    } catch (error) {
      print("Error upload file: $error");
      return null;
    }
  }

  Future<void> _updateProduct() async {
    if (_namaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nama barang tidak boleh kosong")));
      return;
    }

    if (!_isFree && _hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harga tidak boleh kosong")));
      return;
    }

    if (_gramasiController.text.isEmpty || int.tryParse(_gramasiController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gramasi harus berupa angka")));
      return;
    }

    final newImageUrl = await _uploadImage();
    final newFileUrl = await _uploadFile();

    final updateData = {
      'nama_barang': _namaController.text,
      'harga': _isFree ? "Gratis" : (_hargaController.text.isNotEmpty ? _hargaController.text : "Gratis"),
      'deskripsi': _deskripsiController.text,
      'gramasi': int.tryParse(_gramasiController.text) ?? 0,
      'gambar_url': newImageUrl,
      'file_url': newFileUrl,
    };

    print("Mengirim data ke Supabase: $updateData");

    try {
      final response = await supabase.from('barang').update(updateData).match({'id': widget.productData['id']});
      print("Response Supabase: $response");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Produk berhasil diperbarui")));
      Navigator.pop(context);
    } catch (error) {
      print("Error saat update: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memperbarui produk")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Produk")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _namaController, decoration: InputDecoration(labelText: "Nama Barang")),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("Gratis"),
                  selected: _isFree,
                  onSelected: (selected) => setState(() => _isFree = selected),
                ),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text("Custom Harga"),
                  selected: !_isFree,
                  onSelected: (selected) => setState(() => _isFree = !selected),
                ),
              ],
            ),

            if (!_isFree)
              TextField(controller: _hargaController, decoration: InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),

            TextField(controller: _deskripsiController, decoration: InputDecoration(labelText: "Deskripsi")),
            TextField(controller: _gramasiController, decoration: InputDecoration(labelText: "Gramasi"), keyboardType: TextInputType.number),

            ElevatedButton.icon(onPressed: _pickImage, icon: Icon(Icons.image), label: Text("Pilih Gambar")),
            if (_newImageBytes != null) Image.memory(_newImageBytes!, width: 120, height: 120),
            if (_imageUrl != null) Image.network(_imageUrl!, width: 120, height: 120),

            ElevatedButton.icon(onPressed: _pickFile, icon: Icon(Icons.file_upload), label: Text("Pilih File")),
            if (_newFileName != null) Text("File Baru: $_newFileName"),
            if (_fileUrl != null) Text("File Lama: $_fileUrl"),

            ElevatedButton.icon(onPressed: _updateProduct, icon: Icon(Icons.save), label: Text("Simpan Perubahan")),
          ],
        ),
      ),
    );
  }
}
