// TODO: IMPLEMENT CODE

import 'package:spypoint_utility/ffi/disc_api.dart';

class Disc {
  final String volumeName;
  final String rootPath;
  final int blockSize;
  final String busType;
  final String discSize;
  final String partitionTableType;
  final bool isInError;
  final bool isCard;
  final bool isReadOnly;
  final bool isRemovable;
  final bool isUsb;
  final String usedSize;

  Disc({
    required this.volumeName,
    required this.rootPath,
    required this.blockSize,
    required this.busType,
    required this.discSize,
    required this.partitionTableType,
    required this.isInError,
    required this.isCard,
    required this.isReadOnly,
    required this.isRemovable,
    required this.isUsb,
    required this.usedSize,
  });

  @override
  String toString() {
    return 'Disc{volumeName: $volumeName, rootPath: $rootPath, blockSize: $blockSize, busType: $busType,  discSize: $discSize, usedSize: $usedSize partitionTableType: $partitionTableType, isInError: $isInError, isCard: $isCard, isReadOnly: $isReadOnly, isRemovable: $isRemovable, isUsb: $isUsb}';
  }

  // Format method that formats the object itself.
  // Utilizes the disc api in utils
  // TODO: implement format functionality
  Future<bool> format(
      {required String fileSystem,
      required bool quickFormat,
      required int allocationUnitSize,
      String? volumeLabel}) async {
    print("start print");
    print(rootPath);
    print(fileSystem);
    print(volumeLabel);
    print(quickFormat);
    print(allocationUnitSize);
    print("end print");
    return await DiscApi().formatDisk(
        devicePath: rootPath,
        fileSystem: fileSystem,
        volumeLabel: volumeLabel,
        quickFormat: quickFormat,
        allocationUnitSize: allocationUnitSize);
  }

// TODO: implement eject

// TODO:
}
