import 'dart:convert';
import 'dart:io';
import 'package:spypoint_utility/models/disc.dart';

class DiskApi {
  // Helper method to run commands and get output
  Future<String> _runCommand(String command, List<String> arguments) async {
    try {
      final result = await Process.run(command, arguments);
      if (result.exitCode == 0) {
        return result.stdout;
      } else {
        print('Failed to run command $command. Error: ${result.stderr}');
        print('Arguments: $arguments');
        return '';
      }
    } catch (e) {
      print('Exception while running command $command: $e');
      return '';
    }
  }

  // Helper method to get block size
  Future<int> _getBlockSize(String driveLetter) async {
    // Alternative method to handle non-NTFS volumes or errors
    try {
      // Remove the ':' character at it yields an exception in PS
      driveLetter = driveLetter.replaceAll(":", "");
      // Attempt to get block size using PowerShell Get-Volume
      // Execute the PowerShell command to get volume information
      String volumeCommandOutput = await _runCommand('powershell', [
        '-Command',
        "Get-Volume -DriveLetter $driveLetter | Select-Object -ExpandProperty AllocationUnitSize"
      ]);

      // Remove any extra whitespace and convert the output to integer
      volumeCommandOutput = volumeCommandOutput.trim();
      int blockSize = int.parse(volumeCommandOutput);

      print("Block size parsed successfully from volume allocation.");
      return blockSize;
    } catch (e) {
      print('Exception while retrieving block size: $e');
    }

    // Fallback default value
    return 4096;
  }

  // Method to retrieve disk information
  Future<List<Disc>> getDiskInfo() async {
    List<Disc> discs = [];
    List<String> drives = await getDrives();

    for (String drive in drives) {
      String driveLetter = drive[0]; // Extract drive letter (e.g., 'C')
      String rootPath = drive;

      // Retrieve drive type
      String driveType =
          await _runCommand('fsutil', ['fsinfo', 'drivetype', rootPath]);
      bool isRemovable = driveType.contains('Removable');
      Future<String> _runPowerShellCommand(String script) async {
        try {
          final result = await Process.run(
              'powershell', ['-NoProfile', '-Command', script]);
          if (result.exitCode == 0) {
            return result.stdout;
          } else {
            print('Failed to run PowerShell command. Error: ${result.stderr}');
            return '';
          }
        } catch (e) {
          print('Exception while running PowerShell command: $e');
          return '';
        }
      }

      Future<List<String?>> _retrieveVolumeInfoPowerShell(
          String driveLetter) async {
        String script = '''
Get-Volume -DriveLetter $driveLetter | Select-Object -Property DriveLetter,FileSystemLabel,FileSystem,Size | Format-List
  ''';

        String volumeInfo = await _runPowerShellCommand(script);

        print('Raw volumeInfo output: $volumeInfo');

        // Adjust regex to match the format of the output
        RegExp volumeRegExp = RegExp(
            r'DriveLetter\s*:\s*(\w+)\s*FileSystemLabel\s*:\s*(.*?)\s*FileSystem\s*:\s*(.*?)\s*Size\s*:\s*(\d+)');
        Match? volumeMatch = volumeRegExp.firstMatch(volumeInfo);
        String? VolumeName;
        String? FileSystem;
        String? Size;
        if (volumeMatch != null) {
          VolumeName = volumeMatch.group(2)?.trim();
          FileSystem = volumeMatch.group(3)?.trim();
          Size = volumeMatch.group(4) ?? '0';
        } else {
          print('No matches found');
        }
        return [VolumeName, FileSystem, Size];
      }

      // Retrieve volume information
      List<String?> volumeInfo =
          await _retrieveVolumeInfoPowerShell(driveLetter);
      String volumeName = volumeInfo[0] ?? 'Unknown';
      String diskSize = volumeInfo[2] ?? '0';
      // Get block size
      int blockSize = await _getBlockSize(rootPath);
      discs.add(Disc(
        volumeName: volumeName,
        rootPath: rootPath,
        blockSize: blockSize,
        busType: await _isRemovable(driveLetter) ? 'USB' : 'Fixed',
        discSize: diskSize,
        partitionTableType: await _getPartitionTableType(driveLetter),
        isInError: await _isDiskInErrorState(driveLetter),
        isCard: isRemovable,
        isReadOnly: await _isReadOnly(driveLetter),
        isRemovable: isRemovable,
        isUsb: await _isRemovable(driveLetter),
      ));
    }

    return discs;
  }

