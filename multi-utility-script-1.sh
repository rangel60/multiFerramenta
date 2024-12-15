#!/bin/bash

# Função para mostrar a barra de progresso com cancelamento
mostrar_progresso() {
    comando="$1"
    texto="$2"

    (
        eval "$comando" &
        pid=$!
        while kill -0 $pid 2>/dev/null; do
            echo "50"
            sleep 1
        done
        wait $pid
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "100"
        else
            echo "Erro durante a execução!"
            exit 1
        fi
    ) | zenity --progress --title="Progresso" --text="$texto" --percentage=0 --auto-close --auto-kill --width=400

    if [ $? -ne 0 ]; then
        kill $pid 2>/dev/null
        zenity --error --text="Processo cancelado pelo usuário!"
    fi
}

# Funções originais do Mp4-Mp3-M3u.sh
gerar_m3u_youtube_link() {
    link=$(zenity --entry --title="Gerar M3U - YouTube (Link Único)" --text="Cole o link do vídeo:")
    [ -z "$link" ] && return

    categoria=$(zenity --entry --title="Escolher Categoria" --text="Informe a categoria do vídeo (opcional):")
    output_file=$(zenity --file-selection --save --confirm-overwrite --title="Salvar Arquivo M3U" --filename="youtube_single.m3u")
    [ -z "$output_file" ] && return

    mostrar_progresso "(
        titulo=\$(yt-dlp --get-title '$link' 2>/dev/null)
        stream_url=\$(yt-dlp -g '$link' 2>/dev/null)

        if [ -n \"\$titulo\" ] && [ -n \"\$stream_url\" ]; then
            echo '#EXTM3U' > \"$output_file\"
            echo \"#EXTINF:-1, \$categoria - \$titulo\" >> \"$output_file\"
            echo \"\$stream_url\" >> \"$output_file\"
        else
            exit 1
        fi
    )" "Gerando arquivo M3U para link único..."
}

gerar_m3u_youtube_playlist() {
    link=$(zenity --entry --title="Gerar M3U - YouTube (Playlist)" --text="Cole o link da playlist:")
    [ -z "$link" ] && return

    categoria=$(zenity --entry --title="Escolher Categoria" --text="Informe a categoria da playlist (opcional):")
    output_file=$(zenity --file-selection --save --confirm-overwrite --title="Salvar Arquivo M3U" --filename="youtube_playlist.m3u")
    [ -z "$output_file" ] && return

    mostrar_progresso "(
        echo '#EXTM3U' > \"$output_file\"
        yt-dlp --flat-playlist --print-to-file 'url' urls_temp.txt '$link' 2>/dev/null

        while read -r video_url; do
            titulo=\$(yt-dlp --get-title \"\$video_url\" 2>/dev/null)
            stream_url=\$(yt-dlp -g \"\$video_url\" 2>/dev/null)
            if [ -n \"\$titulo\" ] && [ -n \"\$stream_url\" ]; then
                echo \"#EXTINF:-1, \$categoria - \$titulo\" >> \"$output_file\"
                echo \"\$stream_url\" >> \"$output_file\"
            fi
        done < urls_temp.txt
        rm -f urls_temp.txt
    )" "Gerando arquivo M3U para playlist..."
}

gerar_m3u_vimeo() {
    link=$(zenity --entry --title="Gerar M3U - Vimeo" --text="Cole o link do vídeo:")
    [ -z "$link" ] && return

    categoria=$(zenity --entry --title="Escolher Categoria" --text="Informe a categoria do vídeo (opcional):")
    output_file=$(zenity --file-selection --save --confirm-overwrite --title="Salvar Arquivo M3U" --filename="vimeo_playlist.m3u")
    [ -z "$output_file" ] && return

    mostrar_progresso "(
        titulo=\$(yt-dlp --get-title '$link' 2>/dev/null)
        stream_url=\$(yt-dlp -g '$link' 2>/dev/null)

        if [ -n \"\$titulo\" ] && [ -n \"\$stream_url\" ]; then
            echo '#EXTM3U' > \"$output_file\"
            echo \"#EXTINF:-1, \$categoria - \$titulo\" >> \"$output_file\"
            echo \"\$stream_url\" >> \"$output_file\"
        else
            exit 1
        fi
    )" "Gerando arquivo M3U para Vimeo..."
}

download_mp4_playlist() {
    link=$(zenity --entry --title="Download MP4 - Playlist" --text="Cole o link da playlist:")
    [ -z "$link" ] && return

    output_dir=$(zenity --file-selection --directory --title="Escolha a pasta para salvar os vídeos")
    [ -z "$output_dir" ] && return

    mostrar_progresso "(
        yt-dlp -f mp4 -o \"$output_dir/%(title)s.%(ext)s\" \"$link\"
    )" "Baixando vídeos em MP4..."
}

download_mp4_single() {
    link=$(zenity --entry --title="Download MP4 - Único" --text="Cole o link do vídeo:")
    [ -z "$link" ] && return

    output_dir=$(zenity --file-selection --directory --title="Escolha a pasta para salvar o vídeo")
    [ -z "$output_dir" ] && return

    # Ignorar a parte da playlist (se existir)
    link=$(echo "$link" | sed 's/&list=[^&]*//')

    mostrar_progresso "(
        yt-dlp -f mp4 -o \"$output_dir/%(title)s.%(ext)s\" \"$link\"
    )" "Baixando vídeo em MP4..."
}

