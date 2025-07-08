#include "ProcessManager.h"
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QTimer>
#include <QFile>

ProcessManager::ProcessManager(QObject *parent) 
    : QObject(parent)
{
    // Try to detect the best Python executable
    QProcess pythonTest;
    pythonTest.start("python3", QStringList() << "--version");
    if (pythonTest.waitForFinished(3000) && pythonTest.exitCode() == 0) {
        m_pythonExecutable = "python3";
    } else {
        pythonTest.start("python", QStringList() << "--version");
        if (pythonTest.waitForFinished(3000) && pythonTest.exitCode() == 0) {
            m_pythonExecutable = "python";
        } else {
            m_pythonExecutable = "python3";  // Default fallback
        }
    }
    updateStatus("ProcessManager initialized with " + m_pythonExecutable);
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

void ProcessManager::setPythonExecutable(const QString &executable)
{
    if (m_pythonExecutable != executable) {
        m_pythonExecutable = executable;
        emit pythonExecutableChanged(m_pythonExecutable);
        updateStatus("Python executable set to: " + m_pythonExecutable);
    }
}

void ProcessManager::setTrafficSignPath(const QString &path)
{
    m_trafficSignPath = path;
    updateStatus("Traffic sign path set to: " + path);
}

void ProcessManager::setDrowsinessPath(const QString &path)
{
    m_drowsinessPath = path;
    updateStatus("Drowsiness path set to: " + path);
}

void ProcessManager::setCombinedPath(const QString &path)
{
    m_combinedExtraPath = path;
    updateStatus("Combined path set to: " + path);
}

void ProcessManager::setLaneDetectionPath(const QString &path)
{
    m_laneDetectionPath = path;
    updateStatus("Lane detection path set to: " + path);
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
        case LaneDetection:
            startLaneDetection();
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
            errorMessage = "Process failed to start - check if " + m_pythonExecutable + " is installed";
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
    
    // Capture stderr output for debugging
    QByteArray stderrData = process->readAllStandardError();
    QByteArray stdoutData = process->readAllStandardOutput();
    
    QString modelName;
    switch (static_cast<ModelType>(modelType)) {
        case TrafficSignRecognition: modelName = "Traffic Sign"; break;
        case Drowsiness: modelName = "Drowsiness"; break;
        case LaneDetection: modelName = "Lane Detection"; break;
        case Combined: modelName = "Combined"; break;
        default: modelName = "Unknown"; break;
    }
    
    if (exitStatus == QProcess::NormalExit) {
        if (exitCode == 0) {
            updateStatus(QString("%1 process finished successfully").arg(modelName));
        } else {
            QString errorMsg = QString("%1 process finished with exit code %2").arg(modelName).arg(exitCode);
            if (!stderrData.isEmpty()) {
                errorMsg += QString(" - Error: %1").arg(QString::fromUtf8(stderrData));
            }
            updateStatus(errorMsg);
            qWarning() << modelName << "Process stderr:" << stderrData;
            qWarning() << modelName << "Process stdout:" << stdoutData;
        }
    } else {
        updateStatus(QString("%1 process crashed").arg(modelName));
        if (!stderrData.isEmpty()) {
            qWarning() << modelName << "Process stderr before crash:" << stderrData;
        }
    }
    
    // Always print stdout if available for debugging
    if (!stdoutData.isEmpty()) {
        qDebug() << modelName << "Process stdout:" << stdoutData;
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
    
    // Set working directory to the script's directory
    QFileInfo scriptInfo(m_trafficSignPath);
    if (scriptInfo.exists()) {
        process->setWorkingDirectory(scriptInfo.absolutePath());
        updateStatus("Working directory set to: " + scriptInfo.absolutePath());
    } else {
        updateStatus("Warning: Script file does not exist at " + m_trafficSignPath);
    }
    
    // Remove the old output video file if it exists
    QString outputPath = scriptInfo.absolutePath() + "/output.avi";
    QFile::remove(outputPath);
    updateStatus("Starting video processing... This may take several minutes on Raspberry Pi");
    
    // Start the process
    QStringList arguments;
    arguments << m_trafficSignPath;
    process->start(m_pythonExecutable, arguments);
    
    // Use a shorter timeout for initial start
    if (!process->waitForStarted(3000)) {
        updateStatus("Failed to start traffic sign recognition process");
        return;
    }
    
    updateStatus("Traffic sign recognition started with " + m_pythonExecutable + " in " + process->workingDirectory());
    
    // Set up a timer to provide progress updates
    QTimer *progressTimer = new QTimer(this);
    progressTimer->setSingleShot(false);
    progressTimer->setInterval(5000); // Check every 5 seconds
    int progressCounter = 0;
    connect(progressTimer, &QTimer::timeout, [this, process, progressTimer, progressCounter]() mutable {
        if (process->state() == QProcess::Running) {
            progressCounter++;
            QString dots = QString(".").repeated((progressCounter % 4) + 1);
            updateStatus(QString("Processing video%1 (%2s elapsed)").arg(dots).arg(progressCounter * 5));
        } else {
            progressTimer->deleteLater();
        }
    });
    progressTimer->start();
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
    
    // Set working directory to the script's directory
    QFileInfo scriptInfo(m_drowsinessPath);
    if (scriptInfo.exists()) {
        process->setWorkingDirectory(scriptInfo.absolutePath());
        updateStatus("Working directory set to: " + scriptInfo.absolutePath());
    } else {
        updateStatus("Warning: Script file does not exist at " + m_drowsinessPath);
    }
    
    // Start the process
    QStringList arguments;
    arguments << m_drowsinessPath;
    process->start(m_pythonExecutable, arguments);
    
    // Wait a bit to see if it starts successfully
    if (!process->waitForStarted(5000)) {
        updateStatus("Failed to start drowsiness detection process");
        return;
    }
    
    updateStatus("Drowsiness detection started with " + m_pythonExecutable + " in " + process->workingDirectory());
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
    trafficProcess->start(m_pythonExecutable, trafficArgs);
    
    QStringList drowsinessArgs;
    drowsinessArgs << m_drowsinessPath;
    drowsinessProcess->start(m_pythonExecutable, drowsinessArgs);
    
    QStringList combinedArgs;
    combinedArgs << m_combinedExtraPath;
    combinedProcess->start(m_pythonExecutable, combinedArgs);
    
    updateStatus("Combined model started with " + m_pythonExecutable);
}

void ProcessManager::startLaneDetection()
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
    if (m_processes.contains(ModelType::LaneDetection)) {
        delete m_processes[ModelType::LaneDetection];
    }
    m_processes[ModelType::LaneDetection] = process;
    
    // Set working directory to the script's directory
    QFileInfo scriptInfo(m_laneDetectionPath);
    if (scriptInfo.exists()) {
        process->setWorkingDirectory(scriptInfo.absolutePath());
        updateStatus("Working directory set to: " + scriptInfo.absolutePath());
    } else {
        updateStatus("Warning: Script file does not exist at " + m_laneDetectionPath);
    }
    
    // Start the process
    QStringList arguments;
    arguments << m_laneDetectionPath;
    
    // Print the exact command we're running for debugging
    QString command = m_pythonExecutable + " " + m_laneDetectionPath;
    qDebug() << "Running lane detection command:" << command;
    
    process->start(m_pythonExecutable, arguments);
    
    // Wait a bit to see if it starts successfully
    if (!process->waitForStarted(5000)) {
        updateStatus("Failed to start lane detection process");
        return;
    }
    
    updateStatus("Lane detection started with " + m_pythonExecutable + " in " + process->workingDirectory());
    
    // Set up a timer to check process status periodically
    QTimer *laneStatusTimer = new QTimer(this);
    laneStatusTimer->setSingleShot(false);
    laneStatusTimer->setInterval(10000); // Check every 10 seconds
    connect(laneStatusTimer, &QTimer::timeout, [this, process, laneStatusTimer]() {
        if (process->state() == QProcess::Running) {
            updateStatus("Lane detection process still running...");
        } else {
            laneStatusTimer->deleteLater();
        }
    });
    laneStatusTimer->start();
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

void ProcessManager::testPythonEnvironment()
{
    QProcess *testProcess = new QProcess(this);
    
    // Test if Python executable exists and is working
    connect(testProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, testProcess](int exitCode, QProcess::ExitStatus exitStatus) {
                QByteArray output = testProcess->readAllStandardOutput();
                QByteArray error = testProcess->readAllStandardError();
                
                if (exitCode == 0) {
                    updateStatus("Python test successful: " + QString::fromUtf8(output).trimmed());
                } else {
                    updateStatus("Python test failed - Exit code: " + QString::number(exitCode) + 
                               " Error: " + QString::fromUtf8(error));
                }
                
                testProcess->deleteLater();
            });
    
    connect(testProcess, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
            [this, testProcess](QProcess::ProcessError error) {
                QString errorMsg = "Python test error: ";
                switch (error) {
                    case QProcess::FailedToStart:
                        errorMsg += "Failed to start - check if " + m_pythonExecutable + " is installed";
                        break;
                    default:
                        errorMsg += "Error code " + QString::number(error);
                        break;
                }
                updateStatus(errorMsg);
                testProcess->deleteLater();
            });
    
    updateStatus("Testing Python environment...");
    testProcess->start(m_pythonExecutable, QStringList() << "--version");
    
    if (!testProcess->waitForStarted(3000)) {
        updateStatus("Failed to start Python test");
        testProcess->deleteLater();
    }
} 