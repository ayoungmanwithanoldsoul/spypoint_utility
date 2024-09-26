import 'dart:convert';
import 'dart:io';
import 'package:spypoint_utility/models/disc.dart';

/// DiscApi class provides methods to execute system commands and retrieve information
/// about connected removable drives. It abstracts PowerShell and command-line interactions
/// to gather detailed disk information like size, block size, partition table type, etc.
class DiscApi {
  /// Executes a system command using `Process.run` and returns the result as a trimmed string.
  /// If the command fails (non-zero exit code), it logs the error.
  ///
  /// - Parameters:
  ///   - `command`: The command to run (e.g., `powershell`).
  ///   - `arguments`: List of arguments passed to the command.
  /// - Returns: The standard output as a trimmed string if successful, otherwise an empty string.
  Future<String> _runCommand(String command, List<String> arguments) async {
    try {
      final result = await Process.run(command, arguments);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      } else {
        print('Error running $command: ${result.stderr}');
      }
    } catch (e) {
      print('Exception while running $command: $e');
    }
    return '';
  }

  /// A helper method that specifically executes PowerShell commands.
  ///
  /// - Parameters:
  ///   - `script`: The PowerShell script or command to execute.
  /// - Returns: The output of the PowerShell command as a string.
  Future<String> _runPowerShellCommand(String script) async {
    return await _runCommand('powershell', ['-NoProfile', '-Command', script]);
  }

  /// Retrieves information about all removable drives connected to the system.
  /// For each drive, it gathers details like volume name, root path, block size, disc size,
  /// partition table type, and more by running several system and PowerShell commands.
  ///
  /// This method aggregates these details into a list of `Disc` objects.
  ///
  /// - Returns: A list of `Disc` objects containing drive information.
  Future<List<Disc>> getDiscInfo() async {
    final drives = await _getRemovableDrives();
    final discs = <Disc>[];

    // Iterate through each connected drive and gather information.
    for (String drive in drives) {
      final driveLetter = drive[0];
      final rootPath = drive;
      final volumeInfo = await _retrieveVolumeInfoPowerShell(driveLetter);
      final blockSize = await _getBlockSize(rootPath);
      final isRemovable = await _isRemovable(driveLetter);
      final discSize = volumeInfo[2] ?? '0';
      final usedSize = await _getUsedSize(driveLetter, discSize);

      // Add the disk information into the list as a Disc object.
      discs.add(Disc(
        volumeName: volumeInfo[0] ?? 'Unknown',
        rootPath: rootPath.trim(),
        blockSize: blockSize,
        busType: isRemovable ? 'USB' : 'Fixed',
        discSize: discSize,
        usedSize: usedSize,
        partitionTableType: await _getPartitionTableType(driveLetter),
        isInError: await _isDiskInErrorState(driveLetter),
        isCard: isRemovable,
        isReadOnly: await _isReadOnly(driveLetter),
        isRemovable: isRemovable,
        isUsb: isRemovable,
      ));
    }
    return discs;
  }

  // PowerShell helper to retrieve volume info
  ///
  /// Retrieves volume information such as drive letter, file system label,
  /// file system type, and size for a given drive letter using PowerShell.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: A list containing the file system label, file system type, and size
  ///            as strings. If no information is found, returns ['Unknown', 'Unknown', '0'].
  Future<List<String?>> _retrieveVolumeInfoPowerShell(
      String driveLetter) async {
    print("--------------------------------- _retrieveVolumeInfoPowerShell ");
    final script = '''
      Get-Volume -DriveLetter $driveLetter | 
      Select-Object DriveLetter, FileSystemLabel, FileSystem, Size | Format-List
    ''';
    final output = await _runPowerShellCommand(script);

    final regex = RegExp(
        r'DriveLetter\s*:\s*(\w+)\s*FileSystemLabel\s*:\s*(.*?)\s*FileSystem\s*:\s*(.*?)\s*Size\s*:\s*(\d+)');
    final match = regex.firstMatch(output);

    return match != null
        ? [match.group(2)?.trim(), match.group(3)?.trim(), match.group(4)]
        : ['Unknown', 'Unknown', '0'];
  }

  // Get block size with fallback
  ///
  /// Retrieves the block size (allocation unit size) of a specified volume using PowerShell.
  /// If no valid volume is found, returns a default value of 4096 bytes.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: The block size of the volume as an integer.
  Future<int> _getBlockSize(String driveLetter) async {
    print("--------------------------------- _getBlockSize ");

    try {
      // Remove the ':' character as it yields an exception in PowerShell
      driveLetter = driveLetter.replaceAll(":", "");

      // PowerShell script to get the AllocationUnitSize and avoid empty pipe
      final script = '''
      \$volume = Get-Volume -DriveLetter $driveLetter;
      if (\$volume) {
        \$volume | Select-Object -ExpandProperty AllocationUnitSize;
      } else {
        Write-Output "NoVolumeFound";
      }
    ''';

      // Run the PowerShell command
      String volumeCommandOutput = await _runPowerShellCommand(script);
      volumeCommandOutput = volumeCommandOutput.trim();

      // Check if no volume was found
      if (volumeCommandOutput == "NoVolumeFound") {
        print('No valid volume found for drive $driveLetter');
        return 4096; // Return default block size
      }

      // Parse the result as an integer
      int blockSize = int.parse(volumeCommandOutput);
      print("Block size parsed successfully: $blockSize bytes.");
      return blockSize;
    } catch (e) {
      print('Exception while retrieving block size: $e');
    }

    // Fallback default value
    return 4096;
  }

  // Check if the disk is removable
  ///
  /// Checks if the disk associated with the given drive letter is a removable disk.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: True if the disk is removable (USB), false otherwise.
  Future<bool> _isRemovable(String driveLetter) async {
    print("--------------------------------- _isRemovable ");
    try {
      final script = '''
        Get-Volume -DriveLetter $driveLetter | Get-Disk | Select-Object -ExpandProperty BusType
      ''';
      final result = await _runPowerShellCommand(script);
      return result.trim().toLowerCase() == 'usb';
    } catch (e) {
      print('Error checking if disk is removable: $e');
      return false;
    }
  }

  // Get partition table type
  ///
  /// Retrieves the partition table type of the specified volume using PowerShell.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: The partition style of the disk as a string, or 'Unknown' if unable to retrieve.
  Future<String> _getPartitionTableType(String driveLetter) async {
    print("--------------------------------- _getPartitionTableType ");
    final script = '''
      \$disk = Get-Partition -DriveLetter $driveLetter | Get-Disk;
      \$disk.PartitionStyle
    ''';
    return await _runPowerShellCommand(script) ?? 'Unknown';
  }

  // Check if the disk is in an error state
  ///
  /// Checks the health status of the disk associated with the given drive letter.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: True if the disk is in an error state (not healthy), false otherwise.
  Future<bool> _isDiskInErrorState(String driveLetter) async {
    print("--------------------------------- _isDiskInErrorState ");
    try {
      final script = '''
        Get-Volume -DriveLetter $driveLetter | Select-Object -ExpandProperty HealthStatus
      ''';
      final result = await _runPowerShellCommand(script);
      return result.trim().toLowerCase() != 'healthy';
    } catch (e) {
      print('Error checking disk health status: $e');
      return true; // Assume error if unable to check
    }
  }

  // Check if the disk is read-only
  ///
  /// Checks if the disk associated with the given drive letter is read-only.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  /// - Returns: True if the disk is read-only, false otherwise.
  Future<bool> _isReadOnly(String driveLetter) async {
    print("--------------------------------- _isReadOnly ");
    try {
      final script = '''
        Get-Volume -DriveLetter $driveLetter | Get-Disk | Select-Object -ExpandProperty IsReadOnly
      ''';
      final result = await _runPowerShellCommand(script);
      return result.trim().toLowerCase() == 'true';
    } catch (e) {
      print('Error checking if disk is read-only: $e');
      return false;
    }
  }

  // Get used size of the disk
  ///
  /// Calculates the used size of the disk based on total size and remaining size.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume (e.g., `C:`).
  ///   - `totalSize`: The total size of the disk as a string.
  /// - Returns: The used size of the disk as a string.
  Future<String> _getUsedSize(String driveLetter, String totalSize) async {
    try {
      // PowerShell command to get remaining size
      final script = '''
      Get-Volume -DriveLetter $driveLetter | 
      Select-Object -ExpandProperty SizeRemaining
    ''';
      final remainingSizeStr = await _runPowerShellCommand(script);
      final remainingSize = int.tryParse(remainingSizeStr.trim()) ?? 0;
      final totalSizeInt = int.tryParse(totalSize) ?? 0;
      final usedSize = totalSizeInt - remainingSize;

      // Convert bytes to a human-readable format (like MB, GB)
      return usedSize.toString();
    } catch (e) {
      print('Error getting used size for drive $driveLetter: $e');
      return '0';
    }
  }

