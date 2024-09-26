import 'package:flutter/material.dart';
import 'package:spypoint_utility/ffi/disc_api.dart';
import 'package:spypoint_utility/presentation/widgets/sd_card_widget.dart';
import 'package:spypoint_utility/utils/DiscManager.dart';
import '../../models/disc.dart';

class MainContent extends StatefulWidget {
  MainContent({super.key});

  @override
  _MainContentState createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  final DiscManager discManager = DiscManager.instance;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get the discs from the discManager when building the widget
    List<Disc> discs = discManager.discs;

    return Container(
      constraints: const BoxConstraints.expand(),
      color: Colors.blue[600],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SD Cards',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _rescanDiscs,
                  child: isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text('Rescan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: discs.isEmpty
                ? Center(
                    child: const Text(
                      'No SD Cards Detected',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: discs.length,
                    itemBuilder: (context, index) {
                      final Disc disc = discs[index];
                      return SdCardWidget(
                        volumeName: disc.volumeName,
                        rootPath: disc.rootPath,
                        usedCapacity:
                            (double.tryParse(disc.usedSize))! / 1073741824,
                        totalCapacity:
                            (double.tryParse(disc.discSize))! / 1073741824,
                        onLongFormat: () {
                          print('Long format ' + disc.rootPath);
                          _showFormatOptionsDialog(disc, false);
                        },
                        onShortFormat: () {
                          print('Short format ' + disc.volumeName);
                          _showFormatOptionsDialog(disc, true);
                        },
                        onInfo: () {
                          print('Info ' + disc.volumeName);
                        },
                        onBackupPhoto: () {
                          print('Backup ' + disc.volumeName);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _rescanDiscs() async {
    setState(() {
      isLoading = true; // Start loading animation
    });

    // Call the scanDiscs function and wait for it to complete
    await discManager.scanDiscs();

    setState(() {
      isLoading = false; // Stop loading animation
    });
  }

  Future<void> _showFormatOptionsDialog(Disc device, bool quickFormat) async {
    final TextEditingController volumeLabelController = TextEditingController();
    String selectedFileSystem = 'FAT32'; // 'FAT32'; // Default file system
    int allocationUnitSize = 4096; // Default allocation unit size

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text((quickFormat == true ? "Quick Format" : "Long Format") +
              ' Device ' +
              device.rootPath),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filesystem',
                  ),
                  value: 'FAT32', // Default value
                  items: const [
                    DropdownMenuItem(
                        value: 'FAT',
                        child: Text(
                            'FAT = Basic file system for very small drives and older devices (up to 2 GB).')),
                    DropdownMenuItem(
                        value: 'FAT32',
                        child: Text(
                            'FAT32 = Common for drives up to 32 GB, max file size 4 GB, widely compatible.')),
                    DropdownMenuItem(
                        value: 'exFAT',
                        child: Text(
                            'exFAT = Ideal for large flash drives, no 4 GB file limit, cross-platform')),
                    DropdownMenuItem(
                        value: 'NTFS',
                        child: Text(
                            'NTFS = Advanced file system for Windows, supports large drives, permissions, and encryption')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFileSystem =
                          newValue ?? 'FAT32'; // Update the allocationUnitSize
                    });
                  },
                ),
                TextField(
                  controller: volumeLabelController,
                  decoration: InputDecoration(labelText: 'Volume Label'),
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Allocation Unit Size (bytes)',
                  ),
                  value: 4096, // Default value
                  items: const [
                    DropdownMenuItem(
                        value: 512, child: Text('512 bytes = 512')),
                    DropdownMenuItem(value: 1024, child: Text('1 KB = 1024')),
                    DropdownMenuItem(value: 2048, child: Text('2 KB = 2048')),
                    DropdownMenuItem(value: 4096, child: Text('4 KB = 4096')),
                    DropdownMenuItem(value: 8192, child: Text('8 KB = 8192')),
                    DropdownMenuItem(
                        value: 16384, child: Text('16 KB = 16384')),
                    DropdownMenuItem(
                        value: 32768,
                        child: Text(
                            '32 KB = 32768 (common for larger drives, up to 2 TB)')),
                    DropdownMenuItem(
                        value: 65536, child: Text('64 KB = 65536')),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      allocationUnitSize =
                          newValue ?? 4096; // Update the allocationUnitSize
                    });
                  },
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call the formatDisk function here with the selected parameters
                _formatDisk(device, selectedFileSystem, allocationUnitSize,
                    volumeLabelController.text, quickFormat);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Format'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _formatDisk(Disc device, String fileSystem,
      int allocationUnitSize, String volumeLabel, bool quickFormat) async {
    bool success = await device.format(
        fileSystem: fileSystem,
        volumeLabel: volumeLabel,
        quickFormat: quickFormat,
        allocationUnitSize: allocationUnitSize);
    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully formatted ' + device.rootPath)));
    } else {
      // Show failure message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to format ' + device.rootPath)));
    }
  }
}
