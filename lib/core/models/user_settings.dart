class UserSettings {
  final bool notificationsEnabled;
  final bool remindersEnabled;
  final bool autoSyncEnabled;

  // Desktop-specific settings
  final bool launchOnStartup;
  final String defaultDownloadFolder;
  final bool openLinksInDefaultBrowser;
  final bool rememberWindowPosition;

  UserSettings({
    this.notificationsEnabled = true,
    this.remindersEnabled = false,
    this.autoSyncEnabled = true,
    this.launchOnStartup = false,
    this.defaultDownloadFolder = '',
    this.openLinksInDefaultBrowser = true,
    this.rememberWindowPosition = true,
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'remindersEnabled': remindersEnabled,
    'autoSyncEnabled': autoSyncEnabled,
    'launchOnStartup': launchOnStartup,
    'defaultDownloadFolder': defaultDownloadFolder,
    'openLinksInDefaultBrowser': openLinksInDefaultBrowser,
    'rememberWindowPosition': rememberWindowPosition,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    notificationsEnabled: json['notificationsEnabled'] ?? true,
    remindersEnabled: json['remindersEnabled'] ?? false,
    autoSyncEnabled: json['autoSyncEnabled'] ?? true,
    launchOnStartup: json['launchOnStartup'] ?? false,
    defaultDownloadFolder: json['defaultDownloadFolder'] ?? '',
    openLinksInDefaultBrowser: json['openLinksInDefaultBrowser'] ?? true,
    rememberWindowPosition: json['rememberWindowPosition'] ?? true,
  );
}
