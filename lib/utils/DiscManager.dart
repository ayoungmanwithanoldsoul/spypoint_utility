import 'package:spypoint_utility/ffi/disc_api.dart';
import 'package:spypoint_utility/models/disc.dart';

class DiscManager {
  static final DiscManager _instance = DiscManager._internal();
  List<Disc> discs = [];

  DiscManager._internal();

  static DiscManager get instance => _instance;

  Future<void> initialize() async {
    discs = await DiscApi().getDiscInfo();
  }

  Disc getDisc(int index) {
    return discs[index]; // Access any Disc instance by index
  }

  Future<bool> scanDiscs() async {
    try {
      discs = await DiscApi().getDiscInfo();
      return discs
          .isNotEmpty; // Return true if discs are found, false otherwise
    } catch (e) {
      print('Error scanning discs: $e');
      return false; // Return false if there’s an error
    }
  }
}
