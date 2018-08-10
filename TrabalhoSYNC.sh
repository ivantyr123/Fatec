#!/bin/bash
#Script criado por Ivan Taylor

function cadastro_login () {
	echo "Para cadastrar..."
	login
	checa_cadastro
	verifica=$(cat .cadastro.txt | grep -P "^$login\t" | awk {'print $1'})
	if [ "$login" == "$verifica" ];then
		clear
		echo "Login ja usado."
		echo "Por favor insira outro login."
		cadastro_login
	else
		cadastro_senha
	fi
}

function checa_cadastro () {
	if [ ! -s .cadastro.txt ];then
		echo -e "Login\tSenha" >> .cadastro.txt
	fi
}

function cadastro_senha () {
	senha
	if [ "$pass1" != "$pass2" ];then
		clear
		echo -e "\nSenhas nao combinam."
		echo "Por favor digite novamente."
		cadastro_senha
	else
		clear
		echo -e "$login\t$pass1" >> .cadastro.txt 
		echo -e "\nCadastrado com sucesso!!"
		echo -e "$date\nUsuario $login cadastrado com sucesso no servidor FTP ($ip)" >> arquivolog.log
		ftp $ip << fim
		cd root
		put .cadastro.txt
fim
		logar
	fi
}

function login () {
	echo -n "Digite um Login: "
	read login
}

function senha () {
	echo -n "Digite uma senha: "
	stty -echo
	read pass1
	stty echo
	echo -n -e "\nConfirme sua senha: "
	stty -echo
	read pass2
	stty echo
}

function logar () {
	echo "Para logar..."
	echo -n "Digite o login: "
	read login
	echo -n "Digite a senha: "
	stty -echo
	read pass
	stty echo
	checa_cadastro
	verifica=$(cat .cadastro.txt | grep -P "^$login\t" | awk {'print $1'})
	if [ "$login" == "$verifica" ];then
		verifica=$(cat .cadastro.txt | grep -P "^$login\t" | awk {'print $2'})
		if [ "$pass" == "$verifica" ];then
			rm .cadastro.txt
			logado
		else
			clear
			echo -e "\nLogin ou senha incorreto."
			logar
		fi
	else
		clear
		echo -e "\nLogin ou senha incorreto."
		logar
	fi
}
	
function logar_cadastrar () {
	ftp $ip << fim
	cd root
	get .cadastro.txt
fim
	clear
	echo -n "Logar[1] ou Cadastrar[2]: "
	read qq
	if [ $qq == 1 ];then
		logar
	elif [ $qq == 2 ];then
		cadastro_login
	else
		logar_cadastrar
	fi
}

function logado () {
	clear
	echo -e "\nLogado com sucesso no servidor $ip !!"
	echo -e "$date\nUsuario $login logou com sucesso no servidor FTP ($ip) !!" >> arquivolog.log
	sinc
}

function deleta () {
	for file in $(ls -a "$raiz" | sed 's/ /_/g');do
		if [ $file != "." ] && [ $file != ".." ] && [ $file != "TrabalhoSYNC.sh" ];then
			file=$(echo $file | sed 's/_/ /g')
			if [ -d "$raiz/$file" ];then
				if [ -d "$aki/$file" ];then
					cd "$raiz/$file"
					aki=$(echo "$aki/$file")
					raiz=$(echo "$raiz/$file")
					file=$(echo $file | sed 's/\\ / /g')
					origi=$(echo "$origi/$file" | sed 's/\\ / /g' )
					deleta
				else
					limpa_pasta
				fi
			else
				if [ ! -e "$aki/$file" ];then
					file=$(echo "$file" | sed 's/ /\\ /g')
					origi=$(echo "$origi" | sed 's/ /\\ /g')
					ftp -i $ip << fim
					passive
					cd
					$origi
					delete
					$file
					
					by
fim
					file=$(echo "$file" | sed 's/\\ / /g')
					origi=$(echo "$origi" | sed 's/\\ / /g')
				fi
			fi
		fi
	done
}

