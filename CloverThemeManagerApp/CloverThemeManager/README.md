The Clover Theme Manager application allows OS X users to view, install/uninstall and update themes for the [Clover](http://sourceforge.net/projects/cloverefiboot/) boot manager, directly from the [Clover theme repository](http://sourceforge.net/p/cloverefiboot/themes/ci/master/tree/).

This application is based on the objective-c [MacGap](https://github.com/MacGapProject/MacGap1) (MIT license) codebase which has been modified slightly to fit the purpose of this project.

### Overview of operation

When the app is launched, it starts public/bash/script.sh and then creates a web view window before loading public/index.html in to the window. The index.html loads a javascript file and both the bash script and javascript communicate to present the user a running app.

### Requirements
* OS X 10.7 updwards
* git needs to be installed on the users machine.

### Build

Just clone the repository and build in Xcode.
For ref, I’m currently using Xcode v6.1

### License

[GPL v3](http://opensource.org/licenses/GPL-3.0)