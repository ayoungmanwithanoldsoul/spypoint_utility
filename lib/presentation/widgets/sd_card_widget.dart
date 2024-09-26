import 'package:flutter/material.dart';

class SdCardWidget extends StatelessWidget {
  final String rootPath;
  final String volumeName;
  final double usedCapacity;
  final double totalCapacity;
  final VoidCallback onLongFormat;
  final VoidCallback onShortFormat;
  final VoidCallback onInfo;
  final VoidCallback onBackupPhoto;

  const SdCardWidget({
    Key? key,
    required this.rootPath,
    required this.volumeName,
    required this.usedCapacity,
    required this.totalCapacity,
    required this.onLongFormat,
    required this.onShortFormat,
    required this.onInfo,
    required this.onBackupPhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usedCapacityString = _formatCapacity(usedCapacity);
    final totalCapacityString = _formatCapacity(totalCapacity);

    return Container(
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Device root path, for instance E:
          Text(
            'Drive $rootPath',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // Volume label
          Expanded(
            child: Text(
              'SD   $volumeName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Used storage / total capacity
          Text(
            '$usedCapacityString / $totalCapacityString',
            style: TextStyle(fontSize: 16),
          ),
          // Backup Data button
          IconButton(
            icon: Icon(Icons.download_for_offline),
            onPressed: onBackupPhoto,
          ),
          // Long format button
          IconButton(
            icon: Icon(Icons.timelapse), // Replace with your long format icon
            onPressed: onLongFormat,
          ),
          // Short format button
          IconButton(
            icon: Icon(
                Icons.electric_bolt), // Replace with your short format icon
            onPressed: onShortFormat,
          ),
          // Info button
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: onInfo,
          ),
        ],
      ),
    );
  }

  String _formatCapacity(double capacity) {
    // Format the capacity to GB with 2 decimal places
    return '${capacity.toStringAsFixed(2)} GB';
  }
}