download_mp3_playlist() {
    link=$(zenity --entry --title="Download MP3 - Playlist" --text="Cole o link da playlist:")
    [ -z "$link" ] && return

    output_dir=$(zenity --file-selection --directory --title="Escolha a pasta para salvar os áudios")
    [ -z "$output_dir" ] && return

    mostrar_progresso "(
        yt-dlp -x --audio-format mp3 -o \"$output_dir/%(title)s.%(ext)s\" \"$link\"
    )" "Baixando áudios em MP3..."
}

download_mp3_single() {
    link=$(zenity --entry --title="Download MP3 - Único" --text="Cole o link do vídeo:")
    [ -z "$link" ] && return

    output_dir=$(zenity --file-selection --directory --title="Escolha a pasta para salvar o áudio")
    [ -z "$output_dir" ] && return

    # Ignorar a parte da playlist (se existir)
    link=$(echo "$link" | sed 's/&list=[^&]*//')

    mostrar_progresso "(
        yt-dlp -x --audio-format mp3 -o \"$output_dir/%(title)s.%(ext)s\" \"$link\"
    )" "Baixando áudio em MP3..."
}

# Nova função: Remover Senha de PDF
remover_senha_pdf() {
    # Verifica se o qpdf está instalado
    if ! command -v qpdf &> /dev/null; then
        zenity --error --text="O programa 'qpdf' não está instalado. Por favor, instale-o usando:\nsudo apt install qpdf"
        return
    fi

    # Seleciona o arquivo PDF de entrada
    INPUT_FILE=$(zenity --file-selection --title="Selecione o arquivo PDF protegido" --file-filter="*.pdf")
    if [ -z "$INPUT_FILE" ]; then
        return
    fi

    # Pede a senha do PDF
    PASSWORD=$(zenity --password --title="Digite a senha do PDF")
    if [ -z "$PASSWORD" ]; then
        zenity --error --text="Senha não fornecida. Operação cancelada."
        return
    fi

    # Define o nome do arquivo de saída
    DIR_NAME=$(dirname "$INPUT_FILE")
    BASE_NAME=$(basename "$INPUT_FILE" .pdf)
    OUTPUT_FILE="$DIR_NAME/${BASE_NAME}-semSenha.pdf"

    # Executa o comando qpdf para remover a senha
    if qpdf --password="$PASSWORD" --decrypt "$INPUT_FILE" "$OUTPUT_FILE"; then
        zenity --info --text="Senha removida com sucesso!\nArquivo salvo em:\n$OUTPUT_FILE"
    else
        zenity --error --text="Falha ao remover a senha. Verifique a senha ou o arquivo e tente novamente."
    fi
}

