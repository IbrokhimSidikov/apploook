// lib/config/branch_config.dart
class BranchConfig {
  final int branchId;
  final String sievesApiCode;
  final String sievesApiToken;
  final int employeeId;
  final String merchantId;

  const BranchConfig({
    required this.branchId,
    required this.sievesApiCode,
    required this.sievesApiToken,
    required this.employeeId,
    required this.merchantId,
  });
}

class BranchConfigs {
  static final Map<String, BranchConfig> configs = {
    'Test': const BranchConfig(
      branchId: 6,
      sievesApiCode: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      sievesApiToken: 'c0905077-12ac-4ae8-954e-5524b3e30bb1',
      employeeId: 423,
      merchantId: '',
    ),
    'Loook Yunusobod': const BranchConfig(
      branchId: 3,
      sievesApiCode: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      sievesApiToken: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      employeeId: 423,
      merchantId: '685bcb1804711a17e505cfdb',
    ),
    'Loook Beruniy': const BranchConfig(
      branchId: 4,
      sievesApiCode: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      sievesApiToken: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      employeeId: 423,
      merchantId: '686386cc74755eccf65a0f26',
    ),
    'Loook Chilanzar': const BranchConfig(
      branchId: 5,
      sievesApiCode: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      sievesApiToken: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      employeeId: 423,
      merchantId: '685bca7c04711a17e505cfcb',
    ),
    'Loook Maksim Gorkiy': const BranchConfig(
      branchId: 11,
      sievesApiCode: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      sievesApiToken: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      employeeId: 423,
      merchantId: '6863871674755eccf65a0f37',
    ),
    'Loook Boulevard': const BranchConfig(
      branchId: 14,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '686387fd74755eccf65a0f64',
    ),
    'Ava Pizza': const BranchConfig(
      branchId: 15,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '6863879a74755eccf65a0f4d',
    ),
    'Loook Yangiyol': const BranchConfig(
      branchId: 25,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '6863894974755eccf65a0f93',
    ),
    'Loook High Town': const BranchConfig(
      branchId: 26,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '6863885274755eccf65a0f6e',
    ),
  };

  static BranchConfig getConfig(String branchName) {
    return configs[branchName] ?? configs.values.first;
  }
}
