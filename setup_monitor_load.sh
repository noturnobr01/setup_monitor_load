#!/bin/bash

# Caminho do script de monitoramento
SCRIPT_PATH="/usr/local/bin/monitor_load.sh"

# Criação do script de monitoramento
cat << 'EOF' > $SCRIPT_PATH
#!/bin/bash

# Defina o limite de load average (alterado para 700)
LIMIT=700

# Defina o tempo de monitoramento em segundos (5 minutos = 300 segundos)
MONITOR_TIME=300

# Função para obter o load average atual (1 minuto)
get_load_average() {
    awk '{print $1}' /proc/loadavg
}

# Função para monitorar o load average
monitor_load() {
    while true; do
        load=$(get_load_average)

        # Verifique se o load average está acima do limite
        if (( $(echo "$load > $LIMIT" | bc -l) )); then
            echo "Load average de $load detectado, esperando $MONITOR_TIME segundos..."

            # Espere 5 minutos para verificar se o load average se mantém alto
            sleep $MONITOR_TIME

            # Verifique novamente o load average após 5 minutos
            load=$(get_load_average)
            if (( $(echo "$load > $LIMIT" | bc -l) )); then
                echo "Load average de $load persistiu, reiniciando o servidor..."
                reboot
            else
                echo "Load average voltou ao normal: $load"
            fi
        fi

        # Pause por um período curto antes da próxima verificação
        sleep 30
    done
}

monitor_load
EOF

# Torne o script de monitoramento executável
chmod +x $SCRIPT_PATH

# Adicionar o script ao crontab para execução no boot
(crontab -l 2>/dev/null; echo "@reboot $SCRIPT_PATH &") | crontab -

# Criação do serviço systemd
SERVICE_PATH="/etc/systemd/system/monitor_load.service"

cat << EOF > $SERVICE_PATH
[Unit]
Description=Monitor Load Average

[Service]
ExecStart=$SCRIPT_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Ativar e iniciar o serviço
systemctl enable monitor_load.service
systemctl start monitor_load.service

echo "Configuração completa. O script de monitoramento está em execução."
