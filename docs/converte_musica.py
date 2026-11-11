import os
import shutil
from PIL import Image
import pytesseract

if not shutil.which("tesseract"):
  tesseract_windows = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
  if os.path.exists(tesseract_windows):
    pytesseract.pytesseract.tesseract_cmd = tesseract_windows


def limpar_texto(texto):
  """Remove espaços extras e linhas vazias excessivas."""
  linhas = [linha.strip() for linha in texto.split("\n")]
  return [linha for linha in linhas if linha]


def processar_imagem_para_txt(caminho_imagem, pasta_saida=None):
  if pasta_saida is None:
    pasta_saida = os.path.join(os.path.dirname(__file__), "saida_txt")

  if not os.path.exists(pasta_saida):
    os.makedirs(pasta_saida)

  # Realiza o OCR na imagem (usando português como idioma padrão)
  print(
      f"Processando a imagem: {caminho_imagem}..."
  )
  texto_extraido = pytesseract.image_to_string(
      Image.open(caminho_imagem), lang="por"
  )
  linhas = limpar_texto(texto_extraido)

  if not linhas:
    print(f"Nenhum texto encontrado em {caminho_imagem}.")
    return

  # Exemplo de lógica para extrair título e agrupar o conteúdo conforme o padrão .md
  # Você pode ajustar a heurística de acordo com o layout exato dos seus scaneamentos.
  titulo = "MUSICA_EXTRAIDA"
  momento = "outros"

  # Tentativa simples de detectar título baseada em linhas maiúsculas ou numeração
  conteudo_txt = []
  conteudo_txt.append(f"[TITULO]: {titulo}")
  conteudo_txt.append(f"[MOMENTO]: {momento}\n")
  conteudo_txt.append("[ESTROFE 1]")

  for linha in linhas:
    conteudo_txt.append(linha)

  # Nome do arquivo de saída
  nome_base = os.path.splitext(os.path.basename(caminho_imagem))[0]
  caminho_saida = os.path.join(pasta_saida, f"{nome_base}.txt")

  # Salva o arquivo em UTF-8 conforme exigido pelo parser[cite: 1]
  with open(caminho_saida, "w", encoding="utf-8") as f:
    f.write("\n".join(conteudo_txt))

  print(f"Arquivo gerado com sucesso: {caminho_saida}")


# Exemplo de uso em lote para uma pasta com várias imagens
def processar_lote(pasta_imagens=None):
  if pasta_imagens is None:
    pasta_imagens = os.path.join(os.path.dirname(__file__), "musicas_imagens")

  if not os.path.exists(pasta_imagens):
    os.makedirs(pasta_imagens)
    print(
        f"Crie uma pasta chamada '{pasta_imagens}' e coloque suas imagens lá."
    )
    return

  extensoes_validas = (".jpg", ".jpeg", ".png", ".bmp", ".tiff")
  for arquivo in os.listdir(pasta_imagens):
    if arquivo.lower().endswith(extensoes_validas):
      caminho_completo = os.path.join(pasta_imagens, arquivo)
      processar_imagem_para_txt(caminho_completo)


if __name__ == "__main__":
  # Executa o processamento da pasta 'imagens'
  processar_lote()