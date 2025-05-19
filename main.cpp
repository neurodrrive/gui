#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "NetworkService.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Create network service instance
    NetworkService networkService;

    QQmlApplicationEngine engine;
    
    // Register the network service to QML
    engine.rootContext()->setContextProperty("networkService", &networkService);
    
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("NeuroDrive_13_5_2025", "Main");

    return app.exec();
}
