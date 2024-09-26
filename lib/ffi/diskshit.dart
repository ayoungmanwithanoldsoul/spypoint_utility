import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:spypoint_utility/models/disk.dart';

// Load necessary Windows DLLs
final kernel32 = DynamicLibrary.open('kernel32.dll');
final user32 = DynamicLibrary.open('user32.dll');
final shell32 = DynamicLibrary.open('shell32.dll');

// Define function signatures
typedef GetLogicalDrivesC = Uint32 Function();
typedef GetLogicalDrivesDart = int Function();

typedef GetDriveTypeC = Uint32 Function(Pointer<Utf16> lpRootPathName);
typedef GetDriveTypeDart = int Function(Pointer<Utf16> lpRootPathName);

typedef GetDiskFreeSpaceExC = Int32 Function(
    Pointer<Utf16> lpDirectoryName,
    Pointer<Uint64> lpFreeBytesAvailable,
    Pointer<Uint64> lpTotalNumberOfBytes,
    Pointer<Uint64> lpTotalNumberOfFreeBytes);
typedef GetDiskFreeSpaceExDart = int Function(
    Pointer<Utf16> lpDirectoryName,
    Pointer<Uint64> lpFreeBytesAvailable,
    Pointer<Uint64> lpTotalNumberOfBytes,
    Pointer<Uint64> lpTotalNumberOfFreeBytes);

typedef GetVolumeInformationC = Int32 Function(
    Pointer<Utf16> lpRootPathName,
    Pointer<Utf16> lpVolumeNameBuffer,
    Uint32 nVolumeNameSize,
    Pointer<Uint32> lpVolumeSerialNumber,
    Pointer<Uint32> lpMaximumComponentLength,
    Pointer<Uint32> lpFileSystemFlags,
    Pointer<Utf16> lpFileSystemNameBuffer,
    Uint32 nFileSystemNameSize);
typedef GetVolumeInformationDart = int Function(
    Pointer<Utf16> lpRootPathName,
    Pointer<Utf16> lpVolumeNameBuffer,
    int nVolumeNameSize,
    Pointer<Uint32> lpVolumeSerialNumber,
    Pointer<Uint32> lpMaximumComponentLength,
    Pointer<Uint32> lpFileSystemFlags,
    Pointer<Utf16> lpFileSystemNameBuffer,
    int nFileSystemNameSize);

typedef ShFormatDriveC = Int32 Function(Pointer<Uint16> lpRootPathName,
    Pointer<Uint16> lpFileSystemName, Uint32 dwFlags);
typedef ShFormatDriveDart = int Function(Pointer<Uint16> lpRootPathName,
    Pointer<Uint16> lpFileSystemName, int dwFlags);

// Constants for drive types
const DRIVE_REMOVABLE = 2;
const DRIVE_FIXED = 3;
const DRIVE_REMOTE = 4;

// Constants for volume information
const FILE_SYSTEM_FLAG_UNICODE = 0x00000001;

class DiskApi {
  // Bindings for native Windows functions
  final GetLogicalDrivesDart getLogicalDrives =
      kernel32.lookupFunction<GetLogicalDrivesC, GetLogicalDrivesDart>(
          'GetLogicalDrives');

  final GetDriveTypeDart getDriveType =
      kernel32.lookupFunction<GetDriveTypeC, GetDriveTypeDart>('GetDriveTypeW');

  final GetVolumeInformationDart getVolumeInformation =
      kernel32.lookupFunction<GetVolumeInformationC, GetVolumeInformationDart>(
          'GetVolumeInformationW');

// Declare the function
  final ShFormatDriveDart shFormatDrive = shell32
      .lookupFunction<ShFormatDriveC, ShFormatDriveDart>('SHFormatDriveW');

  final GetDiskFreeSpaceExDart getDiskFreeSpaceEx =
      kernel32.lookupFunction<GetDiskFreeSpaceExC, GetDiskFreeSpaceExDart>(
          'GetDiskFreeSpaceExW');

