import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:spypoint_utility/models/disk.dart';

// Load necessary Windows DLLs
final kernel32 = DynamicLibrary.open('kernel32.dll');
final shell32 = DynamicLibrary.open('shell32.dll');

// Define function signatures
typedef GetLogicalDrivesC = Uint32 Function();
typedef GetLogicalDrivesDart = int Function();

typedef GetDriveTypeC = Uint32 Function(Pointer<Uint16> lpRootPathName);
typedef GetDriveTypeDart = int Function(Pointer<Uint16> lpRootPathName);

typedef GetDiskFreeSpaceExC = Int32 Function(
    Pointer<Uint16> lpDirectoryName,
    Pointer<Uint64> lpFreeBytesAvailable,
    Pointer<Uint64> lpTotalNumberOfBytes,
    Pointer<Uint64> lpTotalNumberOfFreeBytes);
typedef GetDiskFreeSpaceExDart = int Function(
    Pointer<Uint16> lpDirectoryName,
    Pointer<Uint64> lpFreeBytesAvailable,
    Pointer<Uint64> lpTotalNumberOfBytes,
    Pointer<Uint64> lpTotalNumberOfFreeBytes);

typedef GetVolumeInformationC = Int32 Function(
    Pointer<Uint16> lpRootPathName,
    Pointer<Uint16> lpVolumeNameBuffer,
    Uint32 nVolumeNameSize,
    Pointer<Uint32> lpVolumeSerialNumber,
    Pointer<Uint32> lpMaximumComponentLength,
    Pointer<Uint32> lpFileSystemFlags,
    Pointer<Uint16> lpFileSystemNameBuffer,
    Uint32 nFileSystemNameSize);
typedef GetVolumeInformationDart = int Function(
    Pointer<Uint16> lpRootPathName,
    Pointer<Uint16> lpVolumeNameBuffer,
    int nVolumeNameSize,
    Pointer<Uint32> lpVolumeSerialNumber,
    Pointer<Uint32> lpMaximumComponentLength,
    Pointer<Uint32> lpFileSystemFlags,
    Pointer<Uint16> lpFileSystemNameBuffer,
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

  final GetDiskFreeSpaceExDart getDiskFreeSpaceEx =
      kernel32.lookupFunction<GetDiskFreeSpaceExC, GetDiskFreeSpaceExDart>(
          'GetDiskFreeSpaceExW');

  final ShFormatDriveDart shFormatDrive = shell32
      .lookupFunction<ShFormatDriveC, ShFormatDriveDart>('SHFormatDriveW');

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

  // Method to retrieve disk information
  Future<List<Disk>> getDiskInfo() async {
    List<Disk> disks = [];
    int drivesBitmask = getLogicalDrives();

    for (int i = 0; i < 26; i++) {
      if ((drivesBitmask & (1 << i)) != 0) {
        String driveLetter = String.fromCharCode(65 + i);
        String rootPath = '$driveLetter:\\';

        final rootPathPtr = rootPath.toNativeUtf16();
        int driveTypeValue = getDriveType(rootPathPtr as Pointer<Uint16>);

        final volumeNamePtr = calloc<Uint16>(256);
        final fileSystemNamePtr = calloc<Uint16>(256);
        final volumeSerialNumberPtr = calloc<Uint32>();
        final maximumComponentLengthPtr = calloc<Uint32>();
        final fileSystemFlagsPtr = calloc<Uint32>();

        int result = getVolumeInformation(
          rootPathPtr as Pointer<Uint16>,
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
        getDiskFreeSpaceEx(rootPathPtr as Pointer<Uint16>, freeBytesAvailable,
            totalNumberOfBytes, totalNumberOfFreeBytes);

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
          partitionTableType: 'MBR sample', // Placeholder; requires more logic
          isInError: false,
          isCard: false,
          isReadOnly: fileSystemFlags & FILE_SYSTEM_FLAG_UNICODE !=
              0, // Example flag check
          isRemovable: driveTypeValue == DRIVE_REMOVABLE,
          isScsi: false,
          isSystem: false,
          isUas: false,
          isUsb: false,
          isVirtual: false,
          isRaw: true,
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
}
