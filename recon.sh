#!/bin/bash

#Instalar/Actualizar herramientass
update() {
	#shuffledns
	sudo rm -f $HOME/go/bin/shuffledns /usr/bin/shuffledns
	go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
	sudo ln -s $HOME/go/bin/shuffledns /usr/bin/shuffledns
	#Analytics
	git clone https://github.com/Josue87/AnalyticsRelationships.git /tmp/analytics
	pip install -r /tmp/analytics/requirements.txt --break-system-packages
	sudo mv /tmp/analytics/Python/analyticsrelationships.py /usr/bin/analyticsrelationships
	sudo sed -i '1s/^/#!\/usr\/bin\/env python\n/' /usr/bin/analyticsrelationships
	rm -fr /tmp/analytics
	#Alterx
	sudo rm -f $HOME/go/bin/alterx /usr/bin/alterx
	go install github.com/projectdiscovery/alterx/cmd/alterx@latest
	sudo ln -s $HOME/go/bin/alterx /usr/bin/alterx
	#testssl
	git clone https://github.com/testssl/testssl.sh.git $HOME/recopilacion/testssl
	#gau 
	sudo rm -f $HOME/go/bin/gau /usr/bin/gau
	go install github.com/lc/gau/v2/cmd/gau@latest
	sudo ln -s $HOME/go/bin/gau /usr/bin/gau
	#spoofcheck
	git clone https://github.com/a6avind/spoofcheck.git /tmp/spoofcheck
	pip3 install -r /tmp/spoofcheck/requirements.txt --break-system-packages
	sudo mv /tmp/spoofcheck/spoofcheck.py /usr/bin/spoofcheck.py
	sudo sed -i '1s/^/#!\/usr\/bin\/env python\n/' /usr/bin/spoofcheck.py
	chmod +x /usr/bin/spoofcheck.py
	#exifray
	udo rm -f $HOME/go/bin/exifray /usr/bin/exifray
	go install github.com/mmarting/exifray@latest
	sudo ln -s $HOME/go/bin/exifray /usr/bin/exifray
}

recon() {
	echo "Iniciando escaneo $1"
	if [ ! -d $HOME/recopilacion/$1 ]; then
		mkdir $HOME/recopilacion/$1
	fi
	logsbase=$HOME/recopilacion/$1/$(date +"%Y_%m_%d_-%H_%M")
	mkdir $logsbase
	
	echo "Ejecutando ShuffleDNS"
	shuffledns -mode bruteforce -d $1 -w $HOME/recopilacion/lists/domains.txt -r $HOME/recopilacion/lists/resolvers.txt -silent > $logsbase/shuffledns.txt
	
	echo "Ejecutando Cero"
	cero -d $1 | unfurl -u domains > $logsbase/cero.txt
	
	echo "Ejecutando Katana"
	echo $1 | katana -silent -jc -o $logsbase/katana_all.txt -kf all > /dev/null 2>&1
	cat $logsbase/katana_all.txt | unfurl -u domains > $logsbase/katana.txt
	rm -f $logsbase/katana_all.txt
	
	#Analytics
	echo "Ejecutando Analytics"
	analyticsrelationships --url https://$1 > $logsbase/analytics.txt
	
	#Gau
	echo "Ejecutando Gau"
	gau $1 | unfurl -u domains > $logsbase/gau.txt
	
	#CTFR
	echo "Ejecutando CTFR" 
	ctfr -d $1 -o $logsbase/ctfr.txt
	
	#Agrupar resultados
	cat $logsbase/shuffledns.txt $logsbase/cero.txt $logsbase/katana.txt $logsbase/gau.txt $logsbase/ctfr.txt $logsbase/analytics.txt > $logsbase/subdominios.txt
	cat $logsbase/subdominios.txt | tr '[:upper:]' '[:lower:]' | grep -E "\.${1}$" | unfurl -u domains > $logsbase/subdominios_limpios.txt
	echo "Agrupando resultados - Total subdominios encontrados: $(cat $logsbase/subdominios_limpios.txt | wc -l)"
	
	
	#Comprobar dominios online
	cat $logsbase/subdominios_limpios.txt | httpx -silent | unfurl -u domains > $logsbase/objetivos.txt
	rm -fr $logsbase/subdominios.txt $logsbase/subdominios_limpios.txt

	
	#AlterX
	echo "Ejecutando AlterX"
	cat $logsbase/objetivos.txt | alterx -silent | head -n 200 | dnsx -r $HOME/recopilacion/lists/resolvers.txt -silent > $logsbase/alterx.txt
	cat $logsbase/alterx.txt >> $logsbase/objetivos.txt
	
	#Cero sobre subdominios
	echo "Ejecutando Cero sobre subdominios"
	cat $logsbase/objetivos.txt | cero | tr '[:upper:]' '[:lower:]' | grep -E "\.${1}$" | httpx -silent | unfurl -u domains >> $logsbase/objetivos.txt
	
	
	#Creamos carpeta subdominios
	mkdir $logsbase/subdominios
	
	#Subzy
	echo "Comprobando Subdomain Takeover"
	subzy run --targets $logsbase/objetivos.txt > $logsbase/subzy.txt
	
	echo "Analizando metadatos"
	exifray -d $1 -q > $logsbase/exifray.txt
	
	#Recorremos todos los subdominios encontrados
	while IF="" read -r p;
	do
		echo "   Procesando subdominio: $p"
		mkdir $logsbase/subdominios/$p
		iptoscan=$(dig +short +retry=3 $p | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
		echo "   Escaneando puertos de $p"
		sudo masscan $iptoscan --top-ports 1000 --banner -oG $logsbase/subdominios/$p/masscan.txt > /dev/null 2>&1
		echo "   Detectando WAF"
		wafw00f $p > $logsbase/subdominios/$p/wafw00f.txt
		echo "   Comprobando seguridad SSL"
		bash /home/kali/recopilacion/testssl/testssl.sh $p > $logsbase/subdominios/$p/testssl.txt
		echo "   Comprobando directorios/fichertos sensibles"
		ffuf -w /usr/share/wordlists/dirb/common.txt -u https://$p/FUZZ -mc 200 > $logsbase/subdominios/$p/ffuf.txt
		echo "   Comprobando tecnologias Web"
		whatweb $p > $logsbase/subdominios/$p/whatweb.txt
		echo "   Comprobando vulnerabilidades Web"
		nuclei -no-stdin -target $p > $logsbase/subdominios/$p/nuclei.txt
		echo "   Comprobando seguridad email"
		spoofcheck.py $p > $logsbase/subdominios/$p/spoofcheck.txt		
	done < $logsbase/objetivos.txt	
	
}

if [ $1 == "update" ]; then
	update
else
 	recon $1
fi
