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

public:
    explicit ProcessManager(QObject *parent = nullptr);
    ~ProcessManager();

    enum ModelType {
        None = 0,
        TrafficSignRecognition = 1,
        Drowsiness = 2,
        Combined = 3
    };
    Q_ENUM(ModelType)

    // Property getters
    int activeModel() const { return m_activeModel; }
    bool isRunning() const { return m_isRunning; }
    QString statusMessage() const { return m_statusMessage; }

    // Property setters
    void setActiveModel(int model);

    // Script paths configuration
    Q_INVOKABLE void setTrafficSignPath(const QString &path);
    Q_INVOKABLE void setDrowsinessPath(const QString &path);
    Q_INVOKABLE void setCombinedPath(const QString &path);

public slots:
    Q_INVOKABLE void startModel(int modelType);
    Q_INVOKABLE void stopCurrentModel();

signals:
    void activeModelChanged(int model);
    void isRunningChanged(bool running);
    void statusMessageChanged(const QString &message);
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
    void terminateAllProcesses();
    void updateStatus(const QString &message);

    int m_activeModel = ModelType::None;
    bool m_isRunning = false;
    QString m_statusMessage = "Ready";

    // Script paths
    QString m_trafficSignPath = "/home/root/traffic/tf/tf.py";
    QString m_drowsinessPath = "/home/root/DROWSINESS/tf/drowsiness_detectorr.py";
    QString m_combinedExtraPath = "/path/to/model3/script3.py";

    // Process management
    QMap<int, QProcess*> m_processes;
};

#endif // PROCESSMANAGER_H 