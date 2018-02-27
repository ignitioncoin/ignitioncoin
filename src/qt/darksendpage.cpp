#include "clientmodel.h"
#include "darksend.h"
#include "darksendconfig.h"
#include "walletmodel.h"
#include "bitcoinunits.h"
#include "optionsmodel.h"
#include "transactiontablemodel.h"
#include "transactionfilterproxy.h"
#include "guiutil.h"
#include "guiconstants.h"

#include <QAbstractItemDelegate>
#include <QPainter>
#include <QScrollArea>
#include <QScroller>
#include <QSettings>
#include <QTimer>
#include "darksendpage.h"
#include "ui_darksendpage.h"

DarksendPage::DarksendPage(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::DarksendPage)
{
    ui->setupUi(this);

    // init "out of sync" warning labels
    ui->labelDarksendSyncStatus->setText("(" + tr("out of sync") + ")");

    fLiteMode = GetBoolArg("-litemode", false);

    if (fLiteMode)
    {
        ui->frameDarksend->setVisible(false);
    } 
    else
    {
        if (fMasterNode)
        {
            ui->toggleDarksend->setText("(" + tr("Disabled") + ")");
            ui->darksendAuto->setText("(" + tr("Disabled") + ")");
            ui->darksendReset->setText("(" + tr("Disabled") + ")");
            ui->frameDarksend->setEnabled(false);
        }
        else
        {
            if (!fEnableDarksend)
            {
                ui->toggleDarksend->setText(tr("Start Darksend Mixing"));
            }
            else
            {
                ui->toggleDarksend->setText(tr("Stop Darksend Mixing"));
            }
            timer = new QTimer(this);
            connect(timer, SIGNAL(timeout()), this, SLOT(darkSendStatus()));
            if(!GetBoolArg("-reindexaddr", false))
                timer->start(60000);
        }
    }

    // start with displaying the "out of sync" warnings
    showOutOfSyncWarning(true);

    //connect(ui->darksendAuto, SIGNAL(clicked()), this, SLOT(darksendAuto()));
    //connect(ui->darksendReset, SIGNAL(clicked()), this, SLOT(darksendReset()));
    //connect(ui->toggleDarksend, SIGNAL(clicked()), this, SLOT(toggleDarksend()));
}

DarksendPage::~DarksendPage()
{
    delete ui;
}

void DarksendPage::showOutOfSyncWarning(bool fShow)
{
    ui->labelDarksendSyncStatus->setVisible(fShow);
}

void DarksendPage::darkSendStatus()
{
    static int64_t nLastDSProgressBlockTime = 0;

    int nBestHeight = pindexBest->nHeight;

    // we we're processing more then 1 block per second, we'll just leave
    if(((nBestHeight - darkSendPool.cachedNumBlocks) / (GetTimeMillis() - nLastDSProgressBlockTime + 1) > 1)) return;
    nLastDSProgressBlockTime = GetTimeMillis();

    if(!fEnableDarksend) {
        if(nBestHeight != darkSendPool.cachedNumBlocks)
        {
            darkSendPool.cachedNumBlocks = nBestHeight;
            updateDarksendProgress();

            ui->darksendEnabled->setText(tr("Disabled"));
            ui->darksendStatus->setText("");
            ui->toggleDarksend->setText(tr("Start Darksend Mixing"));
        }

        return;
    }

    // check darksend status and unlock if needed
    if(nBestHeight != darkSendPool.cachedNumBlocks)
    {
        // Balance and number of transactions might have changed
        //darkSendPool.cachedNumBlocks = nBestHeight;

        updateDarksendProgress();

        ui->darksendEnabled->setText(tr("Enabled"));
    }

    QString strStatus = QString(darkSendPool.GetStatus().c_str());

    QString s = tr("Last Darksend message:\n") + strStatus;

    if(s != ui->darksendStatus->text())
        LogPrintf("Last Darksend message: %s\n", strStatus.toStdString());

    ui->darksendStatus->setText(s);

    if(darkSendPool.sessionDenom == 0){
        ui->labelSubmittedDenom->setText(tr("N/A"));
    } else {
        std::string out;
        darkSendPool.GetDenominationsToString(darkSendPool.sessionDenom, out);
        QString s2(out.c_str());
        ui->labelSubmittedDenom->setText(s2);
    }

    // Get DarkSend Denomination Status
}

/*
void OverviewPage::darksendAuto(){
    darkSendPool.DoAutomaticDenominating();
}

void OverviewPage::darksendReset(){
    darkSendPool.Reset();
    darkSendStatus();

    QMessageBox::warning(this, tr("Darksend"),
        tr("Darksend was successfully reset."),
        QMessageBox::Ok, QMessageBox::Ok);
}
*/

