luneos-components
=================

Summary
-------
Customized components for QML UI in LuneOS.

How to use test it in desktop environment
-----------------------------------------
By default, the qmake configuration is made so that it smoothly compiles in LuneOS. On a desktop environment, some steps must be done before being able to use it.

 - Open the toplevel luneos-components with QtCreator
 - In the Build tab of the project configuration (Projects page, on the left of QtCreator window)
   - Deactivate "Shadow Build"
   - Add "CONFIG+=desktop" as additional arguments to the qmake compilation
 - In the Run tab of the project configuration, in the "Run" area
   - Set "qmlscene" as executable
   - Set "-I modules -I test/imports examples/gallery/main.qml" as arguments
   - In the execution environment, use the compilation environment and add the "QT\_QUICK\_CONTROLS\_STYLE=LuneOS" environment variable


