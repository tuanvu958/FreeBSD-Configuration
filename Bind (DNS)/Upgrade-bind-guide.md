#portsnap fetch
#portsnap update

make reinstall 

1. EREBOS,DNS1のBINDのバージョン確認
　/usr/local/sbin/named -v (psコマンドで、namedのpathを確認が必要)
　BIND 9.9.7-P2 (Extended Support Version)

2. 脆弱性の対象バージョンを確認
　BIND 9.9.7-P2は対象バージョンをなりますので、バージョンアップが必要

3. Port Upgradeを行います。
　# portsnap fetch
　# portsnap update
　# /usr/libexec/locate.update
　# /usr/ports/dns/bind99/Makefileでbindのバージョンを確認
　対象外のバージョンが上がれば、下記のコマンドでバージョンアップします。
　（同じBIND99系なら設定ファイルを殆どそのまま使えます）
　# cd /usr/ports/dns/bind99/
　# make reinstall clean

4. named restart
　#/etc/rc.d/named restart

5. namedバージョンを確認・動作確認


update on Hemera (FreeBSD 10.3)
cp /usr/port/dns/bind99 (full installer) -> インストールしたいサーバ

saramander2:copy folder bind910 of hemera to saramander2, reinstall
+make ALLOW_UNSUPPORTED_SYSTEM=yes reinstall

+libcrypto.so.7 => cp /lib/libcrypto.so.6 /lib/libcrypto.so.7
+libxml2.so.2   => cd /usr/local/lib
		　　　ln -s libxml2.so.5 libxml2.so.2

