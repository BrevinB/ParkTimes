# Icon Composer kit — ParkTimes

Layered SVGs for Apple's Icon Composer (Xcode 26). Each file is a
1024x1024 layer with a transparent background, ordered bottom to top:

1. `1-Background.svg` — night gradient. In Icon Composer you can instead
   set a native gradient background with these stops:
   top `#251D6B` → mid `#141138` → bottom `#0C0C1F`.
2. `2-Stars.svg` — faint background stars (give the least depth).
3. `3-Track.svg` — the coaster track and loop (main glass layer).
4. `4-Car.svg` — the gold coaster car, separated so it catches its own
   specular highlight and floats above the track.
5. `5-Sparkles.svg` — gold sparkles (top layer, most depth; consider
   disabling tinting so they stay gold in tinted mode).

Usage: File → New in Icon Composer, drag layers in bottom-to-top order,
then tune per-layer glass/specular and check the dark + tinted variants.
The mono/tinted variant works because the track is a single flat color.

An alternate hot-air-balloon concept lives in `alternates/` — if you
prefer it, say so and it can be split into layers like the main kit.
