# CoupPhx2

```
mix edeliver build release production --verbose
mix edeliver deploy release to production
```

## Next up


## Feature roadmap

- should indicate whether user is online or offline based on Presence
- should show exclamation mark if an action is "unsafe" (is a bluff)
- should show individual toasts, which should expire after 5 seconds.
- help screen
- player avatars (randomly assigned)
- card art - follow Coup colours
- countdown timer - always default to some action
- default action on 'select target' step should incur a coin penalty

### Lower priority features

- handle user joining an already-started game

### Individual toasts

Change the game state, but only broadcast to the relevant user so as not to trigger a socket push for other users.
