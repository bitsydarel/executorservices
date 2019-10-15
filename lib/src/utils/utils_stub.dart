/// todo: update check when type aliases will be available in dart.
Object createTaskIdentifier() => throw UnsupportedError(
      "Cannot create a task identifier without dart:html or dart:io.",
    );

/// Get the cpu count on the machine.
int getCpuCount() => throw UnsupportedError(
      "Cannot get cpu count without dart:html or dart:io.",
    );