  // Method to format the disk
  Future<bool> formatDisk(
      String devicePath, String fileSystem, bool quickFormat) async {
    String command = 'format';
    List<String> arguments = [
      devicePath,
      '/FS:$fileSystem',
      quickFormat ? '/Q' : '',
      '/Y'
    ];

    try {
      final process = await Process.start(command, arguments);
      await process.exitCode;

      if (process.exitCode == 0) {
        print('Disk formatted successfully with $fileSystem.');
        return true;
      } else {
        print(
            'Failed to format the disk. Error: ${await process.stderr.transform(utf8.decoder).join()}');
        return false;
      }
    } catch (e) {
      print('Exception while formatting disk: $e');
      return false;
    }
  }

  // Method to get the list of drives
  Future<List<String>> getDrives() async {
    String result = await _runCommand('wmic', ['logicaldisk', 'get', 'name']);
    List<String> drives = result
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length == 2 && line[1] == ':')
        .toList();
    return drives;
  }

// Method to list contents of a directory
  Future<List<FileSystemEntity>> listDirectoryContents(
      String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final List<FileSystemEntity> contents = [];

      // Check if the directory exists
      if (await directory.exists()) {
        // List all entities (files and directories) in the directory
        await for (var entity
            in directory.list(recursive: false, followLinks: false)) {
          contents.add(entity);
        }
      } else {
        print('Directory does not exist: $directoryPath');
      }

      return contents;
    } catch (e) {
      print('Error listing directory contents: $e');
      return [];
    }
  }

  // Method to delete content from the disk
  Future<bool> deleteContent(String path) async {
    try {
      // Check if the path exists
      final entityType = await FileSystemEntity.type(path);
      if (entityType == FileSystemEntityType.notFound) {
        print('Path does not exist: $path');
        return false;
      }

      // Check the type of the entity and delete accordingly
      if (entityType == FileSystemEntityType.file) {
        final file = File(path);
        await file.delete();
        print('File deleted: $path');
      } else if (entityType == FileSystemEntityType.directory) {
        final directory = Directory(path);
        // Recursively delete the contents of the directory
        await directory.delete(recursive: true);
        print('Directory deleted: $path');
      } else {
        print('Unknown file system entity type for path: $path');
        return false;
      }

      return true;
    } catch (e) {
      print('Error deleting content: $e');
      return false;
    }
  }

  // Method to rename a file or directory
  Future<bool> renameContent(String oldPath, String newPath) async {
    try {
      // Check if the old path exists
      final entityType = await FileSystemEntity.type(oldPath);
      if (entityType == FileSystemEntityType.notFound) {
        print('Path does not exist: $oldPath');
        return false;
      }

      // Rename based on the type of entity
      if (entityType == FileSystemEntityType.file) {
        final file = File(oldPath);
        await file.rename(newPath);
        print('File renamed from $oldPath to $newPath');
      } else if (entityType == FileSystemEntityType.directory) {
        final directory = Directory(oldPath);
        await directory.rename(newPath);
        print('Directory renamed from $oldPath to $newPath');
      } else {
        print('Unknown file system entity type for path: $oldPath');
        return false;
      }

      return true;
    } catch (e) {
      print('Error renaming content: $e');
      return false;
    }
  }

  // Method to rename (relabel) the disk volume
  Future<bool> renameDiskVolume(String driveLetter, String newLabel) async {
    try {
      // Ensure the drive letter is in the correct format (e.g., "C:")
      if (!driveLetter.endsWith(':')) {
        driveLetter = '$driveLetter:';
      }

      // Run the label command to change the volume label
      final result = await Process.run(
        'label',
        [driveLetter, newLabel],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      // Check if the command was successful
      if (result.exitCode == 0) {
        print('Volume label successfully changed to: $newLabel');
        return true;
      } else {
        print('Failed to change volume label. Error: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('Error renaming disk volume: $e');
      return false;
    }
  }

  // TODO: METHOD TO UNMOUNT DISK
  // TODO: not working it unmounts but upon remount it doesn't get recognized unless manually asigned disk letter
  // Method to unmount the disk
  Future<bool> unmountDisk(String driveLetter) async {
    try {
      // Ensure the drive letter is in the correct format (e.g., "C:")
      if (!driveLetter.endsWith(':')) {
        driveLetter = '$driveLetter:';
      }

      // Run the mountvol command to unmount the volume
      final result = await Process.run(
        'mountvol',
        [driveLetter, '/d'], // /d dismounts the volume
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      // Check if the command was successful
      if (result.exitCode == 0) {
        print('Volume successfully unmounted.');
        return true;
      } else {
        print('Failed to unmount volume. Error: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('Error unmounting disk: $e');
      return false;
    }
  }

  // TODO: EJECT DISK not working it unmounts but upon remount it doesn't recognized unless manually asigned disk drives
  Future<void> ejectDisk(String driveLetter) async {
    // Ensure the drive letter is in the correct format (e.g., "E:")
    if (!driveLetter.endsWith(':')) {
      driveLetter += ':';
    }

    // Create the DiskPart script
    final script = '''
select volume $driveLetter
remove
''';

    // Save the script to a temporary file
    final scriptFile = File('eject_disk_script.txt');
    await scriptFile.writeAsString(script);

    try {
      // Run the DiskPart command with the script
      final result = await Process.run(
        'diskpart',
        ['/s', scriptFile.path],
      );

      if (result.exitCode == 0) {
        print('Disk $driveLetter successfully ejected.');
      } else {
        print('Failed to eject disk $driveLetter: ${result.stderr}');
      }
    } catch (e) {
      print('Error running DiskPart: $e');
    } finally {
      // Clean up the temporary script file
      await scriptFile.delete();
    }
  }

  // Method to get partition table type
  Future<String> _getPartitionTableType(String driveLetter) async {
    // PowerShell command to get partition style (MBR or GPT)
    String command = '''
  \$disk = Get-Partition -DriveLetter $driveLetter | Get-Disk;
  \$disk.PartitionStyle
  ''';

    String result = await _runCommand('powershell', ['-Command', command]);

    // Check for MBR or GPT in result
    if (result.contains("MBR")) {
      return 'MBR';
    } else if (result.contains("GPT")) {
      return 'GPT';
    }
    return 'Unknown';
  }

  // Method to check if the drive is read-only
  Future<bool> _isReadOnly(String driveLetter) async {
    // Use PowerShell to get the read-only status of the disk
    String result = await _runCommand('powershell', [
      '-Command',
      '(Get-Disk -Number (Get-Partition -DriveLetter $driveLetter).DiskNumber).IsReadOnly'
    ]);
    // Check if result contains 'True' to indicate read-only
    return result.trim() == 'True';
  }

  // TODO: error invalid query
  // Method to check if the drive is a system drive
  //refactored to check if it is removable
  Future<bool> _isRemovable(String driveLetter) async {
    // Use PowerShell to check if the drive is a system volume
    String result = await _runCommand('powershell', [
      '-Command',
      '(Get-Volume -DriveLetter $driveLetter).DriveType -eq \'Fixed\''
    ]);

    // Check if result contains 'True'
    return result.trim() == 'False';
  }

  // check if the disk in error
  Future<bool> _isDiskInErrorState(String driveLetter) async {
    try {
      String commandOutput = await _runCommand('powershell', [
        '-Command',
        "Get-WmiObject Win32_DiskDrive | Where-Object { \$_.DeviceID -match '$driveLetter' } | Select-Object -ExpandProperty Status"
      ]);
      // Common error statuses
      return commandOutput.contains('Error') ||
          commandOutput.contains('Critical');
    } catch (e) {
      print('Exception while checking disk error state: $e');
      return false;
    }
  }
}