function limpa_pasta () {
	origi=$(echo "$origi" | sed 's/ /\\ /g')
	find "$raiz/$file" -type d | sed 's/ /\\ /g' > .limpando.txt
	sequencia=$(find "$raiz/$file" -type d | wc -l)
	limpa=$(echo "$limpa" | sed 's/\//\\\//g')
	seq 1 $sequencia | while read seq;do
		limpo=$(tac .limpando.txt | head -$seq | tail -1 | sed -e "s/$limpa//g")
		ftp -i $ip << fim
		passive
		cd 
		$limpo
		mdelete *
		
		by
fim
	done
	seq 1 $sequencia | while read seq;do
		limpo=$(tac .limpando.txt | head -$seq | tail -1 | sed -e "s/$limpa//g")
		echo "$limpo"
		ftp -i $ip << fim
		passive
		rm
		$limpo
				
		by
fim
	done
	origi=$(echo "$origi" | sed 's/\\ / /g')
	rm .limpando.txt
}

function download () {
	wget -m ftp://ftpuser:123@$ip
}

function checa () {
	cd ~
	chekin=$(cat ~/.backupserver.cfg | grep $ip > /dev/null)
	if [ $? != 0 ];then
		echo "host $ip" > .backupserver.cfg
		echo "user ftpuser" >> .backupserver.cfg
		echo "pass 123" >> .backupserver.cfg
	fi
	cheki=$(cat ~/.netrc | grep $ip > /dev/null)
	if [ $? != 0 ];then
		echo -e "\nmachine $ip" >> .netrc
		echo "login ftpuser" >> .netrc
		echo "password 123" >> .netrc
	fi
	cd -
	clear
}
function upload () {
	rm .relatorio.txt
	data_files=$(find . -type f)
	data_diretorio=$(find . -type d)
	echo "$date" >> arquivolog.log
	echo -e "Arquivos upados ou atualizados no servidor FTP ($ip)\n$data_files" >> arquivolog.log
	echo -e "Diretorios upados ou atualizados no servidor FTP ($ip)\n$data_diretorio" >> arquivolog.log
	echo "$date" > .relatorio.txt
	echo -e "Arquivos upados ou atualizados no servidor FTP ($ip)\n$data_files" >> .relatorio.txt
	echo -e "Diretorios upados ou atualizados no servidor FTP ($ip)\n$data_diretorio" >> .relatorio.txt
	ncftpput -f ~/.backupserver.cfg -ZmRF /root/$login/ .
}

function sinc () {
	sleep 1
	echo "Sincronizacao iniciando em ..."
	sleep 1
	echo "3"
	sleep 1
	echo "2"
	sleep 1
	echo "1"
	sleep 1
	upload
	download
	inalt=$(pwd)
	aki=$(pwd)
	raiz=$(echo "$aki/$ip/root/$login") 
	limpa=$(echo "$aki/$ip/") 
	origi="root/$login"
	deleta
	cd "$inalt"
	rm -r $ip
	download
	inalt=$(pwd)
	aki=$(pwd)
	raiz=$(echo "$aki/$ip/root/$login") 
	limpa=$(echo "$aki/$ip/") 
	origi="root/$login"
	deleta
	cd "$inalt"
	rm -r $ip
	download
	inalt=$(pwd)
	aki=$(pwd)
	raiz=$(echo "$aki/$ip/root/$login") 
	limpa=$(echo "$aki/$ip/") 
	origi="root/$login"
	deleta
	cd "$inalt"
	rm -r $ip
	download
	inalt=$(pwd)
	aki=$(pwd)
	raiz=$(echo "$aki/$ip/root/$login") 
	limpa=$(echo "$aki/$ip/") 
	origi="root/$login"
	deleta
	cd "$inalt"
	rm -r $ip
	download
	inalt=$(pwd)
	aki=$(pwd)
	raiz=$(echo "$aki/$ip/root/$login") 
	limpa=$(echo "$aki/$ip/") 
	origi="root/$login"
	deleta
	cd "$inalt"
	rm -r $ip
	download
	cp -r ./$ip/root/$login/* .
	rm -r $ip
	clear
	checagem
}

function checagem () {
	echo -n "Ver ultima atualizacao[1] ou forcar sincronizacao[2] ou sair[3]: "
	read opcao
	if [ $opcao == 1 ];then
		echo -e "\n"
		cat .relatorio.txt
		checagem
	elif [ $opcao == 2 ];then
		sinc
		checagem
	elif [ $opcao == 3 ];then
		clear
		rm .relatorio.txt
		echo -e "$date\nUsuario $login deslogou do servidor FTP ($ip) !!" >> arquivolog.log
		exit
	else
		checagem
	fi
}

function IP () {
	echo -n "Digite o IP ou nome do servidor FTP: "
	read ip
	if [ "$ip" != "" ];then
		checa
		logar_cadastrar
	else
		IP
	fi
}

clear
date=$(date)
IP
