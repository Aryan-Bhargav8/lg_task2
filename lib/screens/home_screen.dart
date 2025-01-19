import 'package:flutter/material.dart';
import 'package:lg_task2/connections/ssh.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text('LG App Demo'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              })
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async{
                  // Add logic to send logo
                  SSH ssh = SSH();
                  await ssh.connectToLG();
                  print('sending logo');
                  await ssh.sendLogo();
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Send Logo',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Add logic to remove logo
                  SSH ssh = SSH();
                  await ssh.connectToLG();
                  print('removing logo');
                  await ssh.cleanSlaves();

                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Clear Logo',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Add logic to send US KML
                  SSH ssh = SSH();
                  await ssh.connectToLG();
                  await ssh.sendKML('US_State_Polygons');
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'US States KML',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async{
                  SSH ssh = SSH();
                  await ssh.connectToLG();

                  await ssh.sendModel();
                  print('sending 3D house');

                  // Add logic to send logo
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    '3D House KML',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async{
                  SSH ssh = SSH();
                  await ssh.connectToLG();
                  await ssh.clearKML();

                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Clear KML',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
