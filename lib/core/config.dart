/// Where Verto looks for language packs and app updates.
/// Change [owner] / [repo] if the GitHub repository lives somewhere else.
class Config {
  static const String owner = 'lumio-apps';
  static const String repo = 'verto';

  static const String packsBaseUrl =
      'https://github.com/$owner/$repo/releases/download/packs/';
  static const String packsManifestUrl = '${packsBaseUrl}manifest.json';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$owner/$repo/releases/latest';
  static const String repoUrl = 'https://github.com/$owner/$repo';
}
