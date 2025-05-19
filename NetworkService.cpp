#include "NetworkService.h"
#include <QDebug>
#include <QFileInfo>
#include <QCoreApplication>
#include <QSslSocket>

NetworkService::NetworkService(QObject *parent) : QObject(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
    
    // Set up SSL configuration to ignore certificate validation (FOR DEVELOPMENT ONLY!)
    m_sslConfig = QSslConfiguration::defaultConfiguration();
    m_sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    
    qDebug() << "SSL support available:" << QSslSocket::supportsSsl();
    qDebug() << "SSL library version:" << QSslSocket::sslLibraryVersionString();
}

bool NetworkService::verifyDriver(const QString &carId, const QString &imagePath)
{
    // Convert image to base64
    // Handle both absolute and relative paths
    QString absoluteImagePath = imagePath;
    if (!QFileInfo(imagePath).isAbsolute()) {
        absoluteImagePath = QCoreApplication::applicationDirPath() + "/" + imagePath;
        qDebug() << "Converting relative path to absolute:" << absoluteImagePath;
    }
    
    QString base64Image = imageToBase64(absoluteImagePath);
    if (base64Image.isEmpty()) {
        emit verificationComplete(false, "Failed to load image");
        return false;
    }
    
    // Prepare the request
    QNetworkRequest request(QUrl("https://localhost:5041/api/verify-driver"));

    //the actual url for live web
    //QNetworkRequest request(QUrl("https://neurodrive.runasp.net/api/verify-driver"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Apply SSL configuration that ignores certificate validation
    request.setSslConfiguration(m_sslConfig);
    
    // Create the JSON payload
    QJsonObject jsonObj;
    jsonObj["carId"] = carId;
    jsonObj["imageBase64"] = "data:image/jpeg;base64," + base64Image;
    
    QJsonDocument doc(jsonObj);
    QByteArray data = doc.toJson();
    
    qDebug() << "Sending request to:" << request.url().toString();
    
    // Send the POST request
    QNetworkReply *reply = m_networkManager->post(request, data);
    
    // Connect to network errors
    connect(reply, &QNetworkReply::sslErrors, [reply](const QList<QSslError> &errors) {
        qDebug() << "SSL errors:" << errors;
        // Ignore SSL errors for development
        reply->ignoreSslErrors();
    });
    
    // Connect to the finished signal to handle the response
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            QJsonDocument responseDoc = QJsonDocument::fromJson(responseData);
            qDebug() << "Response received:" << responseData;
            
            if (responseDoc.isObject()) {
                QJsonObject responseObj = responseDoc.object();
                bool success = responseObj["success"].toBool();
                bool isAuthorized = responseObj["isAuthorized"].toBool();
                QString message = responseObj["message"].toString();
                
                if (success && isAuthorized) {
                    QString driverName = responseObj["driverName"].toString();
                    emit verificationComplete(true, "Welcome " + driverName);
                } else {
                    emit verificationComplete(false, message);
                }
            } else {
                emit verificationComplete(false, "Invalid response format");
            }
        } else {
            qDebug() << "Error:" << reply->errorString();
            emit verificationComplete(false, "Login failed: " + reply->errorString());
        }
        
        reply->deleteLater();
    });
    
    return true;
}

QString NetworkService::imageToBase64(const QString &imagePath)
{
    qDebug() << "Attempting to open image:" << imagePath;
    QFile file(imagePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Failed to open image file:" << imagePath << "Error:" << file.errorString();
        return QString();
    }
    
    QByteArray imageData = file.readAll();
    file.close();
    qDebug() << "Successfully loaded image, size:" << imageData.size() << "bytes";
    
    // Convert to base64
    return QString(imageData.toBase64());
} 