  // Method to retrieve disk information
// Method to retrieve disk information
  Future<List<Disk>> getDiskInfo() async {
    List<Disk> disks = [];
    int drivesBitmask = getLogicalDrives();

    for (int i = 0; i < 26; i++) {
      if ((drivesBitmask & (1 << i)) != 0) {
        String driveLetter = String.fromCharCode(65 + i);
        String rootPath = '$driveLetter:\\';

        final rootPathPtr = rootPath.toNativeUtf16();
        int driveTypeValue = getDriveType(rootPathPtr);

        final volumeNamePtr = calloc<Utf16>(256);
        final fileSystemNamePtr = calloc<Utf16>(256);
        final volumeSerialNumberPtr = calloc<Uint32>();
        final maximumComponentLengthPtr = calloc<Uint32>();
        final fileSystemFlagsPtr = calloc<Uint32>();

        int result = getVolumeInformation(
          rootPathPtr,
          volumeNamePtr,
          256,
          volumeSerialNumberPtr,
          maximumComponentLengthPtr,
          fileSystemFlagsPtr,
          fileSystemNamePtr,
          256,
        );

        String volumeName = volumeNamePtr.cast<Utf16>().toDartString();
        String fileSystemName = fileSystemNamePtr.cast<Utf16>().toDartString();
        int volumeSerialNumber = volumeSerialNumberPtr.value;
        int maximumComponentLength = maximumComponentLengthPtr.value;
        int fileSystemFlags = fileSystemFlagsPtr.value;

        // Retrieve disk size
        final freeBytesAvailable = calloc<Uint64>();
        final totalNumberOfBytes = calloc<Uint64>();
        final totalNumberOfFreeBytes = calloc<Uint64>();
        getDiskFreeSpaceEx(rootPathPtr, freeBytesAvailable, totalNumberOfBytes,
            totalNumberOfFreeBytes);

        int diskSize = totalNumberOfBytes.value.toInt();

        disks.add(Disk(
          name: volumeName,
          devicePath: rootPath,
          blockSize:
              maximumComponentLength, // Placeholder; this could be improved
          busType: 'Unknown',
          busVersion: '1.0',
          description: 'Drive $driveLetter',
          deviceName: 'Device $driveLetter',
          diskSize: diskSize,
          partitionTableType: 'MBR', // Placeholder; requires more logic
          isInError: false,
          isCard: false,
          isReadOnly: fileSystemFlags & 0x00000001 != 0, // Example flag check
          isRemovable: driveTypeValue == DRIVE_REMOVABLE,
          isScsi: false,
          isSystem: false,
          isUas: false,
          isUsb: false,
          isVirtual: false,
          isRaw: false,
        ));

        calloc.free(rootPathPtr);
        calloc.free(volumeNamePtr);
        calloc.free(fileSystemNamePtr);
        calloc.free(volumeSerialNumberPtr);
        calloc.free(maximumComponentLengthPtr);
        calloc.free(fileSystemFlagsPtr);
        calloc.free(freeBytesAvailable);
        calloc.free(totalNumberOfBytes);
        calloc.free(totalNumberOfFreeBytes);
      }
    }

    return disks;
  }

  // Method to list disk contents
  Future<List<FileSystemEntity>> listDiskContents(String devicePath) async {
    final directory = Directory(devicePath);
    return directory.listSync();
  }

  // Method to delete content from the disk
  Future<bool> deleteContent(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      } else {
        final directory = Directory(filePath);
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        } else {
          return false; // File or directory does not exist
        }
      }
      return true;
    } catch (e) {
      print('Error deleting content: $e');
      return false;
    }
  }

  // Method to format the disk
  Future<bool> formatDisk(
      String devicePath, String fileSystem, bool quickFormat) async {
    final drivePtr = devicePath.toNativeUtf16();
    final fsPtr = fileSystem.toNativeUtf16();

    int result = shFormatDrive(drivePtr as Pointer<Uint16>,
        fsPtr as Pointer<Uint16>, quickFormat ? 0x8000 : 0);

    calloc.free(drivePtr);
    calloc.free(fsPtr);

    return result == 0; // 0 indicates success
  }

  // Method to rename the disk
  Future<bool> renameDisk(String devicePath, String newName) async {
    try {
      final drive = Directory(devicePath);
      if (drive.existsSync()) {
        drive.renameSync('$devicePath$newName');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error renaming disk: $e');
      return false;
    }
  }

  // Method to unmount the disk
  Future<bool> unmountDisk(String devicePath) async {
    // Implement using the appropriate FFI functions for unmounting
    // For example, use DeviceIoControl with the FSCTL_DISMOUNT_VOLUME control code.
    // This requires more complex FFI bindings.
    return true;
  }

  // Method to retrieve and list mounted drives
  List<String> getMountedDrives() {
    int drivesBitmask = getLogicalDrives();

    List<String> drives = [];
    for (int i = 0; i < 26; i++) {
      if ((drivesBitmask & (1 << i)) != 0) {
        String driveLetter =
            String.fromCharCode(65 + i); // Convert bit index to drive letter
        drives.add('$driveLetter:\\'); // Format drive letter and root path
      }
    }

    return drives;
  }
}
