class BranchData {
  static final Map<String, String> branchAddresses = {
    "Loook Beruniy": "Toshkent, O'zbekiston yo'nalishi, Beruniy metro bekati, `Korzinka` binosi, 3-qavat",
    "Loook Yunusobod": "Ahmad Donish ko'chasi, 1A, Yunusobod metro bekati",
    "Loook Chilanzar": "Toshkent, Chilonzor tumani, Chilonzor dahasi, M-mavze, Gulbozor yonida",
    "Loook Maksim Gorkiy": "Toshkent, Buyuk Ipak Yo'li ko'chasi, 3",
    "Loook Boulevard": "Toshkent, O'qchi ko'chasi, 3A, `Boulevard` resident kompleks",

  };

  static String getBranchAddress(String? branch) {
    return branch != null && branchAddresses.containsKey(branch)
        ? branchAddresses[branch]!
        : "";
  }
}
