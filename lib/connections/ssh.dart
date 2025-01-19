import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class SSH {
  late String _host;
  late String _port;
  late String _username;
  late String _password;
  final String _numberOfRigs = '3';
  SSHClient? _client;

  // Initialize connection details from shared preference : this remembers the last connection details used
  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? 'default_host';
    _port = prefs.getString('sshPort') ?? '22';
    _username = prefs.getString('username') ?? 'lg';
    _password = prefs.getString('password') ?? '1234';
  }

  // Connect to the Liquid Galaxy
  Future<bool?> connectToLG() async {
    await initConnectionDetails(); // Initialize connection details
    try {
      _client = SSHClient(
        await SSHSocket.connect(_host, int.parse(_port)),
        username: _username,
        onPasswordRequest: () => _password,
      );
      print('$_host:$_port $_username $_password');
      return true;
    } on SocketException catch (e) {
      print('Failed to Connect to LG: $e');
      return false;
    }
  }

  // Sending a Demo Command to the Liquid Galaxy
  Future<SSHSession?> execute() async {
    try {
      if (_client == null) {
        print('SSHClient is not initialized');
        return null;
      }
      final execSession =
          await _client!.execute('echo "search=Lleida" > /tmp/query.txt');
      return execSession;
    } catch (e) {
      print('Failed to execute command: $e');
      return null;
    }
  }

  // Function to Upload a file to the Liquid Galaxy
  Future<void> uploadFile(String localPath, String remotePath) async {
    if (_client == null) {
      print('SSHClient is not initialized');
      return;
    }
    try {
      final sftp = await _client!.sftp();
      final file = File(localPath);
      final bytes = await file.readAsBytes();

      //open a file with SFTP mode open for writing
      final handle = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );

      await handle.writeBytes(bytes);
      await handle.close();
    } catch (e) {
      print('Failed to upload file: $e');
    }
  }

  // Functions of LG Control
  Future<void> cleanSlaves() async {
    try {
      if (_client == null) {
        print('SSHClient is not initialized');
        return;
      }

      for (int i = 2; i <= int.parse(_numberOfRigs); i++) {
        var content = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document id="slave_$i">
  </Document>
</kml>
    ''';
        await _client!
            .execute('echo \'$content\' >/var/www/html/kml/slave_$i.kml');
        print('cleaning slave_$i.kml');
      }
      return;
    } catch (e) {
      print('Failed to execute command: $e');
      return;
    }
  }

  // Function to Relaunch the Liquid Galaxy
  Future<void> relaunchLG() async {
    final pw = _password;
    final user = _username;

    for (var i = int.parse(_numberOfRigs); i >= 1; i--) {
      try {
        final relaunchCommand = '''RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $pw | sudo -S service \\\${SERVICE} start
else
  echo $pw | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $pw ssh -x -t lg@lg$i "\$RELAUNCH_CMD" ''';

        await _client!
            .execute(' \'/home/$user/bin/lg-relaunch\' > /home/$user/log.txt');
        print('Relaunching LG $i');
        await _client!.execute(relaunchCommand);
      } catch (e) {
        print('Failed to relaunch LG: $e');
      }
    }
  }

  // Function to PowerOff the Liquid Galaxy
  Future<void> shutdown() async {
    final pw = _password;

    for (var i = int.parse(_numberOfRigs); i >= 1; i--) {
      try {
        await _client!.execute(
            'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S poweroff"');
      } catch (e) {
        // ignore: avoid_print
        print('Failed to shutdown LG: $e');
      }
    }
  }
  // Function to send LOGO to the Liquid Galaxy
  Future<void> sendLogo() async {
    try {
      //read the logo file
      final logoBytes = await rootBundle.load('assets/LOGO.png');
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/LOGO.png';

      //saving the logo file to the temporary directory
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(logoBytes.buffer.asUint8List());

      //upload the logo file to the Liquid Galaxy
      await uploadFile(tempPath, '/var/www/html/LOGO.png');

      //seding the LOGO KML to Liquid Galaxy
      final logokml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document id="slave_3">
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>http://lg1:81/LOGO.png</href>
      </Icon>
      <overlayXY x="0.3" y="0.3" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.3" y="0.6" xunits="fraction" yunits="fraction"/>
      
    </ScreenOverlay>
  </Document>
</kml>
''';

      await _client!
          .execute('echo \'$logokml\' >/var/www/html/kml/slave_3.kml');
      // print(logokml);

    } catch (e) {
      print('Failed to send logo: $e');
    }
  }

  // Function to send a KML to the Liquid Galaxy
  Future<void> sendKML(String kmlName) async {
    try {
      //read the KML file
      final kmlData= await rootBundle.loadString('assets/$kmlName.kml');

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$kmlName.kml';


      //saving the KML file to the temporary directory
      await File(tempPath).writeAsString(kmlData);


      //upload the KML file to the Liquid Galaxy
      await uploadFile(tempPath, '/var/www/html/$kmlName.kml');

      //write to kmls.txt
      final flyToCmd = 'echo "flytoview=<LookAt><longitude>-77.3</longitude><latitude>41</latitude><range>900000</range><tilt>30</tilt><heading>0</heading><altitudeMode>relativeToGround</altitudeMode></LookAt>" > /tmp/query.txt';
      await _client!.execute(flyToCmd);
      await Future.delayed(const Duration(seconds: 3));
      await _client!.execute('echo "http://lg1:81/$kmlName.kml" > /var/www/html/kmls.txt');

      // Ensure content is visible
      await Future.delayed(const Duration(seconds: 1));
      await _client!.execute('echo "playtour=Refresh" > /tmp/query.txt');
      await Future.delayed(const Duration(milliseconds: 500));
      await _client!.execute('echo "exittour=true" > /tmp/query.txt');
    } catch (e) {
      print('Failed to send KML: $e');
    }
  }

  // Function to send 3D House KML to the Liquid Galaxy
  Future<void> sendModel() async {
    try {
      //read the KML files
      print('function starts here');
      final modelDae= await rootBundle.loadString('assets/model.dae');
      final houseKML= await rootBundle.loadString('assets/House.kml');
      print(houseKML);

      final tempDir = await getTemporaryDirectory();
      final modelPath = '${tempDir.path}/model.dae';
      final housePath = '${tempDir.path}/House.kml';

      //saving the KML files to the temporary directory
      await File(modelPath).writeAsString(modelDae);
      await File(housePath).writeAsString(houseKML, mode: FileMode.write);

      // Validate the written files
      final writtenHouseKML = await File(housePath).readAsString();
      print('Written House.kml content:\n$writtenHouseKML');

      // Check for anomalies in written content
      if (houseKML.trim() != writtenHouseKML.trim()) {
        throw Exception('House.kml file content mismatch after writing.');
      }

      //upload the KML files to the Liquid Galaxy
      await uploadFile(modelPath, '/var/www/html/model.dae');
      await uploadFile(housePath, '/var/www/html/House.kml');

      //write to kmls.txt
      final flyToCmd = 'echo "flytoview=<LookAt><longitude>76.648497</longitude><latitude>35.444991</latitude><range>5000</range><tilt>40</tilt><heading>0</heading><altitudeMode>relativeToGround</altitudeMode><gx:duration>5.0</gx:duration><gx:flyToMode>smooth</gx:flyToMode></LookAt>" > /tmp/query.txt';
      await _client!.execute(flyToCmd);
      await Future.delayed(const Duration(seconds: 3));
      // await _client!.execute('echo "http://lg1:81/model.dae" > /var/www/html/kmls.txt');
      await _client!.execute('echo "http://lg1:81/House.kml" > /var/www/html/kmls.txt');

      // Ensure content is visible
      await Future.delayed(const Duration(seconds: 1));
      await _client!.execute('echo "playtour=Refresh" > /tmp/query.txt');
      await Future.delayed(const Duration(milliseconds: 500));
      await _client!.execute('echo "exittour=true" > /tmp/query.txt');
    } catch (e) {
      print('Failed to send 3D House KML: $e');
    }
  }

  // Function to clear KML to the Liquid Galaxy
  Future<void> clearKML() async {
    try {
      //write to kmls.txt
      await _client!.execute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(seconds: 3));
      final flyToCmd = 'echo "flytoview=<LookAt><longitude>0</longitude><latitude>0</latitude><range>10000000</range><tilt>0</tilt><heading>0</heading><altitudeMode>relativeToGround</altitudeMode></LookAt>" > /tmp/query.txt';
      await _client!.execute(flyToCmd);
      await Future.delayed(const Duration(seconds: 3));

      await _client!.execute('echo "playtour=Refresh" > /tmp/query.txt');
      await Future.delayed(const Duration(seconds: 1));
      await _client!.execute('echo "exittour=true" > /tmp/query.txt');
    } catch (e) {
      print('Failed to clear KML: $e');
    }
  }

}
