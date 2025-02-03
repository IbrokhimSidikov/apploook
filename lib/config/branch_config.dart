// lib/config/branch_config.dart
class BranchConfig {
  final int branchId;
  final String sievesApiCode;
  final String sievesApiToken;
  final int employeeId;

  const BranchConfig({
    required this.branchId,
    required this.sievesApiCode,
    required this.sievesApiToken,
    required this.employeeId,
  });
}

class BranchConfigs {
  static final Map<String, BranchConfig> configs = {
    'Test': const BranchConfig(
      branchId: 6,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
    'Loook Yunusobod': const BranchConfig(
      branchId: 3,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
    'Loook Beruniy': const BranchConfig(
      branchId: 4,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
    'Loook Chilanzar': const BranchConfig(
      branchId: 5,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
    'Loook Maksim Gorkiy': const BranchConfig(
      branchId: 11,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
    'Loook Boulevard': const BranchConfig(
      branchId: 14,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
    ),
  };

  static BranchConfig getConfig(String branchName) {
    return configs[branchName] ?? configs.values.first;
  }
}
