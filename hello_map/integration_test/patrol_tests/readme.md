# Patrol Test
In this directory should be placed tests which require native interaction and must use Patrol package.

## Requirements
Make sure the terminal is opened inside the example directory before running any of the commands below.

## Running tests on real device
`patrol test --release -t integration_test/patrol_tests/patrol_test.dart --verbose`

## Debugging
`patrol develop -t integration_test/patrol_tests/patrol_test.dart --device "emulator-5554"`


## Configure Patrol
Follow instructions from the [patrol documentation website](https://patrol.leancode.co/getting-started#install-patrol_cli).
Make sure `patrol doctor` does not report any issues.

For running on Android make sure the gradle version matches the Java version. Refer to the [compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html).

### Extra steps for Windows
- Make sure the ANDROID_HOME and JAVA_HOME env variables are set.
- Add the `Pub\Cache\bin` directory to the PATH env variable.
- Add the `Android\Sdk\platform_tools` directory to the PATH env variable
