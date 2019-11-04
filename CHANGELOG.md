## 1.0.0

- Initial version, with support for Isolate executor service.

## 1.0.1

- Updated the documentation.

## 1.0.2

- Added support for functions that does not return a future.

## 1.0.3

- Added support for functions that does not return a future on WEB also.

## 1.0.4

- Updated the readme to demonstrate the new feature, updated the task classes to support  to return FutoreOr.

## 1.0.5

- Added shutdown for last oldest unused isolate to free memory gradually.

## 1.0.6

- Added possibility to re-submit the same instance of a task to an ExecutorService.

## 2.0.0

- Added subscribable task feature.

- Subscribable tasks can emit many values before completing.

- Subscribable task's result is a stream, which mean that you can pause, resume and cancel it.

## 2.0.0+1

- Added example for subscribable tasks.

## 2.0.1

- Changed LICENSE from GPL 3 to BSD-3 to allow more adoption.

## 2.0.2

- Cleaner documentation for each methods provided by the library

## 2.0.2+1

- Removed dependency on meta 1.1.8 to allow integration in old flutter projects.
