void example() {
  final date = DateFormat.yMMMMd('en_US').format(invitation.invitedAt.toLocal());
  final names = users.where((user) => user.active).map((user) => user.name).toList();
}