# Nova função: Ordenar USB (fatsort)
ordenar_usb() {
    # Obtendo uma lista de dispositivos de bloco (incluindo USB) usando lsblk
    devices=$(lsblk -o NAME,LABEL -n -l | grep -E '^sd[a-z][0-9]*')

    # Solicitando ao usuário que selecione o dispositivo usando Zenity
    DEVICE_INFO=$(zenity --list --title="Selecione o Dispositivo" --text="Selecione o dispositivo a ser processado:" --column="Dispositivo" --column="Rótulo" $devices)

    # Verificando se o usuário cancelou a seleção
    [ -z "$DEVICE_INFO" ] && return

    # Obtendo o nome e o rótulo do dispositivo selecionado
    DEVICE_NAME=$(echo "$DEVICE_INFO" | awk '{print $1}')
    DEVICE_LABEL=$(echo "$DEVICE_INFO" | awk '{print $2}')

    # Inicializando a barra de progresso
    (
        # Etapa 1: Desmontando o dispositivo
        echo "10"
        echo "# Desmontando o dispositivo $DEVICE_NAME de rótulo $DEVICE_LABEL..."

        # Tenta desmontar o dispositivo e captura a saída e o código de saída
        umount_output=$(echo "12" | sudo -S umount "/dev/$DEVICE_NAME" 2>&1)
        umount_exit_code=$?

        # Verificando se ocorreu algum erro durante o desmonte
        if [ $umount_exit_code -ne 0 ]; then
            zenity --error --text="Erro ao desmontar o dispositivo $DEVICE_NAME: $umount_output"
            exit 1
        fi

        # Etapa 2: Executando o fatsort
        echo "50"
        echo "# Executando o fatsort no dispositivo $DEVICE_NAME de rótulo $DEVICE_LABEL..."

        # Tenta executar o fatsort e captura a saída e o código de saída
        fatsort_output=$(echo "12" | sudo -S fatsort "/dev/$DEVICE_NAME" 2>&1)
        fatsort_exit_code=$?

        # Verificando se ocorreu algum erro durante o fatsort
        if [ $fatsort_exit_code -ne 0 ]; then
            zenity --error --text="Erro ao executar o fatsort no dispositivo $DEVICE_NAME: $fatsort_output"
            exit 1
        fi

        # Concluído
        echo "100"
        echo "# Concluído"
    ) | zenity --progress --title="Progresso" --text="Iniciando... Dispositivo: $DEVICE_NAME, Rótulo: $DEVICE_LABEL" --percentage=0 --auto-close

    # Verificando se não houve erro antes de exibir a mensagem de sucesso
    if [ $umount_exit_code -eq 0 ] && [ $fatsort_exit_code -eq 0 ]; then
        zenity --info --text="SUCESSO... Dispositivo: $DEVICE_NAME, Rótulo: $DEVICE_LABEL."
    fi
}

# Nova função: Listar Arquivos de um Diretório
listar_arquivos() {
    # Usa Zenity para selecionar um diretório
    DIRETORIO=$(zenity --file-selection --directory --title="Selecione um diretório")

    # Verifica se o usuário clicou em Cancelar
    if [ $? -ne 0 ]; then
        zenity --info --text="Operação cancelada pelo usuário."
        return
    fi

    # Executa o comando ls -R para listar arquivos e diretórios recursivamente
    LISTA=$(ls -R "$DIRETORIO")

    # Salva a lista em um arquivo de texto
    echo "$LISTA" > lista_de_arquivos.txt

    # Exibe uma mensagem informando sobre a criação do arquivo
    zenity --info --text="Lista de arquivos salva em 'lista_de_arquivos.txt'."

    # Pode abrir o arquivo de texto usando o visualizador de texto padrão
    xdg-open lista_de_arquivos.txt
}

