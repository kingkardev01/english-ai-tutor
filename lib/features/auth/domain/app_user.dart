class AppUser {
  const AppUser({required this.uid, this.name, this.email, this.photoUrl});

  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
}
