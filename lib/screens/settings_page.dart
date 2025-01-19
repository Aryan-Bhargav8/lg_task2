import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lg_task2/connections/ssh.dart';
import 'package:dartssh2/dartssh2.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  //to pass the inputs from TextFormField to the SSH class we use TextEditingController here
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // this saves the connection status
  bool connectionStatus = false;

  // create an instance of the SSH class so that we can check the instance of the SSH class and use the saved instance of the Connection Settings used
  late SSH ssh;

  //
  Future<void> _connectToLG() async {
    bool? result = await ssh.connectToLG();
    setState(() {
      connectionStatus = result!;
    });
  }
  //Snackbar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: connectionStatus ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void initState(){// initialize the widget
    super.initState();
    _loadSettings(); // load the settings when the widget is created
    ssh = SSH(); //  initialization instance of the SSH class
    _connectToLG(); //Calluing this function to connect to the Liquid Galaxy when the widget is created iff it is present in shared preferences
  }


  @override
  void dispose() { // dispose the controllers when the widget is removed
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostController.text = prefs.getString('ipAddress') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _portController.text = prefs.getString('sshPort') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_hostController.text.isNotEmpty) {
      await prefs.setString('ipAddress', _hostController.text);
    }
    if (_usernameController.text.isNotEmpty) {
      await prefs.setString('username', _usernameController.text);
    }
    if (_passwordController.text.isNotEmpty) {
      await prefs.setString('password', _passwordController.text);
    }
    if (_portController.text.isNotEmpty) {
      await prefs.setString('sshPort', _portController.text);
    }
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.grey[200],
            bottom: const TabBar(
              tabs: [
                Tab(
                  text: 'Connection',
                  icon: Icon(Icons.connected_tv_outlined),
                ),
                Tab(text: 'LG', icon: Icon(Icons.south_america_rounded)),
              ],
            ),
          ),
          body: Container(
            color: Colors.grey[100],
            child: TabBarView(children: [
              connections(),
              LG(),
            ]),
          ),
        ),
      ),
    );
  }

  // LG Tab body
  Widget LG() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Control your LG Rig',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 22,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(onPressed: () async{
                // print('Button Pressed');
                SSH ssh = SSH(); // create an instance of the SSH class
                await ssh.connectToLG(); // connect to the Liquid Galaxy
                await ssh.relaunchLG();
                // await ssh.cleanSlaves(); // call the cleanSlaves function to clean the
              },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Relaunch LG',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black
                    ),
                  ),
                ),
              ),
            ),





            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Power Off'),
                        content: Text('Are you sure you want to power off the Liquid Galaxy?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text('Power Off'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    print('Going to Power Off');
                    SSH ssh = SSH(); // create an instance of the SSH class
                    await ssh.connectToLG(); // connect to the Liquid Galaxy
                    await ssh.shutdown();
                  }
                  else {
                    print('Cancelled');
                  }
                },
                  child: const Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Power Off',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black
                      ),
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 200,),
            const Text('Made with 💖')
          ],
        ),
      ),
    );
  }

  // Connection Tab body
  Widget connections() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Establish connection to the system',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 22,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.router_sharp),
                  labelText: 'Host',
                  hintText: 'Enter the Master IP address',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                  hintFadeDuration: const Duration(milliseconds: 400),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_tree_sharp),
                  labelText: 'Port',
                  hintText: '22',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                  hintFadeDuration: const Duration(milliseconds: 400),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: 'Username',
                  hintText: 'lg',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                  hintFadeDuration: const Duration(milliseconds: 400),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.key_sharp),
                  labelText: 'Password',
                  hintText: 'your password',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                  hintFadeDuration: const Duration(milliseconds: 400),
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ),

            // Button to connect to the Liquid Galaxy
            ElevatedButton(
                onPressed: () async{
                  // print('Button Pressed');

                  //asynchronously save the settings
                  await _saveSettings();
                  //asynchronously connect to the Liquid Galaxy
                  SSH ssh = SSH(); // create an instance of the SSH class
                  bool? result = await ssh.connectToLG(); // connect to the Liquid Galaxy
                  if (result == true){
                    setState(() {
                      connectionStatus = true;
                    });
                    print('Connected to LG');
                  } else {
                    setState(() {
                      connectionStatus = false;
                    });
                    print('Failed to connect to LG');
                  }
                  _showSnackBar(context, connectionStatus ? 'Connected to LG' : 'Failed to connect to LG');
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.network_check_rounded,color: Colors.grey,),
                      SizedBox(width: 10,),
                      Text(
                        'Connect',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black
                        ),
                      ),
                    ],
                  ),
                )
            ),
            SizedBox(
              height: 20,
            ),

            // Button to send a Demo Command to the Liquid Galaxy
            ElevatedButton(
                onPressed: () async{
                  // print('Send a Demo Command');

                  SSH ssh = SSH(); // re-initialization of an instance of the SSH class to avoid errors
                  await ssh.connectToLG(); // connect to the Liquid Galaxy //here it was not working before as I forgot to write await which didn't wait for the connection to be establish and the execute function was called before the connection was established

                  SSHSession? execResult = await ssh.execute(); // execute the command
                  if (execResult != null){
                    print('Command Executed');
                  } else {
                    print('Failed to execute command');
                  }
                  _showSnackBar(context, connectionStatus? 'Command Executed' : 'Failed to execute command');
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.network_check_rounded,color: Colors.grey,),
                      SizedBox(width: 10,),
                      Text(
                        'Send a Demo Command',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black
                        ),
                      ),
                    ],
                  ),
                )
            )

          ],
        ),
      ),
    );
  }
}




