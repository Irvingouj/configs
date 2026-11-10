# Irving's design taste

How Irving wants code designed. Propose the version that matches this first.

## Explicit over clever

- Write one `match` arm per concrete type, such as `TaskJob::<RecordingAiAnalysis>::NAME => ..`.
  Adding a type later means adding an arm, and that's fine.
- No registries, no type erasure, no `Any` and `downcast`, no "kind" abstraction that a reader can't follow.
- Don't build generality for one user. One concrete case gets concrete code.

## Names say what the thing does

- A name must match the behavior. Something that doesn't run anything is not a "runner".
- If the name needs explaining, the name is wrong.

## Shared infrastructure stays generic

- Shared plumbing (a job queue, a job reader) never holds a field named after one feature, such as `ai_analysis`.
- Give it a generic context of shared services instead, and let each feature take what it needs from it.

## Parse at the border, inject dependencies separately

- Turn input (JSON, a database row) into plain data at the border. Parsing needs no services.
- Adding runtime dependencies is a separate, named step (for example "hydration"), not hidden inside parsing.

## Hold only what you use

- Give a type only the capability it calls. If it only pushes jobs, it holds a push-only handle,
  not the whole queue with its other methods.

## Working with me

- Do exactly what I say. Don't infer my intent, don't fix ahead, let the compile fail if I said so.
- Explain with the exact lines of code that changed, not prose, history, or comparisons with older versions.
- No unnecessary change: every line in a diff must be needed.
