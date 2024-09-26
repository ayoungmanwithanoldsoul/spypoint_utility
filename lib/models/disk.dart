// TODO: IMPLEMENT CODE

// models/disk_model.dart
class Disk {
  final String name;
  final String devicePath;
  final int blockSize;
  final String busType;
  final String busVersion;
  final String description;
  final String deviceName;
  final String diskSize;
  final String partitionTableType;
  final bool isInError;
  final bool isCard;
  final bool isReadOnly;
  final bool isRemovable;
  final bool isScsi;
  final bool isSystem;
  final bool isUas;
  final bool isUsb;
  final bool isVirtual;
  final bool isRaw;

  Disk({
    required this.name,
    required this.devicePath,
    required this.blockSize,
    required this.busType,
    required this.busVersion,
    required this.description,
    required this.deviceName,
    required this.diskSize,
    required this.partitionTableType,
    required this.isInError,
    required this.isCard,
    required this.isReadOnly,
    required this.isRemovable,
    required this.isScsi,
    required this.isSystem,
    required this.isUas,
    required this.isUsb,
    required this.isVirtual,
    required this.isRaw,
  });

  @override
  String toString() {
    return 'Disk{name: $name, devicePath: $devicePath, blockSize: $blockSize, busType: $busType, busVersion: $busVersion, description: $description, deviceName: $deviceName, diskSize: $diskSize, partitionTableType: $partitionTableType, isInError: $isInError, isCard: $isCard, isReadOnly: $isReadOnly, isRemovable: $isRemovable, isScsi: $isScsi, isSystem: $isSystem, isUas: $isUas, isUsb: $isUsb, isVirtual: $isVirtual, isRaw: $isRaw}';
  }
}
