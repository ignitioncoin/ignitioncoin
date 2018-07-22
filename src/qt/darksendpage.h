#ifndef DARKSENDPAGE_H
#define DARKSENDPAGE_H

#include "util.h"

#include <QTimer>
#include <QWidget>

class WalletModel;

namespace Ui {
class DarksendPage;
}

class DarksendPage : public QWidget
{
    Q_OBJECT

public:
    explicit DarksendPage(QWidget *parent = 0);
    ~DarksendPage();

    void updateDarksendProgress();
    void showOutOfSyncWarning(bool fShow);
    void setWalletModel(WalletModel *model);

public slots:
    void darkSendStatus();
    void setBalance(const CAmount& balance, const CAmount& stake, const CAmount& unconfirmedBalance, const CAmount& immatureBalance, const CAmount& anonymizedBalance, const CAmount& watchOnlyBalance, const CAmount& watchOnlyStake, const CAmount& watchUnconfBalance, const CAmount& watchImmatureBalance);

private:
    QTimer *timer;
    Ui::DarksendPage *ui;
    CAmount currentBalance;
    CAmount currentAnonymizedBalance;
    int nDisplayUnit;
    WalletModel *walletModel;

private slots:
    void toggleDarksend();
    void darksendAuto();
    void darksendReset();

};

#endif // DARKSENDPAGE_H
