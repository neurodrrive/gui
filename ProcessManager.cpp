#include "ProcessManager.h"
#include <QDebug>
#include <QDir>

ProcessManager::ProcessManager(QObject *parent) 
    : QObject(parent)
{
}

ProcessManager::~ProcessManager()
{
    terminateAllProcesses();
}

void ProcessManager::setActiveModel(int model)
{
    if (m_activeModel != model) {
        m_activeModel = model;
        emit activeModelChanged(m_activeModel);
    }
}

void ProcessManager::setTrafficSignPath(const QString &path)
{
    m_trafficSignPath = path;
}

void ProcessManager::setDrowsinessPath(const QString &path)
{
    m_drowsinessPath = path;
}

void ProcessManager::setCombinedPath(const QString &path)
{
    m_combinedExtraPath = path;
}

void ProcessManager::startModel(int modelType)
{
    // If any model is currently running, stop it first
    stopCurrentModel();
    
    // Set the active model
    setActiveModel(modelType);
    
    // Start the selected model
    switch (static_cast<ModelType>(modelType)) {
        case TrafficSignRecognition:
            startTrafficSignRecognition();
            break;
        case Drowsiness:
            startDrowsinessDetection();
            break;
        case Combined:
            startCombinedModel();
            break;
        default:
            updateStatus("Invalid model selected");
            break;
    }
}

void ProcessManager::stopCurrentModel()
{
    terminateAllProcesses();
    setActiveModel(ModelType::None);
    m_isRunning = false;
    emit isRunningChanged(m_isRunning);
    updateStatus("Model stopped");
}

void ProcessManager::handleProcessError(QProcess::ProcessError error)
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;
    
    QString errorMessage;
    switch (error) {
        case QProcess::FailedToStart:
            errorMessage = "Process failed to start";
            break;
        case QProcess::Crashed:
            errorMessage = "Process crashed";
            break;
        default:
            errorMessage = "Process error: " + QString::number(error);
            break;
    }
    
    qWarning() << "Process error:" << errorMessage;
    emit processError(errorMessage);
    updateStatus("Error: " + errorMessage);
    
    m_isRunning = false;
    emit isRunningChanged(m_isRunning);
}

void ProcessManager::handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;
    
    // Find which model this process belongs to
    int modelType = m_processes.key(process, ModelType::None);
    
    if (exitStatus == QProcess::NormalExit) {
        updateStatus(QString("Process finished with exit code %1").arg(exitCode));
    } else {
        updateStatus("Process crashed");
    }
    
    emit processFinished(modelType, exitCode);
    
    // Check if any processes are still running
    bool anyRunning = false;
    for (auto proc : m_processes.values()) {
        if (proc->state() == QProcess::Running) {
            anyRunning = true;
            break;
        }
    }
    
    if (!anyRunning) {
        m_isRunning = false;
        emit isRunningChanged(m_isRunning);
    }
}

void ProcessManager::handleProcessStateChanged(QProcess::ProcessState state)
{
    if (state == QProcess::Running) {
        if (!m_isRunning) {
            m_isRunning = true;
            emit isRunningChanged(m_isRunning);
        }
    }
}

void ProcessManager::startTrafficSignRecognition()
{
    QProcess *process = new QProcess(this);
    
    // Connect signals
    connect(process, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            this, &ProcessManager::handleProcessError);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::handleProcessFinished);
    connect(process, &QProcess::stateChanged,
            this, &ProcessManager::handleProcessStateChanged);
    
    // Store the process
    if (m_processes.contains(ModelType::TrafficSignRecognition)) {
        delete m_processes[ModelType::TrafficSignRecognition];
    }
    m_processes[ModelType::TrafficSignRecognition] = process;
    
    // Start the process
    QStringList arguments;
    arguments << m_trafficSignPath;
    process->start("python", arguments);
    
    updateStatus("Traffic sign recognition started");
}

void ProcessManager::startDrowsinessDetection()
{
    QProcess *process = new QProcess(this);
    
    // Connect signals
    connect(process, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            this, &ProcessManager::handleProcessError);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::handleProcessFinished);
    connect(process, &QProcess::stateChanged,
            this, &ProcessManager::handleProcessStateChanged);
    
    // Store the process
    if (m_processes.contains(ModelType::Drowsiness)) {
        delete m_processes[ModelType::Drowsiness];
    }
    m_processes[ModelType::Drowsiness] = process;
    
    // Start the process
    QStringList arguments;
    arguments << m_drowsinessPath;
    process->start("python", arguments);
    
    updateStatus("Drowsiness detection started");
}

void ProcessManager::startCombinedModel()
{
    // Start traffic sign recognition process
    QProcess *trafficProcess = new QProcess(this);
    connect(trafficProcess, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            this, &ProcessManager::handleProcessError);
    connect(trafficProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::handleProcessFinished);
    connect(trafficProcess, &QProcess::stateChanged,
            this, &ProcessManager::handleProcessStateChanged);
    
    if (m_processes.contains(ModelType::TrafficSignRecognition)) {
        delete m_processes[ModelType::TrafficSignRecognition];
    }
    m_processes[ModelType::TrafficSignRecognition] = trafficProcess;
    
    // Start drowsiness detection process
    QProcess *drowsinessProcess = new QProcess(this);
    connect(drowsinessProcess, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            this, &ProcessManager::handleProcessError);
    connect(drowsinessProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::handleProcessFinished);
    connect(drowsinessProcess, &QProcess::stateChanged,
            this, &ProcessManager::handleProcessStateChanged);
    
    if (m_processes.contains(ModelType::Drowsiness)) {
        delete m_processes[ModelType::Drowsiness];
    }
    m_processes[ModelType::Drowsiness] = drowsinessProcess;
    
    // Start combined process
    QProcess *combinedProcess = new QProcess(this);
    connect(combinedProcess, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            this, &ProcessManager::handleProcessError);
    connect(combinedProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::handleProcessFinished);
    connect(combinedProcess, &QProcess::stateChanged,
            this, &ProcessManager::handleProcessStateChanged);
    
    if (m_processes.contains(ModelType::Combined)) {
        delete m_processes[ModelType::Combined];
    }
    m_processes[ModelType::Combined] = combinedProcess;
    
    // Start the processes
    QStringList trafficArgs;
    trafficArgs << m_trafficSignPath;
    trafficProcess->start("python", trafficArgs);
    
    QStringList drowsinessArgs;
    drowsinessArgs << m_drowsinessPath;
    drowsinessProcess->start("python", drowsinessArgs);
    
    QStringList combinedArgs;
    combinedArgs << m_combinedExtraPath;
    combinedProcess->start("python", combinedArgs);
    
    updateStatus("Combined model started");
}

void ProcessManager::terminateAllProcesses()
{
    for (auto process : m_processes) {
        if (process->state() != QProcess::NotRunning) {
            process->terminate();
            if (!process->waitForFinished(3000)) {
                process->kill();
            }
        }
    }
    
    // Clean up the processes
    qDeleteAll(m_processes.values());
    m_processes.clear();
}

void ProcessManager::updateStatus(const QString &message)
{
    m_statusMessage = message;
    emit statusMessageChanged(m_statusMessage);
    qDebug() << "ProcessManager:" << message;
} 