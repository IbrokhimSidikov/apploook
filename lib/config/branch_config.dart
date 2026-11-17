// lib/config/branch_config.dart
class BranchConfig {
  final int branchId;
  final String sievesApiCode;
  final String sievesApiToken;
  final int employeeId;
  final String deleverId;

  const BranchConfig({
    required this.branchId,
    required this.sievesApiCode,
    required this.sievesApiToken,
    required this.employeeId,
    required this.deleverId,
  });
}

class BranchConfigs {
  static final Map<String, BranchConfig> configs = {
    'Test': const BranchConfig(
      branchId: 6,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 2983,
      deleverId: '',
    ),
    // Backend API names (matching exactly)
    'Yunusobod': const BranchConfig(
      branchId: 3,
      sievesApiCode: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      sievesApiToken: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      employeeId: 2983,
      deleverId: 'b6780176-358c-4d55-a8bc-0bdb8e3aee6a',
    ),
    'Beruniy': const BranchConfig(
      branchId: 4,
      sievesApiCode: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      sievesApiToken: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      employeeId: 2983,
      deleverId: '6aa27a5c-cba8-46eb-a225-6e6aa3ce485c',
    ),
    'Chilonzor': const BranchConfig(
      branchId: 5,
      sievesApiCode: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      sievesApiToken: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      employeeId: 2983,
      deleverId: '6185a3b8-c874-4f83-88b5-d5caf4a511c7',
    ),
    'Maksim Gorkiy': const BranchConfig(
      branchId: 11,
      sievesApiCode: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      sievesApiToken: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      employeeId: 2983,
      deleverId: '04671531-ef4e-486f-8fe3-4dfcdead80f9',
    ),
    'City Boulevard Loook': const BranchConfig(
      branchId: 14,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 2983,
      deleverId: '7c68b555-5fc5-4d8c-ac45-25360c05fdf5',
    ),
    "Yangiyol Loook": const BranchConfig(
      branchId: 25,
      sievesApiCode: 'a2890a1395c57770f05fda46f4a83f07',
      sievesApiToken: 'a2890a1395c57770f05fda46f4a83f07',
      employeeId: 2983,
      deleverId: '981422f2-326d-4ca7-97ce-0b7ebcbe0c49',
    ),
    "Ganga": const BranchConfig(
      branchId: 27,
      sievesApiCode: '4630f4bf52abc613d43ee3cac51221f9',
      sievesApiToken: '4630f4bf52abc613d43ee3cac51221f9',
      employeeId: 2983,
      deleverId: '195379c9-eb55-47f2-81e6-389675c1ed14',
    ),
    "Sergeli": const BranchConfig(
      branchId: 28,
      sievesApiCode: '200b9adbd17172dd956cb5fdbc722965',
      sievesApiToken: '200b9adbd17172dd956cb5fdbc722965',
      employeeId: 2983,
      deleverId: 'c542c82e-7788-4872-bfd5-b204404730a5',
    ),
  };

  // Names the v3 backend (`/branch/menu`) sends that differ from the keys
  // above. Without these, getConfig fell back to 'Test' (empty deleverId) and
  // the home screen discarded the menu for these branches.
  static const Map<String, String> _aliases = {
    'Maxim Gorkiy': 'Maksim Gorkiy',
    "Yangiyo'l Loook": 'Yangiyol Loook',
  };

  /// Config key for a Sieves branch id, or null if the app has no config.
  static String? keyForBranchId(int branchId) {
    for (final entry in configs.entries) {
      if (entry.key != 'Test' && entry.value.branchId == branchId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Resolves a backend or legacy branch name to its config key.
  static String? resolveKey(String branchName) {
    if (configs.containsKey(branchName)) return branchName;
    final alias = _aliases[branchName];
    if (alias != null) return alias;
    final normalized = _normalize(branchName);
    for (final key in configs.keys) {
      if (_normalize(key) == normalized) return key;
    }
    return null;
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[\s'`ʻʼ’‘\-]"), '')
      .replaceAll('loook', '')
      .replaceAll('maxim', 'maksim');

  static BranchConfig getConfig(String branchName) {
    final key = resolveKey(branchName);
    return (key != null ? configs[key] : null) ?? configs.values.first;
  }
}
