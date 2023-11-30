# Aplicativo de eBooks

Bem-vindo ao Aplicativo de eBooks! Este é um aplicativo Flutter que permite visualizar uma lista de livros, marcá-los como favoritos e até mesmo ler os livros diretamente no aplicativo. No entanto, devido a algumas dificuldades com a API do Vocsy Epub Reader, a funcionalidade de leitura diretamente do aplicativo pode não estar completamente implementada.

## Pré-requisitos

Certifique-se de ter o Flutter instalado em sua máquina. Se você ainda não o fez, siga as instruções em [Instalação do Flutter](https://flutter.dev/docs/get-started/install).

## Executando o Projeto

1. Clone este repositório em sua máquina local:

   ```bash
   git clone https://github.com/wheeout/app-ebooks
   ```

2. Navegue até o diretório do projeto:

   ```bash
   cd app-ebooks
   ```

3. Execute o aplicativo:

   ```bash
   flutter run
   ```

Isso iniciará o aplicativo no seu emulador ou dispositivo.

## Falha na Implementação da Leitura de Livros

Atualmente, a funcionalidade de leitura diretamente do aplicativo pode não estar funcionando conforme o esperado devido a dificuldades na integração com a API do Vocsy Epub Reader.

## Estrutura do Código

- `main.dart`: Ponto de entrada do aplicativo e configuração do `BookApp`.
- `book_model.dart`: Definição do modelo de dados `Book` e `BookModel` que gerencia a lista de livros.
- `book_home.dart`: Página inicial que exibe a grade de livros e a barra de navegação inferior.
- `book_reader.dart`: Página para ler um livro específico.

## APK

Execute o aplicativo em seu próprio celular Android instalando o **app-ebook.apk** que pode ser encontrado na pasta raiz do projeto.

Aproveite o aplicativo! 📚