# Selecionar um diretório usando zenity ZIPA TUDO
ZIPATUDO() {
directory=$(zenity --file-selection --directory --title="Selecione a pasta")

# Verificar se o usuário pressionou "Cancelar" ou escolheu um diretório
if [ -z "$directory" ]; then
    zenity --error --text="Operação cancelada pelo usuário."
else
    # Executar o comando para zipar os diretórios
    find "$directory" -type d -exec zip -r {}.zip {} \;

    # Exibir mensagem de sucesso
    zenity --info --text="Os diretórios foram comprimidos com sucesso!"

    # Abrir o explorador de arquivos no diretório
    xdg-open "$directory"
fi
}
# Configurações de MiniDLNA
configurar_minidlna() {
    # Verificar se está sendo executado como root
    if [ "$(id -u)" -ne 0 ]; then
        zenity --password --title="Autenticação Requerida" --text="Digite a senha do root para continuar:" | sudo -S true
        if [ $? -ne 0 ]; then
            zenity --error --text="Senha incorreta. Encerrando o script."
            return
        fi
    fi

    # Verificar se o arquivo de configuração existe
    CONFIG_FILE="/etc/minidlna.conf"
    if [ ! -f "$CONFIG_FILE" ]; then
        zenity --error --text="Arquivo de configuração $CONFIG_FILE não encontrado!"
        return
    fi

    # Função para atualizar ou adicionar configurações no arquivo
    update_config() {
        local key=$1
        local value=$2

        if grep -q "^$key=" "$CONFIG_FILE"; then
            sudo sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
        else
            echo "$key=$value" | sudo tee -a "$CONFIG_FILE" > /dev/null
        fi
    }

    # Menu de configurações do MiniDLNA
    while true; do
        CONFIG_OPTION=$(zenity --list --title="Configurações do MiniDLNA" \
            --column="Opções" \
            "Alterar diretório de mídia" \
            "Alterar porta" \
            "Alterar nome do servidor" \
            "Ativar/Desativar Inotify" \
            "Visualizar arquivo de configuração" \
            "Sair")

        case $CONFIG_OPTION in

            "Alterar diretório de mídia")
                NEW_MEDIA_DIR=$(zenity --entry --title="Alterar diretório de mídia" --text="Digite o novo diretório de mídia:" --entry-text "/var/lib/minidlna")
                if [ -n "$NEW_MEDIA_DIR" ]; then
                    update_config "media_dir" "$NEW_MEDIA_DIR"
                    zenity --info --text="Diretório de mídia alterado para: $NEW_MEDIA_DIR"
                fi
                ;;
            "Alterar porta")
                NEW_PORT=$(zenity --entry --title="Alterar porta" --text="Digite a nova porta:" --entry-text "8200")
                if [ -n "$NEW_PORT" ]; then
                    update_config "port" "$NEW_PORT"
                    zenity --info --text="Porta alterada para: $NEW_PORT"
                fi
                ;;
            "Alterar nome do servidor")
                NEW_FRIENDLY_NAME=$(zenity --entry --title="Alterar nome do servidor" --text="Digite o novo nome amigável do servidor:" --entry-text "MiniDLNA")
                if [ -n "$NEW_FRIENDLY_NAME" ]; then
                    update_config "friendly_name" "$NEW_FRIENDLY_NAME"
                    zenity --info --text="Nome do servidor alterado para: $NEW_FRIENDLY_NAME"
                fi
                ;;
            "Ativar/Desativar Inotify")
                TOGGLE_INOTIFY=$(zenity --list --title="Ativar/Desativar Inotify" \
                    --column="Escolha" \
                    "Ativar" \
                    "Desativar")
                if [ "$TOGGLE_INOTIFY" == "Ativar" ]; then
                    update_config "inotify" "yes"
                    zenity --info --text="Inotify ativado."
                else
                    update_config "inotify" "no"
                    zenity --info --text="Inotify desativado."
                fi
                ;;
            "Visualizar arquivo de configuração")
                sudo zenity --text-info --title="Arquivo de Configuração" --filename="$CONFIG_FILE" --editable
                ;;
            "Sair")
                break
                ;;
            *)
                zenity --info --text="Opção não reconhecida."
                ;;
        esac
    done
}

# Menu Principal
while true; do
    escolha=$(zenity --list --text="<span color='blue' font='15'>Multi </span><span color='red' font='14'>FERRAMENTA</span>" --height=430 --width=370\
        --column="Opção" --column="Descrição" \
        "1" "Gerar M3U - YouTube (Link Único)" \
        "2" "Gerar M3U - YouTube (Playlist)" \
        "3" "Gerar M3U - Vimeo" \
        "4" "Download MP4 (Playlist)" \
        "5" "Download MP4 (Único)" \
        "6" "Download MP3 (Playlist)" \
        "7" "Download MP3 (Único)" \
        "8" "Remover Senha de PDF" \
        "9" "Fatsort" \
        "10" "Gerar lista txt" \
        "11" "Configurar MiniDLNA" \
"12" "ZipaTudo" \
        "13" "Sair")

    case $escolha in
        1) gerar_m3u_youtube_link ;;
        2) gerar_m3u_youtube_playlist ;;
        3) gerar_m3u_vimeo ;;
        4) download_mp4_playlist ;;
        5) download_mp4_single ;;
        6) download_mp3_playlist ;;
        7) download_mp3_single ;;
        8) remover_senha_pdf ;;
        9) ordenar_usb ;;
        10) listar_arquivos ;;
        11) configurar_minidlna ;;
        12) ZIPATUDO ;;
        13) exit ;;
        *) zenity --error --text="Opção inválida!" ;;
    esac
done
