## Unreleased

- BREAKING: removed legacy key-based APIs (`OtaLocalizations`,
  `OtaLocalizationsDelegate`, `OtaLocalizationBuilder`).
- BREAKING: `OtaLocalizationController` no longer accepts `baseUrl`; API host is
  fixed to `https://rerune.io/api`.
- Added typed `AppLocalizations` overlay flow with
  `OtaTypedLocalizationBuilder<T>`.
- Added generator entrypoint `dart run rerune_flutter_ota:generate` for
  producing typed OTA wrappers.

## 0.0.1

- Initial release of the OTA localization SDK.
- Manifest-based ARB updates with ETag support and local caching.
- Hot-swap localization delegate with Rerune-hosted manifest URLs.
