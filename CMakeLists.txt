cmake_minimum_required(VERSION 3.16)

project(NeuroDrive_13_5_2025 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

set(PROJECT_SOURCES
    main.cpp
    NetworkService.h
    NetworkService.cpp
)

qt_add_executable(appNeuroDrive_13_5_2025
    ${PROJECT_SOURCES}
)

qt_add_qml_module(appNeuroDrive_13_5_2025
    URI NeuroDrive_13_5_2025
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/pages/LoginPage.qml
        qml/components/FeatureButton.qml
    RESOURCES
        img/youssef.jpg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appNeuroDrive_13_5_2025 PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appNeuroDrive_13_5_2025
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appNeuroDrive_13_5_2025
    PRIVATE Qt6::Quick Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appNeuroDrive_13_5_2025
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Copy necessary QML files to build directory
install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/img/youssef.jpg
    DESTINATION ${CMAKE_INSTALL_BINDIR}/img
)
