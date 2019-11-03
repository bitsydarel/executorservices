import "dart:io";
import "dart:isolate";

/// Hack for creating something similar to type alias.
/// And use [Capability].
///
/// We could use something like:
///
/// ```
/// mixin _TaskIdentifierMarker {}
///
/// class TaskIdentifier = Capability with _TaskIdentifierMarker;
/// ```
///
/// But since [Capability] does not have
/// an unnamed constructor it's not possible.
///
/// todo: update check when type aliases will be available in dart.
Object createTaskIdentifier() => Capability();

/// Get the cpu count on the machine.
int getCpuCount() => Platform.numberOfProcessors;
