# Architecture Decision — Stage 09 Repository Layer

## Context

The original Stage 09 prompt asked for: schema, migrations, **repositories**, CRUD, and tests.
The skeleton project delivered schema + migrations + repository *contracts* (10 abstract
classes in `lib/domain/repositories/repositories.dart`), but never wrote the concrete
implementations. Stage 16 (PDF Review) also shipped with mock data instead of real
`DetectedQuestion` entities.

This document records the architectural decision made when filling in those gaps.

## Decision: Hybrid (Option A) — Repositories for CRUD, engines stay direct

**Repositories are the data-access layer for UI-facing CRUD on domain entities.**
**Engines keep direct access to `AppDatabase` for complex business logic.**

### Why hybrid (not "everything through repositories")

1. **Engines already encapsulate non-trivial business logic that is *not* CRUD.**
   - `GradingEngine` computes deterministic scores with negative marking — pure function,
     no persistence concern.
   - `Sm2ReviewScheduler` runs the SM-2 algorithm and then persists via `ReviewRepository`.
     Wrapping the algorithm itself in a repository would mix concerns.
   - `BackupService` orchestrates ZIP archiving + SHA-256 + manifest — cross-table bulk
     export, not single-table CRUD.
   - `AnalyticsEngine` runs aggregate SQL across `exam_results`, `questions`, `mistakes` —
     forcing it through 3 separate repositories would force N+1 queries and lose the
     single-SQL optimization.

2. **The repository abstraction has the most value where UI calls simple CRUD on a
   single table.** That is exactly what the 10 repository contracts model. UI screens
   (Question Bank, Subject list, Tags, Notes, Backup list, Mistakes, Reviews) get the
   clean contract; engines don't need it because they're already cohesive.

3. **Stage 09's contract scope is "repositories + CRUD + tests"** — not "everything in
   the app must go through repositories." Engines were specified separately in Stages
   19/22/23/24/25 with their own contracts (`ExamEngine`, `AnalyticsEngine`, etc.).

4. **Engines can still call repositories internally** where it makes sense:
   - `MistakeManager` will use `MistakeRepository` + `QuestionRepository` for cross-table
     concerns.
   - `Sm2ReviewScheduler` uses `ReviewRepository` for persistence.
   - `BackupService` reads from repositories for export.
   This is layered correctly: engines sit *above* repositories, UI sits *above* engines
   OR repositories depending on whether the operation is CRUD or business logic.

### Concrete layering

```
┌─────────────────────────────────────────────┐
│  UI (presentation/screens)                  │
│  Uses AsyncValue.when(loading/error/data)   │
└─────────────────┬───────────────────────────┘
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
┌──────────────┐    ┌─────────────────────┐
│ Repositories │    │ Engines             │
│ (CRUD on     │    │ (business logic —   │
│  entities)   │    │  uses repositories  │
│              │    │  OR database)       │
└──────┬───────┘    └──────────┬──────────┘
       │                       │
       └───────────┬───────────┘
                   ▼
          ┌─────────────────┐
          │ DAOs (per-table │
          │ query helpers)  │
          └────────┬────────┘
                   ▼
          ┌─────────────────┐
          │   AppDatabase   │
          │   (drift)       │
          └─────────────────┘
```

### What this means for each layer

| Layer | File pattern | Responsibility |
|-------|-------------|---------------|
| Domain entities | `lib/domain/entities/entities.dart` | Pure data classes (freezed) |
| Repository contracts | `lib/domain/repositories/repositories.dart` | Abstract interfaces — UNCHANGED |
| DAOs (new) | `lib/data/database/daos/daos.dart` | Per-table query helpers (plain classes, not `@DriftAccessor` to avoid build_runner coupling) |
| Repository impls (new) | `lib/data/repositories/implementations/*.dart` | Concrete classes implementing contracts, using DAOs, doing entity↔row mapping |
| Engines | `lib/features/*` | Business logic; can use repositories or database directly (UNCHANGED per "do not touch lib/features/*" constraint) |
| ServiceContainer | `lib/services/service_container.dart` | Wires repositories + engines |
| Providers | `lib/presentation/providers/*.dart` | Riverpod providers, split by feature area |

### Trade-off acknowledged

- Engines (`MistakeManager`, `Sm2ReviewScheduler`, `AnalyticsEngine`, `BackupService`,
  `SettingsService`) remain stubs that don't yet call the database. **This is a pre-existing
  limitation from Stages 19/22/23/24/25/26** — the user's instruction explicitly forbids
  touching `lib/features/*`. Where UI screens previously relied on these stub engines
  (returning empty/default data), I rewired them to use repositories directly so the UI
  shows real data. Engines will be filled in a future pass (post-Stage 31 in the original
  roadmap, or a follow-up task) without breaking the repository layer.

### Why plain DAO classes (not `@DriftAccessor`)

Drift's `@DriftAccessor` annotation requires regeneration of `app_database.g.dart` to add
DAO accessor getters to `_$AppDatabase`. By using **plain classes that take `AppDatabase`
as a constructor parameter**, we:
- Avoid modifying the `@DriftDatabase` annotation in `app_database.dart`
- Avoid coupling DAO compilation to build_runner
- Still encapsulate per-table queries cleanly
- Keep `daos.dart` self-contained and testable

The drift table-accessor pattern (`db.subjects`, `db.questions`, etc.) is used inside
the DAO classes — that's the standard drift generated API and is stable.
