# Enterprise Error Handling
- Never expose raw `PostgrestException`.
- Map to `Failure` object:
  - `NetworkFailure`
  - `ServerFailure`
  - `AuthFailure`
- UI must always reflect state via `RxStatus` or specific Failure states.