#ifndef NETWORKSERVICE_H
#define NETWORKSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QBuffer>
#include <QUrl>

class NetworkService : public QObject
{
    Q_OBJECT
    
public:
    explicit NetworkService(QObject *parent = nullptr);
    Q_INVOKABLE bool verifyDriver(const QString &carId, const QString &imagePath);

signals:
    void verificationComplete(bool success, const QString &message);

private:
    QNetworkAccessManager *m_networkManager;
    QString imageToBase64(const QString &imagePath);
};

#endif // NETWORKSERVICE_H 