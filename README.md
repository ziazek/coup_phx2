# CoupPhx2

```
mix edeliver build release production --verbose
mix edeliver deploy release to production
```

## Next up

- [done] Show error message when game start without sufficient players
- Test self-sent messages e.g. `Process.send_after(self(), {:draw_card, 0}, 1_000)`

## Feature list

- should indicate whether user is online or offline based on Presence
