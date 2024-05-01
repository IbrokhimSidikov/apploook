class unboardingContent {
  String image;
  String title;
  String description;
  unboardingContent(
      {required this.description, required this.image, required this.title});
}

List<unboardingContent> contents = [
  unboardingContent(
      description: 'Pick your food from our menu\n',
      image: "images/coverMain.png",
      title: 'Select from Our\n  Best Menu'),
  unboardingContent(
      description:
          'You can pay cash on delivery and\n Card payment is available',
      image: "images/easyOnlinePayment.png",
      title: 'Easy and Online Payment'),
  unboardingContent(
      description: 'Deliver your food\n  on your doorstep',
      image: 'images/onboard_cover.png',
      title: 'Quick delivery at your doorstep')
];
