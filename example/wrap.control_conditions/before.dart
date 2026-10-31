void example() {
  if (user.isActive && user.hasVerifiedEmail && !user.isSuspended && user.age > 18) { grant(); }
}