// Get drives
  Future<List<String>> _getDrives() async {
    final result = await _runCommand('wmic', ['logicaldisk', 'get', 'name']);
    return result
        .split('\n')
        .where((line) => line.trim().length == 2 && line.trim().endsWith(':'))
        .toList();
  }

  // Get removable drives
  ///
  /// Retrieves a list of removable drives (e.g., USB drives) connected to the system.
  /// It uses the WMIC command to filter logical disks by their drive type.
  ///
  /// - Returns: A list of strings representing the drive letters of removable drives.
  Future<List<String>> _getRemovableDrives() async {
    final result = await _runCommand(
        'wmic', ['logicaldisk', 'where', 'DriveType=2', 'get', 'name']);
    return result
        .split('\n')
        .where((line) => line.trim().isNotEmpty && line.trim().endsWith(':'))
        .map((line) => line.trim())
        .toList();
  }

  // List directory contents
  ///
  /// Lists the contents of a specified directory.
  /// Returns a list of FileSystemEntity objects representing the contents of the directory.
  ///
  /// - Parameters:
  ///   - `path`: The path of the directory to list.
  /// - Returns: A list of FileSystemEntity objects representing the files and folders
  ///            in the directory. Returns an empty list if the directory does not exist
  ///            or if an error occurs.
  Future<List<FileSystemEntity>> listDirectoryContents(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists() ? dir.listSync() : [];
    } catch (e) {
      print('Error listing directory contents: $e');
      return [];
    }
  }

  /// Formats the specified disk using the provided parameters.
  ///
  /// The `formatDisk` function allows formatting of a disk (e.g., a microSD card or USB drive)
  /// with customizable options such as the file system type, quick or long format, allocation unit size,
  /// and volume label.
  ///
  /// The format command supports different file systems like FAT32, NTFS, and exFAT, and the method
  /// allows you to control whether to perform a quick format or a full format.
  /// It also automatically confirms the operation to suppress user prompts.
  ///
  /// ### Parameters:
  /// - [devicePath] : The path to the drive or disk to format (e.g., `E:` or `\\.\PhysicalDrive1`).
  /// - [fileSystem] : The file system type to use during the format (e.g., `"FAT32"`, `"NTFS"`, `"exFAT"`).
  /// - [quickFormat] : Boolean flag that specifies whether to perform a quick format (`true`) or long format (`false`).
  ///
  /// ### Return:
  /// - Returns `true` if the formatting succeeds; otherwise, `false` if it fails.
  ///
  /// ### Example Usage:
  /// ```dart
  /// // Format the E: drive as FAT32 with quick format enabled
  /// bool result = await formatDisk('E:', 'FAT32', true);
  /// if (result) {
  ///   print('Disk formatted successfully.');
  /// } else {
  ///   print('Failed to format the disk.');
  /// }
  /// ```
  /// ### Example Usage:
  /// ```dart
  /// // Long Format Drive E: as FAT32 with Volume Label and Allocation Unit Size
  /// await formatDisk(
  ///   devicePath: 'E:',
  ///   fileSystem: 'FAT32',
  ///   volumeLabel: 'MYCARD',
  ///   allocationUnitSize: 32768,  // 32 KB cluster size
  ///   quickFormat: false,        // Long format
  /// );
  /// ```
  ///
  /// ### Additional Information:
  /// - This method executes the Windows `format` command, so it is only compatible with Windows systems.
  /// - Ensure that the drive path (`devicePath`) points to the correct drive or partition to avoid data loss.
  Future<bool> formatDisk({
    required String devicePath, // Drive letter (e.g., F)
    required String fileSystem, // File system (NTFS, FAT32, exFAT)
    String? volumeLabel, // Volume label (optional)
    bool quickFormat = true, // Quick format (true/false)
    int? allocationUnitSize, // Allocation unit size (optional)
  }) async {
    //   // Prepare the PowerShell script
    // TODO: NEED TO FIX THE VOLUME RENAME
    final script = '''
    Format-Volume -DriveLetter ${devicePath.replaceAll(':', '')} -FileSystem $fileSystem ${volumeLabel != null ? '-NewFileSystemLabel "$volumeLabel"' : ''} ${allocationUnitSize != null ? '-AllocationUnitSize $allocationUnitSize' : ''} -Full:${quickFormat ? '\$false' : '\$true'} -Confirm:\$false -Force
    ''';
    // Run the PowerShell command
    final result = await _runPowerShellCommand(script);
    if (result.isNotEmpty) {
      print('Disk formatted successfully with $fileSystem.');
      return true;
    } else {
      print('Failed to format disk.');
      return false;
    }
  }

  // Delete file or directory
  ///
  /// Deletes a file or directory at the specified path.
  /// If the path points to a directory, it will be deleted recursively.
  ///
  /// - Parameters:
  ///   - `path`: The path of the file or directory to delete.
  /// - Returns: A boolean indicating whether the deletion was successful.
  Future<bool> deleteContent(String path) async {
    try {
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.file) {
        await File(path).delete();
      } else if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else {
        print('Unknown entity type at path: $path');
        return false;
      }
      print('Deleted: $path');
      return true;
    } catch (e) {
      print('Error deleting content: $e');
      return false;
    }
  }

  // Rename file or directory
  ///
  /// Renames a file or directory from the old path to the new path.
  /// Checks if the old path exists before attempting to rename.
  ///
  /// - Parameters:
  ///   - `oldPath`: The current path of the file or directory.
  ///   - `newPath`: The new path (including the new name) for the file or directory.
  /// - Returns: A boolean indicating whether the rename operation was successful.
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

  // Rename disk volume
  ///
  /// Changes the label of a disk volume specified by its drive letter.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the volume to rename (e.g., "D").
  ///   - `newLabel`: The new label to assign to the volume.
  /// - Returns: A boolean indicating whether the renaming operation was successful.
  Future<bool> renameDiskVolume(String driveLetter, String newLabel) async {
    final result = await _runCommand('label', ['$driveLetter:', newLabel]);
    if (result.isNotEmpty) {
      print('Volume label changed to $newLabel');
      return true;
    } else {
      print('Failed to rename volume.');
      return false;
    }
  }

  // Eject disk using PS command
  ///
  /// Ejects a disk specified by its drive letter using a PowerShell command.
  ///
  /// - Parameters:
  ///   - `driveLetter`: The drive letter of the disk to eject (e.g., "D").
  /// - Returns: A boolean indicating whether the eject operation was successful.
  Future<bool> ejectDisk(String driveLetter) async {
    // Prepare the PowerShell script to eject the drive
    final script = '''
\$driveEject = New-Object -comObject Shell.Application
\$driveEject.Namespace(17).ParseName("$driveLetter`:\\").InvokeVerb("Eject")
  ''';

    try {
      // Run the PowerShell script using the provided _runPowerShellCommand function
      final result = await _runPowerShellCommand(script);

      // Check if the result contains an indication of success
      if (result.isNotEmpty && result.contains("Eject")) {
        print('Disk $driveLetter ejected.');
        return true;
      } else {
        print('Failed to eject disk $driveLetter.');
        return false;
      }
    } catch (e) {
      print('Error ejecting disk $driveLetter: $e');
      return false;
    }
  }
}
