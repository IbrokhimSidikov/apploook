// lib/config/branch_config.dart
class BranchConfig {
  final int branchId;
  final String sievesApiCode;
  final String sievesApiToken;
  final int employeeId;
  final String merchantId;
  final String deleverId;

  const BranchConfig({
    required this.branchId,
    required this.sievesApiCode,
    required this.sievesApiToken,
    required this.employeeId,
    required this.merchantId,
    required this.deleverId,
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
      deleverId: '',
    ),
    'Loook Yunusobod': const BranchConfig(
      branchId: 3,
      sievesApiCode: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      sievesApiToken: '62a4d1be-d92e-4df4-98ea-837f14959f9c',
      employeeId: 423,
      merchantId: '685bcb1804711a17e505cfdb',
      deleverId: 'b6780176-358c-4d55-a8bc-0bdb8e3aee6a',
    ),
    'Loook Beruniy': const BranchConfig(
      branchId: 4,
      sievesApiCode: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      sievesApiToken: '5fdd640b-516e-42d9-8f06-6aff0806d4c5',
      employeeId: 423,
      merchantId: '686386cc74755eccf65a0f26',
      deleverId: '6aa27a5c-cba8-46eb-a225-6e6aa3ce485c',
    ),
    'Loook Chilanzar': const BranchConfig(
      branchId: 5,
      sievesApiCode: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      sievesApiToken: 'd78fe61d-e901-415a-942c-dab83c361f0b',
      employeeId: 423,
      merchantId: '685bca7c04711a17e505cfcb',
      deleverId: '6185a3b8-c874-4f83-88b5-d5caf4a511c7',
    ),
    'Loook Maksim Gorkiy': const BranchConfig(
      branchId: 11,
      sievesApiCode: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      sievesApiToken: 'cfe6aa95-f035-431c-bd00-9a181c947b4a',
      employeeId: 423,
      merchantId: '6863871674755eccf65a0f37',
      deleverId: '04671531-ef4e-486f-8fe3-4dfcdead80f9',
    ),
    'Loook Boulevard': const BranchConfig(
      branchId: 14,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '686387fd74755eccf65a0f64',
      deleverId: '7c68b555-5fc5-4d8c-ac45-25360c05fdf5',
    ),
    'Ava Pizza': const BranchConfig(
      branchId: 15,
      sievesApiCode: '81e57435850af8fe58f8e6540cad5fd6',
      sievesApiToken: '81e57435850af8fe58f8e6540cad5fd6',
      employeeId: 423,
      merchantId: '6863879a74755eccf65a0f4d',
      deleverId: '',
    ),
    'Loook Yangiyol': const BranchConfig(
      branchId: 25,
      sievesApiCode: 'a2890a1395c57770f05fda46f4a83f07',
      sievesApiToken: 'a2890a1395c57770f05fda46f4a83f07',
      employeeId: 423,
      merchantId: '6863894974755eccf65a0f93',
      deleverId: '981422f2-326d-4ca7-97ce-0b7ebcbe0c49',
    ),
    'Loook High Town': const BranchConfig(
      branchId: 26,
      sievesApiCode: '8c4492755f4a0f0ee466ffb10c721335',
      sievesApiToken: '8c4492755f4a0f0ee466ffb10c721335',
      employeeId: 423,
      merchantId: '6863885274755eccf65a0f6e',
      deleverId: '',
    ),
  };

  static BranchConfig getConfig(String branchName) {
    return configs[branchName] ?? configs.values.first;
  }
}
