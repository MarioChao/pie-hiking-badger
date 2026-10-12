# Changelogs

## [v1.1.2] Badge filter + Gui scaling + Optimization | 2026/10/11 (2)

Added filtering and sorting for pie hiking challenges.
- Filter:
  - Plaintext search (creator, game name, badge name, badge description, tier).
  - Badge ownership (all, own, not owned).
- Sort:
  - Default.
  - Ascending/descending tier (`+ Tier`, `- Tier`).
  - Ascending/descending badge name (`+ Name`, `- Name`).
- These are optimized such that updates are applied only when a setting is modified.

Added `AutoUIScale` for the menu gui. The code is adapted from the [Pie Hiking Plugin](https://github.com/MarioChao/pie-hiking-plugin/).

Made some optimizations on loading pie hiking challenges.
- Initially, all badge frames are loaded from stored data.
- Specific badge data (name, description, icon) are loaded & updated later. This step can take some time due to the `BadgeService` rate limit.

## [v1.1.1] Badge scripts refactoring | 2026/10/11 (1)

Replaced `BadgeEvents` and the `Badge` server script with direct calls to `BadgeUtil`.

Refactored `GiveRankBadge` into a module.
* Migrated `GiveRankBadgeRemote` to [`BelovedRemote`](https://github.com/MarioChao/beloved-remote).
* The module is activated through `ServerMain`.

## [v1.1.0] Data optimization | 2026/08/30

Added new data store `CombinedUserInfo` for retrieving all ranks & usernames more efficiently.
- Migrated the Hiker Hall to use this data store, greatly improving the retrieval time.
- Also allows much more ranks to be retrieved in the future.
- The old data store `TestedRank` is still used for storing personal rank data.

Populated `CombinedUserInfo` with all data from `TestedRank` via the `DataMigration` script.

## [v1.0.3] Player name cache + Auto refresh | 2026/03/14

`GetNameFromUserIdAsync()` is now cached in memory store.
- The cache expires every hour.

Added auto refresh to Hiker's Hall.
- Clears & refreshes data every hour.
- Refresh time is also displayed.

## [v1.0.2] Hiker's hall | 2026/03/12 (2)

Added script for Hiker's Hall (Hall of Hikers).
- Reads data store through `DataStoreReader`.
- Displays all users categorized by ranks.

## [v1.0.1] Badge Util migration + Small changes | 2026/03/12 (1)

Replaced badge modules with [`BadgeUtil`](https://github.com/MarioChao/badge-util).

Slightly changed how throttle is used in the `GiveRankBadge` script.
