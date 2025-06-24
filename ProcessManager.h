#ifndef PROCESSMANAGER_H
#define PROCESSMANAGER_H

#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <QMap>

class ProcessManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int activeModel READ activeModel WRITE setActiveModel NOTIFY activeModelChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QString pythonExecutable READ pythonExecutable WRITE setPythonExecutable NOTIFY pythonExecutableChanged)

public:
    explicit ProcessManager(QObject *parent = nullptr);
    ~ProcessManager();

    enum ModelType {
        None = 0,
        TrafficSignRecognition = 1,
        Drowsiness = 2,
        Combined = 3,
        LaneDetection = 4
    };
    Q_ENUM(ModelType)

    // Property getters
    int activeModel() const { return m_activeModel; }
    bool isRunning() const { return m_isRunning; }
    QString statusMessage() const { return m_statusMessage; }
    QString pythonExecutable() const { return m_pythonExecutable; }

    // Property setters
    void setActiveModel(int model);
    void setPythonExecutable(const QString &executable);

    // Script paths configuration
    Q_INVOKABLE void setTrafficSignPath(const QString &path);
    Q_INVOKABLE void setDrowsinessPath(const QString &path);
    Q_INVOKABLE void setCombinedPath(const QString &path);
    Q_INVOKABLE void setLaneDetectionPath(const QString &path);
    
    // Get current paths
    Q_INVOKABLE QString getTrafficSignPath() const { return m_trafficSignPath; }
    Q_INVOKABLE QString getDrowsinessPath() const { return m_drowsinessPath; }
    Q_INVOKABLE QString getCombinedPath() const { return m_combinedExtraPath; }
    Q_INVOKABLE QString getLaneDetectionPath() const { return m_laneDetectionPath; }

public slots:
    Q_INVOKABLE void startModel(int modelType);
    Q_INVOKABLE void stopCurrentModel();
    Q_INVOKABLE void testPythonEnvironment();

signals:
    void activeModelChanged(int model);
    void isRunningChanged(bool running);
    void statusMessageChanged(const QString &message);
    void pythonExecutableChanged(const QString &executable);
    void processError(const QString &error);
    void processFinished(int modelType, int exitCode);

private slots:
    void handleProcessError(QProcess::ProcessError error);
    void handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleProcessStateChanged(QProcess::ProcessState state);

private:
    void startTrafficSignRecognition();
    void startDrowsinessDetection();
    void startCombinedModel();
    void startLaneDetection();
    void terminateAllProcesses();
    void updateStatus(const QString &message);

    int m_activeModel = ModelType::None;
    bool m_isRunning = false;
    QString m_statusMessage = "Ready";
    QString m_pythonExecutable = "python3";  // Default to python3 for Linux

    // Script paths - Linux paths as specified
    QString m_trafficSignPath = "/home/abdelrhman/Documents/traffic_signs_detection_3/main.py";
    QString m_drowsinessPath = "/home/abdelrhman/Documents/drowsiness_detection_f3/main.py";
    QString m_combinedExtraPath = "/path/to/model3/script3.py";
    QString m_laneDetectionPath = "/home/abdelrhman/Documents/models/lane_detection_3/main.py";

    // Process management
    QMap<int, QProcess*> m_processes;
};

#endif // PROCESSMANAGER_H 