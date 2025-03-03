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
      sievesApiCode: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      sievesApiToken: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      employeeId: 423,
    ),
    'Loook Beruniy': const BranchConfig(
      branchId: 4,
      sievesApiCode: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      sievesApiToken: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      employeeId: 423,
    ),
    'Loook Chilanzar': const BranchConfig(
      branchId: 5,
      sievesApiCode: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      sievesApiToken: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      employeeId: 423,
    ),
    'Loook Maksim Gorkiy': const BranchConfig(
      branchId: 11,
      sievesApiCode: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      sievesApiToken: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      employeeId: 423,
    ),
    'Loook Boulevard': const BranchConfig(
      branchId: 14,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
    ),
  };

  static BranchConfig getConfig(String branchName) {
    return configs[branchName] ?? configs.values.first;
  }
}
