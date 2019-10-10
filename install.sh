#!/usr/bin/env bash
URL='https://raw.githubusercontent.com/firstvds/winhide/master/winhide.tgz'

winhide() {
cat <<EOF
baseconf:
  dbconfig: "/usr/local/mgr5/etc/billmgr.conf.d/db.conf"
  loglevel: "debug"
  sales: "${1}" #id отдела продаж
  intacc: "${2}" #id клиента от которого создается тикет для отдела продаж
dedic_addons:
  cpufield: "cpu" #Служебное имя аддона отвечающего за выбор процессора
  cpucount: "cpucount" #Служебное имя аддона отвечающего за количество процессоров
  osparamname: "ostempl" #внутреннее название параметра услуги "выделенный сервер" отвечающего за выбор ОС
  selector_winedname: "winedit" #Служебное имя аддона отвечающего за выбор редакции Windows, аддон ОБЯЗАН ссылаться на список содержащий поля с внутренними именами "winst", "windc"
  selector_sqledname: "sqledit" #Служебное имя аддона отвечающего за выбор редакции SQL, аддон ОБЯЗАН ссылаться на перечисление sql редакций. Внутренние имена совпадающими с служебными именами sql аддонов и полем none.
  rdp: "rdpcnt" #Служебное имя rdp аддона
vds_addons:
  osparamname: "ostempl" #внутреннее название параметра услуги "выделенный сервер" отвечающего за выбор ОС
  cpucount: "cores" #Служебное имя аддона отвечающего за количество процессоров
  selector_sqledname: "sqledit" #Служебное имя аддона отвечающего за выбор редакции SQL, аддон ОБЯЗАН ссылаться на перечисление sql редакций. Внутренние имена совпадающими с служебными именами sql аддонов и полем none.
  rdp: "rdpcnt" #Служебное имя rdp аддона
  winlic: "winlic" #Служебное имя аддона отвечающего за количество лицензий windows
EOF
}

echo 'Check billmgr'
if /usr/local/mgr5/sbin/mgrctl mgr|grep 'name=billmgr' >/dev/null; then
    echo 'Enter id Sales department'
    read sales
    echo 'Check id'
    /usr/local/mgr5/sbin/mgrctl -m billmgr department.edit elid=${sales} >/dev/null || { echo 'failed' && exit 1 ;}
    echo 'Download and extract plugin'
    curl -s ${URL}|tar -C /usr/local/mgr5 -zx || { echo 'failed' && exit 1 ;}
    echo 'Search project id'
    prj=$(/usr/local/mgr5/sbin/mgrctl -m billmgr project|grep -Eo 'id=[0-9]*'|cut -d'=' -f2|head -n1)
    [[ ${prj} ]] || { echo 'failed' && exit 1 ;}
    echo 'Create service client'
    cid=$(/usr/local/mgr5/sbin/mgrctl -m billmgr account.edit email="noreply@example.ru" project="${prj}" client_lang='ru' country='182' state='null' realname='Monitoring' passwd="%#${RANDOM}@qWQ" confirm="%#${RANDOM}@qWQ" notify='off' recovery='off' so
k=ok|grep -Eo '[0-9]*')
    winhide ${sales} ${cid} > /usr/local/mgr5/etc/winhide.conf
    /usr/local/mgr5/sbin/mgrctl -m billmgr exit
    echo '0 4 * * * root /usr/local/mgr5/addon/winhide --sync > /var/log/billitemchk.log' > /etc/cron.d/billitemchk
    echo 'Plugin installed'
else
    echo 'failed'
fi
