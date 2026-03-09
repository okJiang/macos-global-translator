# Provider Adapter Playbook

1. Create an issue named `Add <Provider> adapter`.
2. Create a branch named `codex/provider-<provider>`.
3. Add a new `TranslationProvider` implementation under `GlobalTranslator/Services/Providers/<Provider>/`.
4. Add fixture-backed contract tests under `GlobalTranslatorTests/Contracts/`.
5. Add a provider entry to `ProviderRegistry`.
6. Add any provider-specific settings labels to `SettingsView`.
7. Run local verification and CI, then open and merge the PR.
