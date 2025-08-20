import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class PayToContactsPage extends StatefulWidget {
  @override
  _PayToContactsPageState createState() => _PayToContactsPageState();
}

class _PayToContactsPageState extends State<PayToContactsPage> {
  List<Contact>? contacts;
  bool loading = true;
  bool permissionDenied = false;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    var status = await Permission.contacts.request();
    if (status.isGranted) {
      final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = fetchedContacts;
        loading = false;
        permissionDenied = false;
      });
    } else {
      setState(() {
        loading = false;
        permissionDenied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay to Contacts'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : permissionDenied
              ? Center(child: Text('Permission denied. Please enable contacts permission.'))
              : contacts == null || contacts!.isEmpty
                  ? Center(child: Text('No contacts found.'))
                  : ListView.builder(
                      itemCount: contacts!.length,
                      itemBuilder: (context, index) {
                        final contact = contacts![index];
                        return ListTile(
                          leading: (contact.photo == null || contact.photo!.isEmpty)
                              ? CircleAvatar(child: Icon(Icons.person))
                              : CircleAvatar(backgroundImage: MemoryImage(contact.photo!)),
                          title: Text(contact.displayName),
                          subtitle: contact.phones.isNotEmpty
                              ? Text(contact.phones.first.number)
                              : Text('No phone number'),
                          onTap: () {
                            // TODO: Implement pay to contact logic
                          },
                        );
                      },
                    ),
    );
  }
}