/*
void DarksendPage::toggleDarksend()
{
    QSettings settings;
    // Popup some information on first mixing
    QString hasMixed = settings.value("hasMixed").toString();
    if (hasMixed.isEmpty()) 
    {
        QMessageBox::information(this, tr("Darksend"),
                tr("If you don't want to see internal Darksend fees/transactions select \"Received By\" as Type on the \"Transactions\" tab."),
                QMessageBox::Ok, QMessageBox::Ok);
        settings.setValue("hasMixed", "hasMixed");
    }

    if (!fEnableDarksend) 
    {
        int64_t balance = currentBalance;
        float minAmount = 1.49 * COIN;
        if (balance < minAmount) 
        {
            QString strMinAmount(BitcoinUnits::formatWithUnit(nDisplayUnit, minAmount));
            QMessageBox::warning(this, tr("Darksend"),
                tr("Darksend requires at least %1 to use.").arg(strMinAmount),
                QMessageBox::Ok, QMessageBox::Ok);
            return;
        }

        // if wallet is locked, ask for a passphrase
        if (walletModel->getEncryptionStatus() == WalletModel::Locked)
        {
            WalletModel::UnlockContext ctx(walletModel->requestUnlock());
            if(!ctx.isValid())
            {
                //unlock was cancelled
                darkSendPool.cachedNumBlocks = std::numeric_limits<int>::max();
                QMessageBox::warning(this, tr("Darksend"),
                    tr("Wallet is locked and user declined to unlock. Disabling Darksend."),
                    QMessageBox::Ok, QMessageBox::Ok);
                if (fDebug) LogPrintf("Wallet is locked and user declined to unlock. Disabling Darksend.\n");
                return;
            }
        }

    }

    fEnableDarksend = !fEnableDarksend;
    darkSendPool.cachedNumBlocks = std::numeric_limits<int>::max();

    if (!fEnableDarksend)
    {
        ui->toggleDarksend->setText(tr("Start Darksend Mixing"));
        darkSendPool.UnlockCoins();
    } 
    else 
    {
        ui->toggleDarksend->setText(tr("Stop Darksend Mixing"));

        // show darksend configuration if client has defaults set 

        if (nAnonymizeHarvestAmount == 0)
        {
            DarksendConfig dlg(this);
            dlg.setModel(walletModel);
            dlg.exec();
        }

    }
}
*/

void DarksendPage::setWalletModel(WalletModel *model)
{
    this->walletModel = model;
    if(model && model->getOptionsModel())
    {
        // Keep up to date with wallet
        setBalance(model->getBalance(), model->getStake(), model->getUnconfirmedBalance(), model->getImmatureBalance(), model->getAnonymizedBalance(),
             model->getWatchBalance(), model->getWatchStake(), model->getWatchUnconfirmedBalance(), model->getWatchImmatureBalance());
        connect(model, SIGNAL(balanceChanged(CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount)), this, SLOT(setBalance(CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount, CAmount)));

        connect(model->getOptionsModel(), SIGNAL(displayUnitChanged(int)), this, SLOT(updateDisplayUnit()));

        connect(ui->darksendAuto, SIGNAL(clicked()), this, SLOT(darksendAuto()));
        connect(ui->darksendReset, SIGNAL(clicked()), this, SLOT(darksendReset()));
        connect(ui->toggleDarksend, SIGNAL(clicked()), this, SLOT(toggleDarksend()));
    }

    // update the display unit, to not use the default ("BTC")
    //updateDisplayUnit();
}

void DarksendPage::setBalance(const CAmount& balance, const CAmount& stake, const CAmount& unconfirmedBalance, const CAmount& immatureBalance, const CAmount& anonymizedBalance, const CAmount& watchOnlyBalance, const CAmount& watchOnlyStake, const CAmount& watchUnconfBalance, const CAmount& watchImmatureBalance)
{
    currentBalance = balance;
    currentAnonymizedBalance = anonymizedBalance;
    ui->labelAnonymized->setText(BitcoinUnits::formatWithUnit(nDisplayUnit, anonymizedBalance));

    updateDarksendProgress();
}


