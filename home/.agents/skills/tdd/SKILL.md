---
name: tdd
description: Test-driven development with red-green-refactor loop.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** verify observable behavior through public interfaces rather than private implementation details. For pure or deterministic domain logic, a focused unit test through the public API is fine; reach for integration-style tests — exercising real code paths through public APIs — where collaboration, persistence, authorization, or serialization is part of the contract. A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators to assert on call sequences, test private methods, or verify internals that aren't the behavior under test (e.g. peeking at a database to check plumbing when the interface already exposes the result). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior. Exception: when persistence, transactions, or durability *are* the behavior under test, asserting on the store directly is legitimate — a response-only assertion could miss state that was never actually saved.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via specific tests. One behavior (or a small cohesive cluster) → implementation → repeat.
```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2, test3 (one cohesive cluster)→impl2
  RED→GREEN: test4→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, use the project's domain glossary so that test names and interface vocabulary match the project's language.

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### 2. Interface Sketch

Before the first test, sketch the public interface this piece of work needs: signatures, types, error shapes. Prefer declarations (types, interfaces, exported no-op signatures) or test fixtures over production dummy behavior — the sketch exists to make the test path resolvable, not to fake results. Sketch first deliberately: it makes RED meaningful (the failure you see is about missing behavior, not about an unresolvable import you didn't plan for), and it gives your editor/LSP something to work with while writing tests.

Treat the sketch as **provisional** — tests and implementation are allowed to reshape it. Extend it minimally, only when the current test demands it; never sketch ahead for future cycles.

### 3. Smoke Test

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → run it → watch it fail for the
       intended reason (assertion failure, or a compile/import failure
       while the interface sketch is being established)
GREEN: Write minimal code to pass → test passes
```

This is your "smoke test" - proves the path works end-to-end.

### 4. Incremental Loop

For each remaining behavior:

```
RED:   Write next test(s) → run → watch each fail for its intended reason:
       - expected once the path is runnable: an assertion failure
       - acceptable while establishing the interface: a compile/import/
         missing-symbol failure → extend the sketch minimally (only what
         this test needs) and re-run; after that, require the assertion
         failure
       - never acceptable: harness, fixture, or environment breakage
GREEN: Minimal code to pass → passes
```

A cycle covers **one behavior, or a small cohesive cluster** of behaviors (e.g. a happy path plus its two closely-related edge cases on the same interface). The unit is not "exactly one test" — it is "tests you can watch fail for distinct, intended reasons".

Rules:

- Every RED test must be **observed failing for its intended reason** — keep the failure output. Once the test path is runnable, that means an assertion failure; a transient compile/import failure is only valid as evidence that the interface sketch still needs establishing for *this* test. A test never seen failing might be testing nothing.
- Never write a test for a behavior whose interface you haven't sketched (declarations or fixtures ok; production dummies only as a last resort, and remove them in GREEN).
- Only enough code to pass current tests
- Don't anticipate future tests
- Keep tests focused on observable behavior
- **Tripwire**: batching more than ~3 tests in one RED, or a GREEN phase much heavier than its RED phase, means you've drifted horizontal — stop and split the cycle.

### 4b. Bug Fixes: Reproduce First

Before touching any implementation:

```
RED:   Write a test that reproduces the bug through the public interface
       → observe it failing with the bug's signature
GREEN: Fix → the reproduction test passes
```

Keep the reproduction test as a regression guard.

### 5. Refactor

Refactor after cycles go green, and opportunistically when a third test reveals duplication (rule of three) — don't wait until "the end". **Never refactor while RED.** Get to GREEN first.

Refactor candidates:

- [ ] Extract duplication
- Deepen modules (move complexity behind simple interfaces)
- Apply SOLID principles where natural
- Consider what new code reveals about existing code
- Run tests after each refactor step

## When NOT to TDD (escape hatches)

Test-first only pays off when you can state the expected behavior. When you can't, don't cargo-cult:

- **Pure config, glue code, one-off scripts**: verify by running them; a test suite adds ceremony, not safety.
- **Unknown domain / unfamiliar API / exploratory data work**: timebox a throwaway **spike** to learn what the behavior even is — then discard the spike code and TDD the real thing with what you learned.
- **Throwaway prototypes**: if the code won't outlive the question it answers, skip the tests.

A spike is not an excuse to skip TDD on code you keep: spike code gets deleted, kept code gets tests.

## Checklist Per Cycle

```
[ ] Interface sketched before tests run (declarations/fixtures, provisional)
[ ] Every RED test observed failing for its intended reason (assertion once runnable)
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for these tests
[ ] No speculative features added
```

# When to use the skill

Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.

Also use when the file(s) you'll be editing already have some test coverage - we want to keep the test coverage up and
doing it with TDD is the best approach.
