import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class ServicesProviderScreen extends StatefulWidget {
  const ServicesProviderScreen({Key? key}) : super(key: key);

  @override
  State<ServicesProviderScreen> createState() => _ServicesProviderScreenState();
}

class _ServicesProviderScreenState extends State<ServicesProviderScreen> {
  List<Map<String, dynamic>> services = [
    {
      'name': 'Makeup',
      'description': 'Bridal makeup full package',
      'price': '150'
    },
    {
      'name': 'Photography',
      'description': 'Full wedding day shoot',
      'price': '500'
    },
  ];

  void _showServiceForm({Map<String, dynamic>? service, int? index}) {
    final TextEditingController nameController =
        TextEditingController(text: service != null ? service['name'] : '');
    final TextEditingController descController = TextEditingController(
        text: service != null ? service['description'] : '');
    final TextEditingController priceController = TextEditingController(
        text: service != null ? service['price'].toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service == null ? 'Add Service' : 'Edit Service',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
              ),
              onPressed: () {
                final newService = {
                  'name': nameController.text,
                  'description': descController.text,
                  'price': priceController.text,
                };
                setState(() {
                  if (index != null) {
                    services[index] = newService;
                  } else {
                    services.add(newService);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                service == null ? 'Add' : 'Save',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _deleteService(int index) {
    setState(() {
      services.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () => _showServiceForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              title: Text(
                service['name'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${service['description']}\nPrice: \$${service['price']}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    onPressed: () => _showServiceForm(
                      service: service,
                      index: index,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteService(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