void DarksendPage::updateDarksendProgress()
{
    if(!darkSendPool.IsBlockchainSynced() || ShutdownRequested()) return;

    if(!pwalletMain) return;

    QString strAmountAndRounds;
    QString strAnonymizeHarvestAmount = BitcoinUnits::formatHtmlWithUnit(nDisplayUnit, nAnonymizeHarvestAmount * COIN, false, BitcoinUnits::separatorAlways);

    if(currentBalance == 0)
    {
        ui->darksendProgress->setValue(0);
        ui->darksendProgress->setToolTip(tr("No inputs detected"));
        // when balance is zero just show info from settings
        strAnonymizeHarvestAmount = strAnonymizeHarvestAmount.remove(strAnonymizeHarvestAmount.indexOf("."), BitcoinUnits::decimals(nDisplayUnit) + 1);
        strAmountAndRounds = strAnonymizeHarvestAmount + " / " + tr("%n Rounds", "", nDarksendRounds);

        ui->labelAmountRounds->setToolTip(tr("No inputs detected"));
        ui->labelAmountRounds->setText(strAmountAndRounds);
        return;
    }

    CAmount nDenominatedConfirmedBalance;
    CAmount nDenominatedUnconfirmedBalance;
    CAmount nAnonymizableBalance;
    CAmount nNormalizedAnonymizedBalance;
    double nAverageAnonymizedRounds;

    {
        TRY_LOCK(cs_main, lockMain);
        if(!lockMain) return;

        nDenominatedConfirmedBalance = pwalletMain->GetDenominatedBalance();
        nDenominatedUnconfirmedBalance = pwalletMain->GetDenominatedBalance(true);
        nAnonymizableBalance = pwalletMain->GetAnonymizableBalance();
        nNormalizedAnonymizedBalance = pwalletMain->GetNormalizedAnonymizedBalance();
        nAverageAnonymizedRounds = pwalletMain->GetAverageAnonymizedRounds();
    }

    //Get the anon threshold
    CAmount nMaxToAnonymize = nAnonymizableBalance + currentAnonymizedBalance + nDenominatedUnconfirmedBalance;

    // If it's more than the anon threshold, limit to that.
    if(nMaxToAnonymize > nAnonymizeHarvestAmount*COIN) nMaxToAnonymize = nAnonymizeHarvestAmount*COIN;

    if(nMaxToAnonymize == 0) return;

    if(nMaxToAnonymize >= nAnonymizeHarvestAmount * COIN) {
        ui->labelAmountRounds->setToolTip(tr("Found enough compatible inputs to anonymize %1")
                                          .arg(strAnonymizeHarvestAmount));
        strAnonymizeHarvestAmount = strAnonymizeHarvestAmount.remove(strAnonymizeHarvestAmount.indexOf("."), BitcoinUnits::decimals(nDisplayUnit) + 1);
        strAmountAndRounds = strAnonymizeHarvestAmount + " / " + tr("%n Rounds", "", nDarksendRounds);
    } else {
        QString strMaxToAnonymize = BitcoinUnits::formatHtmlWithUnit(nDisplayUnit, nMaxToAnonymize, false, BitcoinUnits::separatorAlways);
        ui->labelAmountRounds->setToolTip(tr("Not enough compatible inputs to anonymize <span style='color:red;'>%1</span>,<br>"
                                             "will anonymize <span style='color:red;'>%2</span> instead")
                                          .arg(strAnonymizeHarvestAmount)
                                          .arg(strMaxToAnonymize));
        strMaxToAnonymize = strMaxToAnonymize.remove(strMaxToAnonymize.indexOf("."), BitcoinUnits::decimals(nDisplayUnit) + 1);
        strAmountAndRounds = "<span style='color:red;'>" +
                QString(BitcoinUnits::factor(nDisplayUnit) == 1 ? "" : "~") + strMaxToAnonymize +
                " / " + tr("%n Rounds", "", nDarksendRounds) + "</span>";
    }
    ui->labelAmountRounds->setText(strAmountAndRounds);

    // calculate parts of the progress, each of them shouldn't be higher than 1
    // progress of denominating
    float denomPart = 0;
    // mixing progress of denominated balance
    float anonNormPart = 0;
    // completeness of full amount anonimization
    float anonFullPart = 0;

    CAmount denominatedBalance = nDenominatedConfirmedBalance + nDenominatedUnconfirmedBalance;
    denomPart = (float)denominatedBalance / nMaxToAnonymize;
    denomPart = denomPart > 1 ? 1 : denomPart;
    denomPart *= 100;

    anonNormPart = (float)nNormalizedAnonymizedBalance / nMaxToAnonymize;
    anonNormPart = anonNormPart > 1 ? 1 : anonNormPart;
    anonNormPart *= 100;

    anonFullPart = (float)currentAnonymizedBalance / nMaxToAnonymize;
    anonFullPart = anonFullPart > 1 ? 1 : anonFullPart;
    anonFullPart *= 100;

    // apply some weights to them ...
    float denomWeight = 1;
    float anonNormWeight = nDarksendRounds;
    float anonFullWeight = 2;
    float fullWeight = denomWeight + anonNormWeight + anonFullWeight;
    // ... and calculate the whole progress
    float denomPartCalc = ceilf((denomPart * denomWeight / fullWeight) * 100) / 100;
    float anonNormPartCalc = ceilf((anonNormPart * anonNormWeight / fullWeight) * 100) / 100;
    float anonFullPartCalc = ceilf((anonFullPart * anonFullWeight / fullWeight) * 100) / 100;
    float progress = denomPartCalc + anonNormPartCalc + anonFullPartCalc;
    if(progress >= 100) progress = 100;

    ui->darksendProgress->setValue(progress);

    QString strToolPip = ("<b>" + tr("Overall progress") + ": %1%</b><br/>" +
                          tr("Denominated") + ": %2%<br/>" +
                          tr("Mixed") + ": %3%<br/>" +
                          tr("Anonymized") + ": %4%<br/>" +
                          tr("Denominated inputs have %5 of %n rounds on average", "", nDarksendRounds))
            .arg(progress).arg(denomPart).arg(anonNormPart).arg(anonFullPart)
            .arg(nAverageAnonymizedRounds);
    ui->darksendProgress->setToolTip(strToolPip);
}
