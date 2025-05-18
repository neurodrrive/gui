#include "NetworkService.h"
#include <QDebug>

NetworkService::NetworkService(QObject *parent) : QObject(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
}

bool NetworkService::verifyDriver(const QString &carId, const QString &imagePath)
{
    // Convert image to base64
    QString base64Image = imageToBase64(imagePath);
    if (base64Image.isEmpty()) {
        emit verificationComplete(false, "Failed to load image");
        return false;
    }
    
    // Prepare the request
    QNetworkRequest request(QUrl("https://localhost:5041/api/verify-driver"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Create the JSON payload
    QJsonObject jsonObj;
    jsonObj["carId"] = carId;
    jsonObj["imageBase64"] = "data:image/jpeg;base64," + base64Image;
    
    QJsonDocument doc(jsonObj);
    QByteArray data = doc.toJson();
    
    // Send the POST request
    QNetworkReply *reply = m_networkManager->post(request, data);
    
    // Connect to the finished signal to handle the response
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            QJsonDocument responseDoc = QJsonDocument::fromJson(responseData);
            
            // Process the response - this is a simplification, adjust based on your API's response format
            emit verificationComplete(true, "Login successful");
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
    QFile file(imagePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Failed to open image file:" << imagePath;
        return QString();
    }
    
    QByteArray imageData = file.readAll();
    file.close();
    
    // Convert to base64
    return QString(imageData.toBase64());
} 