#include "appdrawerproxymodel.h"

#include <QDebug>

AppDrawerProxyModel::AppDrawerProxyModel(QObject *parent):
    QSortFilterProxyModel(parent)
{
    setSortRole(AppDrawerModelInterface::RoleName);
    setSortLocaleAware(true);

    connect(this, &QAbstractListModel::rowsInserted, this, &AppDrawerProxyModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved, this, &AppDrawerProxyModel::countChanged);
    connect(this, &QAbstractListModel::layoutChanged, this, &AppDrawerProxyModel::countChanged);
}

QAbstractItemModel *AppDrawerProxyModel::source() const
{
    return m_source;
}

void AppDrawerProxyModel::setSource(QAbstractItemModel *source)
{
    if (m_source != source) {
        m_source = source;
        setSourceModel(m_source);
        sort(0);
        connect(m_source, &QAbstractItemModel::rowsRemoved, this, &AppDrawerProxyModel::invalidateFilter);
        connect(m_source, &QAbstractItemModel::rowsInserted, this, &AppDrawerProxyModel::invalidateFilter);
        Q_EMIT sourceChanged();
    }
}

AppDrawerProxyModel::GroupBy AppDrawerProxyModel::group() const
{
    return m_group;
}

void AppDrawerProxyModel::setGroup(AppDrawerProxyModel::GroupBy group)
{
    if (m_group != group) {
        m_group = group;
        Q_EMIT groupChanged();
        invalidateFilter();
    }
}

QString AppDrawerProxyModel::filterLetter() const
{
    return m_filterLetter;
}

void AppDrawerProxyModel::setFilterLetter(const QString &filterLetter)
{
    if (m_filterLetter != filterLetter) {
        m_filterLetter = filterLetter;
        Q_EMIT filterLetterChanged();
        invalidateFilter();
    }
}

QString AppDrawerProxyModel::filterString() const
{
    return m_filterString;
}

void AppDrawerProxyModel::setFilterString(const QString &filterString)
{
    if (m_filterString != filterString) {
        m_filterString = filterString;
        Q_EMIT filterStringChanged();
        invalidateFilter();
    }
}

int AppDrawerProxyModel::count() const
{
    return rowCount();
}

QVariant AppDrawerProxyModel::data(const QModelIndex &index, int role) const
{
    QModelIndex idx = mapToSource(index);
    if (role == Qt::UserRole) {
        QString name = m_source->data(idx, AppDrawerModelInterface::RoleName).toString();
        return name.length() > 0 ? QString(name.at(0)) : QChar();
    }
    return m_source->data(idx, role);
}

QHash<int, QByteArray> AppDrawerProxyModel::roleNames() const
{
    if (m_source) {
        QHash<int, QByteArray> roles = m_source->roleNames();
        roles.insert(Qt::UserRole, "letter");
        return roles;
    }
    return QHash<int, QByteArray>();
}

bool AppDrawerProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_parent)

    if (m_group == GroupByAToZ && source_row > 0) {
        QString currentName = m_source->data(m_source->index(source_row, 0), AppDrawerModelInterface::RoleName).toString();
        QChar currentLetter = currentName.length() > 0 ? currentName.at(0) : QChar();
        QString previousName = m_source->data(m_source->index(source_row - 1,0 ), AppDrawerModelInterface::RoleName).toString();
        QChar previousLetter = previousName.length() > 0 ? previousName.at(0) : QChar();
        if (currentLetter == previousLetter) {
            return false;
        }
    } else if(m_group == GroupByAll && source_row > 0) {
        return false;
    }
    if (!m_filterLetter.isEmpty()) {
        QString currentName = m_source->data(m_source->index(source_row, 0), AppDrawerModelInterface::RoleName).toString();
        QString currentLetter = currentName.length() > 0 ? QString(currentName.at(0)) : QString();
        if (currentLetter != m_filterLetter) {
            return false;
        }
    }
    if (!m_filterString.isEmpty()) {
        QString currentLabel = m_source->data(m_source->index(source_row, 0), AppDrawerModelInterface::RoleName).toString().toLower();
        if (!currentLabel.startsWith(m_filterString.toLower())) {
            return false;
        }
    }
    return true;
}
