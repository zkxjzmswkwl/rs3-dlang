`tracker.d` needs to be able to support all Skills, not just one as we have now for the PoC.

Should use skill ids when communicating between `rsd-frontend` and `rsd` to simplify things.
Lets us skip the hooplah of performing multiple lookups of `skillId->skillName/address` on either end.

